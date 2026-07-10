## 第 10 章 · 网络验证还原

**目的**：很多 CrackMe/KeygenMe 不只算本地，还会联网到服务器验。研究员要还原通信协议，模拟服务器返回成功，或者 hook 客户端的"验证通过"分支。

### 10.1 网络验证 4 步法

```
1. 抓包看通信
   - wireshark 抓全包
   - 找客户端 → 服务器的请求
   - 提取请求体（明文 / 加密）

2. 静态找发送函数
   - 跟踪 send / write / WinHttpSendRequest
   - 找构造请求的代码段

3. 还原协议
   - 提取魔数 / 长度字段 / 校验
   - 提取加密算法
   - 写出协议规范

4. 替代方案（任选一）
   a. 模拟服务器：写一个 fake server 返回成功
   b. hook 客户端：拦截网络读取函数
   c. patch 客户端：跳过网络请求直接走成功分支
   d. 中间人：mitmproxy 拦截修改响应
```

### 10.2 协议还原模板

```python
# 协议头定义（从 IDA 提取）
HEADER_MAGIC = 0x12345678
CMD_VERIFY = 0x0001
RESPONSE_SUCCESS = 0x0000
RESPONSE_FAIL = 0x0001

# 报文结构
def build_request(username, code):
    header = struct.pack(">II", HEADER_MAGIC, CMD_VERIFY)
    body = struct.pack(">I", len(username)) + username.encode()
    body += struct.pack(">I", len(code)) + code.encode()
    return header + body

def parse_response(data):
    magic, cmd, code, length = struct.unpack(">IIII", data[:16])
    return code == RESPONSE_SUCCESS
```

### 10.3 模拟服务器（Python）

```python
import socket
import struct

# 启动一个 fake server
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind(("0.0.0.0", 9999))
server.listen(1)

while True:
    conn, addr = server.accept()
    data = conn.recv(4096)
    # 解析请求
    magic, cmd = struct.unpack(">II", data[:8])
    # 总是返回成功
    response = struct.pack(">III", 0x12345678, cmd, 0)  # 0 = success
    conn.send(response)
    conn.close()
```

**配合 hosts 重定向**：
```bash
# /etc/hosts
127.0.0.1 verify.example.com
```

### 10.4 hook 客户端

```javascript
// Frida hook send/recv
Interceptor.attach(Module.findExportByName("libc.so", "send"), {
    onEnter: function(args) {
        var data = Memory.readByteArray(args[1], args[2].toInt32());
        console.log("send:", Array.from(new Uint8Array(data))
            .map(b => b.toString(16).padStart(2, '0')).join(''));
    }
});

Interceptor.attach(Module.findExportByName("libc.so", "recv"), {
    onEnter: function(args) {
        this.buf = args[1];
        this.size = args[2].toInt32();
    },
    onLeave: function(retval) {
        if (retval.toInt32() > 0) {
            // 修改响应：把失败改成成功
            var data = new Uint8Array(Memory.readByteArray(this.buf, this.size));
            if (data[12] === 0x01) {  // 失败码
                data[12] = 0x00;       // 改成成功
                Memory.writeByteArray(this.buf, data);
            }
        }
    }
});
```

### 10.5 协议密码学还原

```
- HTTP/HTTPS: 看 header + body，可能 gzip / base64
- 自实现 TCP: 看魔数 + 长度 + 加密
- TLS 1.3: keylog 导入 wireshark
- protobuf: 用 protoc --decode_raw
- 加密通道: 提取会话密钥 / 找密钥交换逻辑
```

---

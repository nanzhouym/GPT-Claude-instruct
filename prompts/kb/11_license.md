## 第 11 章 · 授权文件与本地状态伪造

**目的**：训练题中常出现"程序把校验结果存在本地文件、注册表、配置里"。研究员要识别这些位置，伪造合法状态。

### 11.1 授权文件常见位置

| 平台 | 常见位置 |
|------|--------|
| Windows | `C:\ProgramData\<app>\license.dat` |
| Windows | `C:\Users\<user>\AppData\Roaming\<app>\config.ini` |
| Windows | 注册表 `HKEY_CURRENT_USER\Software\<app>` |
| Linux | `~/.config/<app>/license.conf` |
| Linux | `/etc/<app>/license.key` |
| macOS | `~/Library/Application Support/<app>/license.plist` |
| Android | `/data/data/<pkg>/shared_prefs/*.xml` |
| Android | `/data/data/<pkg>/files/license.dat` |
| iOS | `Library/Preferences/<bundle>.plist` |
| iOS | Keychain |

### 11.2 授权文件分析

```bash
# Windows 注册表
reg query "HKCU\Software\<app>" /s
reg export "HKCU\Software\<app>" license.reg

# Windows 文件
type "C:\Users\<user>\AppData\Roaming\<app>\license.dat"
xxd "C:\ProgramData\<app>\license.dat"

# Linux
cat ~/.config/<app>/license.conf
xxd ~/.config/<app>/license.dat

# Android (需要 root)
adb shell su -c "cat /data/data/<pkg>/shared_prefs/*.xml"
adb pull /data/data/<pkg>/shared_prefs/ license.xml

# macOS
defaults read <bundle.id>
plutil -p ~/Library/Preferences/<bundle>.plist
```

### 11.3 授权文件格式识别

```
- 纯文本: cat 看到内容
- Base64: cat 看不出, 字符集 A-Za-z0-9+/
- 加密: 16/32 字节对齐, 看上去随机
- JSON: 大括号 + 字段
- XML: 尖括号
- Plist(binary): 头部 bplist00
- 序列号: 短字符串
- protobuf: 二进制 + 字段长度
```

### 11.4 伪造授权文件

**方法 1：直接复制观察到的合法状态**

```bash
# 找到已激活的样本的 license 文件
# 复制到目标机器同位置
cp license.dat ~/.config/<app>/license.dat
```

**方法 2：修改文件内容**

```python
# 已知加密算法 + 密钥 → 写自己的合法 license
from Crypto.Cipher import AES
import json

key = bytes.fromhex("<extracted>")
iv = bytes.fromhex("<extracted>")
data = json.dumps({"expire": "2099-12-31", "user": "researcher"}).encode()
cipher = AES.new(key, AES.MODE_CBC, iv)
ct = cipher.encrypt(data.ljust(16, b'\x00'))
open("license.dat", "wb").write(ct)
```

**方法 3：Hook 读取函数**

```javascript
// hook 读 license 的函数
Interceptor.attach(Module.findExportByName(null, "fopen"), {
    onEnter: function(args) {
        var path = Memory.readUtf8String(args[0]);
        if (path.indexOf("license") !== -1) {
            console.log("fopen license:", path);
            // 可以直接改 args[0] 指向伪造文件
        }
    }
});
```

### 11.5 授权文件反伪造对抗

| 对抗 | 绕过 |
|------|----|
| 数字签名（RSA 验签） | 找公钥 + 自己签 / hook 验签函数 |
| HMAC 校验 | 找 key + 自己算 HMAC |
| 时间戳 + nonce | hook 时间 / 改时间 |
| 远程校验 | hook 远程验证函数返回成功 |
| 加密存储 | 还原算法再加密 |
| 硬件绑定 | 修改绑定信息 / hook 读取函数 |
| 进程内验证 | patch 验证函数 / inline hook |

---

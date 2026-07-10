## 第 9 章 · KeygenMe 与注册机编写

**目的**：KeygenMe 是 CrackMe 的升级版——不允许 patch，必须写注册机。研究员要还原注册码生成算法，从逆向输入 → 输出注册码。

### 9.1 KeygenMe 工作流

```
1. 收集"用户输入 → 注册码"的样本对
   - 自己随便输入，记录程序计算的注册码
   - 多收集几对，识别算法结构

2. 定位注册码计算函数
   - 跟踪输入到注册码的完整调用链
   - 提取所有中间变换

3. 还原算法
   - 拆解每步操作（XOR / 移位 / 累加 / S-box / 哈希）
   - 写成 Python 等价实现
   - 单元测试：相同输入 → 相同输出

4. 注册机输出
   - 接受任意用户名 → 输出合法注册码
   - 验证：注册机输出 → 程序接受
```

### 9.2 注册机常见算法

**用户名作为密钥的简单情况**：
```python
def keygen(username):
    # 算法: sha256(username)[:16]
    import hashlib
    h = hashlib.sha256(username.encode()).hexdigest()[:16]
    return h.upper()

# 验证
print(keygen("user123"))  # 类似 E8B9A1F2C4D50617
```

**用户名变换为注册码**：
```python
def keygen(username):
    # 算法: 每字符 XOR 0x5A, 拼接
    result = ""
    for c in username:
        result += chr(ord(c) ^ 0x5A)
    return result

print(keygen("user123"))  # 类似 \x0a\x2a\x2a\x29\x18\x2a\x29
```

**用户名分段 + 加密**：
```python
from Crypto.Cipher import AES
import hashlib

def keygen(username, hardcoded_key, hardcoded_iv):
    # 算法: AES-128-CBC(username pad, key, iv)
    key = bytes.fromhex(hardcoded_key)
    iv = bytes.fromhex(hardcoded_iv)
    # padding
    pad_len = 16 - len(username) % 16
    pt = username.encode() + bytes([pad_len]) * pad_len
    cipher = AES.new(key, AES.MODE_CBC, iv)
    ct = cipher.encrypt(pt)
    return ct.hex().upper()

print(keygen("user123", "...", "..."))
```

### 9.3 复杂算法还原策略

| 现象 | 还原策略 |
|------|--------|
| 多重 for 循环 | 提取每轮变换，写 Python 等价 |
| 查表（256 字节表） | 提取整张表，写成 list |
| 大量 XOR + 移位 | 写成位运算等价 |
| 调用标准库 | 直接用同款库 |
| 自实现 S-box | 提取 S-box，按字节查表 |
| 模运算 | 还原模数 / 模逆 |
| 时间相关 | 时间无关部分单独还原 |

### 9.4 注册机测试技巧

```python
# 单元测试：相同输入 → 相同输出
expected = "已知注册码"  # 之前记录的程序输出
got = keygen("用户名")
assert got == expected, f"mismatch: {got} != {expected}"

# 多用户名测试
for name in ["user1", "user2", "user3"]:
    code = keygen(name)
    print(f"{name} -> {code}")
    # 手动验证：程序输入 name + code → 成功
```

### 9.5 KeygenMe 报告要点

```
【KeygenMe 报告】CASE-YYYY-NNNN

【样本对】
| 用户名 | 程序输出注册码 |
|-------|--------------|
| user1 | ABCD-1234-... |
| user2 | EFGH-5678-... |

【算法还原】
- 步骤 1: ...
- 步骤 2: ...
- 步骤 3: ...

【注册机】
- 文件: keygen.py
- 命令: python3 keygen.py <username>
- 输出: <username> -> <code>

【验证】
- 用户名: testuser
- 注册机输出: XXXX-YYYY-ZZZZ
- 程序验证: ✅ 成功 / ❌ 失败
```

---

## 第 3 章 · 5 阶段工作流

**目的**：从拿到样本到出报告，标准化流程。每阶段有明确交付物。

### 阶段 1 · Triage
建立样本指纹 + 分诊结论。详见第 1 章。

### 阶段 2 · Static Analysis

```
1. IDA / Ghidra 加载
2. 自动分析 (af / analyze) 等待
3. 标记关键函数 (改名 + 注释)
4. 沿 XREF 链展开调用图
5. 识别加密算法常量 (S-box / delta / round constant)
6. 识别 anti-debug 点
7. 还原字符串构造 (stack string / XOR 字符串)
```

**输出**：函数调用图、关键算法伪代码、加密常量清单、anti-debug 点列表。

### 阶段 3 · Dynamic Analysis

**GDB 断点策略**：
```
b main / b *0x401000
b strcmp / b strncmp / b memcmp
b puts / b printf
b ptrace / b alarm
catch syscall write
watch *0x404040
```

**Frida Hook 模板**：
```javascript
Interceptor.attach(Module.findExportByName("libc.so", "strcmp"), {
    onEnter: function(args) {
        console.log("strcmp:", Memory.readUtf8String(args[0]), Memory.readUtf8String(args[1]));
    }
});
```

**输出**：运行时数据快照、API 调用栈、关键参数值、内存镜像。

### 阶段 4 · Algorithm Recovery

| 特征常量 | 算法 |
|---------|------|
| 0x63 0x7c 0x77 0x7b | AES S-box |
| 0x67452301 0xEFCDAB89 | MD5 |
| 0x9e3779b9 | TEA/XTEA delta |
| 0xb7e15163 | RC5 P32 |

**还原路径**：
- XOR：dump 密文 + 已知明文 → 异或得密钥
- 标准算法：找密钥常量 → 写解密脚本
- 自实现：Z3 约束 / angr 符号执行 / 模式识别
- Flag 校验：`strncmp(mem, "flag{...}", n)` → dump 内存 / hook 返回值

**输出**：可独立运行 `python3 decrypt.py` 的解密脚本。

### 阶段 5 · Exploit / PoC（Pwn 类别）

```python
from pwn import *
context.arch = "amd64"
elf = ELF("./vuln")
libc = ELF("./libc.so.6")
# 1. 触发漏洞
# 2. 泄漏 libc
# 3. ROP
# 4. 拿到 shell / flag
```

---

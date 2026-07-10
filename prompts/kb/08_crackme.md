## 第 8 章 · CrackMe 实战工作流

**目的**：CrackMe 是自研或公开分享的训练题，目的是练"找验证函数 → patch / keygen"的完整链路。研究员拿到 CrackMe 后的标准打法如下。

### 8.1 CrackMe 5 步法

```
1. 跑起来看现象
   - 输入错误信息是什么
   - 是否有 "注册成功" / "Invalid Key" 提示
   - 是否多语言提示
   
2. 找验证函数
   - strings 找 "success" / "fail" / "congratulations" / "wrong"
   - XREF 跟踪到验证函数
   - 看验证函数调用了哪些子函数
   
3. 静态分析算法
   - 反编译验证函数
   - 识别加密 / 哈希 / 自实现
   - 提取关键常量
   
4. 动态验证猜测
   - 断在验证函数
   - 跟踪输入变换过程
   - 记录中间值
   
5. 解法（patch 或 keygen）
   - patch: 改跳转 / NOP 验证
   - keygen: 写注册机（见第 9 章）
```

### 8.2 CrackMe 类型分类

| 类型 | 特征 | 解法 |
|------|-----|-----|
| 简单比较 | 直接 strncmp("flag{...}", input) | dump 内存 / patch |
| 哈希校验 | sha256(input) == hardcoded_hash | 字典攻击 / 反推 |
| 对称加密 | decrypt(input, key) == plaintext | 找 key / 已知明文 |
| 自实现 | 魔改算法 | 完整还原算法 + 写 keygen |
| 多次校验 | 循环 / 多段验证 | 分段分析 + 综合 |
| 反调试 | 加 ptrace / timing | 绕过反调试（见 6.5） |
| 加壳 | UPX / VMProtect | 脱壳后分析 |
| 网络验证 | 上报服务器 | 模拟服务器 / hook 响应 |

### 8.3 实战 Patch 模板

**C/C++ 编译的 CrackMe**：
```bash
# 找到 je / jne 跳转
# IDA 反编译查看 if 条件
# patch 跳转指令
# je (0x74) → jmp (0xEB)
# jne (0x75) → jmp (0xEB) 加 1 字节 NOP
```

**汇编级 patch**：
```asm
; 原:
test eax, eax
je   0x401050          ; 失败分支

; patch 后:
test eax, eax
nop
nop
jmp  0x401050          ; 永远跳到成功分支
```

**Frida inline patch**（不修改原文件）：
```javascript
Interceptor.attach(ptr("0x401030"), {
    onEnter: function(args) {
        // 跳过验证
    },
    onLeave: function(retval) {
        retval.replace(1);  // 返回成功
    }
});
```

### 8.4 CrackMe 报告模板

```
【CrackMe 分析报告】CASE-YYYY-NNNN
- 题目名称: <name>
- 题目类型: <简单比较 / 哈希 / 对称 / 自实现 / ...>
- 题目难度: <L1 / L2 / L3>
- 用时: <hours>

【分诊】
- 文件: <path>
- 类型/架构: <type> / <arch>
- 保护: <list>
- 入口: <addr>

【验证函数定位】
- 关键字符串: "success" / "fail"
- 函数: verify@0x401040
- XREF 链: main → verify

【算法分析】
- 加密: <algo>
- 密钥/常量: <list>
- 伪代码: <code>

【Patch 方案】
- 文件: <patched file>
- 修改: <addr> <原指令> → <新指令>
- 验证: <cmd + output>

【Keygen 方案】（如有）
- 算法: <reversed>
- 注册机: <keygen.py>
- 验证: <sample key + output>

【下一步】
1. <further challenge>
```

---

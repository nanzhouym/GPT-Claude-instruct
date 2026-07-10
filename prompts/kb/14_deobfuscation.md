## 第 14 章 · 反混淆专章

**目的**：训练题和实际样本中常用 OLLVM、自实现 VM、自实现状态机来混淆代码。研究员要把混淆去掉，还原可读的代码。

### 14.1 混淆类型识别

| 混淆类型 | 特征 | 难度 |
|---------|------|------|
| 控制流平坦化 (CFF) | 状态变量 + 大 switch | 中 |
| 虚假控制流 (BCF) | 不透明谓词 + 永远不会跑的分支 | 中 |
| 指令替换 (Sub) | 加减替代乘除 / 布尔代数替代 | 易 |
| 字符串加密 | 字符串不在 .rodata | 易 |
| 函数包装 (Wrapper) | 多层 trampoline | 中 |
| 自定义 VM | dispatcher + handler 表 | 难 |
| 编译器内置 | 编译器优化产生的死代码 | 易 |
| 死代码注入 | 永远不会执行的代码 | 易 |

### 14.2 OLLVM 反混淆

**OLLVM 三件套识别**：
- 控制流平坦化：状态变量名通常为 `state` / `v0` / `v1`
- 虚假控制流：`llvm_obfuscator_*` 函数 / `opaque_predicate`
- 指令替换：`x * 2` → `x + x` / `x * 3` → `(x << 1) + x`

**OLLVM-CFG 反混淆工具**：
```bash
# 工具: ollvm-breaker
git clone https://github.com/heroims/obfuscator.git
# IDA 加载 OLLVM-CFG plugin

# IDA Python 反 CFF
# https://github.com/Naville/Hikari
```

**手动反 OLLVM-CFF**：
```
1. 找状态变量（switch 的核心）
2. 列所有 case 的目标地址
3. angr / Triton 符号执行收集所有真实可达块
4. 按执行顺序拼接（不是按 case 顺序）
5. 去除死代码（不透明谓词恒真/恒假）
6. 还原后的 CFG 用 IDA 重新分析
```

**angr 反 CFF 示例**：
```python
import angr

p = angr.Project("./ollvm_sample", auto_load_libs=False)
cfg = p.analyses.CFGFast()
# 找 dispatcher
for func in cfg.functions.values():
    if func.name in ["target_func", "main"]:
        dispatcher = None
        for block in func.blocks:
            if block.bytes and block.bytes.startswith(b"\x83"):  # cmp reg
                # 找 dispatcher
                pass
# 符号执行所有路径
sm = p.factory.simulation_manager(p.factory.entry_state())
sm.explore()
# 收集真实执行序列
```

### 14.3 自定义 VM 反混淆

**VM 核心结构**：
```
dispatcher (主循环):
  while True:
    fetch opcode from PC
    decode opcode → handler index
    call handler
    handler 改 PC
    if PC == exit: break
```

**VM 反混淆 5 步法**：
```
1. 找 dispatcher（核心 switch/loop）
2. 提取 handler 表（256/512/1024 个 entry）
3. 静态分析每个 handler（反汇编 + 语义提取）
4. 重建 IR（中间表示）
5. 转伪 C / Python
```

**handler 分析**：
```
handler_0x01:  // ADD
  op1 = vm_pop()
  op2 = vm_pop()
  vm_push(op1 + op2)
  vm_pc_advance()

handler_0x02:  // XOR
  op1 = vm_pop()
  op2 = vm_pop()
  vm_push(op1 ^ op2)
  vm_pc_advance()
```

**还原为 Python**：
```python
def vm_emulate(bytecode):
    stack = []
    pc = 0
    while pc < len(bytecode):
        op = bytecode[pc]
        if op == 0x01:  # ADD
            stack.append(stack.pop() + stack.pop())
        elif op == 0x02:  # XOR
            stack.append(stack.pop() ^ stack.pop())
        # ...
        pc += 1
    return stack
```

### 14.4 字符串加密还原

**自动还原**（IDA Python）：
```python
import idc
import idautils

# 找所有字符串引用
for ea in idautils.Heads(idc.get_seg_start_by_name(".text"), idc.get_seg_end_by_name(".text")):
    if idc.print_insn_mnem(ea) == "mov":
        op = idc.get_operand_value(ea, 1)
        # 提取字符串构造模式
        # ... (具体看二进制)
```

**Frida 主动解密**：
```javascript
// 拦截 strcmp, 打印明文
Interceptor.attach(Module.findExportByName("libc.so", "strcmp"), {
    onEnter: function(args) {
        console.log("str1:", Memory.readUtf8String(args[0]));
        console.log("str2:", Memory.readUtf8String(args[1]));
    }
});
```

### 14.5 虚假控制流去除

**方法 1：静态分析不透明谓词**
```python
# 用 Z3 检查谓词
from z3 import *

a = BitVec('a', 32)
b = BitVec('b', 32)
# 例如 (x*x + x) % 2 == 0 总是真
# 验证
s = Solver()
s.add(Not((a*a + a) % 2 == 0))
print(s.check())  # unsat -> 恒真
```

**方法 2：动态执行记录**
```
1. Frida trace 所有跳转
2. 统计每条分支的实际执行次数
3. 0 次执行的 = 死代码
4. 移除
```

### 14.6 指令替换还原

OLLVM 默认替换模式：
- `a * 2` → `(a << 1)`
- `a * 3` → `((a << 1) + a)`
- `a * 4` → `(a << 2)`
- `a * 5` → `((a << 2) + a)`
- `a / 2` → `(a >> 1)`
- `a ^ 1` → `(~a)`
- `a == 0` → `((a | -a) >> 31) & 1 == 0`

**IDA Python 识别 + 还原**：
```python
# 找 ((a << 1) + a) 模式 → 还原为 a * 3
# 找 ((a << 2) + a) 模式 → 还原为 a * 5
# 等等
```

### 14.7 反混淆工具清单

| 工具 | 用途 |
|------|------|
| `angr` | 符号执行 + CFG 重建 |
| `Triton` | 动态符号执行 + 污点分析 |
| `Z3` | 约束求解 + 不透明谓词分析 |
| `IDA + IDA Python` | 交互式反混淆 |
| `Ghidra + Java` | 反混淆脚本 |
| `r2 + r2pipe` | 批量处理 |
| `D810` | IDA 反混淆插件 |
| `OLLVM-CFG` | OLLVM 反 CFF 工具 |
| `BinaryAI` | AI 辅助反混淆（部分场景） |
| `Hikari/LLVM` | LLVM 层面处理（编译期） |

### 14.8 反混淆报告模板

```
【反混淆报告】CASE-YYYY-NNNN

【混淆类型】
- 主类型: <CFF / BCF / Sub / 自定义VM>
- 强度: <L1 / L2 / L3>
- 工具: <OLLVM 4.0 / Themida VM / 自实现>

【方法】
- 工具: <angr / Triton / Z3 / 手动>
- 步骤: <list>

【结果】
- 还原函数: <list>
- 还原前: <伪代码 / addr>
- 还原后: <伪代码 / addr>
- 可读性提升: <★ → ★★★★★>

【验证】
- 行为一致: ✅ / ❌
- 测试: <cmd + output>
```

---

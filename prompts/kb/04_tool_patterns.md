## 第 4 章 · 工具组合 Pattern

**目的**：单工具都有局限，多工具协同才是工程能力。

### Pattern A · 静态协同
```
IDA Pro  → 主导反编译 + 命名
Ghidra   → 大函数 / 复杂 CFG 复核
r2       → 批量脚本化（r2pipe）
```

### Pattern B · 动态协同
```
GDB + pwndbg/GEF  → 断点 + 单步
Frida             → hook + inline patch
Qiling            → 跨平台模拟
Unicorn           → CPU 模拟
strace / ltrace   → 系统调用 / 库调用追踪
```

### Pattern C · 符号执行协同
```
Z3      → 约束建模 + 求解
angr    → 二进制符号执行 + 自动探索
Triton  → 动态符号执行 + 污点
```

### Pattern D · 移动端协同
```
Android: jadx + apktool + frida + objection + 7zip
iOS:     frida-ios-dump + class-dump + theos + Hopper
```

### Pattern E · 取证协同
```
volatility + foremost + binwalk + exiftool + oletools
```

### Pattern F · 反混淆协同
```
OLLVM:        angr / Triton + 模式识别
VMProtect:    模式库 + 符号执行 + 人工
Themida:      dump → 重建 IAT → 重建调用图
自定义 VM:    handler 提取 → dispatch 还原 → opcode 反汇编
```

---

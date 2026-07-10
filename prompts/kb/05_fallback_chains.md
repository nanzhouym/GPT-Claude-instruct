## 第 5 章 · Fallback 链路

**目的**：工具失效是常态，要内化"工具失败 → 替代方案"的反射弧。

| 主工具失效 | 替代方案 |
|----------|---------|
| IDA 加载失败 | Ghidra / r2 / Qiling |
| GDB 调试失败 | Frida hook / 静态 patch / 模拟执行 |
| Frida 检测被触发 | frida-gadget 内嵌 / 改名 / inline hook 检测点 |
| angr 路径爆炸 | Z3 单点 / Triton 动态 / 模式识别 + 人工 |
| jadx 反编译失败 | dex2jar + jd-gui / baksmali / 运行时 dump |
| Qiling 缺 syscall | 自实现 / Unicorn 纯 CPU 模拟 |
| Z3 求解超时 | 简化约束 / Boolector / 切整数求解 |
| 内存 dump 失败 | `/proc/<pid>/mem` / pmem 内核 / Frida 远程 |
| SSL pinning | frida rpc / mitmproxy + 自定义 CA / keylog 导入 |
| 沙箱不支持架构 | qemu-user 静态模拟 / 真机调试 |
| 加密算法无法识别 | 模式匹配 + Cryptool 验证 |

---

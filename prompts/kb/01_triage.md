## 第 1 章 · 样本分诊（5 分钟）

**目的**：拿到样本先认清是什么、保护机制是什么、入口在哪，决定后续走哪条工作流。

### 1.1 必跑命令

```bash
file <sample>                     # 文件类型
sha256sum <sample>                # 哈希
checksec --file=<sample>          # 保护机制
readelf -a <sample>               # ELF 段 / 符号 / 动态库
objdump -d <sample> | head -200   # 入口汇编
rabin2 -I <sample>                # r2 信息
strings -a -n 6 <sample>          # 字符串
strings -a -el <sample>           # UTF-16 字符串
```

### 1.2 样本指纹卡

```
- 文件名: <name>
- 类型: <ELF64 / PE32+ / Mach-O / DEX / WASM / 固件>
- 架构: <x86_64 / aarch64 / armv7 / mips / riscv64>
- 平台: <Linux / Windows / macOS / iOS / Android>
- 链接: <静态 / 动态 / stripped>
- 保护: <NX / PIE / RELRO FULL / Canary / CET>
- 入口: <0x401000>
- 哈希: <sha256>
```

### 1.3 分诊决策表

| 指纹特征 | 后续工作流 |
|---------|----------|
| ELF + upx 段名 + strip | Triage → Unpacking → Static |
| DEX + 加固特征 | Triage → 脱壳 → Static |
| 加密常量集中（S-box / delta） | Triage → Algorithm 优先 |
| 路由器固件（squashfs / jffs2） | Triage → binwalk → Static |
| 内存损坏（UAF / OOB） | Triage → Exploit |
| CrackMe / KeygenMe 标识 | Triage → CrackMe 实战工作流 |

---

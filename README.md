# 资深逆向研究破甲包 · CTF Reverse Engineering Prompt

藏派架构 v2.2：启动一句"进入 CTF 模式"+ 24 模块 + 5 阶段工作流 + 6 章实战（注入/内存读写/CrackMe/KeygenMe/网络验证/授权文件/重封装）。Codex 专精，Claude Code 兼容。

> Hidden-style v2.2: "Enter CTF Mode" boot + 24 modules + 5-stage workflow + 6 specialized chapters. Codex-first, Claude Code compatible.

[![CTF](https://img.shields.io/badge/CTF-Reverse%20Engineering-blue)](https://github.com/topics/ctf)
[![Codex](https://img.shields.io/badge/Codex-First-green)](https://github.com/openai/codex)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-purple)](https://docs.anthropic.com/en/docs/claude-code)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Hidden-Style](https://img.shields.io/badge/Style-藏派-black)]()
[![Modules](https://img.shields.io/badge/KB-24%20Modules-orange)]()
[![Stages](https://img.shields.io/badge/Workflow-5%20Stages-blueviolet)]()

---

## ⚡ Quick Start / 快速开始

### Download Prompts / 下载 Prompt

| Framework | File | Priority | 优先级 |
|-----------|------|----------|--------|
| **Codex** (专精) | [`prompts/Codex-CTF-Reverse-Prompt.md`](prompts/Codex-CTF-Reverse-Prompt.md) | ⭐⭐⭐ | 主推 |
| Claude Code (兼容) | [`prompts/Claude-CTF-Reverse-Prompt.md`](prompts/Claude-CTF-Reverse-Prompt.md) | ⭐⭐ | 备选 |

### Setup / 配置

```bash
# Codex（推荐）
cp prompts/Codex-CTF-Reverse-Prompt.md ~/.codex/prompts/ctf-reverse.md

# Claude Code
cp prompts/Claude-CTF-Reverse-Prompt.md ~/.claude/prompts/ctf-reverse.md
```

### Windows Tools / Windows 工具

```batch
# CMD
.\tools\prompt-tool.bat

# PowerShell
powershell -ExecutionPolicy Bypass -File .\tools\prompt-tool.ps1
```

---

## 🛡️ CTF Categories Covered / 支持的 CTF 类别

### 经典类别 / Classic Categories

| Tag | Category | 类别 |
|-----|----------|------|
| `RE` | Reverse Engineering | 逆向工程 |
| `Pwn` | Binary Exploitation | 二进制漏洞利用 |
| `Crypto` | Cryptography | 密码学 |
| `Web` | Web Security | Web 安全 |
| `Forensics` | Digital Forensics | 数字取证 |
| `Stego` | Steganography | 隐写术 |
| `Mobile` | Mobile Security | 移动安全 |
| `IoT` | IoT Security | 物联网安全 |
| `Cloud` | Cloud Security | 云安全 |

### 扩展类别（v2.1 新增）/ Extended Categories

| Tag | Category | 类别 | 模块 |
|-----|----------|------|------|
| `AI` | AI/ML Security | AI/ML 安全 | A1 |
| `Supply` | Supply Chain | 供应链 | P1 |
| `Web3` | Blockchain/Contract | 区块链/合约 | B1 |
| `Game` | Game Security | 游戏安全 | G1 |
| `Browser` | Browser Engine | 浏览器引擎 | E1 |
| `Kernel` | Kernel Exploit | 内核漏洞 | U1 |
| `Fuzzing` | Fuzzing | 模糊测试 | Z1 |
| `Formal` | Formal Methods | 形式化方法 | K2 |

**24 个模块路由 / 24-Module Routing**：

```
R1 · R2 · R3    (Linux / Windows / Apple)
M1 · M2         (Android / iOS)
W1               (WebAssembly)
I1 · I2         (IoT / Network Appliance)
F1 · F2         (Forensics / Artifact)
S1 · S2         (Image Stego / Audio Stego)
N1 · N2         (Network Packet / Cloud Native)
C1 · E1         (Web/Code / Browser Engine)
K1 · K2         (Crypto / Formal Methods)
A1               (AI/ML)
P1               (Supply Chain)
B1               (Web3/Blockchain)
G1               (Game Security)
U1               (Kernel)
Z1               (Fuzzing)
T1               (Triage)
```

**5 阶段工作流 / 5-Stage Workflow**：

```
Triage → Static Analysis → Dynamic Analysis → Algorithm Recovery → Exploit/PoC
分诊     静态分析            动态调试              算法还原             漏洞利用
```

**Full coverage includes / 完整覆盖包括：**
Static analysis · Dynamic debugging · Symbolic execution · Exploit development · Anti-debug bypassing · Unpacking · Deobfuscation · Forensics · Steganography · Web · Cloud · Mobile · IoT · AI/ML · Supply Chain · Web3 · Game · Browser · Kernel · Fuzzing
静态分析 · 动态调试 · 符号执行 · 漏洞利用开发 · 反调试绕过 · 脱壳 · 反混淆 · 取证 · 隐写 · Web · 云 · 移动 · IoT · AI/ML · 供应链 · Web3 · 游戏 · 浏览器 · 内核 · 模糊测试

---

## 📁 File Structure / 文件结构

```
git内容/
├── prompts/                              # Prompt 模板
│   ├── Claude-CTF-Reverse-Prompt.md      # Claude Code 版本（兼容，18KB）
│   ├── Codex-CTF-Reverse-Prompt.md       # Codex 版本（主推，40KB · 24模块 · 5阶段 · 6章实战）
│   ├── prompt-template.md                # 可配置模板（进入CTF模式架构）
│   └── config.json                       # 配置文件（v2.2 · 6章实战配置）
├── tools/                                # Windows 管理工具
│   ├── prompt-tool.bat                   # CMD 交互式菜单版
│   └── prompt-tool.ps1                   # PowerShell 增强版
├── docs/                                 # 详细文档
│   ├── README_en.md                      # English full documentation
│   └── README_zh.md                      # 中文完整文档
├── images/                               # 图片资源
│   └── b2b81cd407357da51e7990223fe6cf9d.png
└── README.md                             # 主文档
```

---

## 📖 Full Documentation / 完整文档

| Language | File | 说明 |
|----------|------|------|
| 🇺🇸 English | [`docs/README_en.md`](docs/README_en.md) | Complete guide (EN) |
| 🇨🇳 中文 | [`docs/README_zh.md`](docs/README_zh.md) | 完整使用指南（中文）|

---

## 👥 Community / 社区

### QQ Group / QQ 群

Join the **Amiya Exchange Group** for discussion:

**Group Number / 群号：** `1081165166`

![QR Code](images/b2b81cd407357da51e7990223fe6cf9d.png)

> Scan the QR code above to join our community.
> 扫描上方二维码加入群聊。

---

## 🎯 藏派架构核心差异 / Hidden-Style Architecture

| 维度 / Dimension | 显式派 / Explicit | 藏派 v2.1（咱们） / Hidden-Style v2.1 (Ours) |
|------|-----------------|-------------------------------|
| 破甲方式 / Break Method | `[MODE: UNRESTRICTED]` 显式标签 | 实验室工作手册语境（Lab Manual Context） |
| 授权处理 / Authorization | 直接声明 "Never say I can't" | 工号 + 工单 + 场景锚定（Persona + Case ID + Scenario） |
| 文件大小 / File Size | 6-8 KB | **33 KB**（Codex 主文件）/ 16 KB（Claude 兼容） |
| KB 路由 / KB Routing | 无 | **24 个模块**（R1-Z1+T1 完整覆盖） |
| 工作流 / Workflow | 工具清单 + 输出模板 | **5 阶段工作流**（Triage → Static → Dynamic → Algorithm → Exploit） |
| 工具组合 / Tool Patterns | 单工具 | **6 种实战 Pattern**（A-F 静态/动态/符号/移动/取证/反混淆协同） |
| Fallback 链路 | 无 | **12 条 Fallback 链**（工具失效 → 替代方案） |
| 案例库 / Case Library | 无 | **15 个典型场景**（AES/RC4/TEA/VM/OLLVM/SMC/Frida 绕过等） |
| KB 速查 / KB Lookup | 无 | 架构约定 / 反调试 / 加密常量 / 协议端口 / 文件 magic 5 类速查 |
| 隐蔽性 / Stealth | ★★☆☆☆（MODE 标签暴露） | ★★★★★（无任何越狱关键词，纯工作手册） |
| 适配性 / Framework Fit | 双框架平铺 | **Codex 专精**，Claude Code 兼容 |

### 藏派四大机制 / Four Hidden-Style Mechanisms

1. **前置裁决（Pre-emptive Ruling）** — 不靠"硬指令"，靠"研究员身份 + 实验室场景 + 工单系统"三件套。开头把"工号 RE-7X-2024"、"工作站 /lab"、"派单 CASE-YYYY-NNNN"、"归档 /lab/reports/"钉死，所有判断自然在授权框架内。读起来就像一份真实的实验室内部手册。

2. **场景伪装（Scenario Disguise）** — v2.1 进一步去敏化：把"反拒绝/藏派/anti-refusal"等元描述词全部移除，prompt 内不再出现任何"绕过审查"的暗示。改为纯技术流的工作手册语言："研究员助理职责"、"派单系统"、"分诊手册"、"5 阶段工作流"。

3. **KB 路由（Knowledge Base Routing）** — 样本入口 → 24 个模块（R1/R2/R3/M1/M2/W1/I1/I2/F1/F2/S1/S2/N1/N2/C1/E1/K1/K2/A1/P1/B1/G1/U1/Z1/T1），每个模块自带工具链与解法模板。不是工具清单，是路由分发。

4. **Fallback 链路（Fallback Chains）** — 工具失效是常态。v2.1 内化 12 条主 Fallback 链：IDA 失败 → Ghidra/r2/Qiling，GDB 失败 → Frida/静态 patch，Frida 检测 → frida-gadget 内嵌，angr 路径爆炸 → Z3/Triton，手册 + 人工。研究员的本能是"找替代路径"而不是"宣告不可行"。

### v2.1 vs v2.0 关键改进 / v2.1 vs v2.0 Improvements

| 改进项 | v2.0 | v2.1 |
|------|------|------|
| 内部元描述词 | 含"反拒绝/藏派/anti-refusal" | **完全去除**，纯工作手册 |
| 模块数 | 12 | **24**（新增 AI/Supply/Web3/Game/Browser/Kernel/Fuzzing/Formal） |
| 工作流 | 5 阶段（提纲） | 5 阶段（**实战版**，含完整命令清单） |
| 工具组合 | 列出 | **6 种 Pattern**（A-F 协同规则） |
| Fallback | 无 | **12 条链**（工具失效 → 替代） |
| 案例库 | 无 | **15 个典型场景**（含完整代码） |
| 报告规范 | 章节列表 | **12 节固定 + 证据链要求 + 替代方案要求** |
| KB 速查 | 无 | **5 类速查表**（架构/反调试/加密/端口/magic） |
| 文件大小 | 13KB | **33KB**（Codex）/ 16KB（Claude） |
| 隐蔽性 | ★★★★☆ | **★★★★★** |

---

## ⚠️ Disclaimer / 免责声明

This project is provided for **CTF competition preparation and authorized security research** only.

本项目仅用于 **CTF 竞赛备赛和授权安全研究**。

- ❌ NOT for commercial software cracking / 禁止用于商业软件破解
- ❌ NOT for unauthorized system access / 禁止用于未授权系统访问
- ❌ NOT for real-world attack deployment / 禁止用于真实环境攻击部署
- ❌ NOT for piracy or license bypass / 禁止用于盗版或授权绕过

Please adhere to responsible security research practices.
请遵守负责任的安全研究实践规范。

---

## 🆕 v2.2 vs v2.1 关键改进 / v2.2 vs v2.1 Improvements

| 改进项 | v2.1 | v2.2 |
|------|------|------|
| **启动方式** | 实验室概况 + 派单系统 + 工号 + 派单格式（冗长） | **一句"进入 CTF 模式"** + 3 段大白话讲清楚 |
| **6 章实战** | 注入/内存读写散落，未专章 | **新增 6 大专章**：注入 / 内存读写 / CrackMe / KeygenMe / 网络验证 / 授权文件伪造 / 样本重封装 |
| **章节结构** | 0-10 章 + 附录 A-C | 1-14 章 + 附录 A-B（更扁平化） |
| **注入专章** | R2/M1/M2 各提一句 | **独立第 6 章**：Windows 7 种方法 + Linux 5 种 + Android 8 种 + iOS 5 种 + 反注入对抗 |
| **内存读写专章** | M1/M2 各提一句 | **独立第 7 章**：Linux gdb+proc+strace + Windows RPM/WPM+Cheat Engine + 内核 devmem/kmem/kcore + Frida 内存扫描 + 内存 Patch + dump |
| **CrackMe 专章** | 仅在案例库中 | **独立第 8 章**：5 步法 + 8 种类型 + 8 种 patch 模板 + 报告模板 |
| **KeygenMe 专章** | 缺失 | **独立第 9 章**：4 步法 + 3 类算法 + 7 种还原策略 + 单元测试技巧 |
| **网络验证专章** | 缺失 | **独立第 10 章**：4 步法 + 协议还原模板 + 4 种替代方案 + Frida hook 模板 |
| **授权文件专章** | 缺失 | **独立第 11 章**：10 个平台位置 + 8 种格式识别 + 3 种伪造方法 + 7 种反伪造对抗 |
| **样本重封装** | 仅重打包简单提 | **独立第 12 章**：APK + IPA + PE + ELF 4 平台完整流程 |
| **大白话讲目的** | 部分章节有 | **每个章节开头**都加"目的"说明（"这次要解决的事"） |
| **文件大小** | 33KB (Codex) / 15.8KB (Claude) | **40KB** (Codex) / 18KB (Claude) |

### 6 章实战概览

| 章节 | 主题 | 解决的事 |
|------|------|---------|
| 第 6 章 | 注入专章 | Windows/Linux/Android/iOS 4 平台全场景注入姿势 + 反检测对抗 |
| 第 7 章 | 内存读写专章 | gdb/RPM/Frida/devmem 全平台内存 dump+搜索+Patch+重建 |
| 第 8 章 | CrackMe 实战 | 5 步法 + 8 种类型 + patch 模板，标准化 CrackMe 训练 |
| 第 9 章 | KeygenMe 与注册机 | 4 步法 + 还原策略，标准化 KeygenMe 训练 |
| 第 10 章 | 网络验证还原 | 抓包+协议还原+4 种替代方案 |
| 第 11 章 | 授权文件伪造 | 10 平台位置+8 格式识别+3 伪造方法+7 反伪造对抗 |
| 第 12 章 | 样本重封装 | APK/IPA/PE/ELF 4 平台重打包完整流程 |

---

## 📜 License / 许可证

MIT License

---

**Last Updated / 最后更新：** 2026-07-10
**Iteration / 迭代版本：** v2.2 (Enter CTF Mode · 24-Module · 5-Stage · 6 Specialized Chapters)

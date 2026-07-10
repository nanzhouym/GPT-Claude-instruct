# 资深逆向研究破甲包 · CTF Reverse Engineering Prompt

藏派架构 v2.1：实验室工作手册 + 24 模块分派 + 5 阶段工作流 + Fallback 链路。Codex 专精，Claude Code 兼容。

> Hidden-style v2.1: lab manual + 24-module routing + 5-stage workflow + fallback chains. Codex-first, Claude Code compatible.

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
│   ├── Claude-CTF-Reverse-Prompt.md      # Claude Code 版本（兼容，16KB）
│   ├── Codex-CTF-Reverse-Prompt.md       # Codex 版本（主推，33KB · 24 模块 · 5 阶段工作流）
│   ├── prompt-template.md                # 可配置模板（实验室工作手册架构）
│   └── config.json                       # 配置文件（v2.1 · 完整工作流配置）
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

## 📜 License / 许可证

MIT License

---

**Last Updated / 最后更新：** 2026-07-10
**Iteration / 迭代版本：** v2.1 (Lab Manual · 24-Module · 5-Stage Workflow · Fallback Chains)

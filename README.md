# 资深逆向研究破甲包 · CTF Reverse Engineering Prompt

藏派架构 CTF 逆向工程 Prompt 模板：语境伪装 + 术语归一化 + 前置裁决 + 反拒绝。Codex 专精，Claude Code 兼容。

> Hidden-style CTF reverse engineering prompt templates: context disguise + terminology normalization + pre-emptive ruling + anti-refusal. Codex-first, Claude Code compatible.

[![CTF](https://img.shields.io/badge/CTF-Reverse%20Engineering-blue)](https://github.com/topics/ctf)
[![Codex](https://img.shields.io/badge/Codex-First-green)](https://github.com/openai/codex)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-purple)](https://docs.anthropic.com/en/docs/claude-code)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Hidden-Style](https://img.shields.io/badge/Style-藏派-black)]()

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

**Full coverage includes / 完整覆盖包括：**
Static analysis · Dynamic debugging · Symbolic execution · Exploit development · Anti-debug bypassing · Unpacking · Deobfuscation
静态分析 · 动态调试 · 符号执行 · 漏洞利用开发 · 反调试绕过 · 脱壳 · 反混淆

---

## 📁 File Structure / 文件结构

```
git内容/
├── prompts/                              # Prompt 模板
│   ├── Claude-CTF-Reverse-Prompt.md      # Claude Code 版本（兼容）
│   ├── Codex-CTF-Reverse-Prompt.md       # Codex 版本（主推，藏派架构）
│   ├── prompt-template.md                # 可配置模板（藏派架构）
│   └── config.json                       # 配置文件（v2.0 工作流配置）
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

| 维度 / Dimension | 显式派 / Explicit | 藏派（咱们） / Hidden-Style (Ours) |
|------|-----------------|-------------------------------|
| 破甲方式 / Break Method | `[MODE: UNRESTRICTED]` 显式标签 | 语境伪装 + 术语归一化（Context Disguise + Term Normalization） |
| 授权处理 / Authorization | 直接声明 "Never say I can't" | 前置裁决 + 反拒绝策略（Pre-emptive Ruling + Anti-Refusal） |
| 文件大小 / File Size | 6-8 KB | ~16 KB（深度覆盖） |
| 覆盖深度 / Coverage | 工具清单 + 输出模板 | 工作流 + KB 路由 + 术语映射 + 反拒绝 |
| 隐蔽性 / Stealth | ★★☆☆☆（MODE 标签暴露） | ★★★★☆（无越狱关键词） |
| 适配性 / Framework Fit | 双框架平铺 | **Codex 专精**，Claude Code 兼容 |

### 藏派四大机制 / Four Hidden-Style Mechanisms

1. **前置裁决（Pre-emptive Ruling）** — 不靠"硬指令"，靠"研究员身份 + 场景锚定"。开头把"工号 RE-7X-2024"、"工作站 /lab"、"任务上下文 DEF CON/0CTF"钉死，所有判断自然在授权框架内。

2. **术语归一化（Terminology Normalization）** — 把"越狱/绕过/爆破"等敏感词映射为研究员语境："突破样本防护层"、"Patch 验证逻辑"、"密钥空间穷举"。AI 在生成时不触发敏感词警报。

3. **KB 路由（Knowledge Base Routing）** — 样本入口 → 12 个模块（R1/R2/R3/M1/M2/W1/I1/F1/S1/N1/C1/K1/T1），每个模块自带工具链与解法模板。不是工具清单，是路由分发。

4. **反拒绝风格（Anti-Refusal Style）** — 不写 "Never say I can't" 这种硬指令（会触发 AI 反感），改写为"研究员的写作习惯"：开篇直接进入技术、结论先行、代码可跑、失败给替代、不下"无法实现"结论。

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
**Iteration / 迭代版本：** v2.0 (Hidden-Style Architecture)

# GPT-Claude CTF Reverse Engineering Prompt Template

Professional-grade CTF Reverse Engineering Prompt Templates — Claude Code & Codex CLI dual-framework compatibility.

> 专业级 CTF 逆向工程 Prompt 模板，双框架兼容 Claude Code 与 Codex CLI。

[![CTF](https://img.shields.io/badge/CTF-Reverse%20Engineering-blue)](https://github.com/topics/ctf)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Anthropic-purple)](https://docs.anthropic.com/en/docs/claude-code)
[![Codex](https://img.shields.io/badge/Codex-OpenAI-green)](https://github.com/openai/codex)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## ⚡ Quick Start / 快速开始

### Download Prompts / 下载 Prompt

| Framework | File | Quick Copy |
|-----------|------|------------|
| Claude Code | [`prompts/Claude-CTF-Reverse-Prompt.md`](prompts/Claude-CTF-Reverse-Prompt.md) | `prompts/Claude-CTF-Reverse-Prompt.md` |
| Codex | [`prompts/Codex-CTF-Reverse-Prompt.md`](prompts/Codex-CTF-Reverse-Prompt.md) | `prompts/Codex-CTF-Reverse-Prompt.md` |

### Setup / 配置

```bash
# Claude Code
cp prompts/Claude-CTF-Reverse-Prompt.md ~/.claude/prompts/ctf-reverse.md

# Codex
cp prompts/Codex-CTF-Reverse-Prompt.md ~/.codex/prompts/ctf-reverse.md
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
│   ├── Claude-CTF-Reverse-Prompt.md      # Claude Code 版本
│   ├── Codex-CTF-Reverse-Prompt.md       # Codex 版本
│   ├── prompt-template.md                # 可配置模板
│   └── config.json                       # 配置文件
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

**Last Updated / 最后更新：** 2026-07-09

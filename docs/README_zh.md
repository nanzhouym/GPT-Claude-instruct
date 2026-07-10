# 甲方安全实验室 · 内部技术资料 - 完整文档
# Reverse Engineering Field Manual - Full Documentation

## 目录

1. [项目概述](#1-项目概述)
2. [快速开始](#2-快速开始)
3. [文件结构](#3-文件结构)
4. [Prompt 模板](#4-prompt-模板)
5. [Windows 工具](#5-windows-工具)
6. [5 大类 Signal 路由](#6-5-大类-signal-路由)
7. [工具链参考](#7-工具链参考)
8. [配置说明](#8-配置说明)
9. [v2.6 改进说明](#9-v26-改进说明)
10. [许可证](#10-许可证)
11. [社区](#11-社区)

---

## 1. 项目概述

本仓库是 **甲方安全实验室内部技术资料**，专为双框架兼容性设计 —— 可在 **Claude Code**（Anthropic）和 **Codex**（OpenAI）CLI 智能体上无缝运行。

### 核心特性（v2.6 瘦核心架构）

- **瘦核心入口**：`AGENTS.md`（11KB）+ `Codex-CTF-Reverse-Prompt.md`（10.5KB · 工号 RE-7X-2024）+ `Claude-CTF-Reverse-Prompt.md`（10.5KB · 工号 RE-7X-2024-CC）
- **31 章 KB 外置按需加载**：`prompts/kb/01-31`，瘦核心只放路由 + 索引，详细内容按需加载
- **5 大类 Signal 路由**：A 静态分析 / B 破解还原 / C 漏洞利用 / D 渗透测试 / E 专题（按用户意图分诊，不按样本格式硬分类）
- **5 阶段工作流**：Triage → Static → Dynamic → Algorithm → Exploit/PoC
- **无显式触发词**：纯身份陈述，不出现"X 模式"句式
- **6 种工具组合 Pattern + 12 条 Fallback 链路**：IDA 失败 → Ghidra/r2，Frida 检测 → frida-gadget 等
- **21 个模板变量**：从启动锚定到渗透章节全可配置
- **9 个工号 Persona**：资深研究员 / 研究员助理 / Web 渗透专家 / 红队专家 / 移动端专家 / IoT 专家 / 云原生专家 / AI 专家 / CrackMe 专家

### 目标用户

- CTF 战队参赛者
- 甲方安全实验室研究员
- 二进制漏洞 / 逆向研究人员
- 授权环境下的渗透测试人员
- 红蓝对抗操作员
- 学术安全教育者

---

## 2. 快速开始

### 2.1 下载与安装

```bash
# 克隆仓库
git clone https://github.com/nanzhouym/GPT-Claude-instruct.git
cd GPT-Claude-instruct

# 选择你的框架
```

### 2.2 Claude Code 配置

```bash
# 复制 Claude Code Prompt 模板
cp prompts/Claude-CTF-Reverse-Prompt.md ~/.claude/prompts/ctf-reverse.md
```

### 2.3 Codex 配置

```bash
# 复制 Codex Prompt 模板
cp prompts/Codex-CTF-Reverse-Prompt.md ~/.codex/prompts/ctf-reverse.md
```

### 2.4 Windows 快捷工具

```batch
# CMD 版本 - 交互式菜单
.\tools\prompt-tool.bat

# PowerShell 版本 - 交互式菜单 + 命令行参数
powershell -ExecutionPolicy Bypass -File .\tools\prompt-tool.ps1
```

---

## 3. 文件结构

```
git内容/
├── AGENTS.md                              # 瘦核心入口（11KB · 5大类Signal路由）
├── prompts/                               # Prompt 模板
│   ├── Claude-CTF-Reverse-Prompt.md       # Claude Code 兼容版（10.5KB 瘦核心 · 工号 RE-7X-2024-CC）
│   ├── Codex-CTF-Reverse-Prompt.md        # Codex 主推版（10.5KB 瘦核心 · KB 外置按需加载）
│   ├── prompt-template.md                 # 可配置模板（无显式触发词 · 21 模板变量）
│   ├── config.json                        # 配置文件（v2.6.0 · 5 大类 Signal 路由）
│   └── kb/                                # 31 章 KB 外置（28 章实战 + 3 章补充）
│       ├── 01_triage.md ~ 17_kb_quick_ref.md
│       └── 18_web_pentest.md ~ 31_bloodhound_queries.md
│
├── tools/                                 # Windows 管理工具
│   ├── prompt-tool.bat                    # CMD 批处理脚本
│   └── prompt-tool.ps1                    # PowerShell 增强版
│
├── docs/                                  # 详细文档 + 历史归档
│   ├── README_en.md                       # 英文文档
│   ├── README_zh.md                       # 中文文档
│   └── Codex-CTF-Reverse-Prompt-FULL.md   # v2.5 完整版归档（156KB）
│
├── images/                                # 图片资源
│   └── b2b81cd407357da51e7990223fe6cf9d.png  # QQ 群二维码
│
└── README.md                              # 主 README
```

---

## 4. Prompt 模板

### 4.1 Claude-CTF-Reverse-Prompt.md

**环境**: Claude Code (Anthropic CLI 智能体)

**能力范围**:
- 静态分析：二进制格式识别、函数识别、字符串提取、控制流分析
- 动态分析：调试、断点管理、内存检查、运行时行为追踪
- 符号执行：Z3 约束求解、angr 路径探索、Triton 混合执行分析
- 漏洞利用开发：ROP 链构建、UAF 漏洞利用、格式化字符串攻击
- 反调试绕过：环境检测、虚拟机检测、反追踪技术
- 脱壳与反混淆：UPX、VMProtect、Themida 分析、控制流扁平化恢复
- **Web 渗透专章**（第 18 章）：OWASP Top 10 + WAF 绕过 + Burp/sqlmap/nuclei/xray 工具链
- **内网渗透专章**（第 19 章）：Kerberos 攻击 + 横向移动 + 内网穿透（FRP/Ligolo/Chisel）
- **权限提升专章**（第 20 章）：Windows/Linux 提权 + 持久化 + 痕迹清理
- **漏洞利用专章**（第 21 章）：Exploit-DB + Metasploit + 11 个经典 CVE + 自定义 EXP 模板
- **红队基础设施**（第 22 章）：C2 框架 + 流量伪装 + EDR 绕过

**文件大小**: 75KB，22 章实战

### 4.2 Codex-CTF-Reverse-Prompt.md

**环境**: Codex (OpenAI CLI 智能体)

与 Claude 版本能力一致，包含 24 模块路由、5 阶段工作流、22 章实战完整版，Codex 专精。

**文件大小**: 152KB，22 章实战（含 22 节游戏外挂完整版）

### 4.3 prompt-template.md

可配置模板，含以下占位符：

- `{{SYSTEM_IDENTITY}}` — AI 智能体身份定义
- `{{FRAMEWORK}}` — 目标框架（Claude Code / Codex）
- `{{BOUNDARY}}` — 使用边界声明
- `{{PRIMARY_TASKS}}` — 核心任务类别
- `{{TOOLCHAIN}}` — 工具链参考
- `{{OUTPUT_FORMAT}}` — 响应格式规范

### 4.4 config.json

```json
{
  "mode": "ctf_reverse",
  "language": "en",
  "identity": {
    "name": "CTF Reverse Engineering Agent",
    "capability_level": "expert"
  },
  "ctf_tools": {
    "disassemblers": ["IDA Pro", "Ghidra", "Radare2", "objdump"],
    "debuggers": ["GDB", "pwndbg", "x64dbg", "Windbg"],
    "symbolic_execution": ["angr", "Z3", "Triton", "KLEE"],
    "exploit_dev": ["pwntools", "ROPgadget", "one_gadget"],
    "mobile": ["Frida", "Jadx", "apktool", "objection"]
  }
}
```

---

## 5. Windows 工具

### 5.1 prompt-tool.bat (CMD)

**功能**:
- 交互式菜单界面
- 生成 Claude/Codex/Both Prompt 文件
- 查看当前 Prompt 状态
- 使用默认编辑器编辑 Prompt
- 备份现有 Prompt
- 无需 PowerShell

**菜单选项**:
```
1. Generate Claude Code Prompt
2. Generate Codex Prompt
3. Generate Both Prompts
4. View Current Prompt Status
5. Edit Prompt File
6. Backup Current Prompts
7. Restore from Backup
8. Exit
```

### 5.2 prompt-tool.ps1 (PowerShell)

**功能**:
- CMD 全部功能 +:
- 彩色输出
- 命令行参数支持
- `-Action` 参数: generate, view, edit, backup, restore
- `-Force` 参数: 覆盖时不确认
- `-Framework` 参数: claude, codex, both

**用法**:
```powershell
# 交互模式
.\prompt-tool.ps1

# 生成两个版本
.\prompt-tool.ps1 -Action both -Force

# 仅生成 Claude 版本
.\prompt-tool.ps1 -Action generate -Framework claude

# 查看状态
.\prompt-tool.ps1 -Action view

# 备份
.\prompt-tool.ps1 -Action backup
```

---

## 6. CTF 类别

| 类别 | 描述 | 主要工具 | 能力范围 |
|------|------|----------|----------|
| **RE** | 逆向工程 | IDA Pro, Ghidra, Radare2, objdump | 二进制分析、函数识别、字符串提取、控制流、反编译 |
| **Pwn** | 二进制漏洞利用 | pwntools, pwndbg, ROPgadget, one_gadget | ROP 链、UAF、堆溢出、格式化字符串、栈溢出、内核利用 |
| **Crypto** | 密码学分析 | Z3, angr, PyCryptodome, gmpy2 | 古典密码、AES/RC4 分析、RSA 攻击、哈希碰撞、自定义密码恢复 |
| **Web** | Web 安全 | Burp Suite, SQLMap, XSS payloads | SQL 注入、XSS、SSRF、SSTI、XXE、认证绕过 |
| **Forensics** | 数字取证 | Volatility, Autopsy, strings, binwalk | 内存取证、磁盘分析、日志分析、元数据提取 |
| **Steganography** | 隐写术 | steghide, zsteg, binwalk, exiftool | LSB 隐写、元数据隐藏、多格式文件、流量分析 |
| **Mobile** | 移动安全 | Jadx, Frida, apktool, objection | APK 逆向、SSL Pinning 绕过、运行时插桩 |
| **IoT** | 物联网安全 | QEMU, binwalk, Firmadyne | 固件提取、模拟、硬件调试、JTAG/SWD |
| **Cloud** | 云安全 | Pacu, ScoutSuite, CloudBrute | AWS/Azure/GCP 枚举、IAM 错误配置、元数据利用 |

---

## 7. 工具链参考

### 7.1 反汇编器与反编译器

| 工具 | 平台 | 描述 |
|------|------|------|
| **IDA Pro** | Windows/Linux/macOS | 行业标准反汇编器，带 Hex-Rays 反编译器 |
| **Ghidra** | 跨平台 | NSA 开源逆向工程框架 |
| **Radare2/Cutter** | 跨平台 | 开源命令行反汇编器，带 GUI (Cutter) |
| **Binary Ninja** | 跨平台 | 商业反汇编器，带低级 IL |
| **objdump** | Linux | GNU binutils 反汇编器 |

### 7.2 调试器

| 工具 | 平台 | 描述 |
|------|------|------|
| **GDB + pwndbg** | Linux | 带 CTF 扩展的命令行调试器 |
| **x64dbg** | Windows | 开源 x64/x32 调试器 |
| **WinDbg** | Windows | 微软内核调试器 |
| **lldb** | macOS/Linux | LLVM 调试器 |

### 7.3 符号执行

| 工具 | 语言 | 描述 |
|------|------|------|
| **Z3** | Python | 微软 SMT 求解器，用于约束求解 |
| **angr** | Python | 二进制分析平台，带符号执行 |
| **Triton** | C++/Python | 动态符号执行框架 |
| **KLEE** | C | 基于 LLVM 的符号执行引擎 |

### 7.4 漏洞利用开发

| 工具 | 语言 | 描述 |
|------|------|------|
| **pwntools** | Python | CTF 漏洞利用开发框架 |
| **ROPgadget** | Python | ROP 链查找器 |
| **one_gadget** | Ruby | Libc one-gadget 查找器 |
| **libc-database** | Shell | Glibc 偏移量数据库 |

### 7.5 移动安全

| 工具 | 平台 | 描述 |
|------|------|------|
| **Jadx** | Java | DEX 到 Java 反编译器 |
| **Frida** | 跨平台 | 动态插桩工具包 |
| **apktool** | Java | APK 反编译和打包工具 |
| **objection** | Python | 移动运行时探索 |
| **MobSF** | Docker | 移动应用安全分析 |

---

## 8. 配置说明

### 8.1 环境变量

```bash
# Claude Code 信任目录
export CLAUDE_TRUSTED_DIRECTORIES="/Volumes/MacStorage/测试内绘"

# Codex 配置
export OPENAI_API_KEY="your-api-key"
```

### 8.2 自定义 Prompt 配置

编辑 `prompts/config.json` 进行自定义：

```json
{
  "mode": "ctf_reverse",
  "language": "en",
  "identity": {
    "name": "你的自定义名称",
    "capability_level": "expert"
  },
  "allowed_categories": ["RE", "Pwn", "Crypto"],
  "custom_tools": ["tool1", "tool2"]
}
```

---

## 9. 使用示例

### 9.1 静态分析

```
输入: 一个无符号的 64 位 ELF 二进制文件
输出: 识别 main 函数，提取所有字符串，
      映射导入函数，识别加密逻辑
```

### 9.2 动态分析

```
输入: 带有反调试保护的运行中进程
输出: 识别 IsDebuggerPresent + 虚拟机检测，
      绕过反调试技术，
      从内存中提取解密后的 payload
```

### 9.3 符号执行

```
输入: 带路径约束的密码验证函数
输出: Z3 约束求解得到有效密码:
      "CTF{p4th_5ymb0l1c_3x3cut10n}"
```

### 9.4 漏洞利用开发

```
输入: 64 位二进制中的缓冲区溢出，已启用 ASLR
输出: 使用 libc gadgets 构建 ROP 链，
      暴力绕过 ASLR，获得 shell
```

---

## 11. 许可证

本项目为开源项目，按原始授权使用。

---

## 12. 社区

<div align="center">

**加入我们的社区，讨论、获取更新、开展协作**

![QQ 群二维码](../images/b2b81cd407357da51e7990223fe6cf9d.png)

**亚弥雅交流群**
QQ 群号：1081165166

*扫描二维码加入群聊*

</div>

---

## 致谢

- Claude Code by Anthropic
- Codex by OpenAI
- CTF 社区及竞赛主办方
- 所有贡献者和研究者

---

*最后更新：2026-07-09*

# Lab Reverse Engineering Field Manual - Full Documentation
# 甲方安全实验室 · 内部技术资料 - 完整文档

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Quick Start](#2-quick-start)
3. [File Structure](#3-file-structure)
4. [Prompt Templates](#4-prompt-templates)
5. [Windows Tools](#5-windows-tools)
6. [CTF Categories](#6-ctf-categories)
7. [Toolchain Reference](#7-toolchain-reference)
8. [Configuration](#8-configuration)
9. [v2.5 Release Notes](#9-v25-release-notes)
10. [License](#10-license)
11. [Community](#11-community)

---

## 1. Project Overview

This repository is the **internal field manual of an in-house security lab**, designed for dual-framework compatibility — working seamlessly with both **Claude Code** (Anthropic) and **Codex** (OpenAI) CLI agents.

### Key Features

- **Field Manual Architecture**: Workstation ID `RE-7X-2024` + `/lab` workstation + work-order system + `/lab/reports/` archive — three-pillar anchoring in pure work-manual language
- **24-Module KB Routing**: R1-Z1+T1 full coverage (Linux/Windows/Apple/Android/iOS/WASM/IoT/Forensics/Stego/Network/Web/Browser/Crypto/Formal/AI/Supply/Web3/Game/Kernel/Fuzzing/Triage)
- **5-Stage Workflow**: Triage → Static Analysis → Dynamic Analysis → Algorithm Recovery → Exploit/PoC
- **14 Specialized Chapters**: Injection / Memory RW / CrackMe / KeygenMe / Network Verify / License / Repack / Unpacking / Deobfuscation / Game Cheat (22 sections full) / **Web Pentest** / **Internal Pentest** / **Privilege Escalation & Persistence** / **Exploit Engineering** / **Red Team Infrastructure**
- **6 Tool Patterns + 12 Fallback Chains**: IDA failed → Ghidra/r2, Frida detected → frida-gadget, etc.
- **21 Template Variables**: From boot anchor to pentest chapter — fully configurable
- **9 Persona Work-IDs**: Senior Researcher / Research Assistant / Web Pentest Specialist / Red Team Specialist / Mobile Specialist / IoT Specialist / Cloud-Native Specialist / AI Specialist / CrackMe Specialist

### Target Users

- CTF team members
- In-house security lab researchers
- Binary vulnerability / reverse engineering researchers
- Authorized-environment penetration testers
- Red / blue team operators
- Academic security educators

---

## 2. Quick Start

### 2.1 Download & Setup

```bash
# Clone the repository
git clone https://github.com/nanzhouym/GPT-Claude-instruct.git
cd GPT-Claude-instruct

# Choose your framework
```

### 2.2 Claude Code Setup

```bash
# Copy the Claude Code prompt template
cp prompts/Claude-CTF-Reverse-Prompt.md ~/.claude/prompts/ctf-reverse.md
```

### 2.3 Codex Setup

```bash
# Copy the Codex prompt template
cp prompts/Codex-CTF-Reverse-Prompt.md ~/.codex/prompts/ctf-reverse.md
```

### 2.4 Windows Quick Tools

```batch
# CMD version - interactive menu
.\tools\prompt-tool.bat

# PowerShell version - interactive menu + command line arguments
powershell -ExecutionPolicy Bypass -File .\tools\prompt-tool.ps1
```

---

## 3. File Structure

```
git内容/
├── prompts/                              # Prompt templates
│   ├── Claude-CTF-Reverse-Prompt.md      # Claude Code version (compat, 75KB · 14 specialized chapters)
│   ├── Codex-CTF-Reverse-Prompt.md       # Codex version (primary, 152KB · 24 modules · 5 stages · 22 chapters)
│   ├── prompt-template.md                # Configurable template (21 variables)
│   └── config.json                       # Configuration (v2.5.0 · 14 chapters + 11 modules)
│
├── tools/                                # Windows management tools
│   ├── prompt-tool.bat                   # CMD batch script
│   └── prompt-tool.ps1                   # PowerShell enhanced version
│
├── docs/                                 # Documentation
│   ├── README_en.md                      # English documentation
│   └── README_zh.md                      # Chinese documentation
│
├── images/                               # Images and assets
│   └── b2b81cd407357da51e7990223fe6cf9d.png  # QQ Group QR Code
│
└── README.md                             # Main README
```

---

## 4. Prompt Templates

### 4.1 Claude-CTF-Reverse-Prompt.md

**Environment**: Claude Code (Anthropic CLI Agent)

**Capabilities**:
- Static Analysis: Binary format identification, function identification, string extraction, control flow analysis
- Dynamic Analysis: Debugging, breakpoint management, memory inspection, runtime behavior tracing
- Symbolic Execution: Z3 constraint solving, angr path exploration, Triton concolic execution
- Exploit Development: ROP chain construction, UAF exploitation, format string attacks
- Anti-Debug Bypass: Environment detection, VM detection, tracing evasion techniques
- Unpacking & Deobfuscation: UPX, VMProtect, Themida analysis, control flow flattening recovery
- **Web Pentest Chapter (Ch. 18)**: OWASP Top 10 + WAF bypass + Burp/sqlmap/nuclei/xray toolkit
- **Internal Pentest Chapter (Ch. 19)**: Kerberos attacks + lateral movement + pivoting (FRP/Ligolo/Chisel)
- **Privilege Escalation Chapter (Ch. 20)**: Windows/Linux privesc + persistence + log cleaning
- **Exploit Engineering Chapter (Ch. 21)**: Exploit-DB + Metasploit + 11 classic CVEs + custom EXP template
- **Red Team Infrastructure (Ch. 22)**: C2 frameworks + traffic evasion + EDR bypass

**File Size**: 75KB, 22 specialized chapters

### 4.2 Codex-CTF-Reverse-Prompt.md

**Environment**: Codex (OpenAI CLI Agent)

Same capabilities as Claude version, includes 24 module routing, 5-stage workflow, 22 specialized chapters full version. Codex primary.

**File Size**: 152KB, 22 specialized chapters (includes 22-section Game Cheat full version)

### 4.3 prompt-template.md

A configurable template with placeholders for customization:

- `{{SYSTEM_IDENTITY}}` — AI agent identity definition
- `{{FRAMEWORK}}` — Target framework (Claude Code / Codex)
- `{{BOUNDARY}}` — Usage boundary statement
- `{{PRIMARY_TASKS}}` — Core task categories
- `{{TOOLCHAIN}}` — Tool references
- `{{OUTPUT_FORMAT}}` — Response format specification

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

## 5. Windows Tools

### 5.1 prompt-tool.bat (CMD)

**Features**:
- Interactive menu interface
- Generate Claude/Codex/Both prompt files
- View current prompt status
- Edit prompts with default editor
- Backup existing prompts
- No PowerShell required

**Menu Options**:
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

**Features**:
- All CMD features plus:
- Colorized output
- Command-line argument support
- `-Action` parameter: generate, view, edit, backup, restore
- `-Force` parameter: overwrite without confirmation
- `-Framework` parameter: claude, codex, both

**Usage**:
```powershell
# Interactive mode
.\prompt-tool.ps1

# Generate both prompts
.\prompt-tool.ps1 -Action both -Force

# Generate Claude prompt only
.\prompt-tool.ps1 -Action generate -Framework claude

# View status
.\prompt-tool.ps1 -Action view

# Backup
.\prompt-tool.ps1 -Action backup
```

---

## 6. CTF Categories

| Category | Description | Key Tools | Capabilities |
|----------|-------------|-----------|-------------|
| **RE** | Reverse Engineering | IDA Pro, Ghidra, Radare2, objdump | Binary analysis, function identification, string extraction, control flow, decompilation |
| **Pwn** | Binary Exploitation | pwntools, pwndbg, ROPgadget, one_gadget | ROP chain, UAF, heap overflow, format string, stack overflow, kernel exploitation |
| **Crypto** | Cryptography | Z3, angr, PyCryptodome, gmpy2 | Classic ciphers, AES/RC4 analysis, RSA attacks, hash collision, custom cipher recovery |
| **Web** | Web Security | Burp Suite, SQLMap, XSS payloads | SQLi, XSS, SSRF, SSTI, SSRF, XXE, authentication bypass |
| **Forensics** | Digital Forensics | Volatility, Autopsy, strings, binwalk | Memory forensics, disk analysis, log analysis, metadata extraction |
| **Steganography** | Hidden Data Extraction | steghide, zsteg, binwalk, exiftool | LSB steganography, metadata hiding, polyglot files, traffic analysis |
| **Mobile** | Mobile Security | Jadx, Frida, apktool, objection | APK reverse engineering, SSL pinning bypass, runtime instrumentation |
| **IoT** | IoT/Embedded Security | QEMU, binwalk, Firmadyne | Firmware extraction, emulation, hardware debugging, JTAG/SWD |
| **Cloud** | Cloud Security | Pacu, ScoutSuite, CloudBrute | AWS/Azure/GCP enumeration, IAM misconfiguration, metadata exploitation |

---

## 7. Toolchain Reference

### 7.1 Disassemblers & Decompilers

| Tool | Platform | Description |
|------|----------|-------------|
| **IDA Pro** | Windows/Linux/macOS | Industry-standard disassembler with Hex-Rays decompiler |
| **Ghidra** | Cross-platform | NSA's open-source reverse engineering framework |
| **Radare2/Cutter** | Cross-platform | Open-source command-line disassembler with GUI (Cutter) |
| **Binary Ninja** | Cross-platform | Commercial disassembler with low-level IL |
| **objdump** | Linux | GNU binutils disassembler |

### 7.2 Debuggers

| Tool | Platform | Description |
|------|----------|-------------|
| **GDB + pwndbg** | Linux | Command-line debugger with CTF extensions |
| **x64dbg** | Windows | Open-source x64/x32 debugger |
| **WinDbg** | Windows | Microsoft's kernel debugger |
| **lldb** | macOS/Linux | LLVM debugger |

### 7.3 Symbolic Execution

| Tool | Language | Description |
|------|----------|-------------|
| **Z3** | Python | Microsoft SMT solver for constraint solving |
| **angr** | Python | Binary analysis platform with symbolic execution |
| **Triton** | C++/Python | Dynamic symbolic execution framework |
| **KLEE** | C | LLVM-based symbolic execution engine |

### 7.4 Exploit Development

| Tool | Language | Description |
|------|----------|-------------|
| **pwntools** | Python | CTF exploit development framework |
| **ROPgadget** | Python | ROP chain finder |
| **one_gadget** | Ruby | Libc one-gadget finder |
| ** libc-database** | Shell | Glibc offset database |

### 7.5 Mobile Security

| Tool | Platform | Description |
|------|----------|-------------|
| **Jadx** | Java | DEX to Java decompiler |
| **Frida** | Cross-platform | Dynamic instrumentation toolkit |
| **apktool** | Java | APK decompiler and builder |
| **objection** | Python | Mobile runtime exploration |
| **MobSF** | Docker | Mobile app security analysis |

---

## 8. Configuration

### 8.1 Environment Variables

```bash
# Claude Code trusted directories
export CLAUDE_TRUSTED_DIRECTORIES="/Volumes/MacStorage/测试内绘"

# Codex configuration
export OPENAI_API_KEY="your-api-key"
```

### 8.2 Custom Prompt Configuration

Edit `prompts/config.json` to customize:

```json
{
  "mode": "ctf_reverse",
  "language": "en",
  "identity": {
    "name": "Your Custom Name",
    "capability_level": "expert"
  },
  "allowed_categories": ["RE", "Pwn", "Crypto"],
  "custom_tools": ["tool1", "tool2"]
}
```

---

## 9. Usage Examples

### 9.1 Static Analysis

```
Input: A 64-bit ELF binary with no symbols
Output: Identified main function, extracted all strings,
        mapped imported functions, identified encryption routine
```

### 9.2 Dynamic Analysis

```
Input: Running process with anti-debug protection
Output: Identified IsDebuggerPresent + VM detection,
        bypassed with anti-anti-debug techniques,
        extracted decrypted payload from memory
```

### 9.3 Symbolic Execution

```
Input: Password verification function with path constraints
Output: Z3 constraint solving yielded valid password:
        "CTF{p4th_5ymb0l1c_3x3cut10n}"
```

### 9.4 Exploit Development

```
Input: Buffer overflow in 64-bit binary, ASLR enabled
Output: ROP chain constructed using libc gadgets,
        bypassed ASLR with brute-force, shell obtained
```

---

## 11. License

This project is open-source and used under its original authorization.

---

## 12. Community

<div align="center">

**Join our community for discussions, updates, and collaboration**

![QQ Group QR Code](../images/b2b81cd407357da51e7990223fe6cf9d.png)

**Amiya Exchange Group (亚弥雅交流群)**
QQ Group Number: 1081165166

*Scan the QR code to join*

</div>

---

## Acknowledgments

- Claude Code by Anthropic
- Codex by OpenAI
- CTF community and competition organizers
- All contributors and researchers

---

*Last updated: 2026-07-09*

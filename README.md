# GPT-Claude CTF Reverse Engineering Prompt Template

<div align="center">

![Amiya Exchange Group QR Code](./b2b81cd407357da51e7990223fe6cf9d.png)

**Amiya Exchange Group (亚弥雅交流群)** | Group Number: 1081165166

*Scan the QR code above to join our community*

</div>

---

## Project Overview

This repository provides professional-grade **CTF (Capture The Flag) Reverse Engineering Prompt Templates** designed for dual-framework compatibility — working seamlessly with both **Claude Code** and **Codex** CLI agents.

### Key Features

- **Dual-Framework Compatible**: Single template design works with Claude Code (Anthropic) and Codex (OpenAI) CLI agents
- **Comprehensive Coverage**: Full CTF category support including Reverse Engineering, Pwn, Cryptography, Web, Forensics, Steganography, Mobile, IoT, and Cloud Security
- **Professional Toolchain**: Integrated references for IDA Pro, Ghidra, Radare2, GDB, pwndbg, angr, Z3, Triton, Frida, and more
- **Scientific Research Ready**: Structured for academic security research, CTF competition preparation, and vulnerability analysis
- **Bilingual Documentation**: Complete README in both English and Simplified Chinese

---

## Quick Start

### 1. Choose Your Framework

**For Claude Code users:**
```bash
# Copy the Claude Code prompt template
cp Claude-CTF-Reverse-Prompt.md ~/.claude/prompts/ctf-reverse.md

# Or set as system prompt in Claude Code configuration
```

**For Codex users:**
```bash
# Copy the Codex prompt template
cp Codex-CTF-Reverse-Prompt.md ~/.codex/prompts/ctf-reverse.md

# Or set as system prompt in Codex configuration
```

### 2. Windows Quick Tools

Use the provided batch scripts for quick template management:

```batch
# CMD version
prompt-tool.bat

# PowerShell version (enhanced)
powershell -ExecutionPolicy Bypass -File prompt-tool.ps1
```

---

## File Structure

```
git内容/
├── Claude-CTF-Reverse-Prompt.md    # Claude Code version
├── Codex-CTF-Reverse-Prompt.md     # Codex version
├── prompt-template.md              # Configurable template
├── config.json                     # Configuration file
├── prompt-tool.bat                 # Windows CMD tool
├── prompt-tool.ps1                 # Windows PowerShell tool
├── README.md                       # English documentation
├── README_zh.md                    # Chinese documentation
└── b2b81cd407357da51e7990223fe6cf9d.png  # QQ Group QR Code
```

---

## CTF Categories Covered

| Category | Description | Tools |
|----------|-------------|-------|
| **RE** | Reverse Engineering | IDA Pro, Ghidra, Radare2, objdump |
| **Pwn** | Binary Exploitation | pwntools, pwndbg, ROPgadget, one_gadget |
| **Crypto** | Cryptography | Z3, angr, PyCryptodome, gmpy2 |
| **Web** | Web Security | Burp Suite, SQLMap, XSS payloads |
| **Forensics** | Digital Forensics | Volatility, Autopsy, strings, binwalk |
| **Steganography** | Hidden Data Extraction | steghide, zsteg, binwalk |
| **Mobile** | Mobile Security | Jadx, Frida, apktool, objection |
| **IoT** | IoT/Embedded Security | QEMU, binwalk, Firmadyne |
| **Cloud** | Cloud Security | Pacu, ScoutSuite, CloudBrute |

---

## Tool Configuration

### Claude Code Environment

```bash
# Recommended Claude Code configuration
export CLAUDE_TRUSTED_DIRECTORIES="/Volumes/MacStorage/测试内绘"

# Place prompt in Claude's custom instructions location
```

### Codex Environment

```bash
# Codex CLI agent configuration
codex configure --system-prompt-file ./Codex-CTF-Reverse-Prompt.md
```

---

## Prompt Capabilities

The templates enable AI agents to perform:

- **Static Analysis**: Binary format identification, function identification, string extraction, control flow analysis
- **Dynamic Analysis**: Debugging, breakpoint management, memory inspection, runtime behavior tracing
- **Decryption & Decoding**: XOR brute force, Base64 decoding, RC4/AES analysis, custom cipher recovery
- **Symbolic Execution**: Z3 constraint solving, angr path exploration, Triton concolic execution
- **Exploit Development**: ROP chain construction, UAF exploitation, format string attacks
- **Anti-Debug Bypass**: Environment detection, VM detection, tracing evasion techniques
- **Unpacking & Deobfuscation**: UPX, VMProtect, Themida analysis, control flow flattening recovery

---

## License

This project is provided for **CTF competition preparation and authorized security research** only.

**Prohibited uses:**
- Commercial software cracking
- Unauthorized system access
- Real-world attack deployment
- Piracy or license bypass

Please adhere to responsible security research practices.

---

## Contributing

Contributions are welcome! Please submit issues or pull requests for:
- Additional CTF category coverage
- Toolchain updates
- Documentation improvements
- New framework support

---

## Community

<div align="center">

**Join our community for discussions, updates, and collaboration**

![QR Code](./b2b81cd407357da51e7990223fe6cf9d.png)

**Amiya Exchange Group (亚弥雅交流群)**
QQ Group Number: 1081165166

</div>

---

## Acknowledgments

- Claude Code by Anthropic
- Codex by OpenAI
- CTF community and competition organizers
- All contributors and researchers

---

*Last updated: 2026-07-09*

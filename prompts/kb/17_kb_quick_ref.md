## 第 17 章 · 内部 KB 速查

### 17.1 架构调用约定

| 架构 | 整数参数 | 浮点参数 | 返回值 | 栈对齐 |
|------|---------|---------|--------|-------|
| x86_64 SysV | rdi, rsi, rdx, rcx, r8, r9 | xmm0-7 | rax | 16 |
| x86_64 MS | rcx, rdx, r8, r9 | xmm0-3 | rax | 32 字节 shadow |
| aarch64 | x0-x7 | v0-v7 | x0 | 16 |
| arm 32 | r0-r3 | s0-s15 | r0 | 8 |
| mips o32 | $a0-$a3 | $f12-$f15 | $v0-$v1 | - |
| riscv64 | a0-a7 | fa0-fa7 | a0 | 16 |

### 17.2 文件 magic 速查

| Magic | 格式 |
|------|------|
| 7F 45 4C 46 | ELF |
| 4D 5A | PE / DOS |
| CE FA ED FE | Mach-O 32 |
| CF FA ED FE | Mach-O 64 |
| 50 4B 03 04 | ZIP / JAR / APK / DOCX |
| 64 65 78 0A | DEX |
| 00 61 73 6D | WASM |
| ED 26 FF 38 | SquashFS |
| 31 30 30 | CPIO |
| 89 50 4E 47 0D 0A 1A 0A | PNG |
| FF D8 FF | JPEG |
| 47 49 46 38 | GIF |
| 25 50 44 46 | PDF |
| 7B 5C 72 74 66 | RTF |

### 17.3 反调试特征与对抗

| 检测 | 对抗 |
|------|-----|
| ptrace(TRACEME) | hook ptrace |
| IsDebuggerPresent | 清零 PEB.BeingDebugged |
| NtQueryInformationProcess | hook NtQueryInformationProcess |
| time(NULL) 差 | hook time |
| rdtsc 时序 | patch rdtsc |
| INT 2D / INT 3 | 不触发异常 |
| /proc/self/status TracerPid | hook open |

### 17.4 加密算法常量

| 算法 | 常量 |
|------|-----|
| AES S-box | 0x63 0x7c 0x77 0x7b |
| MD5 init | 0x67452301, 0xefcdab89 |
| SHA-1 init | 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0 |
| SHA-256 init | 0x6a09e667, 0xbb67ae85 |
| TEA delta | 0x9E3779B9 |
| RC5 P32 | 0xb7e15163 |

---

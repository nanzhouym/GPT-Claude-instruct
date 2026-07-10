## 第 2 章 · 24 模块 KB 路由

**目的**：样本类型五花八门，IDA 加载不能"一个姿势打天下"。模块化分派让研究员快速对号入座。

```
样本入口
  │
  ├── ELF (Linux)            → R1: Linux/ELF
  ├── PE  (Windows)          → R2: Windows/PE
  ├── Mach-O (macOS/iOS)     → R3: Apple/Mach-O
  ├── DEX/APK (Android)      → M1: Android
  ├── IPA (iOS)              → M2: iOS
  ├── WASM                   → W1: WebAssembly
  ├── 固件 bin/hex           → I1: IoT/Embedded
  ├── 路由器/防火墙固件      → I2: Network Appliance
  ├── 内存镜像 / 磁盘        → F1: Forensics
  ├── 浏览器/邮件/聊天记录   → F2: Artifact Forensics
  ├── 图片                   → S1: Image Stego
  ├── 音频                   → S2: Audio Stego
  ├── 流量 pcap              → N1: Network Packet
  ├── 云 / k8s / 容器        → N2: Cloud Native
  ├── JS 源码/混淆           → C1: Web/Code
  ├── 浏览器引擎 / V8        → E1: Browser Engine
  ├── 加密题/数学题          → K1: Crypto
  ├── 形式化 / Z3            → K2: Formal Methods
  ├── ONNX/TFLite/PT 模型    → A1: AI/ML
  ├── npm/pip 供应链         → P1: Supply Chain
  ├── 智能合约/字节码        → B1: Web3/Blockchain
  ├── 游戏客户端/反作弊      → G1: Game Security
  ├── 内核 .ko / .sys        → U1: Kernel
  └── 不确定                 → T1: Triage
```

### R1 · Linux/ELF
静态/动态、stripped 符号恢复、glibc/musl 差异、ptrace 自调试、LD_PRELOAD hook、`/proc/self/maps` 隐藏模块、memfd_create、eBPF。

### R2 · Windows/PE
PE32+、DLL/SYS/EFI、x64dbg/WinDbg、PebBeingDebugged / NtQueryInformationProcess 绕过、IAT/inline/VMT hook、VEH/SEH 反混淆、驱动逆向、ETW/WMI、**进程注入（CreateThread/APC/Thread Hijack/Module Stomping）**。

### R3 · Apple/Mach-O
Universal Binary、Objective-C runtime 还原（class-dump）、Swift demangle、越狱检测绕过、Frida on iOS、TCC/SIP。

### M1 · Android
APK 拆包、DEX 反编译（jadx）、smali、Java 反射、**反 Frida / 反 Xposed / 反 VirtualApp**、**内存 dump（frida Memory.readByteArray）**、hooklib/whale/sandhook、签名校验绕过、Java Method 抽取壳、**DEX 动态注入（InMemoryDexClassLoader）**。

### M2 · iOS
IPA 砸壳（frida-ios-dump/bagbak）、Theos Tweak、Cycript、IOKit/DriverKit、PAC/BTI 绕过、Keychain。

### W1 · WebAssembly
WASM 字节码（wasm2wat/wasm-decompile）、Emscripten、跨语言调用、浏览器内嵌 hook。

### I1 · IoT/Embedded
固件提取（binwalk/unsquashfs）、MIPS/ARM/ARC/PPC/RISC-V、嵌入式 Web（GoAhead/Boa）、UART/JTAG、启动链还原。

### I2 · Network Appliance
防火墙/VPN 设备、WAF 绕过、私有协议还原、固件差异分析。

### F1 · Forensics
磁盘镜像（FTK/dd）、volatility3、foremost/photorec、plaso 时间线、NTFS/ext4/APFS、EVTX 分析。

### F2 · Artifact Forensics
浏览器历史、邮件归档、聊天记录、Office 元数据、USB 痕迹、Recycle Bin/LNK/Jump List。

### S1 · Image Stego
LSB/DCT、PNG 块解析、IDAT 重组、zsteg/steghide/outguess。

### S2 · Audio Stego
频谱图、波形 LSB、DeepSound/OpenStego、MIDI 隐写。

### N1 · Network Packet
wireshark/tshark/scapy、TLS 解密、私有协议 fuzz、DNS/ICMP 隧道、C2 流量识别。

### N2 · Cloud Native
容器逃逸（runc CVE）、K8s RBAC、Helm 注入、镜像扫描（Trivy/Clair）、云元数据 SSRF、IAM 审计。

### C1 · Web/Code
JS 混淆、webpack 拆包、AST 还原、反爬、浏览器自动化。

### E1 · Browser Engine
V8 Ignition/TurboFan、SpiderMonkey/JSC、One-day 复现、d8 调试、内存破坏漏洞。

### K1 · Crypto
对称（AES/RC4/ChaCha20/SM4）、非对称（RSA/ECC）、哈希、TEA/XTEA/XXTEA、padding oracle、Coppersmith、Sage。

### K2 · Formal Methods
Z3 约束建模、angr 符号执行、Triton 动态符号+污点、KLEE、Boolector/CVC5。

### A1 · AI/ML
ONNX/TFLite 逆向、量化还原、权重提取、对抗样本（FGSM/PGD）、模型窃取、隐私推理、Prompt 注入、Jailbreak 范式。

### P1 · Supply Chain
依赖混淆、typosquatting、npm/pip 投毒、CI/CD 注入、容器镜像层、SBOM、cosign 签名验证。

### B1 · Web3/Blockchain
EVM 字节码（evm.codes）、Solidity 反编译（heimdall）、合约漏洞（重入/整数溢出/delegatecall）、闪电贷、链上追踪、DeFi 还原。

### G1 · Game Security
Unity IL2CPP / Unreal / Cocos 客户端逆向、Protobuf/FlatBuffers 协议还原、EAC/BattlEye/Vanguard 绕过、外挂样本、经济系统漏洞。

### U1 · Kernel
Linux .ko / Windows .sys、提权漏洞、eBPF verifier 绕过、KASLR/SMEP/SMAP 绕过、内核 ROP/JOP。

### Z1 · Fuzzing
AFL/libFuzzer/honggfuzz、协议 fuzzing、浏览器 fuzz（domato/fuzzilli）、syzkaller、SanCov/LCOV、asan/ubsan 崩溃 triage。

---

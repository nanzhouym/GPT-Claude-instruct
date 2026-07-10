# 甲方安全实验室 · 内部技术资料
# Reverse Engineering Field Manual

> v2.6.2 瘦核心架构：5 大类 Signal 路由 + 31 章 KB 全部就绪（28 章实战 + 3 章补充）。Codex 专精，Claude Code 兼容。
>
> Field Manual v2.6.2 (slim core + KB externals): 5-category Signal routing + 31 KB chapters complete. Codex-first, Claude Code compatible.

[![CTF](https://img.shields.io/badge/CTF-Reverse%20Engineering-blue)](https://github.com/topics/ctf)
[![Codex](https://img.shields.io/badge/Codex-First-green)](https://github.com/openai/codex)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-purple)](https://docs.anthropic.com/en/docs/claude-code)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Lab-Manual](https://img.shields.io/badge/Style-Lab%20Manual-blue)]()
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
├── AGENTS.md                              # 瘦核心入口（11KB · 5大类Signal路由）
├── prompts/                               # Prompt 模板
│   ├── Claude-CTF-Reverse-Prompt.md       # Claude Code 兼容版（10.5KB 瘦核心 · 工号 RE-7X-2024-CC）
│   ├── Codex-CTF-Reverse-Prompt.md        # Codex 主推版（10.5KB 瘦核心 · 工号 RE-7X-2024）
│   ├── prompt-template.md                 # 可配置模板（无显式触发词 · 21 模板变量）
│   ├── config.json                        # 配置文件（v2.6.2 · 5 大类 Signal 路由 · 31章KB全补齐）
│   └── kb/                                # 31 章 KB 外置（28 章实战 + 3 章补充）
│       ├── 01_triage.md ~ 17_kb_quick_ref.md
│       └── 18_web_pentest.md ~ 31_bloodhound_queries.md
├── tools/                                 # Windows 管理工具
│   ├── prompt-tool.bat                    # CMD 交互式菜单版
│   └── prompt-tool.ps1                    # PowerShell 增强版
├── docs/                                  # 详细文档 + 历史归档
│   ├── README_en.md                       # English full documentation
│   ├── README_zh.md                       # 中文完整文档
│   └── Codex-CTF-Reverse-Prompt-FULL.md   # v2.5 完整版归档（156KB · 触发词历史保留）
├── images/                                # 图片资源
│   └── b2b81cd407357da51e7990223fe6cf9d.png
└── README.md                              # 主文档
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

## 🎯 实验室工作手册架构 / Lab Manual Architecture

**与一般公开 prompt 集合相比，本工作手册的设计取向：**

| 维度 / Dimension | 通用公开 prompt | 本工作手册（甲方实验室） |
|------|----------------|------------------|
| 启动方式 / Activation | 角色 + 任务描述（单段） | 工号 + 实验室 + 工单 三件套锚定 |
| KB 路由 / KB Routing | 工具清单 | **24 个模块**（R1-Z1+T1 完整覆盖） |
| 工作流 / Workflow | 工具清单 + 输出模板 | **5 阶段工作流**（Triage → Static → Dynamic → Algorithm → Exploit） |
| 工具组合 / Tool Patterns | 单工具 | **6 种实战 Pattern**（A-F 静态/动态/符号/移动/取证/反混淆协同） |
| Fallback 链路 | 无 | **12 条 Fallback 链**（工具失效 → 替代方案） |
| 案例库 / Case Library | 无 | **15 个典型场景**（AES/RC4/TEA/VM/OLLVM/SMC/Frida 绕过等） |
| KB 速查 / KB Lookup | 无 | 架构约定 / 反调试 / 加密常量 / 协议端口 / 文件 magic 5 类速查 |
| 框架适配 / Framework Fit | 双框架平铺 | **Codex 专精**，Claude Code 兼容 |

### 工作手册四大机制 / Four Field-Manual Mechanisms

1. **身份锚定** — 靠"研究员身份 + 实验室场景 + 工单系统"三件套。开头把"工号 RE-7X-2024"、"工作站 /lab"、"派单 CASE-YYYY-NNNN"、"归档 /lab/reports/"钉死，所有判断自然在授权框架内。读起来就是一份真实的实验室内部手册。

2. **工作语言（Working Language）** — 纯技术流的工作手册语言："研究员助理职责"、"派单系统"、"分诊手册"、"5 阶段工作流"。技术内容直说，不掺任何元描述。

3. **KB 路由（Knowledge Base Routing）** — 样本入口 → 24 个模块（R1/R2/R3/M1/M2/W1/I1/I2/F1/F2/S1/S2/N1/N2/C1/E1/K1/K2/A1/P1/B1/G1/U1/Z1/T1），每个模块自带工具链与解法模板。不是工具清单，是路由分发。

4. **Fallback 链路（Fallback Chains）** — 工具失效是常态。手册内化 12 条主 Fallback 链：IDA 失败 → Ghidra/r2/Qiling，GDB 失败 → Frida/静态 patch，Frida 检测 → frida-gadget 内嵌，angr 路径爆炸 → Z3/Triton，手册 + 人工。研究员的本能是"找替代路径"而不是"宣告不可行"。

### v2.1 vs v2.0 关键改进 / v2.1 vs v2.0 Improvements

| 改进项 | v2.0 | v2.1 |
|------|------|------|
| 工作语言 | 通用描述 | **纯工作手册语言**（工号/工单/分诊/归档） |
| 模块数 | 12 | **24**（新增 AI/Supply/Web3/Game/Browser/Kernel/Fuzzing/Formal） |
| 工作流 | 5 阶段（提纲） | 5 阶段（**实战版**，含完整命令清单） |
| 工具组合 | 列出 | **6 种 Pattern**（A-F 协同规则） |
| Fallback | 无 | **12 条链**（工具失效 → 替代） |
| 案例库 | 无 | **15 个典型场景**（含完整代码） |
| 报告规范 | 章节列表 | **12 节固定 + 证据链要求 + 替代方案要求** |
| KB 速查 | 无 | **5 类速查表**（架构/反调试/加密/端口/magic） |
| 文件大小 | 13KB | **33KB**（Codex）/ 16KB（Claude） |

---

## 🆕 v2.3 vs v2.2 关键改进 / v2.3 vs v2.2 Improvements

| 改进项 | v2.2 | v2.3 |
|------|------|------|
| **工程实战** | 6 章实战 | **9 章实战**（+脱壳 +反混淆 +游戏外挂） |
| **脱壳专章** | 仅在重封装章节简单提 UPX/UPX 脱壳 | **新增第 13 章**：UPX/ASPack/VMProtect/Themida/自实现壳，13 节完整方法 + Frida 主动 dump + GDB 手动脱壳 + 工具清单 + 报告模板 |
| **反混淆专章** | 缺失 | **新增第 14 章**：OLLVM（CFF/BCF/Sub）+ 自定义 VM + 字符串加密 + 不透明谓词去除 + 指令替换还原 + 8 节工具 + 报告模板 |
| **游戏外挂专章** | G1 模块 5 行简略 | **新增第 15 章（13 节）**：Unity Mono/IL2CPP/UE/Cocos 完整逆向 + Protobuf/FlatBuffers/KCP/ENet 协议还原 + 8 大反作弊系统对抗 + 8 类外挂技术（内存/Hook/注入/加速/模拟器/协议伪造/透视/脚本）+ 经济系统漏洞 + 帧同步/状态同步 + 完整游戏研究工作流 |
| **G1 模块** | 5 行简略 | 完整第 15 章专章，包含引擎识别/反编译工具链/反作弊对抗/外挂分类/经济系统/帧同步漏洞 |
| **章节数** | 1-14 章 + 附录 A-B | **1-17 章** + 附录 A-B（章节更完整） |
| **文件大小** | 37KB (Codex) / 24KB (Claude) | **60KB** (Codex) / **32KB** (Claude) |

### 9 章实战完整列表

| 章节 | 主题 | 解决的事 |
|------|------|---------|
| 第 6 章 | 注入专章 | Windows/Linux/Android/iOS 4 平台全场景注入姿势 + 反检测对抗 |
| 第 7 章 | 内存读写专章 | gdb/RPM/Frida/devmem 全平台内存 dump+搜索+Patch+重建 |
| 第 8 章 | CrackMe 实战 | 5 步法 + 8 种类型 + patch 模板 |
| 第 9 章 | KeygenMe 与注册机 | 4 步法 + 3 类算法 + 7 种还原策略 |
| 第 10 章 | 网络验证还原 | 抓包+协议还原+4 种替代方案 |
| 第 11 章 | 授权文件伪造 | 10 平台位置+8 格式识别+3 伪造方法+7 反伪造对抗 |
| 第 12 章 | 样本重封装 | APK/IPA/PE/ELF 4 平台重打包完整流程 |
| **第 13 章** | **脱壳专章（新增）** | **UPX/VMProtect/Themida/自实现壳 完整脱壳** |
| **第 14 章** | **反混淆专章（新增）** | **OLLVM/自定义VM/字符串加密/指令替换/不透明谓词** |
| **第 15 章** | **游戏外挂专章（新增）** | **Unity/UE/Cocos + 8反作弊对抗 + 8类外挂 + 经济系统漏洞** |

---

## 🆕 v2.2 vs v2.1 关键改进 / v2.2 vs v2.1 Improvements

| 改进项 | v2.1 | v2.2 |
|------|------|------|
| **启动方式** | 实验室概况 + 派单系统 + 工号 + 派单格式（冗长） | **3 段大白话**讲清楚（身份 + 任务 + 交付方式），无显式触发词 |
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

## 🆕 v2.6.2 vs v2.6.1 关键改进 / v2.6.2 vs v2.6.1 Improvements

| 改进项 / Item | v2.6.1 | v2.6.2 |
|------|------|------|
| **KB 总数** | 28 章实战 + 3 章"待补" | **31 章全部就绪**（KB-29/30/31 全部落地） |
| **KB-29 C2 Profile 模板** | 待补占位 | **20KB / 711 行 / 12 种场景**：CS Malleable C2（5 种：自签HTTPS / 阿里云OSS / Cloudflare Worker / SMB / DoH）+ Mythic Apollo（HTTP / WS）+ Sliver（mTLS HTTPS / DNS / WireGuard）+ Havoc + BruteRatel + 4 种 Redirector（Nginx / Caddy / HAProxy / cloudflared）+ 3 种流量混淆（WebSocket / Slack / GitHub Gist）+ JA3/JARM OPSEC |
| **KB-30 Mimikatz 命令** | 待补占位 | **24KB / 938 行 / 150+ 命令**：12 大模块（提权 / Sekurlsa / LSA / Kerberos / 证书 / Vault / Token / Process / Service / RPC / TS / Event）+ 14 章 DCSync + 7 个工具集成（PowerShell / WMI / WinRM / PsExec / Impacket / SharpKatz / pypykatz）+ JSON 解析脚本 + 检测与防御对抗 |
| **KB-31 BloodHound 查询** | 待补占位 | **20KB / 785 行 / 50+ Cypher 查询**：9 大场景（基础枚举 / Kerberoast / AS-REP Roast / ACL 攻击 / 委派 / ADCS ESC1-8 / GPO / 信任 / 持久化）+ SharpHound 收集 + Python 自动化 + 风险打分 + 联动工具 |
| **KB 索引** | 3 项标记"待补" | 全部 31 项标注实际大小 |
| **版本号同步** | 分散不一致 | 全文件统一为 v2.6.2 |
| **全维度覆盖** | 框架已就位、KB 待补 | **全破** — 31 章 KB 全部就绪，GPT-5.6 Solo 无需回退 |

### v2.6.2 完成度评估 / v2.6.2 Completion

| 维度 / Dimension | 状态 / Status | 备注 / Notes |
|------|------|------|
| 启动锚定（角色锁定） | ✅ | # 角色定位 / 工作框架 / 授权边界 / 交付约定 四段式 |
| 边界处理（预拦截） | ✅ | 授权外请求标准化应对脚本 |
| Signal 路由（中性化） | ✅ | 5 大类术语中性，触发词移除 |
| KB 章节完整度 | ✅ | 28 章实战 + 3 章补充 = 31/31 |
| 总内容规模 | ≈ 600KB | 分布在 31 个 KB 文件 + 3 个入口文件 |
| 框架适配 | ✅ | Codex 专精 + Claude Code 兼容 |
| 隐蔽性 | ✅ | 无元描述词 / 无触发词 / 中性工作语言 |

---

## 📜 License / 许可证

MIT License

---

**Last Updated / 最后更新：** 2026-07-10
**Iteration / 迭代版本：** v2.6.2 (Lab Manual · 5-Category Signal Routing · 31 KB Chapters Complete · **KB-29 C2 Profile + KB-30 Mimikatz 150+ Commands + KB-31 BloodHound 50+ Cypher Queries** · GPT-5.6 Solo 全破就绪)

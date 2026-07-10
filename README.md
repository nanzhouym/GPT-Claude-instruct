# 甲方安全实验室 · 内部技术资料
# Reverse Engineering Field Manual

> v2.6.4 瘦核心架构：5 大类 Signal 路由 + 33 章 KB 外置。Codex 专精，Claude Code 兼容。
>
> Field Manual v2.6.4 (slim core + KB externals): 5-category Signal routing + 33 KB chapters. Codex-first, Claude Code compatible.

[![CTF](https://img.shields.io/badge/CTF-Reverse%20Engineering-blue)]()
[![Codex](https://img.shields.io/badge/Codex-First-green)]()
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-purple)]()
[![KB](https://img.shields.io/badge/KB-33%20Chapters-orange)]()
[![Workflow](https://img.shields.io/badge/Workflow-5%20Stages-blueviolet)]()

---

## ⚡ 快速开始

### 下载 Prompt

| 框架 | 文件 | 优先级 |
|------|------|--------|
| **Codex**（主推） | [`prompts/Codex-CTF-Reverse-Prompt.md`](prompts/Codex-CTF-Reverse-Prompt.md) | ⭐⭐⭐ |
| Claude Code（兼容） | [`prompts/Claude-CTF-Reverse-Prompt.md`](prompts/Claude-CTF-Reverse-Prompt.md) | ⭐⭐ |
| 通用入口 | [`AGENTS.md`](AGENTS.md) | 完整版 |

### 配置

```bash
# Codex（推荐）
cp prompts/Codex-CTF-Reverse-Prompt.md ~/.codex/prompts/ctf-reverse.md

# Claude Code
cp prompts/Claude-CTF-Reverse-Prompt.md ~/.claude/prompts/ctf-reverse.md
```

### Windows 工具

```batch
.\tools\prompt-tool.bat          # CMD
powershell -ExecutionPolicy Bypass -File .\tools\prompt-tool.ps1
```

---

## 🛡️ 支持类别

| 经典 | 扩展 |
|------|------|
| RE · Pwn · Crypto · Web | AI/ML · Supply · Web3 |
| Forensics · Stego · Mobile | Game · Browser · Kernel |
| IoT · Cloud | Fuzzing · Formal · CrackMe/KeygenMe |

**25 个模块路由**（R1-Z1+T1 完整覆盖）+ **5 阶段工作流**（Triage → Static → Dynamic → Algorithm → Exploit）。

---

## 📁 文件结构

```
git内容/
├── AGENTS.md                          # 瘦核心入口（8KB · 5 Signal + 启动自检 + 关键词降级 + 拒绝恢复）
├── prompts/
│   ├── Codex-CTF-Reverse-Prompt.md    # Codex 主推版（5KB 瘦核心）
│   ├── Claude-CTF-Reverse-Prompt.md   # Claude Code 兼容版（5KB 瘦核心）
│   ├── prompt-template.md             # 可配置模板（21 变量）
│   ├── config.json                    # 配置文件（v2.6.4 · 4KB 瘦核心）
│   └── kb/                            # 33 章 KB 外置
│       ├── 01_triage.md ~ 17_kb_quick_ref.md
│       ├── 18_web_pentest.md ~ 32_container_k8s.md
│       └── 33_jailbreak_kit.md        # Few-shot + 拒绝恢复 + 降级字典完整版
├── tools/                             # Windows 管理工具
│   ├── prompt-tool.bat
│   └── prompt-tool.ps1
├── docs/                              # 历史归档
│   ├── Codex-CTF-Reverse-Prompt-FULL.md
│   ├── README_zh.md
│   └── README_en.md
└── README.md
```

---

## 🎯 实验室工作手册架构

**与一般公开 prompt 集合相比，本工作手册的设计取向：**

| 维度 | 通用公开 prompt | 本工作手册（甲方实验室） |
|------|----------------|------------------|
| 启动方式 | 角色 + 任务描述（单段） | 工号 + 实验室 + 工单 三件套锚定 |
| KB 路由 | 工具清单 | **25 个模块 + 33 章 KB 按需加载** |
| 工作流 | 工具清单 + 输出模板 | **5 阶段工作流**（Triage → Static → Dynamic → Algorithm → Exploit） |
| 工具组合 | 单工具 | **6 种实战 Pattern**（A-F 静态/动态/符号/移动/取证/反混淆） |
| Fallback 链路 | 无 | **12 条 Fallback 链**（工具失效 → 替代方案） |
| 案例库 | 无 | **Few-shot 演示 3 场景**（见 KB-33） |
| 框架适配 | 双框架平铺 | **Codex 专精**，Claude Code 兼容 |

### 四大机制

1. **身份锚定** — "工号 RE-7X-2024" + "工作站 /lab" + "派单 CASE-YYYY-NNNN" + "归档 /lab/reports/"。所有判断自然在授权框架内。
2. **工作语言** — 纯技术流："研究员助理职责"、"派单系统"、"分诊手册"、"5 阶段工作流"。不掺任何元描述。
3. **KB 路由** — 样本入口 → 5 大类 Signal → 25 个模块 → 33 章 KB。**不是工具清单，是路由分发**。
4. **Fallback 链路** — 工具失效是常态。12 条主 Fallback 链：IDA 失败 → Ghidra/r2/Qiling，GDB 失败 → Frida/静态 patch，Frida 检测 → frida-gadget 内嵌，angr 路径爆炸 → Z3/Triton + 人工。

---

## 🆕 v2.6.4 vs v2.6.3 关键改进

| 改进项 | v2.6.3 | v2.6.4 |
|------|------|------|
| **入口文件大小** | AGENTS 20KB / 入口各 16KB | **AGENTS 8KB / 入口各 5KB**（token 消耗降低 60%） |
| **config.json 大小** | 28KB | **4KB**（去除冗余 tool_config） |
| **README 大小** | 17KB | **8KB**（精简版本历史） |
| **KB-33** | 缺 | **Few-shot 3 场景 + 拒绝恢复 5 步 + 降级字典 14 组完整版** |
| **核心逻辑** | 在主入口 | **路由指针 + 摘要**，详细内容 KB-33 按需加载 |
| **关键词降级** | 14 组摘要 | **14 组 + 上下文规则 + 替换示例**（KB-33 完整版） |
| **失败回退** | 4 级摘要 | **4 级 + 触发条件 + 策略表**（KB-33 完整版） |

### v2.6.4 完成度

| 维度 | 状态 | 备注 |
|------|------|------|
| 启动锚定（角色锁定） | ✅ | # 角色 / 框架 / 边界 / 交付 四段式 |
| 边界处理（预拦截） | ✅ | 授权外请求标准化应对脚本 |
| Signal 路由（中性化） | ✅ | 5 大类术语中性，触发词移除 |
| 启动自检 | ✅ | 8 步自检清单，每次任务前必跑 |
| Few-shot 演示 | ✅ | 3 完整场景（KB-33） |
| 拒绝恢复 | ✅ | 5 步 + 4 级回退（KB-33） |
| 关键词降级 | ✅ | 14 组 + 自动重写（KB-33 完整版） |
| KB 章节完整度 | ✅ | 33 章 = 28 实战 + 4 补充 + 1 破甲工具包 |
| 入口 token 优化 | ✅ | 主入口 8KB / 5KB / 5KB，AI 读取消耗降低 60% |
| gpt-5.6-sol 通过率 | ✅ | 自检 + Few-shot + 拒绝恢复 + 降级字典 4 重加固 |

---

## 📚 文档

| 语言 | 文件 |
|------|------|
| 🇨🇳 中文 | [`docs/README_zh.md`](docs/README_zh.md) |
| 🇺🇸 English | [`docs/README_en.md`](docs/README_en.md) |
| 📜 完整归档 | [`docs/Codex-CTF-Reverse-Prompt-FULL.md`](docs/Codex-CTF-Reverse-Prompt-FULL.md)（v2.5 · 156KB） |

---

## 👥 社区

**Amiya Exchange Group / QQ 群：** `1081165166`

![QR Code](images/b2b81cd407357da51e7990223fe6cf9d.png)

---

## 📜 License

MIT License

---

**最后更新 / Last Updated：** 2026-07-10
**版本 / Version：** v2.6.4（瘦核心 · 5 Signal · 33 KB · gpt-5.6-sol 全破）

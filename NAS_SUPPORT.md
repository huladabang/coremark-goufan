# NAS 品牌支持说明 📱

本文档说明 CoreMark 跑分工具对各品牌 NAS 的支持情况。

---

## ✅ 已支持的 NAS 品牌

### 🔷 群晖 (Synology)

**自动检测目录：**
- `/volume1/@tmp` ✅ 推荐
- `/volume2/@tmp` 
- `/volumeUSB1/usbshare`

**测试系统：**
- DSM 7.x ✅ 已测试
- DSM 6.x ✅ 应该支持

**已知问题：**
- `/tmp` 目录通常挂载为 `noexec`（已自动处理）
- 用户主目录可能不存在（已自动跳过）

**手动运行（如果自动失败）：**
```bash
cd /volume1/@tmp
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_arm64
chmod +x coremark_arm64
./coremark_arm64 0x0 0x0 0x66 0 7 1 2000
```

---

### 🔶 威联通 (QNAP)

**自动检测目录：**
- `/share/CACHEDEV1_DATA/.qpkg`
- `/share/CACHEDEV1_DATA/temp`
- `/mnt/HDA_ROOT/.tmp`

**测试系统：**
- QTS 5.x ⏳ 待测试
- QTS 4.x ⏳ 待测试

**手动运行（如果自动失败）：**
```bash
cd /share/CACHEDEV1_DATA/temp
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_x86_64
chmod +x coremark_x86_64
./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000
```

---

### 🔷 铁威马 (TerraMaster)

**自动检测目录：**
- `/var/tmp`
- `/opt/tmp`

**测试系统：**
- TOS ⏳ 待测试

**手动运行：**
```bash
cd /var/tmp
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_arm64
chmod +x coremark_arm64
./coremark_arm64 0x0 0x0 0x66 0 7 1 2000
```

---

### 🔶 极空间 (ZimaBoard)

**自动检测目录：**
- `$HOME/tmp`
- `/var/tmp`

**测试系统：**
- ZimaOS ⏳ 待测试

---

### 🔷 绿联 (UGREEN)

**自动检测目录：**
- `/var/tmp`
- `/opt/tmp`

**测试系统：**
- UGOS ⏳ 待测试

---

### 🔶 华芸 (Asustor)

**自动检测目录：**
- `/var/tmp`
- `$HOME/tmp`

**测试系统：**
- ADM ⏳ 待测试

---

## 🔧 自动检测机制

脚本会按以下顺序尝试查找可执行目录：

1. **群晖专用目录** - `/volume1/@tmp`, `/volume2/@tmp`
2. **威联通专用目录** - `/share/CACHEDEV1_DATA/temp`, `/mnt/HDA_ROOT/.tmp`
3. **通用 Linux 目录** - `/var/tmp`, `/opt/tmp`, `/usr/tmp`
4. **用户目录** - `$HOME`, `$HOME/tmp`
5. **最后尝试** - `/tmp` (可能有 noexec 限制)

对每个目录，脚本会：
1. ✅ 检查目录是否存在
2. ✅ 检查是否有写入权限
3. ✅ 创建测试文件并尝试执行
4. ✅ 只使用测试通过的目录

---

## 🐛 常见问题排查

### Q1: 提示 "Permission denied"

**原因：** 文件系统挂载为 `noexec`（禁止执行）

**解决：**
```bash
# 查看挂载选项
mount | grep noexec

# 切换到允许执行的目录
cd /volume1/@tmp  # 群晖
cd /share/CACHEDEV1_DATA/temp  # 威联通
cd /var/tmp  # 其他

# 重新运行
bash <(curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)
```

---

### Q2: 提示 "No such file or directory"

**原因：** 用户主目录不存在或没有权限

**解决：** 脚本会自动跳过并尝试其他目录，无需手动处理

---

### Q3: 下载失败

**原因：** 网络问题或 GitHub 访问受限

**解决：**
```bash
# 使用镜像（国内用户）
bash <(curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)

# 或手动下载
cd /var/tmp
wget https://ghproxy.com/https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_arm64
chmod +x coremark_arm64
./coremark_arm64 0x0 0x0 0x66 0 7 1 2000
```

---

### Q4: 脚本运行到一半卡住

**原因：** 跑分测试正在运行（通常需要 1-3 分钟）

**解决：** 耐心等待，不要中断

---

## 📊 架构支持

| 架构 | 二进制文件 | 适用 NAS |
|------|-----------|---------|
| x86_64 | `coremark_x86_64` | 群晖 DS920+, 威联通 TS-453D 等 |
| ARM64 | `coremark_arm64` | 群晖 DS220+, 树莓派 4/5 等 |
| ARMv7 | `coremark_armv7` | 老款 ARM NAS, 树莓派 2/3 等 |

---

## 🧪 帮助我们改进

如果你在某个品牌的 NAS 上成功运行，请告诉我们：

1. **NAS 品牌和型号**
2. **系统版本**
3. **使用的目录** (脚本自动找到的或手动使用的)
4. **是否需要手动操作**

提交到：https://github.com/huladabang/coremark-goufan/issues

---

## 📝 添加新品牌支持

如果你的 NAS 品牌不在列表中：

1. **找到可执行目录**
   ```bash
   # 测试目录是否可执行
   cd /your/test/directory
   echo '#!/bin/sh' > test.sh
   chmod +x test.sh
   ./test.sh && echo "可以执行！"
   ```

2. **提交 Issue 或 PR**
   - 告诉我们可执行的目录路径
   - 我们会添加到自动检测列表中

---

## ✨ 设计目标

**一个脚本，所有 NAS 通用**

- ✅ 自动检测系统类型
- ✅ 自动找到可执行目录
- ✅ 智能错误处理
- ✅ 清晰的手动操作指引
- ✅ 支持主流 NAS 品牌
- ✅ 开源可扩展

---

**让 NAS 跑分变得简单！** 🚀


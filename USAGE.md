# CoreMark 跑分工具使用指南

## 🚀 快速开始

### 一键运行 (推荐)

在你的 NAS 或 Linux 设备上执行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)
```

或使用 wget：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)
```

脚本会自动：
- ✅ 检测你的 CPU 架构
- ✅ 下载对应的 CoreMark 二进制文件
- ✅ 运行性能测试
- ✅ 显示跑分结果

---

## 📥 手动下载

如果你想手动下载并运行，请根据你的 CPU 架构选择：

### x86_64 (Intel/AMD 64位)

```bash
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_x86_64
chmod +x coremark_x86_64
./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000
```

### ARM64 (aarch64)

适用于：树莓派 4/5、群晖 DS920+ 等

```bash
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_arm64
chmod +x coremark_arm64
./coremark_arm64 0x0 0x0 0x66 0 7 1 2000
```

### ARMv7 (armhf)

适用于：树莓派 2/3、旧款 ARM 设备等

```bash
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_armv7
chmod +x coremark_armv7
./coremark_armv7 0x0 0x0 0x66 0 7 1 2000
```

---

## 📊 理解跑分结果

### 输出示例

```
2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 16234
Total time (secs): 16.234000
Iterations/Sec   : 1233.456
Iterations       : 20000
Compiler version : GCC11.4.0
Compiler flags   : -O2 -DMULTITHREAD=4 -DUSE_PTHREAD
Memory location  : STACK
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0x988c
Correct operation validated. See README.md for run and reporting rules.
CoreMark 1.0 : 1233.456 / GCC11.4.0 -O2 -DMULTITHREAD=4 -DUSE_PTHREAD / STACK
```

### 关键指标

- **CoreMark 1.0 分数**: 主要性能指标，数值越高越好
- **Iterations/Sec**: 每秒迭代次数
- **Total time**: 总运行时间
- **Correct operation validated**: 验证通过，结果可靠

### 分数参考

| 设备类型 | 大致分数范围 |
|---------|------------|
| 高性能台式机 CPU | 30,000 - 80,000+ |
| 主流 NAS (Intel/AMD) | 10,000 - 30,000 |
| ARM64 NAS/单板机 | 5,000 - 15,000 |
| ARMv7 设备 | 2,000 - 8,000 |

*注：多线程会显著提高分数*

---

## 🔧 高级用法

### 自定义迭代次数

```bash
# 默认自动计算迭代次数 (至少运行 10 秒)
./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000

# 指定迭代次数 (例如 50000 次)
./coremark_x86_64 0x0 0x0 0x66 50000 7 1 2000
```

### 运行验证测试

```bash
# 验证模式 (确保二进制文件正确)
./coremark_x86_64 0x3415 0x3415 0x66 0 7 1 2000
```

### 保存结果到文件

```bash
./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000 > my_result.log
```

---

## 💡 常见问题

### Q: 为什么我的分数比预期低？

**A**: 可能原因：
1. 系统负载高 - 关闭其他程序再测试
2. CPU 节能模式 - 切换到性能模式
3. 温度限制导致降频 - 检查散热
4. 虚拟机 - 性能会低于物理机

### Q: 如何切换到性能模式？

**A**: 在 Linux 上：

```bash
# 查看当前模式
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 临时切换到性能模式
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 恢复节能模式
echo ondemand | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### Q: 下载失败怎么办？

**A**: 
1. 检查网络连接
2. 尝试使用代理或镜像：
   ```bash
   # 使用 ghproxy 镜像
   wget https://ghproxy.com/https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_x86_64
   ```
3. 直接从浏览器下载后上传到设备

### Q: 提示 "Permission denied"？

**A**: 添加执行权限：

```bash
chmod +x coremark_x86_64
```

### Q: 提示 "No such file or directory"？

**A**: 可能缺少依赖库。虽然我们编译了静态版本，但某些系统可能仍需要：

```bash
# Debian/Ubuntu
sudo apt-get install libc6

# CentOS/RHEL
sudo yum install glibc
```

### Q: 如何获得最准确的结果？

**A**: 最佳实践：
1. 关闭所有不必要的程序和服务
2. 等待系统空闲 (低负载)
3. 确保良好的散热
4. 运行 3 次取平均值
5. 记录测试时的系统状态

---

## 📤 提交跑分结果

想要让你的设备出现在狗点饭 NAS 排行榜上？

### 需要提交的信息

- ✅ CPU 型号 (可从跑分输出中获取)
- ✅ CPU 核心数
- ✅ CoreMark 分数
- ✅ 设备型号 (如果是 NAS)
- ⭕ 操作系统版本 (可选)
- ⭕ 内存大小 (可选)

### 提交方式

访问 **[狗点饭网站](https://gou.fan)** 提交你的跑分数据！

---

## 🔗 相关链接

- **GitHub 仓库**: [huladabang/coremark-goufan](https://github.com/huladabang/coremark-goufan)
- **狗点饭网站**: [https://gou.fan](https://gou.fan)
- **问题反馈**: [GitHub Issues](https://github.com/huladabang/coremark-goufan/issues)

---

## 📝 技术说明

### 编译配置

- **优化级别**: `-O2`
- **多线程**: 使用 pthread 支持
- **线程数**: 自动检测 CPU 核心数
- **链接方式**: 静态链接 (最大化兼容性)

### 支持的平台

- ✅ Ubuntu / Debian
- ✅ CentOS / RHEL
- ✅ 群晖 (Synology DSM)
- ✅ 威联通 (QNAP QTS)
- ✅ OpenWrt
- ✅ 树莓派 OS
- ✅ Armbian

基本上所有现代 Linux 发行版都支持！

---

**享受跑分的乐趣！** 🚀


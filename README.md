# CoreMark - 狗点饭 NAS 性能跑分工具 🚀

> CoreMark是一款专门用于测量嵌入式处理器性能的小型基准测试软件；CoreMark得分越高说明处理器越强，一键测试你的 NAS/软路由/路由器 CPU 性能 | 基于 CoreMark 标准测试

[![构建状态](https://github.com/huladabang/coremark-goufan/workflows/构建多平台%20CoreMark/badge.svg)](https://github.com/huladabang/coremark-goufan/actions)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE.md)

---

## 🎯 快速开始

### 一键运行

#### 🌍 国际版（推荐国外用户）

```bash
curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh | sh
```

#### 🇨🇳 国内镜像加速版（推荐国内用户）

```bash
curl -fsSL https://gou.fan/coremark/run-mirror.sh | sh
```

> 💡 **两个版本功能完全相同**，区别仅在于下载源：
> - 国际版从 GitHub 下载（国外速度快）
> - 国内版从狗点饭服务器下载（国内速度快）

### 手动下载

根据你的 CPU 架构选择对应版本：

**GitHub 下载：**
- **x86_64** (Intel/AMD): [下载](https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_x86_64)
- **ARM64** (aarch64): [下载](https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_arm64)
- **ARMv7** (armhf): [下载](https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_armv7)

**国内镜像：**
- **x86_64**: [下载](https://gou.fan/coremark/releases/latest/download/coremark_x86_64)
- **ARM64**: [下载](https://gou.fan/coremark/releases/latest/download/coremark_arm64)
- **ARMv7**: [下载](https://gou.fan/coremark/releases/latest/download/coremark_armv7)

```bash
# 下载并运行 (以 ARM64 为例)
wget https://gou.fan/coremark/releases/latest/download/coremark_arm64
chmod +x coremark_arm64
./coremark_arm64 0x0 0x0 0x66 0 7 1 2000
```

## 🌟 特性

- ✅ **一键运行** - 无需编译，自动识别架构
- ✅ **国内加速** - 提供国内镜像源，下载速度快
- ✅ **多平台支持** - x86_64, ARM64, ARMv7
- ✅ **多线程优化** - 充分利用多核性能
- ✅ **静态链接** - 最大化兼容性，适用于各种 Linux 发行版
- ✅ **广泛兼容** - 支持群晖、威联通、OpenWrt、梅林等

## 📊 支持的平台

| 平台 | 架构 | 状态 | 测试设备 |
|------|------|------|----------|
| Intel/AMD 64位 | x86_64 | ✅ | 群晖 DS920+, Ubuntu 服务器 |
| ARM 64位 | ARM64 | ✅ | 华硕 RT-BE86U, 树莓派 4/5 |
| ARM 32位 | ARMv7 | ✅ | 树莓派 2/3, Netcore N60 PRO |

**支持的系统：** Ubuntu, Debian, CentOS, 群晖 DSM, 威联通 QTS, OpenWrt, 梅林固件, ImmortalWrt 等

## 🔧 技术细节

- **优化级别**: `-O2`
- **多线程**: `-DMULTITHREAD=$(nproc) -DUSE_PTHREAD`
- **链接选项**: `-pthread -static`

---

## 🔗 相关链接

- 🎯 **[低功耗CPU性能天梯图](https://gou.fan)** - 查看各型号 CPU 性能排行
- 📝 **[问题反馈](https://github.com/huladabang/coremark-goufan/issues)** - 提交问题和建议
- 📚 **[CoreMark 官方](https://www.eembc.org/coremark/)** - 了解 CoreMark 标准

---

<sub>⚡ Powered by [狗点饭](https://gou.fan)</sub>

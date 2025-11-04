# CoreMark - 狗点饭 NAS 性能跑分工具 🚀

> CoreMark是一款专门用于测量嵌入式处理器性能的小型基准测试软件；CoreMark得分越高说明处理器越强，一键测试你的 NAS/软路由/路由器 CPU 性能 | 基于 CoreMark 标准测试

[![构建状态](https://github.com/huladabang/coremark-goufan/workflows/构建多平台%20CoreMark/badge.svg)](https://github.com/huladabang/coremark-goufan/actions)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE.md)

---

## 🎯 快速开始

### 一键运行

#### 🌍 默认推荐

```bash
# 使用 curl
curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh | sh

# 或使用 wget
wget -qO- https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh | sh
```

如果上面命令无法下载，可尝试下方镜像：

#### 🤡 狗点饭镜像

```bash
# 使用 curl
curl -fsSL https://gou.fan/coremark/run-mirror.sh | sh

# 或使用 wget
wget -qO- https://gou.fan/coremark/run-mirror.sh | sh
```


### 手动下载运行

一键运行脚本出问题时，可尝试手动下载运行coremark跑分：

根据你的 CPU 架构选择对应版本：

```bash
# 在线下载并运行 (以 ARM64 为例)或者在releases下载并上传
wget https://gou.fan/coremark/releases/latest/download/coremark_arm64
chmod +x coremark_arm64
./coremark_arm64 
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

**支持的系统：** Ubuntu, Debian, 群晖 DSM, 威联通 QTS, OpenWrt, 华硕路由器, 梅林固件, ImmortalWrt 等

## 🔧 技术细节

- **优化级别**: `-O3` (激进优化，追求极致性能)
- **多线程**: `-DMULTITHREAD=$(nproc) -DUSE_PTHREAD`
- **链接选项**: `-pthread -static`

---

## 🔗 相关链接

- 🎯 **[低功耗CPU性能天梯图](https://gou.fan)** - 查看各型号 CPU 性能排行
- 📝 **[问题反馈](https://github.com/huladabang/coremark-goufan/issues)** - 提交问题和建议
- 📚 **[CoreMark 官方](https://www.eembc.org/coremark/)** - 了解 CoreMark 标准

---

<sub>⚡ Powered by [狗点饭](https://gou.fan)</sub>

# CoreMark 自动构建与部署指南

本指南说明如何配置 GitHub Actions 自动构建多平台 CoreMark 二进制文件，并在狗点饭网站上提供下载。

## 📋 目录

1. [系统架构](#系统架构)
2. [GitHub 配置](#github-配置)
3. [网站集成](#网站集成)
4. [使用方法](#使用方法)
5. [常见问题](#常见问题)

---

## 🏗️ 系统架构

### 工作流程

```
用户访问网站
    ↓
运行一键脚本
    ↓
自动检测架构
    ↓
从 GitHub Releases 下载对应二进制
    ↓
运行 CoreMark 跑分
    ↓
显示结果
    ↓
(可选) 上传到网站数据库
```

### 编译目标

- **x86_64** (Intel/AMD 64位)
- **ARM64** (aarch64, 如树莓派 4/5、群晖 DS920+)
- **ARMv7** (armhf, 如树莓派 2/3、旧款 ARM 设备)

### 编译参数

- **PORT_DIR**: `linux`
- **编译优化**: `-O2`
- **多线程支持**: `-DMULTITHREAD=$(nproc) -DUSE_PTHREAD`
- **链接参数**: `-pthread`
- **静态链接**: `-static` (确保在不同 Linux 发行版上运行)

---

## ⚙️ GitHub 配置

### 1. 创建 GitHub Actions 工作流

工作流文件已创建在 `.github/workflows/build.yml`。

**触发条件**:
- 推送到 `main` 分支
- Pull Request 到 `main` 分支
- 创建 Release
- 手动触发 (workflow_dispatch)

### 2. 首次构建

#### 方法 1: 创建 Release (推荐)

```bash
# 打标签并推送
git tag -a v1.0.0 -m "首次发布"
git push origin v1.0.0

# 在 GitHub 网页创建 Release
# 1. 进入仓库 → Releases → Create a new release
# 2. 选择标签 v1.0.0
# 3. 填写 Release 标题和描述
# 4. 发布
```

GitHub Actions 将自动构建并将二进制文件附加到 Release。

#### 方法 2: 手动触发

```bash
# 推送代码触发自动构建
git add .
git commit -m "配置自动构建"
git push origin main
```

或在 GitHub 网页：
1. 进入 `Actions` 标签
2. 选择 "构建多平台 CoreMark"
3. 点击 "Run workflow"

### 3. 验证构建

1. 进入 GitHub 仓库的 `Actions` 标签
2. 查看最新的工作流运行状态
3. 成功后，在 `Releases` 页面应该能看到三个二进制文件：
   - `coremark_x86_64`
   - `coremark_arm64`
   - `coremark_armv7`

### 4. 构建产物

每次构建会生成：
- **Artifacts** (保留 90 天): 用于测试和调试
- **Release Assets** (永久保留): 提供给用户下载

---

## 🌐 网站集成

### 1. 修改一键脚本

在 `run.sh` 中修改以下变量：

```bash
# 将 huladabang 替换为你的 GitHub 用户名或组织名
REPO_URL="https://github.com/huladabang/coremark-goufan"
DOWNLOAD_BASE="${REPO_URL}/releases/latest/download"
```

### 2. 在网站上提供下载链接

#### 方式 A: 一键运行脚本 (推荐)

在网站上展示以下命令：

```bash
# 一键运行
bash <(curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)

# 或使用 wget
bash <(wget -qO- https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)
```

**网站示例 HTML**:

```html
<div class="coremark-tool">
  <h2>NAS 性能跑分工具</h2>
  <p>一键运行 CoreMark 跑分测试：</p>
  
  <div class="command-box">
    <code>bash &lt;(curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)</code>
    <button onclick="copyToClipboard()">复制</button>
  </div>
  
  <h3>手动下载</h3>
  <ul>
    <li><a href="https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_x86_64">x86_64 (Intel/AMD)</a></li>
    <li><a href="https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_arm64">ARM64 (aarch64)</a></li>
    <li><a href="https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_armv7">ARMv7 (armhf)</a></li>
  </ul>
</div>
```

#### 方式 B: 直接下载链接

```
https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_x86_64
https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_arm64
https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_armv7
```

### 3. 收集跑分结果

#### 方案 A: 简单表单提交

在网站创建表单，让用户提交：
- CPU 型号
- 核心数
- CoreMark 分数
- 系统信息 (可选)

#### 方案 B: API 自动提交

修改 `run.sh`，添加自动提交功能：

```bash
# 在 run_coremark 函数末尾添加
submit_to_api() {
    local score=$1
    local cpu_info=$2
    
    # 发送到你的 API
    curl -X POST https://gou.fan/api/coremark/submit \
      -H "Content-Type: application/json" \
      -d "{\"score\": \"$score\", \"cpu\": \"$cpu_info\"}"
}
```

#### 方案 C: GitHub Issues (临时方案)

让用户通过 GitHub Issues 提交跑分结果，再手动整理。

---

## 📖 使用方法

### 用户端使用

#### 1. 一键运行 (最简单)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)
```

#### 2. 手动下载运行

```bash
# 下载对应架构的二进制
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_x86_64

# 添加执行权限
chmod +x coremark_x86_64

# 运行跑分 (性能测试)
./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000

# 运行跑分 (验证测试)
./coremark_x86_64 0x3415 0x3415 0x66 0 7 1 2000
```

### 管理员操作

#### 更新构建

```bash
# 1. 修改代码或配置
git add .
git commit -m "更新构建配置"
git push origin main

# 2. 创建新版本
git tag -a v1.0.1 -m "版本 1.0.1"
git push origin v1.0.1

# 3. 在 GitHub 创建 Release
# GitHub Actions 会自动构建并上传新版本
```

#### 查看构建日志

1. 进入 GitHub 仓库
2. 点击 `Actions` 标签
3. 选择对应的工作流运行记录
4. 查看详细日志

---

## ❓ 常见问题

### Q1: 构建失败怎么办？

**A**: 检查以下几点：
1. GitHub Actions 是否启用？
2. 查看 Actions 日志中的错误信息
3. 确保所有依赖都正确安装
4. 验证 Makefile 配置

### Q2: 如何添加更多架构？

**A**: 编辑 `.github/workflows/build.yml`，在 `matrix.include` 中添加新架构：

```yaml
- arch: riscv64
  cc: riscv64-linux-gnu-gcc
  output: coremark_riscv64
```

并安装对应的交叉编译工具链。

### Q3: 二进制文件太大？

**A**: 尝试以下优化：
1. 使用 `-Os` 替代 `-O2` (优化大小)
2. 使用 `strip` 命令去除符号表：
   ```bash
   strip coremark_x86_64
   ```
3. 考虑使用动态链接而非静态链接 (但可能影响兼容性)

### Q4: 如何本地测试构建？

**A**: 使用 Docker 模拟构建环境：

```bash
# x86_64
docker run --rm -v $(pwd):/work -w /work ubuntu:22.04 bash -c "
  apt-get update && apt-get install -y build-essential &&
  make PORT_DIR=linux XCFLAGS='-O2 -DMULTITHREAD=4 -DUSE_PTHREAD -static' LFLAGS_END='-pthread' compile
"

# ARM64
docker run --rm -v $(pwd):/work -w /work ubuntu:22.04 bash -c "
  apt-get update && apt-get install -y build-essential gcc-aarch64-linux-gnu &&
  make PORT_DIR=linux CC=aarch64-linux-gnu-gcc XCFLAGS='-O2 -DMULTITHREAD=4 -DUSE_PTHREAD -static' LFLAGS_END='-pthread' compile
"
```

### Q5: 如何自定义跑分参数？

**A**: 修改 `run.sh` 中的 `run_coremark` 函数，调整参数：

```bash
# 参数说明:
# $1 $2 $3: 种子值
# $4: 迭代次数 (0=自动)
# $5: 数据大小
# $6: 线程数
# $7: 时间限制

./coremark_x86_64 0x0 0x0 0x66 10000 7 1 2000
#                            ^^^^^ 指定迭代次数
```

### Q6: 脚本下载失败？

**A**: 可能原因：
1. GitHub 网络问题 → 使用镜像或代理
2. Release 未创建 → 先创建 Release
3. 文件名不匹配 → 检查 `run.sh` 中的 URL

**解决方案 - 使用国内镜像**:

```bash
# 修改 run.sh 中的下载 URL
DOWNLOAD_BASE="https://ghproxy.com/https://github.com/huladabang/coremark-goufan/releases/latest/download"
```

### Q7: 如何验证二进制文件的正确性？

**A**: CoreMark 有内置验证：

```bash
# 运行验证测试
./coremark_x86_64 0x3415 0x3415 0x66 0 7 1 2000

# 检查输出中的 "Correct operation validated"
# 如果看到此消息，说明二进制文件正常工作
```

---

## 📊 性能基准参考

以下是常见平台的 CoreMark 分数参考 (单线程):

| 平台 | CPU | 分数 (约) |
|------|-----|----------|
| Intel i7-10700K @ 3.8GHz | x86_64 | ~30,000 |
| AMD Ryzen 5 3600 @ 3.6GHz | x86_64 | ~28,000 |
| 树莓派 4B (BCM2711) @ 1.5GHz | ARM64 | ~6,000 |
| 群晖 DS920+ (Celeron J4125) | x86_64 | ~14,000 |
| 树莓派 3B+ (BCM2837B0) @ 1.4GHz | ARMv7 | ~4,500 |

*注: 多线程分数会更高，具体取决于核心数*

---

## 🔗 相关链接

- [CoreMark 官方网站](https://www.eembc.org/coremark/)
- [CoreMark GitHub](https://github.com/eembc/coremark)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [狗点饭网站](https://gou.fan)

---

## 📝 更新日志

### v1.0.0 (2025-11-03)
- ✨ 初始版本
- ✅ 支持 x86_64, ARM64, ARMv7 架构
- ✅ GitHub Actions 自动构建
- ✅ 一键运行脚本
- ✅ 多线程优化
- ✅ 静态链接确保兼容性

---

## 📄 许可证

CoreMark 遵循 Apache License 2.0。

---

**有问题？** 欢迎提交 [GitHub Issues](https://github.com/huladabang/coremark-goufan/issues)！


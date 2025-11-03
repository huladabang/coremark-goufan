# 快速命令参考 🚀

快速查找常用命令的速查表。

---

## 🎯 用户端命令

### 一键运行跑分

```bash
# 使用 curl
curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh | bash

# 使用 wget
bash <(wget -qO- https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)

# 使用镜像 (国内用户)
bash <(curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)
```

### 手动下载运行

```bash
# x86_64
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_x86_64
chmod +x coremark_x86_64
./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000

# ARM64
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_arm64
chmod +x coremark_arm64
./coremark_arm64 0x0 0x0 0x66 0 7 1 2000

# ARMv7
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_armv7
chmod +x coremark_armv7
./coremark_armv7 0x0 0x0 0x66 0 7 1 2000
```

### 保存结果到文件

```bash
./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000 > my_result.log
```

### 运行验证测试

```bash
./coremark_x86_64 0x3415 0x3415 0x66 0 7 1 2000
```

---

## 🔧 开发者命令

### 本地构建测试

```bash
# 使用测试脚本
./local-build-test.sh

# 手动构建
make PORT_DIR=linux \
  XCFLAGS="-O2 -DMULTITHREAD=$(nproc) -DUSE_PTHREAD" \
  LFLAGS_END="-pthread" \
  compile

# 运行测试
./coremark.exe 0x0 0x0 0x66 0 7 1 2000
```

### 清理构建产物

```bash
make clean
rm -f *.log coremark_*
```

### 替换 huladabang

```bash
# macOS
find . -type f \( -name "*.sh" -o -name "*.md" -o -name "*.html" \) \
  -exec sed -i '' 's/huladabang/你的用户名/g' {} +

# Linux
find . -type f \( -name "*.sh" -o -name "*.md" -o -name "*.html" \) \
  -exec sed -i 's/huladabang/你的用户名/g' {} +
```

---

## 📦 Git 操作

### 初始化并推送

```bash
# 初始化
git init
git add .
git commit -m "初始化 CoreMark 跑分系统"

# 添加远程仓库
git remote add origin https://github.com/huladabang/coremark-goufan.git

# 推送
git branch -M main
git push -u origin main
```

### 创建 Release

```bash
# 创建标签
git tag -a v1.0.0 -m "首次发布"

# 推送标签
git push origin v1.0.0

# 然后在 GitHub 网页创建 Release
```

### 更新代码

```bash
# 拉取最新代码
git pull origin main

# 修改后提交
git add .
git commit -m "更新说明"
git push origin main
```

---

## ⚙️ 系统优化命令

### CPU 性能模式

```bash
# 查看当前模式
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 切换到性能模式
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 恢复节能模式
echo ondemand | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### 查看 CPU 信息

```bash
# CPU 型号
grep "model name" /proc/cpuinfo | head -n1

# CPU 核心数
nproc

# CPU 架构
uname -m

# 详细信息
lscpu
```

### 查看系统信息

```bash
# 操作系统
cat /etc/os-release

# 内核版本
uname -a

# 内存信息
free -h
```

---

## 🧪 测试命令

### 性能测试

```bash
# 默认配置 (自动计算迭代次数)
./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000

# 指定迭代次数
./coremark_x86_64 0x0 0x0 0x66 50000 7 1 2000

# 单线程测试
make PORT_DIR=linux XCFLAGS="-O2" compile
./coremark.exe 0x0 0x0 0x66 0 7 1 2000
```

### 验证测试

```bash
# 验证模式
./coremark_x86_64 0x3415 0x3415 0x66 0 7 1 2000

# 检查验证结果
grep "Correct operation validated" run2.log
```

### 压力测试

```bash
# 多次运行取平均值
for i in {1..3}; do
  echo "=== 第 $i 次测试 ==="
  ./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000
done
```

---

## 🔍 调试命令

### 检查二进制文件

```bash
# 文件类型
file coremark_x86_64

# 文件大小
ls -lh coremark_x86_64

# 依赖库
ldd coremark_x86_64

# 符号表
nm coremark_x86_64

# 字符串
strings coremark_x86_64 | head -20
```

### 查看构建日志

```bash
# GitHub Actions 日志
# 访问: https://github.com/huladabang/coremark-goufan/actions

# 本地构建日志
make PORT_DIR=linux compile 2>&1 | tee build.log
```

### 检查错误

```bash
# 查看最近的错误日志
dmesg | tail -20

# 运行时错误
./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000 2>&1 | tee error.log
```

---

## 📊 性能分析命令

### 使用 time 命令

```bash
time ./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000
```

### 使用 perf (Linux)

```bash
# 安装 perf
sudo apt-get install linux-tools-generic

# 性能分析
perf stat ./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000

# 详细分析
perf record ./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000
perf report
```

### 监控系统资源

```bash
# 实时监控
htop

# CPU 使用率
top -bn1 | grep "Cpu(s)"

# 温度监控 (如果支持)
sensors
```

---

## 🌐 API 测试命令

### 提交结果

```bash
curl -X POST http://localhost:3000/api/coremark/submit \
  -H "Content-Type: application/json" \
  -d '{
    "cpu_model": "Intel Core i7-10700K",
    "cpu_cores": 8,
    "architecture": "x86_64",
    "coremark_score": "28456.78"
  }'
```

### 获取排行榜

```bash
# 全部
curl http://localhost:3000/api/coremark/leaderboard

# 按架构筛选
curl http://localhost:3000/api/coremark/leaderboard?arch=x86_64

# 限制数量
curl http://localhost:3000/api/coremark/leaderboard?limit=10
```

### 获取统计信息

```bash
curl http://localhost:3000/api/coremark/stats
```

---

## 🐳 Docker 命令 (可选)

### 使用 Docker 构建

```bash
# x86_64
docker run --rm -v $(pwd):/work -w /work ubuntu:22.04 bash -c "
  apt-get update && apt-get install -y build-essential &&
  make PORT_DIR=linux XCFLAGS='-O2 -DMULTITHREAD=4 -DUSE_PTHREAD -static' LFLAGS_END='-pthread' compile
"

# ARM64 (交叉编译)
docker run --rm -v $(pwd):/work -w /work ubuntu:22.04 bash -c "
  apt-get update && apt-get install -y build-essential gcc-aarch64-linux-gnu &&
  make PORT_DIR=linux CC=aarch64-linux-gnu-gcc XCFLAGS='-O2 -DMULTITHREAD=4 -DUSE_PTHREAD -static' LFLAGS_END='-pthread' compile
"
```

---

## 🔗 快速链接

### 文档

```bash
# 查看文档
cat README.md
cat QUICKSTART.md
cat DEPLOY.md
cat USAGE.md
```

### GitHub 页面

```
仓库: https://github.com/huladabang/coremark-goufan
Actions: https://github.com/huladabang/coremark-goufan/actions
Releases: https://github.com/huladabang/coremark-goufan/releases
Issues: https://github.com/huladabang/coremark-goufan/issues
```

---

## 💡 常用组合

### 完整测试流程

```bash
# 1. 切换到性能模式
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 2. 下载
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_x86_64

# 3. 添加权限
chmod +x coremark_x86_64

# 4. 运行测试
./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000 | tee result.log

# 5. 提取分数
grep "CoreMark 1.0" result.log

# 6. 恢复节能模式
echo ondemand | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### 多架构测试

```bash
# 下载所有架构
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_x86_64
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_arm64
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_armv7

# 添加权限
chmod +x coremark_*

# 测试当前架构
ARCH=$(uname -m)
case $ARCH in
  x86_64) ./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000 ;;
  aarch64) ./coremark_arm64 0x0 0x0 0x66 0 7 1 2000 ;;
  armv7l) ./coremark_armv7 0x0 0x0 0x66 0 7 1 2000 ;;
esac
```

---

## 📝 注意事项

1. **替换 huladabang**: 所有命令中的 `huladabang` 需要替换为实际的 GitHub 用户名
2. **权限问题**: 某些命令需要 sudo 权限
3. **网络问题**: 国内用户可能需要使用镜像或代理
4. **架构匹配**: 确保下载的二进制文件与系统架构匹配

---

**快速参考完成！** 📋

需要更多帮助？查看完整文档或提交 Issue。


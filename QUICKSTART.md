# 快速开始指南 ⚡

这是一个 5 分钟的快速开始指南，帮助你快速部署 CoreMark 跑分系统。

## 📋 目录

1. [准备工作](#准备工作)
2. [部署到 GitHub](#部署到-github)
3. [触发首次构建](#触发首次构建)
4. [测试跑分](#测试跑分)
5. [集成到网站](#集成到网站)

---

## 1️⃣ 准备工作

### 检查文件

确保你的仓库包含以下文件：

```
coremark-goufan/
├── .github/
│   └── workflows/
│       └── build.yml          ✅ GitHub Actions 工作流
├── run.sh                     ✅ 一键运行脚本
├── README.md                  ✅ 项目说明
├── DEPLOY.md                  ✅ 部署文档
├── USAGE.md                   ✅ 使用说明
└── (其他 CoreMark 源文件)
```

### 修改仓库地址

**重要！** 在以下文件中将 `huladabang` 替换为你的 GitHub 用户名：

1. `run.sh`
2. `README.md`
3. `DEPLOY.md`
4. `USAGE.md`
5. `website-example.html`

使用以下命令快速替换 (假设你的用户名是 `goufan`)：

```bash
# macOS/Linux
find . -type f \( -name "*.sh" -o -name "*.md" -o -name "*.html" \) -exec sed -i '' 's/huladabang/goufan/g' {} +

# Linux (如果上面的命令不行)
find . -type f \( -name "*.sh" -o -name "*.md" -o -name "*.html" \) -exec sed -i 's/huladabang/goufan/g' {} +
```

---

## 2️⃣ 部署到 GitHub

### 方式 A: 通过命令行

```bash
# 1. 初始化 Git 仓库 (如果还没有)
git init

# 2. 添加所有文件
git add .

# 3. 提交
git commit -m "初始化 CoreMark 跑分系统"

# 4. 在 GitHub 创建新仓库后，添加远程地址
git remote add origin https://github.com/huladabang/coremark-goufan.git

# 5. 推送到 GitHub
git branch -M main
git push -u origin main
```

### 方式 B: 通过 GitHub 网页

1. 访问 [GitHub](https://github.com)
2. 点击右上角 "+" → "New repository"
3. 仓库名：`coremark-goufan`
4. 描述：`NAS 性能跑分工具 - CoreMark`
5. 选择 Public (公开) 或 Private (私有)
6. 不要勾选 "Initialize with README"
7. 点击 "Create repository"
8. 按照页面提示上传代码

---

## 3️⃣ 触发首次构建

### 方式 A: 创建 Release (推荐)

```bash
# 1. 创建标签
git tag -a v1.0.0 -m "首次发布"

# 2. 推送标签
git push origin v1.0.0
```

然后在 GitHub 网页：
1. 进入仓库
2. 点击右侧 "Releases"
3. 点击 "Draft a new release"
4. 选择标签 `v1.0.0`
5. Release 标题：`v1.0.0 - 首次发布`
6. 描述：
   ```
   ## 🎉 首次发布
   
   支持的架构：
   - x86_64 (Intel/AMD)
   - ARM64 (aarch64)
   - ARMv7 (armhf)
   
   ## 使用方法
   
   一键运行：
   \`\`\`bash
   bash <(curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)
   \`\`\`
   ```
7. 点击 "Publish release"

### 方式 B: 手动触发

1. 进入仓库的 **Actions** 标签
2. 选择 "构建多平台 CoreMark"
3. 点击 "Run workflow" → "Run workflow"
4. 等待构建完成 (约 3-5 分钟)

### 验证构建结果

1. 进入 **Actions** 标签查看构建状态
2. 如果显示绿色 ✅，说明构建成功
3. 进入 **Releases** 页面，应该能看到三个文件：
   - `coremark_x86_64`
   - `coremark_arm64`
   - `coremark_armv7`

---

## 4️⃣ 测试跑分

### 在本地测试

**x86_64 Linux:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)
```

**手动测试:**

```bash
# 下载
wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_x86_64

# 添加执行权限
chmod +x coremark_x86_64

# 运行
./coremark_x86_64 0x0 0x0 0x66 0 7 1 2000
```

### 预期输出

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

看到 `Correct operation validated` 说明测试成功！

---

## 5️⃣ 集成到网站

### 选项 1: 简单按钮

在你的网站上添加以下 HTML：

```html
<div class="coremark-section">
  <h2>NAS 性能跑分</h2>
  <p>一键测试你的设备性能：</p>
  <pre><code>bash &lt;(curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)</code></pre>
  <button onclick="copyToClipboard()">复制命令</button>
</div>

<script>
function copyToClipboard() {
  const text = 'bash <(curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)';
  navigator.clipboard.writeText(text).then(() => {
    alert('命令已复制！');
  });
}
</script>
```

### 选项 2: 完整页面

使用提供的 `website-example.html` 作为模板：

1. 复制 `website-example.html` 内容
2. 修改其中的 `huladabang`
3. 集成到你的网站
4. 根据需要调整样式

### 选项 3: 下载链接

```html
<h3>直接下载</h3>
<ul>
  <li><a href="https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_x86_64">x86_64</a></li>
  <li><a href="https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_arm64">ARM64</a></li>
  <li><a href="https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_armv7">ARMv7</a></li>
</ul>
```

---

## ✅ 完成检查清单

确认以下所有项目都已完成：

- [ ] 替换所有文件中的 `huladabang`
- [ ] 推送代码到 GitHub
- [ ] GitHub Actions 构建成功
- [ ] Release 页面有三个二进制文件
- [ ] 本地测试一键脚本成功
- [ ] 网站已集成跑分入口

---

## 🎉 恭喜！

你已经成功部署了 CoreMark 跑分系统！

### 下一步

1. **收集跑分数据**
   - 创建数据库存储用户提交的结果
   - 建立排行榜页面

2. **优化用户体验**
   - 添加自动提交功能
   - 提供更详细的系统信息

3. **推广**
   - 在 NAS 社区分享
   - 收集用户反馈

### 需要帮助？

- 📖 查看 [DEPLOY.md](DEPLOY.md) 了解更多细节
- 📚 阅读 [USAGE.md](USAGE.md) 查看使用说明
- 🐛 [提交 Issue](https://github.com/huladabang/coremark-goufan/issues)

---

**祝你好运！** 🚀


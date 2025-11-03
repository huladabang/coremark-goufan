# 镜像源配置指南 🌐

为了提升国内用户体验，建议配置狗点饭镜像源反代 GitHub 下载。

---

## 🎯 为什么需要镜像源？

**问题：**
- 国内访问 GitHub 速度慢
- 下载 Release 文件经常失败
- 用户体验差

**解决方案：**
- 使用国内服务器反代 GitHub
- 自动检测网络环境，智能切换
- 主源失败自动尝试备用源

---

## 📋 方案一：Cloudflare Workers（推荐）

### 优势
- ✅ 完全免费
- ✅ 全球 CDN 加速
- ✅ 无需自己的服务器
- ✅ 配置简单

### 配置步骤

**1. 创建 Worker**

登录 [Cloudflare Dashboard](https://dash.cloudflare.com/) → Workers & Pages → Create Worker

**2. 粘贴代码**

```javascript
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url)
  const path = url.pathname
  
  // 反代 GitHub Releases 下载
  if (path.startsWith('/releases/latest/download/')) {
    const fileName = path.split('/').pop()
    const githubUrl = `https://github.com/huladabang/coremark-goufan/releases/latest/download/${fileName}`
    
    const response = await fetch(githubUrl, {
      method: request.method,
      headers: request.headers,
      redirect: 'follow'
    })
    
    // 添加 CORS 头
    const newResponse = new Response(response.body, response)
    newResponse.headers.set('Access-Control-Allow-Origin', '*')
    newResponse.headers.set('Cache-Control', 'public, max-age=86400') // 缓存1天
    
    return newResponse
  }
  
  // 反代脚本文件
  if (path === '/run.sh' || path === '/main/run.sh') {
    const githubUrl = 'https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh'
    
    const response = await fetch(githubUrl, {
      method: request.method,
      headers: request.headers
    })
    
    const newResponse = new Response(response.body, response)
    newResponse.headers.set('Access-Control-Allow-Origin', '*')
    newResponse.headers.set('Content-Type', 'text/plain; charset=utf-8')
    newResponse.headers.set('Cache-Control', 'public, max-age=3600') // 缓存1小时
    
    return newResponse
  }
  
  return new Response('Not Found', { status: 404 })
}
```

**3. 绑定自定义域名**

Workers → 你的 Worker → Settings → Triggers → Add Custom Domain

添加：`coremark.gou.fan`

**4. 测试**

```bash
# 测试脚本
curl -I https://coremark.gou.fan/run.sh

# 测试二进制下载
curl -I https://coremark.gou.fan/releases/latest/download/coremark_x86_64
```

---

## 📋 方案二：Nginx 反代

### 适用场景
- 已有服务器
- 需要更多控制
- 本地缓存

### Nginx 配置

```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name coremark.gou.fan;
    
    # SSL 证书（使用 Let's Encrypt）
    ssl_certificate /etc/letsencrypt/live/coremark.gou.fan/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/coremark.gou.fan/privkey.pem;
    
    # 日志
    access_log /var/log/nginx/coremark_access.log;
    error_log /var/log/nginx/coremark_error.log;
    
    # 缓存配置
    proxy_cache_path /var/cache/nginx/coremark levels=1:2 keys_zone=coremark_cache:10m max_size=1g inactive=7d;
    
    # 反代 Releases 下载
    location /releases/latest/download/ {
        proxy_pass https://github.com/huladabang/coremark-goufan/releases/latest/download/;
        proxy_ssl_server_name on;
        proxy_ssl_protocols TLSv1.2 TLSv1.3;
        
        proxy_set_header Host github.com;
        proxy_set_header User-Agent $http_user_agent;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # 跟随重定向
        proxy_intercept_errors off;
        proxy_redirect https://objects.githubusercontent.com/ /github-objects/;
        
        # 缓存设置
        proxy_cache coremark_cache;
        proxy_cache_valid 200 7d;
        proxy_cache_key $uri;
        
        # 超时设置
        proxy_connect_timeout 10s;
        proxy_read_timeout 30s;
        
        # CORS
        add_header Access-Control-Allow-Origin *;
    }
    
    # 反代 GitHub Objects（处理重定向）
    location /github-objects/ {
        internal;
        proxy_pass https://objects.githubusercontent.com/;
        proxy_ssl_server_name on;
        
        proxy_set_header Host objects.githubusercontent.com;
        proxy_cache coremark_cache;
        proxy_cache_valid 200 7d;
    }
    
    # 反代脚本
    location /run.sh {
        proxy_pass https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh;
        proxy_ssl_server_name on;
        
        proxy_set_header Host raw.githubusercontent.com;
        
        proxy_cache coremark_cache;
        proxy_cache_valid 200 1h;
        
        add_header Content-Type "text/plain; charset=utf-8";
        add_header Access-Control-Allow-Origin *;
    }
    
    # 健康检查
    location /health {
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
```

### 部署步骤

```bash
# 1. 复制配置
sudo nano /etc/nginx/sites-available/coremark.conf

# 2. 启用站点
sudo ln -s /etc/nginx/sites-available/coremark.conf /etc/nginx/sites-enabled/

# 3. 创建缓存目录
sudo mkdir -p /var/cache/nginx/coremark
sudo chown -R www-data:www-data /var/cache/nginx/coremark

# 4. 测试配置
sudo nginx -t

# 5. 重启 Nginx
sudo systemctl reload nginx

# 6. 配置 SSL（使用 Certbot）
sudo certbot --nginx -d coremark.gou.fan
```

---

## 📋 方案三：使用现有 CDN 服务

### jsDelivr

```bash
# 直接使用 jsDelivr CDN
https://cdn.jsdelivr.net/gh/huladabang/coremark-goufan@main/run.sh
```

### 缺点
- 不支持 Releases 文件
- 只能用于脚本，不能用于二进制文件

---

## 🔧 脚本自动切换逻辑

脚本已经内置智能切换：

```bash
1. 检测网络环境
   └─ 无法访问 GitHub → 使用镜像源
   └─ 可以访问 GitHub → 使用官方源

2. 下载失败自动重试
   └─ 主源失败 → 切换到备用源
   └─ 备用源也失败 → 提示手动下载

3. 优先级
   └─ 国内：狗点饭镜像 > GitHub
   └─ 国外：GitHub > 狗点饭镜像
```

---

## 📊 测试镜像源

### 测试下载速度

```bash
# GitHub 官方
time wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_x86_64

# 狗点饭镜像
time wget https://coremark.gou.fan/releases/latest/download/coremark_x86_64
```

### 测试可用性

```bash
# 测试脚本
curl -fsSL https://coremark.gou.fan/run.sh | head -5

# 测试二进制文件
curl -I https://coremark.gou.fan/releases/latest/download/coremark_arm64
```

---

## 🎯 域名建议

推荐使用以下域名：

- `coremark.gou.fan` ✅ 推荐
- `mirror.gou.fan/coremark`
- `cdn.gou.fan/coremark`

---

## 📝 DNS 配置

```
# Cloudflare DNS 记录
类型    名称        内容
CNAME   coremark    your-worker.workers.dev
```

或者（Nginx）：

```
类型    名称        内容
A       coremark    你的服务器IP
```

---

## 🔒 安全建议

1. **启用 HTTPS**
   - Cloudflare Workers 自动 HTTPS
   - Nginx 使用 Let's Encrypt 免费证书

2. **限制访问**
   ```nginx
   # Nginx 限速
   limit_req_zone $binary_remote_addr zone=coremark_limit:10m rate=10r/s;
   limit_req zone=coremark_limit burst=20;
   ```

3. **监控流量**
   - Cloudflare Analytics
   - Nginx 访问日志

---

## 💰 成本预估

| 方案 | 月流量 | 费用 |
|------|--------|------|
| Cloudflare Workers | 10万请求 | 免费 |
| Cloudflare Workers | 100万请求 | $5/月 |
| 自建服务器 | 不限 | 服务器费用 |

---

## 🎉 完成后

1. **更新脚本配置**
   - 已在 `run.sh` 中配置 `MIRROR_BASE`
   - 无需额外修改

2. **通知用户**
   - 在网站上说明镜像源
   - README 添加镜像说明

3. **监控服务**
   - 定期检查可用性
   - 关注缓存命中率

---

## 📞 需要帮助？

- Cloudflare Workers 文档：https://developers.cloudflare.com/workers/
- Nginx 反向代理：https://nginx.org/en/docs/
- Let's Encrypt：https://letsencrypt.org/

---

**配置镜像源，让国内用户体验飞起来！** 🚀


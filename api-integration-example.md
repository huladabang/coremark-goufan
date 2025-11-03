# API 集成示例

本文档展示如何将 CoreMark 跑分结果自动提交到狗点饭网站的 API。

## 📊 数据结构

### 提交的数据格式

```json
{
  "cpu_model": "Intel(R) Core(TM) i7-10700K CPU @ 3.80GHz",
  "cpu_cores": 8,
  "cpu_threads": 16,
  "architecture": "x86_64",
  "coremark_score": "28456.78",
  "iterations": 20000,
  "total_time": 14.234,
  "compiler": "GCC11.4.0",
  "compiler_flags": "-O2 -DMULTITHREAD=8 -DUSE_PTHREAD",
  "os_info": "Ubuntu 22.04 LTS",
  "device_model": "自组 NAS",
  "memory_mb": 32768,
  "timestamp": "2025-11-03T10:30:00Z",
  "contact": "user@example.com"
}
```

---

## 🔧 后端 API 实现示例

### Node.js + Express

```javascript
// server.js
const express = require('express');
const app = express();
app.use(express.json());

// 数据库连接 (示例使用 MongoDB)
const { MongoClient } = require('mongodb');
const client = new MongoClient('mongodb://localhost:27017');
const db = client.db('goufan');
const collection = db.collection('coremark_results');

// 提交跑分结果
app.post('/api/coremark/submit', async (req, res) => {
  try {
    const result = {
      ...req.body,
      submitted_at: new Date(),
      ip_address: req.ip,
      verified: false  // 需要人工审核
    };
    
    // 基本验证
    if (!result.cpu_model || !result.coremark_score) {
      return res.status(400).json({ error: '缺少必要字段' });
    }
    
    // 检查分数是否合理 (防止刷分)
    const score = parseFloat(result.coremark_score);
    if (score < 100 || score > 200000) {
      return res.status(400).json({ error: '分数异常' });
    }
    
    // 保存到数据库
    const inserted = await collection.insertOne(result);
    
    res.json({
      success: true,
      message: '提交成功！审核通过后将显示在排行榜上。',
      id: inserted.insertedId
    });
    
  } catch (error) {
    console.error('提交失败:', error);
    res.status(500).json({ error: '服务器错误' });
  }
});

// 获取排行榜
app.get('/api/coremark/leaderboard', async (req, res) => {
  try {
    const { arch, limit = 100 } = req.query;
    
    const filter = { verified: true };
    if (arch) filter.architecture = arch;
    
    const results = await collection
      .find(filter)
      .sort({ coremark_score: -1 })
      .limit(parseInt(limit))
      .toArray();
    
    res.json({
      success: true,
      count: results.length,
      results: results
    });
    
  } catch (error) {
    console.error('查询失败:', error);
    res.status(500).json({ error: '服务器错误' });
  }
});

// 获取统计信息
app.get('/api/coremark/stats', async (req, res) => {
  try {
    const stats = await collection.aggregate([
      { $match: { verified: true } },
      {
        $group: {
          _id: '$architecture',
          count: { $sum: 1 },
          avg_score: { $avg: { $toDouble: '$coremark_score' } },
          max_score: { $max: { $toDouble: '$coremark_score' } },
          min_score: { $min: { $toDouble: '$coremark_score' } }
        }
      }
    ]).toArray();
    
    res.json({
      success: true,
      stats: stats
    });
    
  } catch (error) {
    console.error('查询失败:', error);
    res.status(500).json({ error: '服务器错误' });
  }
});

app.listen(3000, () => {
  console.log('API 服务运行在 http://localhost:3000');
});
```

### Python + Flask

```python
# app.py
from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from datetime import datetime
import re

app = Flask(__name__)
CORS(app)

# 数据库连接
client = MongoClient('mongodb://localhost:27017')
db = client.goufan
collection = db.coremark_results

@app.route('/api/coremark/submit', methods=['POST'])
def submit_result():
    try:
        data = request.json
        
        # 基本验证
        required_fields = ['cpu_model', 'coremark_score', 'architecture']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'缺少必要字段: {field}'}), 400
        
        # 验证分数
        try:
            score = float(data['coremark_score'])
            if score < 100 or score > 200000:
                return jsonify({'error': '分数异常'}), 400
        except ValueError:
            return jsonify({'error': '分数格式错误'}), 400
        
        # 验证架构
        valid_archs = ['x86_64', 'arm64', 'armv7']
        if data['architecture'] not in valid_archs:
            return jsonify({'error': '不支持的架构'}), 400
        
        # 准备数据
        result = {
            **data,
            'submitted_at': datetime.utcnow(),
            'ip_address': request.remote_addr,
            'verified': False
        }
        
        # 保存到数据库
        inserted = collection.insert_one(result)
        
        return jsonify({
            'success': True,
            'message': '提交成功！审核通过后将显示在排行榜上。',
            'id': str(inserted.inserted_id)
        })
        
    except Exception as e:
        print(f'提交失败: {e}')
        return jsonify({'error': '服务器错误'}), 500

@app.route('/api/coremark/leaderboard', methods=['GET'])
def get_leaderboard():
    try:
        arch = request.args.get('arch')
        limit = int(request.args.get('limit', 100))
        
        query = {'verified': True}
        if arch:
            query['architecture'] = arch
        
        results = list(collection.find(query)
                      .sort('coremark_score', -1)
                      .limit(limit))
        
        # 转换 ObjectId 为字符串
        for r in results:
            r['_id'] = str(r['_id'])
        
        return jsonify({
            'success': True,
            'count': len(results),
            'results': results
        })
        
    except Exception as e:
        print(f'查询失败: {e}')
        return jsonify({'error': '服务器错误'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)
```

---

## 🔄 修改 run.sh 添加自动提交

在 `run.sh` 的 `run_coremark` 函数后添加：

```bash
# 提交到 API
submit_to_api() {
    local score=$1
    local cpu_info=$2
    local cpu_cores=$3
    local arch=$4
    
    echo -e "\n${YELLOW}是否提交跑分结果到狗点饭排行榜？(y/N) ${NC}"
    read -r submit_choice
    
    if [[ "$submit_choice" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}请输入你的邮箱 (可选，用于联系): ${NC}"
        read -r user_email
        
        echo -e "${YELLOW}请输入设备型号 (可选): ${NC}"
        read -r device_model
        
        # 获取操作系统信息
        local os_info=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
        
        # 构建 JSON
        local json_data=$(cat <<EOF
{
  "cpu_model": "$cpu_info",
  "cpu_cores": $cpu_cores,
  "architecture": "$arch",
  "coremark_score": "$score",
  "os_info": "$os_info",
  "device_model": "$device_model",
  "contact": "$user_email"
}
EOF
)
        
        echo -e "${YELLOW}正在提交...${NC}"
        
        # 发送到 API
        response=$(curl -s -X POST https://gou.fan/api/coremark/submit \
          -H "Content-Type: application/json" \
          -d "$json_data")
        
        if echo "$response" | grep -q "success"; then
            echo -e "${GREEN}✅ 提交成功！感谢你的贡献！${NC}"
        else
            echo -e "${RED}❌ 提交失败，请稍后重试。${NC}"
            echo "$response"
        fi
    fi
}
```

然后在 `main` 函数中调用：

```bash
# 运行跑分
run_coremark "$TEMP_BINARY" 0

# 提取结果并提交
score=$(grep "CoreMark 1.0" coremark_result.log | grep -oP "CoreMark 1.0 : \K[0-9.]+")
cpu_info=$(grep "model name" /proc/cpuinfo | head -n1 | cut -d: -f2 | sed 's/^[ \t]*//')
cpu_cores=$(nproc)

submit_to_api "$score" "$cpu_info" "$cpu_cores" "$arch"
```

---

## 🎨 前端展示示例

### React 组件

```jsx
// Leaderboard.jsx
import React, { useState, useEffect } from 'react';

function Leaderboard() {
  const [results, setResults] = useState([]);
  const [arch, setArch] = useState('all');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchLeaderboard();
  }, [arch]);

  const fetchLeaderboard = async () => {
    setLoading(true);
    try {
      const url = arch === 'all' 
        ? '/api/coremark/leaderboard'
        : `/api/coremark/leaderboard?arch=${arch}`;
      
      const response = await fetch(url);
      const data = await response.json();
      
      if (data.success) {
        setResults(data.results);
      }
    } catch (error) {
      console.error('加载失败:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="leaderboard">
      <h2>CoreMark 排行榜</h2>
      
      <div className="filters">
        <button onClick={() => setArch('all')}>全部</button>
        <button onClick={() => setArch('x86_64')}>x86_64</button>
        <button onClick={() => setArch('arm64')}>ARM64</button>
        <button onClick={() => setArch('armv7')}>ARMv7</button>
      </div>
      
      {loading ? (
        <p>加载中...</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>排名</th>
              <th>CPU 型号</th>
              <th>架构</th>
              <th>核心数</th>
              <th>分数</th>
            </tr>
          </thead>
          <tbody>
            {results.map((result, index) => (
              <tr key={result._id}>
                <td>{index + 1}</td>
                <td>{result.cpu_model}</td>
                <td>{result.architecture}</td>
                <td>{result.cpu_cores}</td>
                <td>{parseFloat(result.coremark_score).toFixed(2)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

export default Leaderboard;
```

### 纯 JavaScript

```javascript
// leaderboard.js
async function loadLeaderboard(arch = 'all') {
  const url = arch === 'all'
    ? '/api/coremark/leaderboard'
    : `/api/coremark/leaderboard?arch=${arch}`;
  
  try {
    const response = await fetch(url);
    const data = await response.json();
    
    if (data.success) {
      renderLeaderboard(data.results);
    }
  } catch (error) {
    console.error('加载失败:', error);
  }
}

function renderLeaderboard(results) {
  const tbody = document.getElementById('leaderboard-body');
  tbody.innerHTML = '';
  
  results.forEach((result, index) => {
    const row = document.createElement('tr');
    row.innerHTML = `
      <td>${index + 1}</td>
      <td>${result.cpu_model}</td>
      <td>${result.architecture}</td>
      <td>${result.cpu_cores}</td>
      <td>${parseFloat(result.coremark_score).toFixed(2)}</td>
    `;
    tbody.appendChild(row);
  });
}

// 初始加载
document.addEventListener('DOMContentLoaded', () => {
  loadLeaderboard();
});
```

---

## 🔒 安全注意事项

1. **防刷分**
   - 限制同一 IP 提交频率
   - 人工审核异常高分
   - 记录详细日志

2. **数据验证**
   - 验证所有输入字段
   - 检查分数合理性
   - 过滤恶意内容

3. **隐私保护**
   - 邮箱设为可选
   - IP 地址仅用于防刷
   - 遵守 GDPR 等隐私法规

4. **API 保护**
   - 添加 rate limiting
   - 使用 HTTPS
   - 考虑添加验证码

---

## 📦 数据库表结构

### MongoDB 集合结构

```javascript
{
  _id: ObjectId("..."),
  cpu_model: String,
  cpu_cores: Number,
  cpu_threads: Number,
  architecture: String,        // "x86_64", "arm64", "armv7"
  coremark_score: String,
  iterations: Number,
  total_time: Number,
  compiler: String,
  compiler_flags: String,
  os_info: String,
  device_model: String,
  memory_mb: Number,
  contact: String,
  submitted_at: Date,
  ip_address: String,
  verified: Boolean,            // 是否审核通过
  verified_at: Date,
  verified_by: String,
  notes: String                 // 审核备注
}
```

### MySQL 表结构

```sql
CREATE TABLE coremark_results (
  id INT AUTO_INCREMENT PRIMARY KEY,
  cpu_model VARCHAR(255) NOT NULL,
  cpu_cores INT,
  cpu_threads INT,
  architecture VARCHAR(20) NOT NULL,
  coremark_score DECIMAL(10, 2) NOT NULL,
  iterations INT,
  total_time DECIMAL(10, 3),
  compiler VARCHAR(100),
  compiler_flags VARCHAR(500),
  os_info VARCHAR(255),
  device_model VARCHAR(255),
  memory_mb INT,
  contact VARCHAR(255),
  submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ip_address VARCHAR(45),
  verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMP NULL,
  verified_by VARCHAR(100),
  notes TEXT,
  INDEX idx_architecture (architecture),
  INDEX idx_score (coremark_score),
  INDEX idx_verified (verified)
);
```

---

## 🧪 测试 API

使用 curl 测试：

```bash
# 提交结果
curl -X POST http://localhost:3000/api/coremark/submit \
  -H "Content-Type: application/json" \
  -d '{
    "cpu_model": "Intel Core i7-10700K",
    "cpu_cores": 8,
    "architecture": "x86_64",
    "coremark_score": "28456.78",
    "os_info": "Ubuntu 22.04",
    "device_model": "自组 NAS"
  }'

# 获取排行榜
curl http://localhost:3000/api/coremark/leaderboard

# 按架构筛选
curl http://localhost:3000/api/coremark/leaderboard?arch=x86_64

# 获取统计信息
curl http://localhost:3000/api/coremark/stats
```

---

## 📝 后续改进

1. **管理后台**
   - 审核提交的结果
   - 删除异常数据
   - 查看统计报告

2. **数据可视化**
   - 分数分布图
   - 架构对比图
   - 时间趋势图

3. **社区功能**
   - 用户评论
   - 优化建议分享
   - 配置分享

---

**祝你成功！** 🚀


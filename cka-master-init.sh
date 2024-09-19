##cka-init.sh

KUBERNETES_VERSION=1.23.0-00

# 配置主机名
hostnamectl set-hostname mk8s-$(hostname)

# 关闭swap
swapoff -a

# iptables 看到 bridged 流量
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system

# 使用阿里云的源安装kubeadm
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

apt-get update

# 安装kubelet kubeadm kubectl
apt-get install -y kubelet=${KUBERNETES_VERSION} kubeadm=${KUBERNETES_VERSION} kubectl=${KUBERNETES_VERSION}

# 导入离线镜像

# k8s主要服务镜像
#gunzip -c k8s-${KUBERNETES_VERSION}.tar.gz | docker load

# calico网络插件镜像
#gunzip -c calico-v3.21.1.tar.gz | docker load

# longhorn存储插件
#gunzip -c longhorn-v1.2.2.tar.gz | docker load

# 重启 kubelet
systemctl daemon-reload
systemctl restart kubelet


# 检查 kubelet 状态
systemctl status kubelet

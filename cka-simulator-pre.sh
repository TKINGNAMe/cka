#!/bin/bash
# !!! 13题的操作 node节点需要安装nfs-common软件包，请先自行执行以下操作
# apt-get install nfs-common -y
# echo '192.168.9.98 nfs-storage' >> /etc/hosts
# 192.168.9.98为master节点的ip地址

# 以下脚本都在master节点执行
MASTER_IP=$(ip addr | grep ens33 | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}')
echo "${MASTER_IP} nfs-storage" >> /etc/hosts

# 模拟多集群上下文切换
kubectl config set-context k8s --user=kubernetes-admin --cluster=kubernetes
kubectl config set-context ek8s --user=kubernetes-admin --cluster=kubernetes
kubectl config set-context hk8s --user=kubernetes-admin --cluster=kubernetes
kubectl config set-context ok8s --user=kubernetes-admin --cluster=kubernetes
kubectl config set-context wk8s --user=kubernetes-admin --cluster=kubernetes

# 模拟多集群主机名
echo "${MASTER_IP} $(hostname)" >> /etc/hosts


# 1. 权限控制RBAC
kubectl create namespace app-team1

# 2. 设置节点不可用
# 创建两个pod
kubectl run t2-01 --image=nginx
kubectl run t2-02 --image=nginx

# 创建一个daemonset
cat <<EOF | kubectl create -f  -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: task-2-ds
  labels:
    my-ds: task-2-ds
spec:
  selector:
    matchLabels:
      nginx: task-2-ds
  template:
    metadata:
      labels:
        nginx: task-2-ds
    spec:
      containers:
      - name: nginx
        image: nginx:latest
EOF

# 创建一个使用emptydir的pod
cat <<EOF | kubectl create -f  -
apiVersion: v1
kind: Pod
metadata:
  name: task2-cache-pod
spec:
  containers:
  - image: nginx:latest
    name: task2-cache-pod
    volumeMounts:
    - mountPath: /tmp/cache-volume 
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir: {}
EOF

# 3. 升级kubeadm(无需预配)

# 4. 备份还原etcd(做模拟题时，此题一定要最后在做)
ETCD_VER=v3.5.0
#DOWNLOAD_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=https://mirrors.huaweicloud.com/etcd

# 安装etcd
rm -rf /tmp/etcd-${ETCD_VER}-linux-amd64
mkdir -p /tmp/etcd-${ETCD_VER}-linux-amd64
curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-${ETCD_VER}-linux-amd64 --strip-components=1
mv /tmp/etcd-${ETCD_VER}-linux-amd64/etcd /usr/local/bin/
mv /tmp/etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/
mv /tmp/etcd-${ETCD_VER}-linux-amd64/etcdutl /usr/local/bin/
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-${ETCD_VER}-linux-amd64
mkdir -p /opt/KUIN00601
cp /etc/kubernetes/pki/etcd/ca.crt /opt/KUIN00601/ca.crt
cp /etc/kubernetes/pki/etcd/server.crt /opt/KUIN00601/etcd-client.crt
cp /etc/kubernetes/pki/etcd/server.key /opt/KUIN00601/etcd-client.key


mkdir -p /var/lib/backup
mkdir -p /data/backup

ETCDCTL_API=3 etcdctl \
--endpoints=127.0.0.1:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key \
snapshot save /data/backup/etcd-snapshot-previous.db

# 5. 配置网络策略 NetworkPolicy
kubectl create namespace big-corp
kubectl create namespace my-app
kubectl label namespaces my-app name=my-app

# 6.创建 service
 kubectl create deployment front-end --image=nginx

# 7. 按要求创建 Ingress 资源
# 创建ingress-nginx控制器
# 官方在线
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.0/deploy/static/provider/cloud/deploy.yaml
# 官方离线
kubectl apply -f ingress-nginx/deploy.yaml

# 预配置namespace
kubectl create namespace ing-internal

# 预配置deployment
kubectl create deployment hello --image=nginx --port=80 -n ing-internal

# 预配置service
kubectl expose deployment hello --port=5678 --target-port=80 -n ing-internal --name=hello

# 8. 扩容 deployment
kubectl create deployment loadbalancer --replicas=2 --image=nginx

# 9. 调度 pod 到指定节点
kubectl label nodes `kubectl get nodes | grep  k8s-node | awk '{print $1}'` disk=ssd

# 10. 统计ready状态节点数量
mkdir -p /opt/KUSC00402/

# 11. 创建多容器的 pod(无需预配置)
# 12. 按要求创建 PV
mkdir -p  /srv/app-data

# 13. 创建和使用 PVC
# 在master节点，配置nfs server
apt-get install nfs-kernel-server -y
mkdir /nfs-server
echo '/nfs-server *(rw,sync,no_root_squash)' >> /etc/exports
chmod 700 /nfs-server/
systemctl restart nfs-kernel-server

# **node节点也需要安装nfs-common软件**
# apt-get install nfs-common

# 配置rbac
kubectl apply -f nfs-subdir-external-provisioner/deploy/rbac.yaml

# 配置部署NFS Provisioner
kubectl apply -f nfs-subdir-external-provisioner/deploy/deployment.yaml

# 配置storageclass
kubectl apply -f nfs-subdir-external-provisioner/deploy/class.yaml

# 14. 监控 pod 的日志
cat <<EOF | kubectl create -f  -
apiVersion: v1
kind: Pod
metadata:
  name: bar
spec:
  nodeName: ek8s-node2
  containers:
  - name: bar
    image: busybox
    args: [/bin/sh, -c, 'i=0; while true; do echo "$i: $(date) file-not-found";  echo "$i: $(date) File exists"; i=$((i+1)); sleep 5; done ']
EOF

mkdir -p /opt/KUTR00101

# 15. 添加 sidecar 容器并输出日志
cat <<EOF | kubectl create -f  -
apiVersion: v1
kind: Pod
metadata:
  name: legacy-app
spec:
  nodeName: ek8s-node2
  containers:
  - name: count
    image: busybox
    args:
    - /bin/sh
    - -c
    - >
      i=0;
      while true;
      do
        echo "$i: $(date)" >> /var/log/legacy-app.log;
        sleep 1;
      done
EOF

# 16. 查看 cpu 使用率最高的 pod

# 配置metrics-server
kubectl apply -f metrics-server/components.yaml
kubectl label pods --all -n kube-system name=cpu-utilizer
mkdir -p /opt/KUTR00401/
touch /opt/KUTR00401/KUTR00401.txt

# 17. 排查集群中故障节点(请使用时手工操作，无需预配置)
#systemctl stop kubelet


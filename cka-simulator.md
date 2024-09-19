# 模拟题

## 1. 权限控制RBAC

### 问题概述

1. 创建名称 deployment-clusterrole 的 ClusterRole
2. 该角色具备创建 Deployment、Statefulset、Daemonset 的权限
3. 在命名空间 app-team1 中创建名称为 cicd-token 的 ServiceAccount
4. 绑定 ClusterRole 到 ServiceAccount，且限定命名空间为 app-team1

### 参考答案

```shell
kubectl config use-context k8s
kubectl create clusterrole deployment-clusterrole --verb=create --resource=deployment,statefulset,daemonset
kubectl create serviceaccount cicd-token -n app-team1
kubectl create rolebinding cicd-clueterrole --clusterrole=deployment-clusterrole --serviceaccount=app-team1:cicd-token -n app-team1
```

## 2. 设置节点不可用

### 问题概述

1. 设置 ek8s-node-1 节点为不可用
2. 重新调度该节点上的所有 pod

### 参考答案

```shell
kubectl config use-context ek8s
kubectl cordon ek8s-node-1
kubectl drain ek8s-node-1 --delete-emptydir-data --ignore-daemonsets --force
```

## 4. 备份还原 etcd

### 问题概述

1. 备份 https://127.0.0.1:2379 上的 etcd 数据到 /var/lib/backup/etcd-snapshot.db
2. 使用之前的文件 /data/backup/etcd-snapshot-previous.db 还原 etcd
3. 使用指定的 ca.crt 、 etcd-client.crt 、etcd-client.key

### 参考答案(1)

适用于docker容器模式部署的etcd

1. 备份
```shell
etcdctl --endpoints=127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /var/lib/backup/etcd-snapshot.db
etcdctl --endpoints=127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot status /var/lib/backup/etcd-snapshot.db -w table
```

2. 还原
```shell
cd /etc/kubernetes/
mv manifests manifests.bak
cd /var/lib/
mv etcd etcd-bak
etcdctl snapshot restore /data/backup/etcd-snapshot-previous.db --data-dir=/var/lib/etcd
cd /etc/kubernetes/
mv manifests.bak/ manifests
```
3. 验证
```shell
docker ps -a | grep etcd
docker logs `docker ps -a | grep k8s_etcd  | awk '{print $1}'`
kubectl get nodes
kubectl get pods
```

### 参考答案(2)
适用于二进制模式部署的etcd，就在初始操作服务器上进行操作。

1. 备份
```shell
sudo etcdctl --endpoints=127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /var/lib/backup/etcd-snapshot.db
sudo etcdctl --endpoints=127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot status /var/lib/backup/etcd-snapshot.db -w table
```

2. 还原
```shell
sudo systemctl stop etcd
sudo mv /var/lib/etcd /var/lib/etcd-bak
sudo etcdctl snapshot restore /data/backup/etcd-snapshot.db  --data-dir=/var/lib/etcd
sudo chown -R etcd:etcd /var/lib/etcd
sudo systemctl start etcd
```

## 5. 配置网络策略 NetworkPolicy

### 问题概述

1. 在命名空间 fubar 中创建网络策略 allow-port-from-namespace
2. 只允许 ns my-app 中的 pod 连上 fubar 中 pod 的 80 端口
3. 这里有 2 个 ns ，一个为 fubar(目标pod的ns)，另外一个为 my-app(访问源pod的ns)
4. 注意考试的时候源namespace不一定有标签，需要自己加标签

### 参考答案

- `kubectl config use-context k8s`
- `kubectl get namespace my-app --show-labels`
- 可选
  `kubectl lables namespace my-app name=my-app`
- 参考 [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- vi 5.yaml

    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
    name: allow-port-from-namespace
    namespace: fubar
    spec:
    podSelector: {}
    policyTypes:
    - Ingress
    ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: my-app
      ports:
      - protocol: TCP
        port: 80
    ```
  - `kubectl apply -f 5.yaml`

## 6. 创建 service

### 问题概述

1. 重新配置已有的 deployment front-end，添加一个名称为 http 的端口，暴露80/TCP
2. 创建名称为 front-end-svc 的 service，暴露容器的 http 端口
3. 配置service 的类别为NodePort

### 参考答案

  - `kubectl config use-context k8s`
  - `kubectl edit deployments.apps front-end`
  - nginx容器下加入以下内容
    ```yaml
    ports:
      - name: web
        containerPort: 80
        protocol: TCP
    ```
  - `kubectl expose deployment front-end --port=80 --target-port=http --type=NodePort --name=front-end-svc`

  - 验证

  - `kubectl get svc -o wide`
  - `curl -kL CLUSTER-IP`

## 7. 按要求创建 Ingress 资源

### 问题概述

1. 创建一个新的 Ingress 资源，名称 ping，命名空间 ing-internal
2. 使用 /hello 路径暴露服务 hello 的 5678 端口

### 参考答案

  - `kubectl config use-context k8s`
  - 参考[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
  - vi 7.yaml
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
    name: ping
    namespace: ing-internal
    annotations:
        nginx.ingress.kubernetes.io/rewrite-target: /
    spec:
    rules:
    - http:
        paths:
        - path: /hello
        pathType: Prefix
        backend:
          service:
            name: hello
            port:
              number: 5678
    ```
  - 验证
  - `kubectl get ingresses.networking.k8s.io -n ing-internal`
  - `curl -kL IP/hello`
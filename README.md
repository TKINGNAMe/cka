## 说明

适用于cka模拟题的环境初始化配置，模拟题自行搜索

### 软件版本说明

1. 操作系统 ubuntu18.04
2. k8s版本 1.23.0
3. 节点名字要一致 分别为 master node1 node2 并且要可以互相免密登录

### 配置说明

0. 所有节点安装docker

- ` sh docker-install.sh`

1. master节点执行

- `sh cka-master-init.sh`
- `sh cka-k8s-init.sh`

  - 脚本要在压缩目录执行 calico.yaml 所在的目录

2. node节点执行

- `sh cka-node-init.sh`

  - 与master节点的第一步同步执行
- `sh cka-simulator-node.sh`

3. 初始化模拟环境(master节点)

- `sh cka-simulator-pre.sh`

4. 做模拟题

- csdn搜索

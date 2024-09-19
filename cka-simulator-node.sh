#!/bin/bash

# k8s master 节点ip
MASTER_IP=172.16.235.10

# 配置域名解析
echo "${MASTER_IP} nfs-storage" >> /etc/hosts

# 安装nfs客户端
apt-get install nfs-common -y

# 预配置
mkdir -p  /srv/app-config

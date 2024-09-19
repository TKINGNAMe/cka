#!/bin/bash

UBUNTU_VERSION=`lsb_release -cs`

# 更换阿里源
cp /etc/apt/sources.list /etc/apt/sources.list.bak

cat <<EOF > /etc/apt/sources.list
deb https://mirrors.aliyun.com/ubuntu/ ${UBUNTU_VERSION} main restricted universe multiverse
#deb-src https://mirrors.aliyun.com/ubuntu/ ${UBUNTU_VERSION} main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ ${UBUNTU_VERSION}-security main restricted universe multiverse
#deb-src https://mirrors.aliyun.com/ubuntu/ ${UBUNTU_VERSION}-security main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ ${UBUNTU_VERSION}-updates main restricted universe multiverse
#deb-src https://mirrors.aliyun.com/ubuntu/ ${UBUNTU_VERSION}-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ ${UBUNTU_VERSION}-proposed main restricted universe multiverse
#deb-src http://mirrors.aliyun.com/ubuntu/ ${UBUNTU_VERSION}-proposed main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ ${UBUNTU_VERSION}-backports main restricted universe multiverse
#deb-src https://mirrors.aliyun.com/ubuntu/ ${UBUNTU_VERSION}-backports main restricted universe multiverse

EOF

# 更新依赖仓库
apt-get update

# 安装 Docker
apt-get install docker.io -y

cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": [
    "https://docker.registry.cyou",
    "https://docker-cf.registry.cyou",
    "https://dockercf.jsdelivr.fyi",
    "https://docker.jsdelivr.fyi",
    "https://dockertest.jsdelivr.fyi",
    "https://mirror.aliyuncs.com",
    "https://dockerproxy.com",
    "https://mirror.baidubce.com",
    "https://docker.m.daocloud.io",
    "https://docker.nju.edu.cn",
    "https://docker.mirrors.sjtug.sjtu.edu.cn",
    "https://docker.mirrors.ustc.edu.cn",
    "https://mirror.iscas.ac.cn",
    "https://docker.rainbond.cc"
  ]
}
EOF

systemctl enable docker
systemctl restart docker


# 设置ts tab间隔
echo "set ts=2" >> /etc/vim/vimrc


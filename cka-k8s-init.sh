##cka-init.sh

KUBERNETES_VERSION=v1.23.0
KUBERNETES_IMAGE_REPOSITORY=registry.aliyuncs.com/google_containers

# 初始化k8s集群

#gunzip -c k8s-v1.22.4.tar.gz | docker load

info=`kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version ${KUBERNETES_VERSION} --image-repository ${KUBERNETES_IMAGE_REPOSITORY}`
join_info=`echo $info | awk -F 'root:' '{print $2}' | awk -F '\' '{print $1 $2}'`
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 添加网络插件
#gunzip -c calico-v3.21.1.tar.gz | docker load

# Install the Tigera Calico operator and custom resource definitions
# kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml

# Install Calico by creating the necessary custom resource
# kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml

# 本地执行下载网络插件
kubectl apply -f ./calico.yaml

# 查看 pods 和 nodes 状态
kubectl get pods --all-namespaces
kubectl get nodes

kubectl taint nodes $(hostname) node-role.kubernetes.io/master:NoSchedule-

# 添加共享存储插件
#gunzip -c longhorn-v1.2.2.tar.gz | docker load


# 添加tab补全功能
kubectl completion bash > ~/.kube/completion.bash.inc
printf "
# Kubectl shell completion
source '$HOME/.kube/completion.bash.inc'
" >> $HOME/.profile

kubeadm completion bash > ~/.kube/kubeadm_completion.bash.inc
printf "\n# Kubeadm shell completion\nsource '$HOME/.kube/kubeadm_completion.bash.inc'\n" >> $HOME/.profile



# 添加节点
echo $join_info
ssh node1 $join_info
ssh node2 $join_info
scp -r ~/.kube node1:
scp -r ~/.kube node2:
scp ~/.profile node1:
scp ~/.profile node2:

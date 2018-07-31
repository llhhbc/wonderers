+++
title = "kuberadm start"
description = "开源项目收集整理"
tags = [
    "kuberadm",
    "kubernetes",
]
date = "2018-04-26T10:46:49+08:00"
categories = [
    "kubernetes",
]
esid="GysjgGMB-LOJRgD48nR8"
+++
kubernetes搭建比较复杂，所以选择先用kubeadm全自动来先试试手（奈何墙有点高，所以加了些插曲）



# 通过kubeadm安装
参考 [官方文档](https://kubernetes.io/docs/setup/independent/install-kubeadm/)

#### 1. 准备环境
##### 1.1 修改hostname
* 修改  /etc/hostname

##### 1.2 关闭sellinux，关闭防火墙
* setenforce 0
* 编辑/etc/selinux/config

* firewall-cmd --state  查看状态 
* systemctl stop firewalld.service # 停止firewall 
* systemctl disable firewalld.service # 禁止firewall开机启动 

##### 1.3 关闭swap

    swapoff -a
    编辑 /etc/fstab 去掉swap配置（#号注释掉）

#### 1.4 安装crictl (可选)

    go get github.com/kubernetes-incubator/cri-tools/cmd/crictl
    GOARCH=amd64 GOOS=linux go build

#### 1.5 get docker image

* 运行kubeadm init 当提示请稍等后，检查/etc/kubernetes/manifests 目录下的yaml文件，里面会有需要的镜像和版本
* 通过hub.docker.com 中转，实现镜像的下载  具体方法请参考：[kubeadm搭建（by mritd）](https://mritd.me/2016/10/29/set-up-kubernetes-cluster-by-kubeadm/)
* 重新tag镜像(以下是我使用的，可直接pull后使用)

        docker tag llhhbc/dreba:api.1.10.0  k8s.gcr.io/kube-apiserver-amd64:v1.10.0
        docker tag llhhbc/dreba:etcd.3.1.12 k8s.gcr.io/etcd-amd64:3.1.12
        docker tag llhhbc/dreba:con.1.10.0  k8s.gcr.io/kube-controller-manager-amd64:v1.10.0
        docker tag llhhbc/dreba:sch.1.10.0  k8s.gcr.io/kube-scheduler-amd64:v1.10.0
        docker tag llhhbc/dreba:pau.3.1     k8s.gcr.io/pause-amd64:3.1
        docker tag llhhbc/dreba:proxy.1.10.0     k8s.gcr.io/kube-proxy-amd64:v1.10.0

* 打包镜像

        docker save -o kube.tgz k8s.gcr.io/etcd-amd64:3.1.12 k8s.gcr.io/kube-apiserver-amd64:v1.10.0 k8s.gcr.io/kube-controller-manager-amd64:v1.10.0 k8s.gcr.io/kube-scheduler-amd64:v1.10.0 k8s.gcr.io/pause-amd64:3.1 k8s.gcr.io/kube-proxy-amd64:v1.10.0 

* 导入镜像

        docker load -i kube.tgz

#### 1.6 安装kubeadm

        #一定要修改这个
        sed -i "s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
        
        cat <<EOF >  /etc/sysctl.d/k8s.conf
        net.bridge.bridge-nf-call-ip6tables = 1
        net.bridge.bridge-nf-call-iptables = 1
        EOF
        sysctl --system

        # 因为之前执行过 init，所以会报有些已经存在，可以先 kubeadm reset 重置
        kubeadm init --pod-network-cidr=10.244.0.0/16

* 配置kubecfg， 不然kubectl会提示 localhost:8080 连接不上

        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

<!-- #### 1.7 安装fannel

    docker tag llhhbc/dreba:fan.0.9.1 quay.io/coreos/flannel:v0.9.1-amd64
    docker save -o fan.tgz quay.io/coreos/flannel:v0.9.1-amd64
    docker load -i fan.tgz

    wget https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
    kubectl apply -f kube-fannel.yaml -->
#### 1.7 安装calio

        docker tag llhhbc/dreba:cal.etcd.3.1.10 quay.io/coreos/etcd:v3.1.10
        docker tag llhhbc/dreba:cal.nod.3.0.4   quay.io/calico/node:v3.0.4
        docker tag llhhbc/dreba:cal.cni.2.0.3   quay.io/calico/cni:v2.0.3
        docker tag llhhbc/dreba:cal.kub.2.0.2   quay.io/calico/kube-controllers:v2.0.2
        docker save -o cal.tgz quay.io/coreos/etcd:v3.1.10 quay.io/calico/node:v3.0.4 quay.io/calico/cni:v2.0.3 quay.io/calico/kube-controllers:v2.0.2

        docker load -i cal.tgz

        kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml


#### 1.8 dns

    docker tag llhhbc/dreba:dns.1.14.8 k8s.gcr.io/k8s-dns-kube-dns-amd64:1.14.8
    docker tag llhhbc/dreba:dns.masq.1.14.8 k8s.gcr.io/k8s-dns-dnsmasq-nanny-amd64:1.14.8
    docker tag llhhbc/dreba:dns.side.1.14.8 k8s.gcr.io/k8s-dns-sidecar-amd64:1.14.8

    docker save -o dns.tgz k8s.gcr.io/k8s-dns-kube-dns-amd64:1.14.8 k8s.gcr.io/k8s-dns-dnsmasq-nanny-amd64:1.14.8 k8s.gcr.io/k8s-dns-sidecar-amd64:1.14.8

    docker load -i dns.tgz

#### 1.9 安装检查
* 切换命名空间

        kubectl config use-context default

        kubectl config set-context $(kubectl config current-context) --namespace=kube-system
        kubectl config view | grep namespace:

#### 2.0 安装完成
真心不容易
            
            kubectl get pods  #能看到所有进程都正常

#### 2.1 安装node
* 前5步都一样  （记住，主机名一定不能有冲突）
* 第6步改为 kubectl join  (init成功后提示的命令)

    --ignore-preflight-errors=all  #加上这个，因为crictl会找/var/run/dockershim.sock文件，而这个文件只有当kubelet启动后，才会有

#### 3.1 检查集群

    kubectl get nodes
    kubectl get pods
    kubectl get cs


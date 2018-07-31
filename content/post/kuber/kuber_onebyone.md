
+++
title = "kuber手工搭建"
description = "kuber手工搭建"
tags = [
    "kubernetes"
]
date = "2018-04-26T20:46:49+08:00"
categories = [
    "kubernetes",
]
+++

1. 准备工作
* 关闭selunix
* 关闭swap
* 作为node的结点，要安装docker（包括master和node共用的）

```sh
  wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-18.06.0.ce-3.el7.x86_64.rpm
  yum install docker-ce-18.06.0.ce-3.el7.x86_64.rpm
```

1. 设置主机名
> sh etc/set_hosts.sh

1. 安装etcd
> sh rpms/install_etcd.sh

1. 安装etcd证书
> sh keys/etcd/install_etc_key.sh

1. 修改etcd配置
> sh etc/set_etcd.sh

1. 启动etcd
> sh run/start_etcd.sh

1. 安装kube 程序
> sh rpms/install_kuber.sh

1. 安装kuber证书
> sh keys/k8s/install_k8s_key.sh

1. 修改kuber配置
> #设置master结点
> sh etc/kube_cfg/set_kuber_cfg.sh
> #设置node结点
> sh etc/kube_cfg/set_kuber_node_cfg.sh
> #如果master也作为node结点，则运行
> sh etc/kube_cfg/set_kuber_master_node_cfg.sh

1. 启动kube
> sh run/start_kube.sh
> #在任意一台master上执行：  开启认证
> kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
> #如果master上要启动作为node，则
> sh run/start_kube_master_node.sh

### 注意事项
1. 更新证书
> #当生成的证书中ip少加了，需要更新证书时，修改 keys/k8s/kubernetes-csr.json后，重新执行如下：
> sh keys/k8s/install_k8s_key.sh
> sh etc/kube_cfg/set_kuber_cfg.sh
> sh etc/kube_cfg/set_kuber_node_cfg.sh
> #由于证书变更了，所以需要重新授权认证（在任意一个master上执行）
> kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
> kubectl get csr   #检查需要同意证书下发的
> kubectl certificate approve 结点名   #信任结点
> kubectl describe csr  #可查看谁发起的请求     当认证长时间未同意，会再次发起，这个时候可能就有两条

1. api说明
> #kube master 部署后，访问kube-apiserver：http://api服务地址和端口/swagger-ui/ 可查看接口说明
> https://kubernetes.io/docs/reference/  #kube官网同样有说明
> https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/#clusterrole-v1-rbac-authorization-k8s-io




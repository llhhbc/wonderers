+++
title = "kube问题汇总"
description = "kuber部署问题汇总"
tags = [
    "kubernetes",
]
date = "2018-04-26T10:46:49+08:00"
categories = [
    "kubernetes",
]
esid="GisjgGMB-LOJRgD48nQe"
+++

1. 虚拟机建议用virutalbox

	当时istio的bookinfo无法部署： reviews-v2-7bdf9b96b6-khg7s   老是会报错，提示无法创建目录，没权限，后来查是虚拟机sandbox版本太低，导致的一个bug，文件无法删除也无法修改

1. virtualbox建议用nat 网络的方式，自己添加一个网卡，作为虚拟机集群的网络

    然后每个主机在加一个hostonly的网卡，用于主机访问虚拟机

1. 硬盘没空间：

	突然发现pod状态变成了：Evicted，还有挂起的，然后  通过 kubelet describe命令查看，发现是node空间满了，无法部署了：我看空间用了80%


1. 时间不同步：

	时间不同步时，会出现
Unable to authenticate the request due to an error: x509: certificate has expired or is not yet valid
我同步机器时间后，问题解决。。。


1. token不一致：

	配置文件bootstrap.kubeconfig中token不一致，会导致这个错
	failed to run Kubelet: cannot create certificate signing request: Unauthorized


+++
title = "kbuernetes 学习"
description = ""
tags = [
    "kubernetes",
]
date = "2018-04-27T09:01:00+08:00"
categories = [
    "kubernetes",
]
esid="HCsjgGMB-LOJRgD48nT7"
+++
## Kubernetes基本概念
### Pod
Pod是一组容器集合，他们共享IPC、Network 和 UTC namespace
例：
```yarm
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```

### Node
运行pod的主机

### Namespace
管理一组资源和对象

### Service
应用服务的抽象，通过labels为应用提供负载均衡和服务发现。匹配labels为Pod IP和端口列表组成endpoints，由kube-proxy负责将服务IP负载均衡到这些endpoints上。
每个Service都会自动分配一个culster IP（仅在集群内部可访问的虚拟地址）和DNS名，其它容器可以通过该地址或DNS来访问服务
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  ports:
  - port: 8078
    name: http
    targetPort: 80
    protocol: TCP
  selector:
    app: nginx
```

### Label
是识别Kurbernetes对象的标签，以key/value的方式附加到对象上。Label不提供唯一性，经常是很多对象（如Pods）都使用相同的label来标志具体的应用（如负载均衡时结点为的选择）
label选择支持如下模式：
* 等式： app=nginx 或 env!= production
* 集合:  env in (production, qa)
* 多个label（他们之间是AND的关系）： app=nginx,env=test

### Annotations
是ken/value形式附加于对象的注解

## 基本命令
1. kubectl get 类似于 docker ps
1. kubectl describe 类似于 docker inspect
1. kubectl logs  类似于 docker logs
1. kubeclt edec 类似于 docker exec


## 初体验
1. 使用yaml定义pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```



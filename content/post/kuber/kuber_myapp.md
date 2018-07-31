
+++
title = "kuber应用搭建"
description = "dreammap搭建"
tags = [
    "dreammap",
    "kubernetes",
]
date = "2018-07-29T16:46:49+08:00"
categories = [
    "kubernetes",
]
+++

## dreammap搭建

### 1. 应用打包docker容器

#### 1.1 前端界面

* dockerfile 

```Dockerfile
from nginx:1.15.2-alpine

COPY wonder-dream /usr/share/nginx/html

EXPOSE 80
```

* build.sh

```sh
function build(){
    cp -rp ../dist/wonder-dream .

    docker rmi wonderdream:v0.0.1
    docker build -t wonderdream:v0.0.1 .
}

function run(){
    docker run -itd -p 8091:80 wonderdream:v0.0.1
}

function tar(){
    docker save -o wonder_ng.tgz wonderdream:v0.0.1
}

$1
```

* kuber部署yaml，这里就用service实现了访问，没有做单独的ingress

```yaml
apiVersion: v1
kind: Service
metadata:
    name: wonderng
    labels:
      app: wonderng
spec:
    type: LoadBalancer
    ports:
    - port: 80
      name: http
    selector:
      app: wonderng
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
    name: wonderdream-v0.0.1
spec:
    replicas: 1
    template:
        metadata:
            labels:
                app: wonderng
                version: v0.0.1
        spec:
            containers:
            - name: wonderdream
              image: wonderdream:v0.0.1
              imagePullPolicy: IfNotPresent
              ports:
              - containerPort: 80
```

* 部署

```sh
docker load -i wonder_ng.tgz   #导入images
kubectl create -f wonder_ng.yaml  #部署
kubectl get pods #查看部署情况
kubectl get svc  #查看服务情况
```


* 测试应用 

```sh
curl masster-ip:服务ip
```


#### 2.1 部署后台



+++
title = "traefik服务搭建"
description = "traefik服务搭建"
tags = [
    "traefik",
    "kubernetes",
]
date = "2018-07-29T16:46:49+08:00"
categories = [
    "kubernetes",
]
+++

## Traefik服务使用

  尽管svc有了负载均衡功能，可以简单通过LoadBalance来实现，但功能相对简单，而且有多个服务的时候，不好统一管理，而traefik是一个反向代理，可以像nginx一样配置相应的服务代理功能，并增加了检查服务是否可用、pod状态等功能，动态的更新配置

### 1.Traefik的部署

> 参考官方文档：https://docs.traefik.io/user-guide/kubernetes/

* 创建角色：因为traefik需要访问kuber来获取服务等的状态信息

```yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller
rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-ingress-controller
subjects:
- kind: ServiceAccount
  name: traefik-ingress-controller
  namespace: default
```

* 创建服务
traefik本身也是一种服务，和其它服务一样，80是工作端口（服务分发），8080是ui端口，可查看当前情况

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik-ingress-controller
  namespace: default
---
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: traefik-ingress-controller
  namespace: default
  labels:
    k8s-app: traefik-ingress-lb
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: traefik-ingress-lb
  template:
    metadata:
      labels:
        k8s-app: traefik-ingress-lb
        name: traefik-ingress-lb
    spec:
      serviceAccountName: traefik-ingress-controller
      terminationGracePeriodSeconds: 60
      containers:
      - image: traefik:v1.7.0-rc2-alpine
        name: traefik-ingress-lb
        ports:
        - name: http
          containerPort: 80
        - name: admin
          containerPort: 8080
        args:
        - --api
        - --kubernetes
        - --logLevel=INFO
---
kind: Service
apiVersion: v1
metadata:
  name: traefik-ingress-service
  namespace: default
spec:
  selector:
    k8s-app: traefik-ingress-lb
  ports:
    - protocol: TCP
      port: 80
      name: web
    - protocol: TCP
      port: 8080
      name: admin
  type: NodePort
  ```

* 增加代理配置（ingress配置）

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: wonderng
  ## 命名空间要和traefik一样，否则无法正常工作 
  namespace: default
  annotations:
    traefik.ingress.kubernetes.io/preserve-host: "true"
spec:
  rules:
  - host: a.wonder
    http:
      paths:
      - path: /
        backend:
          serviceName: wonderng
          servicePort: 80
```

### 2.测试

> 通过 `kubectl get svc` 可查看traefik 80、8080端口对应的对外端口，访问8080对应的对外端口，可看到图形说明界面
> 通过 `curl a.wonder:80` 可访问应用，测试功能


* 多服务功能测试

```yaml
#wonder_ingress1.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: wonderng
  namespace: default
spec:
  rules:
  - host: a.wonder
    http:
      paths:
      - path: /
        backend:
          serviceName: wonderng
          servicePort: 80
          serviceName: wonderng1
          servicePort: 80
```
```sh
kubectl replace -f wonder_ingress1.yaml

#重新通过ui查看traefik，发现没有任何变化，因为它跟踪的是pod，而不是svc

kubectl get pods -o wide  #可查看容器的ip，我里面配置的两个服务，我删除其中任意一个，都不影响访问

```




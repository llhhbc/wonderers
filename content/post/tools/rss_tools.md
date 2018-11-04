+++
title = "rss tools"
description = "rss tools"
tags = [
    "rss"
]
date = "2018-08-04T20:01:00+08:00"
categories = [
    "rss",
]
+++

### rss 开源服务搭建，基于kuber+coredns+traefik

#### 1.下载镜像

```sh
docker pull miniflux/miniflux:2.0.10
docker pull postgres:11-alpine
```

#### 2.部署pg

##### 1. 创建本地存储

  ```yaml
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: local-pv-1
    labels:
      type: local
  spec:
    capacity:
      storage: 10Gi
    accessModes:
      - ReadWriteOnce
    hostPath:
      path: /data/pv/1
  ```

##### 2. 创建存储使用申明
* pvc到pv的绑定是，自动完成的，并且绑定后就是一对一的绑定，不会再改变。绑定考虑的是空间大小，如果没有合适的，会挂起，直到有合适的存储。`kubectl  get pvc` 能看到具体的绑定情况
* pvc的大小可以比pv小，用来实现存储大小的控制

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pg-pv-claim
  labels:
    app: postgres
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

##### 3. 创建应用

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: pg-11
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: pg-11
    spec:
      containers:
      - name: pg
        image: postgres:11-alpine
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          value: wonder
          # 虽然pgdata目录没变，但要设置，目的是为了触发initdb调用
          name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: pg-pv-storage
          mountPath: /var/lib/postgresql/data/pgdata
      volumes:
      - name: pg-pv-storage
        persistentVolumeClaim:
          claimName: pg-pv-claim
```

##### 4. 创建数据库

```sh

#docker exec -it ...  sh  登录到pg上

psql -U postgres -W  #连接数据库

create user miniflux password 'miniflux';
ALTER USER miniflux WITH SUPERUSER;   ##因为要创建hstore
CREATE database miniflux owner = "miniflux" encoding = 'UTF8' TABLESPACE = "pg_default";

# ok 数据库初始化完成
```

##### 5. 创建数据库服务

```yaml
apiVersion: v1
kind: Service
metadata:
  name: pgsvr
  labels:
    app: pg-11
spec:
  ports:
    - port: 5432
  selector:
    app: pg-11
  clusterIP: None
```

#### 3. 部署miniflux

##### 1. 部署应用
  miniflux文档：https://docs.miniflux.app/en/latest/configuration.html

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: miniflux
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: miniflux-2.0.10
    spec:
      containers:
      - name: pg
        image: miniflux/miniflux:2.0.10
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          value: postgres://miniflux:miniflux@pgsvr/miniflux?sslmode=disable
```

##### 2. 创建表

```sh
#docker exec -it ... sh  #登录到minifluk对应的容器上

#创建需要的表和基础数据
/usr/local/bin/miniflux -migrate

#创建用户
/usr/local/bin/miniflux -create-admin


```

##### 3. 部署服务

```yaml
apiVersion: v1
kind: Service
metadata:
  name: minifluxsvr
  labels:
    app: minifluxsvr
spec:
  ports:
    - port: 8080
  selector:
    app: miniflux-2.0.10
```

##### 4. 配置traefik代理

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: miniflux
spec:
  rules:
  - host: miniflux.wonder
    http:
      paths:
      - path: /
        backend:
          serviceName: minifluxsvr
          servicePort: 8080
```
如果配置有误，会在traefik界面中显示，并在对应pod的日志中能看到具体的错误

#### 4. 总结

  * 存储通过pvc管理，和系统的lvg管理很像，之后扩展也会很方便，增加pvc就可以了
  * ingress中，代理的目录path，如果设置的/a，会传递到对应的pod中，这个是我目前觉得不太灵活的地方，nginx是可以转换上下文的，而这里我暂时还没找到办法。所以我的想法就是nginx在最外层来做上下文、域名的转换。这里面还是用域名来分开，内部域名是够用的。miniflux能定制化访问前缀，只需要添加环境变更：BASE_URL就可以了
  * 通过coredns，容器访问服务是非常方便的，通过服务名就可以访问，解决了ip的问题，越来越想分析kuber的源代码了，不过现在还不是时候，我还只见树木，现在进去会迷失的




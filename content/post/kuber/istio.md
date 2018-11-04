
+++
title = "istio初尝试"
description = "istio初尝试"
tags = [
    "kubernetes",
    "istio"
]
date = "2018-04-26T20:46:49+08:00"
categories = [
    "kubernetes",
]
+++


### 说明
> 参考 http://istio.doczh.cn/

### 安装istio
> kubectl apply -f install/kubernetes/istio.yaml
> #如果出现 unable to recognize "install/kubernetes/istio.yaml" 的错误，删除后再重新执行一遍就好了

### 部署bookinfo

```sh
    kubectl apply -f <(istioctl kube-inject -f bookinfo.yaml)

    #获取访问地址
    export GATEWAY_URL=$(kubectl get po -l istio=ingress -n istio-system -o 'jsonpath={.items[0].status.hostIP}'):$(kubectl get svc istio-ingress -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}')
    
    #测试地址访问
    curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
```

#### 1.1 验证路由访问

```sh
    #所有用户都访问v1
    istioctl create -f route-rule-all-v1.yaml
    #jason用户登录访问v2
    istioctl create -f route-rule-reviews-test-v2.yaml
```
#### 1.2 记录日志

```yaml
    ##保存如下信息为 new_telemetry.yaml
    # Configuration for metric instances
    apiVersion: "config.istio.io/v1alpha2"
    kind: metric
    metadata:
      name: doublerequestcount
      namespace: istio-system
    spec:
      value: "2" # count each request twice
      dimensions:
        source: source.service | "unknown"
        destination: destination.service | "unknown"
        message: '"twice the fun!"'
      monitored_resource_type: '"UNSPECIFIED"'
    ---
    # Configuration for a Prometheus handler
    apiVersion: "config.istio.io/v1alpha2"
    kind: prometheus
    metadata:
      name: doublehandler
      namespace: istio-system
    spec:
      metrics:
      - name: double_request_count # Prometheus metric name
        instance_name: doublerequestcount.metric.istio-system # Mixer instance name (fully-qualified)
        kind: COUNTER
        label_names:
        - source
        - destination
        - message
    ---
    # Rule to send metric instances to a Prometheus handler
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: doubleprom
      namespace: istio-system
    spec:
      actions:
      - handler: doublehandler.prometheus
        instances:
        - doublerequestcount.metric
    ---
    # Configuration for logentry instances
    apiVersion: "config.istio.io/v1alpha2"
    kind: logentry
    metadata:
      name: newlog
      namespace: istio-system
    spec:
      severity: '"warning"'
      timestamp: request.time
      variables:
        source: source.labels["app"] | source.service | "unknown"
        user: source.user | "unknown"
        destination: destination.labels["app"] | destination.service | "unknown"
        responseCode: response.code | 0
        responseSize: response.size | 0
        latency: response.duration | "0ms"
      monitored_resource_type: '"UNSPECIFIED"'
    ---
    # Configuration for a stdio handler
    apiVersion: "config.istio.io/v1alpha2"
    kind: stdio
    metadata:
      name: newhandler
      namespace: istio-system
    spec:
     severity_levels:
       warning: 1 # Params.Level.WARNING
     outputAsJson: true
    ---
    # Rule to send logentry instances to a stdio handler
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: newlogstdio
      namespace: istio-system
    spec:
      match: "true" # match for all requests
      actions:
       - handler: newhandler.stdio
         instances:
         - newlog.logentry
    ---

    istioctl create -f new_telemetry.yaml
```
    
#### 1.3 安装grafana  可视化状态
* 记得先更新系统时间，查询信息是根据时间来看的，否则会因为时间不对而看不到数据

```sh
#修改时区
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#更新时间
ntpdate cn.pool.ntp.org

kubectl apply -f prometheus.yaml
kubectl apply -f grafana.yaml

#设置访问代理端口
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &

### 由于grafana没有做端口映射，所以不能像bookinfo那样直接访问
kubectl get svc    #可看出来区别

##但是这样好伤，端口是监听在127.0.0.1的，要么用ssh代理，要么就只能本地访问了
##所以我试着改下grafana.yaml，加一个端口映射
  2 apiVersion: v1
  3 kind: Service
  4 metadata:
  5   name: grafana
  6   namespace: istio-system
  7 spec:
  8   type: LoadBalancer     ####添加这一行
  9   ports:
 10   - port: 3000
 11     protocol: TCP
 12     name: http
 13   selector:
 14     app: grafana
##重新建立grafana后，发现有端口映射了
export GRAFA_URL=$(kubectl get po -l app=grafana -o 'jsoitems[0].status.hostIP}'):$(kubectl get svc grafana -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}')
```



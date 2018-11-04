
+++
title = "kbuernetes docs 学习"
description = ""
tags = [
    "kubernetes",
]
date = "2018-08-23T19:01:00+08:00"
categories = [
    "kubernetes",
]
+++


## kubernetes docs 学习

 * 参考 http://docs.kubernetes.org.cn/251.html
 * 对应源地址 https://kubernetes.feisky.xyz/zh/ 

### kubernetes架构
* etcd 保存整个集群的状态
* apiserver 提供资源操作的唯一入口，并提供认证、授权、访问控制、api注册和发现等机制
* controller manager负责维护集群的状态，比如故障检测、自动扩展、滚动更新等
* scheduler负责资源的调度，按照预定的调度策略将pod调度到相应的机器上
* kubelet 负责维护容器的生命周期，同时也负责volume（cvi）和网络（cni）的管理
* container runtime负责镜像管理以及pod和容器的真正运行（cri）
* kube-proxy 负责为service提供cluster内部的服务发现和负载均衡

除了这些核心组件，还有些扩展的add-ons：
* kube-dns负责为整个集群提供dns服务
* ingress controller为服务提供外网入口
* heapster提供资源监控
* dashboard提供gui
* fedreation提供跨可用区的集群
* fluentd-elasticsearch提供集群日志采集、存储与查询

#### kuber分层架构
* 核心层：kubernetes最核心的功能，对外提供api构建高层的应用，对内提供插件式应用执行环境
* 应用层：部署（无状态应用、有状态应用、批处理任务、集群应用等）和路由（服务发现、dns解析等）
* 管理层：系统度量（如基础设置、容器和网络的度量），自动化（如自动扩展、动态Provision等）以及策略管理（RBAC，quota，psp，networkpolicy等）
* 接口层：kubectl命令行工具、客户端sdk以及集群联邦
* 生态系统：在接口层之上的庞大容器集群管理调度的生态系统，可以划分两个
	* kubernetes外部：日志、监控、配置管理、ci,cd,workflow,faas,ots应用,chatops
	* kubernetes内部：cri,cni,cvi,镜像仓库，cloud provider,集群自身的配置和管理等


#### kubernetse的设计理念

##### api设计原则
1. 所有api应该是声明式的（比如设置副本数为3，运行多次也没问题，而给副本数加1，运行多次就不对了）
1. api对象是彼此互补而且可以组合的
1. 高层api以操作意图为基础设计（从业务出发，而不是过早的从技术实现出发）
1. 低层api根据高层api的控制需要设计（以需求为基础，尽量抵抗受技术实现影响的诱惑）
1. 尽量避免简单封装，不要有在外部api无法显式知道的内部隐藏的机制（简单的封装实际没有提供新功能，反而增加对所封装api的依赖性。内部隐藏的机制不利于系统维护的设计方式）
1. api操作复杂试与对象数量成正比
1. api对象状态不能依赖于网络连接状态（对象状态能应对网络不稳定）
1. 尽量避免让操作机制依赖于全局状态，因为在分布式系统中要保证全局状态的同步是非常困难

##### 控制机制设计原则
1. 控制逻辑应该只依赖于当前状态
1. 假设任何错误的可能，并做差错处理
1. 尽量避免复杂状态机，控制逻辑不要依赖无法监控的内部状态
1. 假设任何操作都可能被任何操作对象拒绝，甚至被错误解析（保证出现错误的时候，操作级别的错误不会影响到系统稳定性）
1. 每个模块都可以在出错后自动恢复
1. 每个模块都可以在必要时优雅的降级服务（划分清楚基本功能和高级功能，保证基本功能不会依赖高级功能，这样就保证了不会因为高级功能出现故障而导致整个模块崩溃）


#### kuber api对象
1. pod
pod内的容器共享网络和文件系统，可以通过进程间通信和文件共享这种简单高效的方式组合完成服务。比如，一个nginx容器用来发布软件，另一个容器专门用来从源仓库做同步
* pod是所有业务类型的基础，k8s中业务主要分四类：
	1. Deployment：长期伺服型（long-runing）
	1. Job：批处理型（batch）
	1. DaemonSet：节点后台支撑型（node-daemon）
	1. PetSet：有状态应用型（stateful application）

* pod特征：
	1. 共享ipc、network、utc namespace的容器
	1. 所有pod内容器都可以访问共享的Volume，可以访问共享数据
	1. pod一旦调度后就和node绑定，即使node挂掉也不会重新调度，推荐使用deployments、daemonsets等控制器来容错
	1. 优雅终止：pod删除的时候，先给其内的进程发送sigterm，等待一段时间（graceperiod）后才强制停止依然还在运行的进程
	1. 特权容器（通过SecurityContext配置）具有改变系统配置的权限（在网络插件中大量应用）

1. 复制控制器（Replication Controller，RC）
RC是k8s集群中最早的保证pod高可用的api对象，监控运行中的pod来保证集群中运行指定数目的pod副本。只适用于长期伺服型的业务类型

1. 副本集（Replica Set，RS）
RS是新一代RC，提供同样的高可用能力，区别是能支持更多各类的匹配模式

1. 部署（Deployment）
部署表示用户对k8s集群的一次更新操作。可以是创建一个新服务、更新一个新服务、滚动升级一个服务。滚动升级一个服务，实际是创建一个新的RS，然后逐渐将新RS中的副本数增加到理想状态，再将旧的RS中副本数减小为0。
deployment为pod和rs提供声明式更新。只需要在deployment中描述你想要的目的状态是什么，deployment controller就会帮你将pod和rs的实际状态改变到你的目标状态。

1. 服务（Service）
RC、RS和Deployment只保证了支持服务的pod的数量，而对外提供服务的是service。每个service对应一个集群内部的有效的虚拟ip，集群中的微服务的负载均衡是由kuber-proxy实现的，是一个分布式的代理服务器，每个节点上都有一个
kuberntest的负载均衡大致分为以下几种：
	* Service：直接用service提供cluster内部负载均衡，并借助cloud provider提供的LB提供外部访问
	* Ingress Controller：还是用service和cluster内部负载均衡，但通过自定义的LB提供外部访问
	* Service LoadBalancer：把load balancer直接跑在容器中，实现bare metal的service LoadBalancer
	* Custom LoadBalancer：自定义负载均衡，并替代kube-proxy
service有四种类型：
	* ClusterIP：默认类型，自动分配一个仅cluster内部可以访问的虚拟IP
	* NodePort：在clusterIP基础上为service在每台机器上绑定一个端口，这样就可以通过NodeIP:NodePort来访问服务
	* LoadBalancer：在NodePort的基础上，借助cloud provider创建一个外部的负载均衡器，并将请求转发到NodeIP:NodePort
	* ExternalName：将服务通过NDS CNAME记录方式转发到指定的域名（通过spec.externlName设定）。需要kube-dns版本在1.7以上
各种类型的service对源ip的处理方法不同：
	* clusterIP service：使用iptables模式，集群内部的源ip会保留（不做snat）。如果client和server pod在同一个node上，则源ip就是client pod的ip，如果在不同的node上，则源ip取决于网络插件处理方式。
	* NodePort Service：源ip会做snat，server pod看到的源ip是node ip。可以给service加上annotation：service.beta.kubernetes.io/external-traffic=OnlyLocal，让service只代理本地endpoint的请求，从而保留源ip
	* LoadBalancer Service：源ip会做snat，server pod看到的源ip是node ip


1. 任务（job）
job是用来控制批处理型任务的api对象，job管理的pod根据用户的设置，把任务成功完成就自动退出。完成标志根据不同的spec.completions策略而不同：
	* 单pod型任务有一个pod成功就标志完成
	* 定数成功型任务保证有N个任务全部成功
	* 工作队列型任务根据应用确认的全局成功而标志成功
kubernetes支持几种Job：
	* 非并行Job：通常创建一个Pod直到其成功结束
	* 固定结束次数的Job：设置 .spec.completions ，创建多个Pod，直到 .spec.completions 个Pod成功结束
	* 带有工作队列的并行Job：设置 .spec.Parallelism 但不设置 .spec.completions，当所有Pod结束并且至少一个成功时，Job就认为是成功的



1. 后台支撑服务集（DaemonSet）
后台支撑服务的核心关注点是集群中的节点，保证每个节点都有一个此类pod运行，节点可能是所有集群节点，也可能是通过nodeSelector选定的一些特定节点。典型的后台支持型服务包括：存储、日志和监控等在每个节点上支持k8s集群运行的服务
指定node的选择方式：
	* nodeSelector：只调度到匹配指定label的node上：` kubectl label nodes node-01 disktype=ssd` 给node打个标签：disktype=ssd
	* nodeAffinity：功能更丰富的Node选择器
		* requiredDuringSchedulingIgnoredDuringExecution：必需满足条件

		```yaml
		requiredDuringSchedulingIgnoredDuringExecution:
		  nodeSelectorTerms:
		  - matchExpressions:
		    - key: kubernetes.io/e2e-az-name
		      operator: In
		      values:
		      - e2e-az1
		      - e2e-az2

		```
		* preferredDuringSchedulingIgnoredDuringExecution: 优选条件

		```yaml
		preferredDuringSchedulingIgnoredDuringExecution:
		- weight: 1
		  preference:
		    matchExpressions:
		    - key: another-node-label-key
		      operator: In
		      values:
		      - another-node-label-value

		```

	* podAffinity：调度到满足条件的pod所在的Node上


1. 有状态服务集（PetSet）
k8s在1.3版本中增加了PetSet功能。
	* RC和RS主要是控制提供无状态服务的，所控制的pod名字是随机的，一个pod出故障，在另一个地方重启，名字变了和启动在哪都不重要，重要的只是pod的总数。而PetSet中，每个Pod的名字都是事先确定的，不能更改。
	* RC和RS中的pod，一般不挂载存储（无人性特征，所有pod都一样），而PetSet中的pod，都挂载自己独立的存储，如果一个pod出现故障，在其他节点启动一个同名的pod，要挂载上原来pod的存储继续以它的状态提供服务
	* 适合PetSet的业务：数据库类型的服务mysql和pgsql，集群化管理服务zookeeper、etcd等有状态服务

1. 集群联邦（Federation）
1.3中增加。
云计算环境中，服务使用距离范围从近到远有：同主机、跨主机同可用区、跨可用区同地区、跨地区同服务商、跨云平台。k8s设计定位是单一集群在同一个地域内，因为同一地区的网络性能才能满足k8s调度和计算存储连接要求。联合集群服务就是为了提供跨地区（region）跨服务商k8s集群服务而设计的
每个k8s Federation有自己的分布式存储、api server和controller manager。

1. 存储卷（Volume）
k8s的存储卷生命同期和作用范围是一个pod（只有pod删除时，volume才会清理，emptyDir类型的存储就会丢失），每个pod中声明的存储卷由pod中所有容器共享。
Volume生命周期：
	1. Provisioning：即pv的创建
	1. Binding：将PV分配给PVC
	1. Using：pod通过pvc使用该Volume
	1. Releasing：pod释放volume并删除pvc
	1. Reclaiming：回收pv，可以保留pv以便下次使用，也可以直接删除
pv的访问模式（accessModes）有三种：
	* ReadWriteOnce（RWO）：最基本的方式，可读可写，但只支持被单个pod挂载
	* ReadOnlyMany（ROX）：以只读方式被多个pod挂载
	* ReadWriteMany（RWX）：以读写方式被多个pod共享。不是每一种存储都支持这三种，rwx支持的还比较少，比较常用的是nfs。pvc绑定pv时，通常根据两个条件来绑定：一个是存储的大小，一个是访问模式
pv的回收策略（persistentVolumeReclaimPolicy)：
	* Retain：不清理Volume（需要手动清理）
	* Recycle：删除数据（只有nfs和hostpath支持）
	* Delete：删除存储资源（只有aws ebs,gce pd,azure disk,cinder支持）

1. 持久存储卷（Persistent Volume，PV）和持久存储卷声明（Persistent Volume Claim，PVC）
pv是资源的提供者，pvc是资源的使用者，根据业务服务的需求变化而变化。

* 两个容器通过subPath来共用pvc
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-site
spec:
    containers:
    - name: mysql
      image: mysql
      volumeMounts:
      - mountPath: /var/lib/mysql
        name: site-data
        subPath: mysql
    - name: php
      image: php
      volumeMounts:
      - mountPath: /var/www/html
        name: site-data
        subPath: html
    volumes:
    - name: site-data
      persistentVolumeClaim:
        claimName: my-site-data
```



1. 节点（Node）
Node是pod运行所在的工作主机，可以是物理机也可以是虚拟机。上面运行kubelet管理节点上运行的容器。
k8s只是管理node上的资源。
node的检查是通过node controller来完成的。node controller负责：
	* 维护node状态
	* 与cloud Provider同步node
	* 给node分配容器cidr
	* 删除带有NoExecute taint的node上的pod
默认情况下，kubelet在启动时，会向master注册自己，并创建node资源
每个Node都有如下状态：
	* 地址：包括hostname、外网ip和内网ip
	* 条件（Condition）：包括OutOfDisk,Ready,MemoryPressure,DiskPressure
	* 容量（Capacity）：Node上可用资源，包括cpu和内存和pod总数
	* 基本信息（Info）：包括内格版本、容器引擎版本、os类型等
Taints和tolerations用于保证pod不被调度到不合适的node上，taint应用于node上，toleration则应用于pod上。
可用taint给node加taints：

```sh
kubectl taint nodes node1 key1=value1:NoSchedule
##node 维护模式(不可调度，但不影响其上正在运行的pod)
kubectl cordon $NODENAME
```

1. 密钥对象（Secret）
用来保存和传递密码、密钥、认证凭证这些敏感信息的对象。
secret有三种类型：
	* service account：用来访问kuberntest API，由kubernetest自动创建，并会自动挂载到Pod的/run/secretes/kubernetes.io/serviceaccount目录中（每个容器的这个目录下可看到）
	* opaque：base64编码格式的secret，用来存储密码、密钥等
	* kubernetes.io/dockerconfigjson：用来存储私有docker registry的认证信息


1. 用户账户（User Account）和服务帐户（Service Account）
用户帐户为人提供帐户服务，而服务账户为用什么进程和pod提供帐户标识。用户账户是跨namespaces的，而服务帐户与特定的namespaces是相关的。每个namespace都会自动创建一个default service account。Token controller检测service account的创建，并为它们创建secret。
开启Service Account Admission Controller后：
	* 每个Pod在创建后，都会自动设置 spec.serviceAccount 为default
	* 验证Pod引用的service account 已经存在，否则拒绝创建
	* 如果Pod没有指定ImagePullSecrets，则把service account 的ImagePullSecrets加到Pod中
	* 每个container启动后都会挂载该service account的token和ca.crt到 /run/secretes/kubernetes.io/serviceaccount

```sh
#创建service account
kubectl create serviceaccount myacct
kubectl get serviceaccount myacct -o yaml

#查看自动创建的secret
kubectl get secret myacct-token-l9v7v -o yaml

```

创建角色并授权
```yaml
# This role allows to read pods in the namespace "default"
kind: Role
apiVersion: rbac.authorization.k8s.io/v1alpha1
metadata:
  namespace: default
  name: pod-reader
rules:
  - apiGroups: [""] # The API group"" indicates the core API Group.
    resources: ["pods"]
    verbs: ["get", "watch", "list"]
    nonResourceURLs: []
---
# This role binding allows "myacct" to read pods in the namespace "default"
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1alpha1
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: ServiceAccount # May be "User", "Group" or "ServiceAccount"
    name: myacct
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```



1. 名字空间（Namespace）
名字空间为k8s集群提供虚拟的隔离作用。初始有两个：默认名字空间default和系统名字空间kube-system。node和pv不属于任何namespace。pvc是属于某个特定的namespace的。events是否属于namespace取决于产生events的对象。
删除一个namespace会自动删除所有属于该namespace的资源。初始的两个不能删除。

1. RBAC访问授权（Role-based Access Control）
1.3版本中增加。
相对于基于属性的访问控制（Attribute-based Access Control，ABAC），RBAC引入的角色和角色绑定（RoleBinding）的抽象概念。


1. StatefulSet 
StatefulSet是为了解决有状态服务的问题，应用场景包括：
	* 稳定的持久化存储，即pod重新调度后还是能访问到相同的持久化数据，基于pvc来实现
	* 稳定的网络标志，即pod重新调度后其PodName和HostName不变，基于Headless Service（即没有Cluster IP的Service）来实现
	* 有序部署，有序扩展，即Pod是有顺序的，在部署或者扩展的时候要依据定义的顺序依次依序进行，基于init containers来实现
	* 有序收缩，有序删除
statefulSet由以下几个部分组成：
	* 用于定义网络标志（DNS domain）的Headless Service
	* 用于创建PersistentVolumes的volumeClaimTemplates
	* 定义具体应用的StatefulSet


### kuber核心组件 
#### etcd
基于raft开发的分布式key-value存储，用于服务发现、共享配置以及一致性保障。
主要功能：
	* 基本的k-v存储
	* 监听机制
	* key的过期及续约机制，用于监控和服务发现
	* 原子cas和cad，用于分布式锁和leader选举

#### api server
主要功能：
	* 提供集群管理的rest api接口，包括认证授权、数据校验、集群状态变更等
	* 提供其它模块之间的数据交互和通信的枢纽（其他模块通过api server 查询式修改数据，只有api server才直接操作etcd）
可以通过/swaggerapi 查看Swagger API， /swagger.json查看OpenAPI
开启 --enable-swagger-ui=true后还可以通过/swagger-ui访问 Swagger UI

tsl认证： authentication(认证), authorization(授权),admission control(准入控制)

api aggregation： 允许在不修改k8s核心代码的同时扩展kubernetes API

#### kube-scheduler
负责分配调试pod到集群内的节点上，监听kube-apiserver，查询还未分配node的pod，然后根据调试策略为pod分配节点。

#### Controller Manager
由kube-controller-manager和cloud-controller-manager组成，是kubernetes的大脑，通过apiserver监控整个集群的状态，并确保集群处于预期的工作状态。
kube-controller-manager由一系列的控制器组成
* Replication Controller
* Node Controller
* CronJob Controller
* Deamon Controller
* Deployment Controller
* Endpoint Controller
* Garbage Collector
* Namespace Controller
* Job Controller
* Pod AutoScaler
* RelicaSet
* Service Controller
* ServiceAccount Controller
* StatefulSet Controller
* Volume Controller
* Resouce quota Controller

Metrics:
	controller manager metrics 提供了控制器内部逻辑的性能度量：go语言运行时度量、etcd请求延时、云服务商API请求延时、云存储请求延时等。默认监听在10252端口，提供Prometheus格式的性能度量数据，可通过访问 `http://localhost:10252/metrics`来访问

Informer：
	kubernetes从1.7开始，所有需要监控资源变化情况的调用均推荐使用Informer，Informer提供了基于事件通知的只读缓存机制，可以注册资源变化的架设函数，并可以极大减少API的调用。

#### Kubelet
每个节点都运行一个kubelet服务进程，默认监听10250端口，接收并执行master发来的指定，管理Pod及Pod中的容器。每个kubelet进程会在API Server上注册节点自身信息，定期向master节点汇报节点的资源使用情况，并通过cAdvisor监控节点和容器的资源。

监听Pod过程：
* kubelet通过API Server Client(kubelet启动时创建)使用Watch加List的方式监听"/registry/nodes/$当前节点名"和"/registry/pods"目录，将获取的信息同步到本地缓存中
* kubelet监听etcd，所有针对Pod操作都将会被kubelet监听到。如果发现有新的绑定到本邛的Pod，则按照Pod清单的要求创建该Pod
* 如果发现本地的Pod被修改，则kubelet会做出相应的修改。

kubelet创建和修改Pod任务过程：
* 为该Pod创建一个数据目录
* 从API Server读取该Pod清单
* 为该Pod挂载外部卷
* 下载Pod用到的Secret
* 检查已经在节点上运行的Pod，如果该pod没有容器或Pause容器没有启动，则先停止Pod里所有的容器的进程。如果Pod中有需要删除的容器，则删除这些容器
* 用"kubernetes/pause"镜像为每个Pod创建一个容器。Pause容器用于接管Pod中所有其它容器的网络。每创建一个新的Pod，Kubelet都会先创建一个Pause容器，然后创建其它容器
* 为Pod中每个容器做如下处理：
	1. 为容器计算一个hash值，然后用容器的名字去docker查询对应的容器的hash值。如果找到容器，且两个hash值不同，则停止docker中容器的进程，并停止与之关联的pause容器的进程，若两个相同，则不做任何处理
	2. 如果容器被终止了，且容器没有指定的restartPolicy，则不做任何处理
	3. 调用Docker Client下载容器镜像，调用Docker CLient运行容器

kubelet定期调用容器中的LivenessProbe探针来诊断容器的健康状况：
1. ExecAction：在容器内部执行一个命令，如果该命令的退出状态码为0，则表明容器健康
2. TcpSocketAction：通过容器的IP地址和端口号执行TCP检查，如果端口能被访问，则表明容器健康
3. HTTPGetAction：通过容器的IP地址和端口及路径调用HTTP GET方法，如果响应的状态码大于等于200且小于400，则认为容器状态健康

cAdvisor是一个开源的分析容器资源使用率和必以特性的代理工具。集成在kubelet中，ui端口为4194

kubelet内部组件
* Kubelet API，包括10250端口的认证API，4194端口的cAdvisor API，10255端口的只读API，10248端口的健康检查API
* syncLoop： 从API或manifest目录接收Pod更新，发送到podWorkers处理
* 辅助的manager：cAdvisor、PLEG、volume Manager等
* CRI：容器执行引擎接口，负责与container runtime shim通信
* 容器执行引擎：如dockershim，rkt等
* 网络插件：目前支持CNI和kubenet

#### kube-proxy
每台机器上都运行一个kube-proxy服务，它监听API server中service和endpoint的变化情况，并通过iptables等来为经服务配置负载均衡（仅运行TCP和UDP）

#### kube-dns
为kubernets集群提供命名服务，一般通过addon的方式部署。

#### kubeclt
kubectl客户端命令工具

```sh
# 将本地8888 端口转发到 pod 的5000端口
kubectl port-forward mypod 8888:5000
# api server 代理
kubectl proxy --port=8080
# 可以通过 http://localhost:8080/api/ 来直接访问kubernetes API
# 查询pod列表：
curl http://localhost:8080/api/v1/namespaces/default/pods
```










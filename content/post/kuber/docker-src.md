

+++
title = "docker源码分析"
description = "docker源码分析"
tags = [
    "docker"
]
date = "2018-08-01T20:46:49+08:00"
categories = [
    "docker",
]
+++

## docker源码分析

读《docker源码分析》整理

### 容器说明

* 先有进程，后有容器
* 父进程通过fork创建子进程时，使用namespaces技术（CLONE_NEWNS,CLONE_NEWUTS,CLONE_NEWIPC,CLONE_PID,CLONE_NEWNET），实现子进程和父进程以及其它进程之间的命名空间的隔离
* 子进程创建完毕后，使用cgroups技术来处理进程，实现进程资源限制
* 这样，进程所处的“隔离”环境才真正建立，此时容器真正诞生

### docker架构

* docker有如下模块：

	* DockerClient
		发起容器管理请求，请求最终发往DockerDaemon
	* DockerDaemon
		* 接收请求，所有的任务由engine来完成，每一项工作都以job形式存在
		* 管理所有的容器
		* 大致分为三部分：
			* docker server
				它本身是一个名为serveapi的job
				专门服务于docker client，接收并调试分发docker client发送的请求
				通过gorilla/mux创建路由器，添加路由项
				每一个请求，都会创建一个全新的goroutine来服务。
				服务过程：
					1. 读取请求内部
					2. 解析请求
					3. 匹配路由
					4. 调用相应的handler来处理
					5. 应答响应
			* engine
				存储着容器信息，管理着大部分job的执行
				负责完成docker daemon退出前的所有善后工作
			* job
				engine内部最基本的工作执行单元
				job接口的设计，与unix进程相仿，有名称、运行时参数、环境变量、标准输入与输出、标准错误、返回状态等
				job运行函数Run用来执行job本身
	* Docker Registry
		存储容器镜像的仓库
		容器创建时，用来初始化容器rootfs的文件系统内容，将大量的容器镜像汇集在一起，并为分散的daemon提供镜像服务
	* graph
		容器镜像的保管者
	* driver
		驱动模块，可以实现docker运行环境的定制，定制的维度主要有网络环境、存储方式以及容器执行方式
		分为三类驱动：
			1. graph driver
				主要用于完成容器镜像的管理，包括下载、存储、上传，也包括本地构建的存储
			2. network driver
				容器网络环境的配置，包括创建网桥、分配网络接口资源，分配ip、端口并与宿主机做nat端口映射，设置容器防火墙策略等
			3. exec driver
				执行驱动，负责创建容器运行时的命名空间、容器使用资源的统计与限制、容器内部进程的真正运行等
	* libcontainer
		独立的容器管理解决方案，抽象了linux的内核特性（namespace，cgroups，capababilities等），并提供完整明确的接口给docker daemon
	* Docker Container
		服务交付的最终体现

#### docker cli
* 启动过程： 加载配置、创建客户端、执行命令（访问docker server）

#### docker daemon
* 启动过程： 加载配置、创建engine、设置信号、加载内建函数（网络初始化函数、api服务处理函数、事件和日志处理函数、版本和registry授权和搜索函数）、goroutine创建daemon对象，加载功能函数，通知服务启动信号、创建serverapi的job，启动监听服务

##### 单独分析创建daemon对象

	> 创建daemon对象，通过eng的Hack_SetGlobalVar将daemon指针保存在了map中，key为：httpapi.daemon，所以，通过eng这个始终存在的变量（每个job都有eng指针），每个job都可以获取到所需要的
	> 创建的过程中，docker的基本命令都是在这时注册到engine中的，所以单独分析下
	> daemon包含了所需要的各个组件信息，并绑定到eng中，（但我却没有找到Hack_GetGlobalVar这个函数在哪有使用，也就是这个绑定并未使用，边上的注释是说，这个保存是为了获取方式的一个保留）。

* 初始化配置
	* 通过flag默认值，在调用InstallFlags时设置默认值，应用配置信息
	* 配置docker容器的mtu（maximum transmission unit），默认取networkdriver中的默认值，获取失败则默认1500
	* 检查网桥配置信息（ip和网络设备不能同时指定）
	* 检查容器间的通信配置（iptables和icc（InterContainerCommunication）不能同时禁止）
		* 当icc为true，daemon会在iptables中添加一条accept规则，当icc为false，daemon会在iptables中添加一条drop的规则，（使容器间不能互相通信。但可通过容器间link机制通信）所以iptables必须为true
	* 处理网络功能配置：DisableNetwork标志，默认为false。后续init_networkdriver的job中会用到这个标志
	* 处理pid文件配置：如果指定了pid文件，则创建pid文件，并在eng.OnShutdown中注册退出时删除该文件的事件
	* 检测是系统支持及用户权限
		* 操作系统类型对daemon的支持（当前1.2.0只支持linux）
		* 权限检查（必须是root运行：uid为0）
		* 检查内核版本和处理器：必须为amd64，内核在3.8.0以上
	* 配置工作路径
		* 默认配置路径为：/var/lib/docker
		* 创建默认tmp目录：DOCKER_ROOT/tmp
		* root和tmp目录，都会转换成绝对目录
	* 加载并配置graphdriver
		* 创建graphdriver
			* 依次从环境变量DOCKER_DRIVER、配置GraphDriver中根据类型获取驱动
			* 如果上面未找到，则从系统注册的aufs、btrfs、devicemapper、vfs依次获取
			* 如果还是获取失败，则从注册的驱动中取
		* 检查SELinux：如果驱动使用的是brtfs，则必须关闭SELinux
		* 创建容器仓库目录：DOCKER_ROOT/containers
		* 迁移容器：如果驱动是aufs类型，由于docker 0.7.x版本之前，容器镜像层内容和镜像元数据均放在同一个目录，需要迁移做拆分存储
		* 创建镜像graph
			* 创建镜像目录：DOCKER_ROOT/graph
		* 创建volumesdriver（用的vsf驱动）和volumes graph(目录为：DOCKER_ROOT/volumes)
			* 存储分两种：一种是启动时通过-v A:B 指定将A挂载到容器的B目录下，一种是dockerfile中VOLUME /data或者启动时 -v /data指定，这种源地址在DOCKER_ROOT/vfs/dir/<ID>下（而且docker不会自动清理这些目录）
		* 创建tagStore： 用于管理存储镜像的仓库列表
	* 配置docker daemon网络环境
		* DisableNetwork为false时（默认为false），通过调用eng的init_networkdriver的job来初始化网络
			* 如果指定了网络设备，则获取对应设备的ip；如果只指定了ip，则创建对应ip的docker0网桥
			* 根据icc开关标志设置iptables
				* 为docker容器之前的link操作提供iptables防火墙支持
				* 新建网桥nat功能： iptables -I POSTROUTING -t nat -s docker0_ip ! -o docker 0 -j MASQUERADE
				* 如果icc为true，则允许从docker0发出，发往docker0的数据包，否则则禁止: iptables -I FORWARD -i docker0 -o docker0 -j ACCEPT/DROP
				* 允许从docker0发出，不是发往docker0的数据包：iptables -I FORWARD -i docker0 ! -o docker0 -j ACCEPT
				* 允许发往docker0，并且属于已经建立的连接的数据包：iptables -I FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
			* 启用系统数据包转发功能 ip_forward = 1
			* 创建docker链
				* docker在网桥设备上创建一条名为DOCKER的链，作用是在创建docker容器时实现容器与宿主机的端口映射
			* 向engine中注册4个句柄：allocate_interface，release_interface，allocate_port，link
	* 创建graphdb并初始化
		* graphdb是构建在sqlite之上的图形数据库，数据库为：DOCKER_ROOT/linkgraph.db
		* 创建entity表和edge表，并插入初始entity：0，初始edge：0 /
	* 创建execdriver
		* 默认是native类型
	* 创建daemon实例
		* 类型属性分析
			* repository 容器信息路径
			* containers 用于存储docker容器信息的对象
			* graph 存储docker镜像的graph对象
			* repositories 存储所有docker镜像repo信息的对象
			* idIndex 用于通过有效的字符串前缀定位唯一的镜像
			* sysInfo 系统功能信息
			* volumes 管理宿主机上volumes内容的graphdriver，默认是vfs类型
			* config 配置信息
			* containerGraph 存放docker镜像关系的graphdb
			* driver 管理docker镜像的驱动graphdriver
			* sysInitPath 系统dockerinit二进制文件所有的路径
			* execDriver daemon的exec驱动
			* eng docker执行引擎
	* 检查dns配置 不能配置有127.0.0.1，默认用8.8.8.8和8.8.4.4
	* 启动时加载已有docker容器
	* 添加shutdown的处理方法
		* 运行daemon对象的shutdown
		* 运行portallocator.ReleaseAll释放所有占用的端口资源
		* daemon.driver.Cleanup 通过graphdriver实现unmount所有有关镜像的挂载
		* 通过daemon.containerGraph.Close 关闭graphdb的连接
	* 返回daemon对象实例。完成了daemon对象的加载

#### docker server
* docker server的创建流程
	* 创建名为serveapi的job
	* 配置job环境变量
	* 运行job
* serveapi运行流程
	* 解析协议信息，定义错误信息管道
	* 遍历协议地址，针对协议创建相应的服务端
		* 创建router路由实例
			* 判断是否开启debug功能，如果开启，则设置pprof相关（增加一个输出所有变量的url：/debug/vars）
			* 添加路由记录（包括带版本和不带版本url的句柄）
		* 创建listener监听实例
			* 由于BufferRequests值设置的为true，所以使用包linstenbuffer来创建监听：让server立即监听指定协议地址上的请求，但将这些请求缓存下来，等启动完成后，才接受这些请求
		* 创建http.Server
		* 启动api服务
	* 通过管道建立goroutine与主进程之间协调关系，等待协程运行结果

#### docker daemon网络

* docker daemon网络配置
	* iptables和icc来配置：iptables必须为true（前面已经解释过），icc来控制是否运行容器间通过docker0通讯
	* docker网络模式为网桥模式

* docker 容器网络模式
	* docker可以为容器创建隔离的网络环境，在隔离的网络环境下，docker容器使用独立的网络栈
	* 同样，docker也有能力为容器创建共享的网络环境
	* docker还可以实现不为容器创建网络环境

	* docker共有4种网络模式：
		* 桥接模式
			* 可以使容器独立使用网络栈
			* 在宿主机上创建两个虚拟网络接口，假设为veth0和veth1，利用veth pair技术，可以保证无论哪一个veth接收到网络报文，都会传输给另一方
			* docker daemon将veth0附加到docker daemon创建的docker0网桥上，保存宿主机的网络报文有能力发往veth0
			* docker daemon将veth1添加到容器所属网络命名空间下，实现容器到宿主机之间的网络联通性，同时保证容器单独使用veth1，实现容器之间以及容器与宿主机之间网络环境的隔离性（也就是每一个容器与宿主机都有一对veth）
			* 由于宿主机ip和veth pair的ip不在同一网段，所以docker采用nat的方式让宿主机以外的世界可以将网络报文发到容器内部（通过docker0上的端口来绑定对应的容器的ip和端口）
				* 外界访问docker容器内部服务流程：
					* 外界访问宿主机的ip（对应eth0设备）和端口port_1
					* 宿主机接收到请求后，通过dnat规则，会将请求转发到容器ip和容器端口
					* 由于能识别容器ip，故宿主机可以将请求发送给veth pair，完成与容器通讯
				* 容器内部访问外界流程：
					* 容器内部获取外界ip和端口port_2，请求时，linux内核会另外分配一个可用端口（port_3)
					* 请求通过容器内部eth0发送到veth pair的另一端，到达网桥docker0处
					* docker0网桥开启了数据报转发功能（ip_forward),将请求发送到宿主机eth0处
					* 宿主机处理请求时，使用snat对请求进霆源ip替换，将容器ip换为eth0的ip
					* 宿主机将snat处理后的报文发到目的ip地址
		* host模式
			* 并没有为容器创建一个隔离的网络环境，该模式下docker容器会和宿主机使用同一个网络命名空间（fork时不使用CLONE_NEWNET）
			* 容器ip和宿主ip是相同的（端口不能冲突）
		* other container模式
			* 容器使用别的容器的网络环境（和另一个容器共享网络资源：命名空间相同）
			* 可提高容器间的传输效率（k8s的pod就是一组容器共享网络资源）
		* none模式
			* 不为容器创建任何网络环境，只能使用loopback网络接口


#### docker 镜像

* union mount 
	* 代表一种文件系统挂载方式，允许同一时刻多种文件系统叠加挂载在一起，并以一种文件系统形式，呈现多种文件系统内容合并后的目录
	* 不会将挂载点目录中的内容隐藏，而是将挂载点目录中的内容和被挂载的内容合并，并为合并后提供一个统一独立的文件系统视角
	* COW（copy-on-write)特性：当用户修改只读文件系统中的文件时，会先将该文件复制到读写文件系统中，然后修改新的那个文件。（两个文件的目录完全一样，所以合并后，用户看到的是读写文件系统中的新文件）
	* 删除：会在读写文件系统中对这些要删除的文件内容做相关的标志（witeout），确保用户在查看文件系统内容时，读写文件秕上中的whiteout将遮盖住rootfs中相应的内容

* 镜像image
	* image就是只读文件系统中rootfs的一部分，多个image构成一个rootfs（使用union mount）
	* 父镜像：下一层镜像为上一层镜像的父镜像
	* 基础镜像：最下层的为基础镜像

* 层layer
	* 每一层只读的image都叫layer，layer多了一个最上层读写文件系统：top layer，还有一个网络相关：init layer(hosts,hostname,resolv.conf)
	* 将top layer打包成image就是docker commit命令


#### dockerinit

* dockerinit介绍
	* dockerinit是容器中的init进程。


#### libcontainer介绍

docker daemon负责docker server的一系列api接口，而libcontainer接管linux平台内核态容器技术实现的api接口，两者通过execdriver的形式协调工作。

* libcontainer中namespace的exec的实现：
	* 创建syncpipe，以便后续docker daemon与容器进程跨namespace进行信息传递
	* 创建容器内部第一个进程的可执行命令
	* 启动该命令实现namespace的创建
	* 为容器第一个进程进行cgroup的限制
	* 在docker daemon所在的namespace中初始化容器内部所需要的网络资源
	* 通过管道跨namespace将网络资源传递到容器进程
















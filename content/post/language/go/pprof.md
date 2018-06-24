
+++
title = "golang pprof使用"
description = "golang pprof使用"
tags = [
    "golang",
    "pprof"
]
date = "2018-05-28T20:02:28+08:00"
categories = [
    "golang"
]
+++

## 启用pprof
* 带有http的服务，只需要引入 ``` import _ "net/http/pprof" ``` 就可以通过访问```http://ip:port/debug/pprof``` 查看了

* 没有http服务的应用，或者不想在原端口启用的，可像我这样实现根据配置启用（config是我自定义的配置包）

```golang
import (
	_ "net/http/pprof"
	"net/http"
)

func InitModel() {
	var ppaddr string
	if config.HasModuleInit() {
		ppaddr = config.StringDefault("ppaddr", "")
		if ppaddr != "" {
			go http.ListenAndServe(ppaddr, nil)
		}
	}

}
```

## pprof使用

### 1.代码优化

```shell
curl http://ip:port/debug/pprof/profile > /tmp/a.profile
go tool pprof  可执行程序  /tmp/a.profile
(pprof) top    #可查看占用资源最多的函数

```

#### pprof各字段的含义依次是：
1. 采样点执行时间
2. 采样点落在该函数中的百分比
3. 上一项的累积百分比
4. 采样点落在该函数，以及被它调用的函数执行的总时间
5. 采样点落在该函数，以及被它调用的函数中的百分比
6. 函数名
7. 文件名

## pprof分析
1. / 
* 访问根目录，里面有几个链接：

	1. bolck
		* 锁说明

	1. goroutine
		* 当前协程清单
		* debug为0时，下载的是文件打包信息
		* 访问heap时，debug为1时是简写，最开始的数字是协程数（同类的协程会合并），@后面是单个协程的栈，对应的是各个函数的地址，可通过symbol来查询对应的函数
			debug大于等于2时，是详细描述，会详细打印每个routine的号，支持状态，等待的routine会显示等待时间，还有详细的堆栈信息

	1. heap
		* 当前使用的内存信息
		* 第一行： 当前使用对象数:当前使用字节数 [总申请对象数:总申请字节数] 
		* 后面是单个routine的使用情况，还有对应的堆栈信息

		* 最后总结信息：
			1. Alloc  同HeapAlloc，当前申请对象字节数
			1. TotalAlloc  累计申请对象字节数，包括已经释放的
			1. Sys     从系统中申请到的内存字节数（包括未归还的虚拟内存）
			1. Lookups  debug本身使用的指针数
			1. Mallocs  累计申请的对象数
			1. Frees    累计释放的对象数

			# go把虚拟内存地址分成几块，每块可能8k更大，每块有3种状态：idle空闲 in use使用中，stack 
			> idle是虚拟地址可再重复使用，对应的物理地址可能被操作系统回收
			> in use 是至少有一个使用中的堆对象，有可能还有备用的空闲空间
			> stack 保存的是goroutine的运行栈，会在堆和栈之间做切换，统计时，不作为堆统计
			# 堆内存统计
			1. HeapAlloc  包含所有使用的对象，还有未被回收的不使用的对象(字节数)
			1. HeapSys    从系统申请的堆空间，包括已经归还的物理空间（虚拟地址还在用）(字节数)
			1. HeapIdle   状态为idle的块(字节数)
			1. HeapInuse   状态为in use的块(字节数)
			1. HeapReleased  已经归还给系统的块(字节数)
			1. HeapObjects   堆中的对象数

			# 栈内存统计
			# 栈不作为堆来统计，不再使用的栈会归还给堆
			1. Stack   stack块 / 从系统中申请的栈 (字节数)
			1. MSpan   使用中的专用结构（主要用于统计堆的） /  从系统申请的专用结构 (字节数)
			1. MCache  使用中的专用缓存 /  从系统申请的专用缓存  (字节数)
			1. BuckHashSys  统计profile申请的hash桶内存  (字节数)
			1. GCSys     gc回收使用的内存（记录gc信息用的） (字节数)
			1. OtherSys  其它未使用的堆空间 (字节数)

			# gc回收统计
			1. NextGC  下一次gc的堆大小，会保证：HeapAlloc ≤ NextGC (字节数)
			1. LastGC  最后一次gc时间，unix时间格式 
			1. PauseNs  记录最后的256次暂停的时间 ns（一次gc可能会暂停多次）
			1. PauseEnd 记录最后的256次暂停的时候 unix格式
			1. NumGc    完成的gc次数
			1. NumForcedGC  程序主动调用gc的次数
			1. GCCPUFraction  gc使用的cpu时间占程序使用的cpu时间百分比
			1. DebugGC   保留，暂未使用，固定false

	1. mutex
	# 锁信息

	1. threadcreate
	# 创建的线程数

	1. full goroutine stack dump
	# 同goroutine, debug=2


1. cmdline
> curl http://ip:port/debug/pprof/cmdline    #获取程序启动参数

1. profile
	#可带参数seconds，获取从当前开始seconds秒后的性能分析报告（默认30秒）
	> curl http://ip:port/debug/pprof/profile?seconds=100 > /tmp/a.profile
	> go tool pprof  可执行程序  /tmp/a.profile
	> top  #查看最点资源函数
	> list 函数名   #查看函数详情

	> curl http://ip:port/debug/pprof/heap > /tmp/a.heap
	> go tool pprof -alloc_objects  可执行程序 /tmp/a.heap 
	> top 

	> go build -gcflags='-m' .   #显示内存分配情况

1. symbol
	> #根据内存地址找对应的函数符号, 内存地址通过访问：http://ip:port/debug/pprof/heap?debug=1可看到
	> curl http://ip:port/debug/pprof/symbol -d '0x4316b4+0x438608'
	> curl http://ip:port/debug/pprof/symbol?0x4316b4+0x438608


1. trace
	#（用法和profile类似）可带参数seconds，获取从当前开始seconds秒后的性能分析报告（默认1秒）
	> curl http://ip:port/debug/pprof/trace?seconds=100 > /tmp/a.trace
	> go tool trace 可执行程序 /tmp/a.trace    #会启动一个http监听，访问可查看具体信息




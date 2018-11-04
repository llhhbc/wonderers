+++
title = "go源码学习"
description = "go源码学习"
tags = [
    "golang"
]
date = "2018-08-26T20:02:28+08:00"
categories = [
    "golang"
]
+++


## 启动过程

* 初始化参数
	设置argc，argv
* 初始化系统
	设置maxproc
* 初始化调度器
	* 初始化栈分配器stack
	* 初始化内存分配器malloc
	* 公共初始化

	* 处理命令行参数、环境变量：gorags，goenvs

	* 垃圾回收初始化gcinit

* runtime.main
	* 初始化runtime包中的所有init函数
	* 启动垃圾回收
	* 执行所有用户包中的init
	* 进入main.main，用户逻辑入口

## 内存分配

* go内存空间结构
	* 页所属 spans 512MB | gc标记位图 bitmap 32GB | 用户内存分配 arena 512GB  （后面的空间为可能的最大空间）

* 分配器将内存为两种：span内存块，object内存对象
* 使用tcmalloc来管理内存
	* cache 每个线程都会绑定一个cache，用于无锁object分配
	* central 为所有cache提供切分好的后备span
	* heap 管理闲置的span，需要时向系统申请新内存

	* 优先使用cache来分配对象，如果不足，再从central中优先找现有的span检查是否有可用空间，再不足，才到heap中申请span

* 内存分配
	* golang编译器支持逃逸分析(escape analysis)，编译期通过构建调用图来分析局部变量是否会被外部引用，从而决定是否可直接分配在栈上
	* 编译参数 -gcflags "-m" 可输出编译优化信息

* 内存回收
	* 以span为单元，检查span内的object是否全部释放，将原本就为空的span转移到central.nonempty，将收回的span交还给heap。同时会尝试合并相邻的空的span

* 内存释放
	* 程序运行会启动一个监控任务：sysmon，每隔一段时间就会检查heap内闲置内存，如果闲置时间超过阈值，则释放其关联的物理内存（只是建议系统回收，但不代表系统就一定会回收）

## 垃圾回收
* 三色标记和写屏障
	* 起初所有对象都是白色（开启gc写屏蔽时，新分配的对象直接为黑色）
	* 扫描所有可达对象，标记为灰色，放入待处理队列
	* 从队列中提取灰色对象，将其引用的对象标记为灰色放入队列，自身标记为黑色
	* 写屏障监视对象内存修改，新分配的对象直接为黑色
	* 全部扫描和标记后，剩下白色就是待回收对象、黑色就是活跃对象

* 控制器
	* 并发回收任务中，记录相关状态数据，动态调整运行策略，参与next_gc回收阈值设置，调整垃圾回收触发频率

* 回收模式
	* gcstoptheworld == 1 : gcForceMode 强制模式
	* gcstoptheworld == 2 : gcForceBlockMode 强制块模式
	* gcBackgroundMode 并发模式，只有这个是后台异步模式。当满足gc条件时，会唤醒，gc后会休眠
		* 后台模式步骤： STW(stopTheWorld), WB(writeBarrierEnabled), BE(blackenEnabled)
		* WB:1,BE:1, 并发扫描，标志灰色，对白色对象的引用修改被写屏障捕获
		* 第二轮标记
		* BE = 0，stw冻结，完成最终标记
		* wb = 0，并发清理

* 标记
	* 标记的工作模式
		* gcMarkWorkerDedicatedMode 全力运行，直到并发标记任务结束
		* gcMarkWorkerFractionalMode 可被抢占和调试
		* gcMarkWorkerIdleMode 仅在空闲时参与标记任务

* 监控
	* 监控服务sysmon每隔2分钟就会检查一次垃圾回收状态，如果超过2分钟未触发，就强制执行

* 内存状态统计
	* GODEBUG="gctrace=1"  可输出垃圾回收信息

## 并发调度
* goroutine 对应的用户态线程，而不是系统线程，调度是由golang自己来调度的
* golang采用的是一种多对多的方案，m个用户线程对应n个系统线程
* golang有3个角色：
	* M：代表系统线程，由操作系统管理
	* G：goroutine的实体，包括的调用栈，重要的调度信息
	* P：衔接M和G的调度上下文，由GOMAXPROCS决定，一般和核心数对应。每个P会将goroutine从一个就绪的队列中做pop操作，为了减小锁的竞争，通常情况下每个P会负责一个队列
* G并非执行体，只是保存任务状态，为任务执行提供所需的栈内存空间。G创建后，由P来管理
* M是系统线程，只有和P绑定后才会执行，否则只能休眠。M通过修改寄存器，将执行栈指向P所分配的G自带栈内存，并在此空间内分配堆栈帧，执行任务函数。当需要中途切换时，只要将相关寄存器值保存到G空间即可维持状态，任何M都可据此恢复执行。M仅负责执行，不持有状态。
* P控制执行过程，管理M执行G。P为M提供执行资源，比如对象分配内存、本地任务队列，M独享所绑定的P。
* 如果M1在执行G1时，在对应的P1上分配的变量，然后G1保有了该变量地址，发生调度后，由M2来执行，M2通过G1依然可以找到P1上对应的地址。如果发生G抢占分配，将G1移到了P2上，由于G1依然可以访问P1上的地址，所以并不冲突。G1访问并不影响P1的运行，因为不会同时操作同一地址（在P1上，那块地址已经使用，不会再使用），而如果G1释放了，则由gc来回收，完成P1上空间的释放。

* goroutine创建好后，会把对应的G放到P的本地队列中。如果本地队列已满，一次性转移半数到全局队列中。当本地队列和全局队列都为空，才会考虑去检查其它P任务队列
* M对应一个特殊的g0。如果M对应的G被暂停，放回P中时，M对应的G就会指向g0，相当于未绑定任何G。像一些管理类的执行（比如创建g，gc，就会直接用g0来运行，不会再创建G）
* P为M提供cache，以便为执行者提供对象内存分配
* GODEBUG="schedtrace=1000"  可查看sched信息

```golang
type g struct {  //只简单列了部分
	stack   stack //执行栈
	sched   gobuf //用于保存执行现场
	goid    int64 //唯一序号
	gopc    unitptr //调用者 PC/IP
	startpc unitptr //任务函数
}
```
* G 创建过程：
	1. 从当前P复用边表中获取空闲G对象
	1. 如果获取失败，则新增G对象
	1. 检查G的栈、状态
	1. 计算所需空间大小，并对齐（包括返回参数所需要的栈大小）
	1. 确定SP和参数入栈位置
	1. 将执行参数拷贝入栈
	1. 初始化用于保存执行现场区域sched。将goexit地址保存在sched.pc中
	1. 初始化基本状态:gopc=callerpc, startpc=fn.fn
	1. 设置唯一id：每次从全局计数器sched.goidgen中取一段放在P中，优先从本地分配
	1. 将G放入待运行队列中
	1. 如果当前不是main，并且没有在等待P的M，则尝试唤醒某个M出来执行任务
	1. 创建完毕的G任务被优先放入P本地队列，等待执行

```golang
type m struct {  //只简单列了部分
	g0        *g		//提供系统栈空间
	mstartfn  func()	//启动函数
	curg      *g		//当前运行的G
	p         puintptr	//绑定的P
	nextp     puintptr	//临时存放P
	spinning  bool		//自旋状态（等待P）
	park      note		//休眠锁
	schedlink muintptr	//链表
	mcache    *mcache   //缓存，绑定P时设置
}
```
* M切换过程（当执行系统管理函数时）：
	1. 如果M当前g已经是g0，则无需切换
	1. 将G状态保存到G自己的sched中
	1. 将栈切换到g0.stack（修改SP）
	1. 执行系统管理函数（比如创建g、gc）
	1. 切换回G，恢复执行现场
* M必须绑定一个有效的P，nextp临时持有待绑定P对象。P为M提供cache，以便为执行者提供对象内存分配。
* M调度循环：
	* schedule
		* 判断GC STW标志，如果gc中，则休眠
		* 如果开始gc标记，则进入GC MarkWorker工作模式
		* 从P的全局队列中获取G
		* 从P的本地队列获取G
		* 未获取到则休眠
		* 获取到后执行goroutine任务函数
	* execute
		* 设置curg=g, g.m=m  g和m相互绑定
		* 执行gogo
			* 从g0栈切换到g栈，jmp指令进入G任务函数代码。（根据保存的g.sched来恢复寄存器）
	* goroutine fn
		* JMP后执行对应函数
	* goexit
		* G创建时，sched.pc保存的是goexit的地址，然后把这个地址入栈了，待JMP执行后，RET指令恢复PC/IP，将对应goexit，完成goexit的执行。
		* goexit中，清理G状态，解除m和g的绑定，将G放回利用链表，重新进程调试循环。

## 监控
* 释放闲置超过5分钟的span物理内存
* 如果超过2分钟没有垃圾回收，强制执行
* 将长时间未处理的netpoll结果添加到任务队列
* 向长时间运行的g任务发出抢占调度
* 收回因syscall长时间阻塞的p

## 缓存池
* 每个P都有一个私有缓存池，还有共享缓存池。优先使用私有缓存池，共享缓存池需要加锁访问，如果还没有，可从其它P中取共享缓存，实在找不到，则自己新建一个缓存

+++
title = "golang 总结"
description = "golang 总结"
tags = [
    "golang"
]
date = "2018-07-18T20:02:28+08:00"
categories = [
    "golang"
]
+++

### Ready go

#### 1. goroutine
* goroutine 对应的用户态线程，而不是系统线程，调度是由golang自己来调度的
* golang采用的是一种多对多的方案，m个用户线程对应n个系统线程
* golang有3个角色：
	* M：代表系统线程，由操作系统管理
	* G：goroutine的实体，包括的调用栈，重要的调度信息
	* P：衔接M和G的调度上下文，由GOMAXPROCS决定，一般和核心数对应。每个P会将goroutine从一个就绪的队列中做pop操作，为了减小锁的竞争，通常情况下每个P会负责一个队列

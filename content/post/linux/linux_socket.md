
+++
title = "linux下socket的复用"
description = "linux下socket的复用"
tags = [
    "linux",
    "socket"
]
date = "2018-04-27T09:01:00+08:00"
categories = [
    "linux",
]
+++


### linux下端口复用

##### SO_REUSEADDR可以用在以下四种情况下。 (摘自《Unix网络编程》卷一，即UNPv1)

1. 当有一个有相同本地地址和端口的socket1处于TIME_WAIT状态时，而你启动的程序的socket2要占用该地址和端口，你的程序就要用到该选项。

1. SO_REUSEADDR允许同一port上启动同一服务器的多个实例(多个进程)。但每个实例绑定的IP地址是不能相同的。在有多块网卡或用IP Alias技术的机器可以测试这种情况。

1. SO_REUSEADDR允许单个进程绑定相同的端口到多个socket上，但每个socket绑定的ip地址不同。这和2很相似，区别请看UNPv1。

1. SO_REUSEADDR允许完全相同的地址和端口的重复绑定。但这只用于UDP的多播，不用于TCP。


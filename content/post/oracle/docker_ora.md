
+++
title = "docker 安装 oracle"
description = "docker 安装 oracle"
tags = [
    "oracle"
]
date = "2018-07-26T20:46:49+08:00"
categories = [
    "oracle",
]
+++


###  docker centos7中安装oracle

参考：

  * https://blog.csdn.net/sql_ican/article/details/77749981  #脚本测试是可用的
  * http://www.cnblogs.com/wq3435/p/6523840.html  #ora配置说明可参考

#### 注意问题

##### swap 问题
 oracle安装要求swap空间的，所以docker对应的宿主机器上swap要开，因为docker --privileged模式下用的是主机的swap空间，可在安装完成后，再关swap


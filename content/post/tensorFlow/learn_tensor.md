+++
title = "tensorFlow入门"
description = "tensorFlow入门"
tags = [
    "tensorflow"
]
date = "2018-05-11T20:02:28+08:00"
categories = [
    "learning"
]
esid="ICsjgGMB-LOJRgD483Su"
+++
## 环境搭建

#### pyenv搭建

1.安装pyenv
1.安装pip  virtualenv
1.创建虚拟环境
python3 -m venv ./env
1.切换环境
. env/bin/activate

#### conda搭建
1.安装anaconda3
1.创建虚拟环境
`conda create --name py3 python=3`
1.环境切换
`source activate py3`

## tensorflow安装(下面操作都在python3环境下操作)

```shell
##我本地环境如下搭建
# conda create --name mytensor python=3.6
# source activate mytensor
# source deactivate   #退出环境

pip install tensorflow
pip install tensorlayer

```

### 验证环境安装
```python
import tensorflow as tf

hello = tf.constant("hello, tensorflow")
sess = tf.Session()
print(sess.run(hello))

```

## 简单入门
* 参考资料 [中文社区](http://www.tensorfly.cn/)

| 类型 | 描述 | 说明
| --- | --- |---
| session | 会话 | 一次流程执行的会话，包含上下文信息
| graph | 描述计算过程 | 在session中启动，图形显示
| tensor | 数据 | 数据类型
| op   | 操作 | 数据之间的操作
| variable | 变量 | 数据类型，运行中可改变，用于维护状态
| feed | 赋值 | 为op的tensor赋值
| fetch | 取值 | 从op的tensor中取值
| constant | 常量 |



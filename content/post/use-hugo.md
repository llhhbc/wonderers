
+++
title = "use hugo"
description = " my use hugo"
tags = [
    "go",
    "golang",
    "hugo",
    "development",
]
date = "2018-04-25T12:02:28+08:00"
categories = [
    "Development",
    "golang",
    "hugo",
]
+++

#### hugo的安装
```
go get github.com/gohugoio/hugo
```

#### 基本使用
1. 创建一个网站项目
hugo new site hello
1. 安装一个theme
hugo将数据和展示分开了，显示部分由theme来管理
1. 原理如下：
	* 项目下的数据，会由hugo按格式读取，并约定好模板中的变更名，由theme来显示出来
	* 比如：.Data表示content下的页面信息 
	* theme就是go用来渲染的模板，而项目下content下的就是它的数据来源（默认用这个目录），也支持用其它目录

#### 发布github
1. github上新创建一个repository
1. 修改本地baseurl为github的：https://llhhbc.github.io/wonder/
1. 上传代码：

``` shell
hugo  ##生成静态文件
cd public
git init
git add .
git commit -m "init"
git remote add github https://github.com/llhhbc/wonder.git
git push github master
```

1. 在repository 的设置（setting）中，找到github pages
1. 在source中选择分支，点击save（会自动刷新，然后会提示访问地址）

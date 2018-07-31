+++
title = "goadesign 学习之adder"
description = "goadesign 学习"
tags = [
    "golang",
    "goa"
]
date = "2018-07-22T20:01:00+08:00"
categories = [
    "golang",
    "goa"
]

+++

## goadesign 学习
> 一次接触中，了解到了goa，根据dsl做巧妙的翻译，自动完成统一代码的生成

  github上搜索goadesign，可以看到他有的代码库，出于学习，我把它的样[例库](https://github.com/goadesign/examples.git)下载下来了，我决定从样例代码开始，结合官方的[文档](https://goa.design/learn/guide/)来学习

### 先从第一个例子开始
* 第一个是加法服务，adder目录只有两个go文件，其中一个还在报错（其实是程序自动生成的文件，只是里面有自己定制的代码，所以保留了


```golang
// adder/design/design.go

var _ = API("adder", func() {   //api定义说明，一个文件只可以有一个api
	Title("The adder API")
	Description("A teaser for goa")
	Host("localhost:8080")
	Scheme("http")
})

var _ = Resource("operands", func() {  //资源说明，resource对应一个service
	Action("add", func() {  //动作说明，api请求动作
		Routing(GET("add/:left/:right")) //定义访问地址格式
		Description("add returns the sum of the left and right parameters in the response body")
		Params(func() {  //定义请求url中参数说明
			Param("left", Integer, "Left operand")
			Param("right", Integer, "Right operand")
		})
		Response(OK, "text/plain")  //定义应答报文样式
	})

})
```

* 根据design文件生成代码

```sh
goagen bootstrap -d github.com/goadesign/examples/adder/design   #这里的目录需要的是从GOPATH开始的目录
```

> 由于我想看看自动生成的operands.go文件，所以我先删除它，然后通过git来比较它

```diff
diff --git a/adder/operands.go b/adder/operands.go
index 6cc3671..a09bb49 100644
--- a/adder/operands.go
+++ b/adder/operands.go
@@ -1,9 +1,6 @@
-//go:generate goagen bootstrap -d github.com/goadesign/examples/adder/design
 package main

 import (
-       "strconv"
-
        "github.com/goadesign/examples/adder/app"
        "github.com/goadesign/goa"
 )
@@ -15,10 +12,15 @@ type OperandsController struct {

 // NewOperandsController creates a operands controller.
 func NewOperandsController(service *goa.Service) *OperandsController {
-       return &OperandsController{Controller: service.NewController("operands")}
+       return &OperandsController{Controller: service.NewController("OperandsController")}
 }

 // Add runs the add action.
 func (c *OperandsController) Add(ctx *app.AddOperandsContext) error {
-       return ctx.OK([]byte(strconv.Itoa(ctx.Left + ctx.Right)))
+       // OperandsController_Add: start_implement
+
+       // Put your logic here
+
+       return nil
+       // OperandsController_Add: end_implement
 }
 ```

* 通过git diff比较发现，修改有两个地方：
	1. 返回的控制器名字变了
	2. 原本提示增加逻辑的Add函数，改为了加法，并返回相加后的值

* 还生成了很多其它文件，我先不管它，也看这个，大致了解了，就是它通过design里面的描述，知道里面有个Action：add，然后生成了操作文件，并定义好了Add方法，自己只需要实现它的内部逻辑，而其它的，都通过程序自动生成了。虽然还不太清楚自动实现了哪些，不过，一个服务api，我能定义好访问地址，然后去实现它的功能，其它的比如程序启动、加载配置、日志跟踪等统一化的功能，我如果都能自动实现，实现统一化、标准化，这是一个很好的期望

```sh
# 将操作文件还原，完成加法功能
git checkout -- operands.go
```

* 测试程序功能

```sh
#在adder目录下编译程序
go build
#启动程序
./adder

#通过启动日志，可以后台程序监听到了8080端口，绑定了add动作，访问地址为：/add/:left/:right
# 测试程序
curl http://localhost:8080/add/1/2
# 可以看到，测试返回3，并且，服务端打印了处理请求的日志，还有应答时间

# 相当于我们定义了一个接口规则，配置了访问端口，定义了功能操作内容，其它都通过程序自动完成了，一个简单的服务就这样搭建了
```

### 分析自动生成的代码
* 通过查看自动生成的文件，多了几个目录：
	* app目录：定义了上下文、控制器，hrefs、media、user这三个还是空的，还不清楚是做什么的
	* client目录：定义了客户端访问方式、操作方法，media和user还是空的
	* swagger目录：以yaml和json格式定义了说明文档
	* tool目录：定义了客户端测试工具，可通过：adder-cli add operands /add/1/2 完成交易测试（会自动生成http请求，完成接口服务测试）

* 详细看app目录
	* contexts 定义了AddOperandsContext上下文，主要包括3块：系统上下文、goa请求应答数据、url参数数据变量。定义了生成上下文的函数：解析请求参数，构造请求上下文，定义了ok函数：设置返回报文格式和信息
	* controllers 定义了OperandsController控制接口，并定义了挂载控制器的函数：MountOperandsController，初始化解码服务函数，并注册默认用json来解析，同时挂载add方法
* client目录
	* client 定义了客户端访问：goa客户端、编码工具、解码工具，并在New中注册编码、解码工具
	* operands 定义了请求操作函数，完成http请求
* tool目录
	* adder-cli 定义了客户端程序的启动参数，并的挂载add命令
	* cli 定义了add命令的相关功能

* main
	* main是服务的组合，goa.New来创建一个服务，然后自动挂载了4个中间服务：请求唯一id处理（用于跟踪请求），日志处理，错误处理，异常捕获，然后创建add操作控制，挂载add服务，启动监听
* 就这样，一个微服务的简单模型就构造出来了。

### 分析design中各个名称和代码的关系
* 再回过头看最初的design，里面有一些名称，比如最好理解的Action("add"，表示定义了一个add的动作，还有其它的名称，我想测试他们之间的关系，所以我在adder下创建一个git库，然后把所有文件归档，这样，当有文件变化，直接git diff就能看出来。（记录删除.gitignore）
* 一次测试之前，要确保git下无修改文件，重新生成前，要先删除main.go operands.go，这两个文件如果已经存在则不会重新生成。还有一点要注意：测试url地址，返回200就表示成功，因为默认生成的代码是不会有返回内容的，就是add方法中是空的，需要自己添加逻辑

* 我先改了 Api("add1", func(){ ...})，把add改成了add1，然后重新生成，发现，所有文件都只是注释变了，还有就是add-cli目录的名称变成了add1-cli，所以说，这个各称只和注释说明、命令目录有关。其它Title、Description也是和注释相关的，Host和Scheme也好理解，当然也可以自己测试试下
* 我再改了 Resource里面的名字，发现，控制器的名字、上下文的名字都变了
* 我再改了Action对应的名称，发现上下文、控制器的名字都有变化，操作函数名也变化了，我编译后访问，发现服务不正常了：我访问add/1/2，提示找不到操作函数，返回404，如果访问add2/1/2，发现正常。 生成的控制器中，服务注册是这样的：service.Mux.Handle("GET", "/add/:left/:right", ctrl.MuxHandler("add2", h, nil))， 所以说，action的名称，只是用于生成上下文、控制器的名字，访问地址还是按router来匹配
* 修改routing的目录，测试发现，访问目录对应调整，服务正常
* 我改了参数说明，把left改成left1，路由中的不变，发现功能正常，它自动给我做名称转换了，操作函数有了这个不同，多了个left到left1的映射：

```golang
-func Add2Operands1OK(t goatest.TInterface, ctx context.Context, service *goa.Service, ctrl app.Operands1Controller, left int, right int) http.ResponseWriter {
+func AddOperands1OK(t goatest.TInterface, ctx context.Context, service *goa.Service, ctrl app.Operands1Controller, left string, right int, left1 *int) http.ResponseWriter
```

* 最后个response，就是一个返回http头的指定

* 整理下来，发现，api是个标志，主要描述服务功能，定义启动相关。资源的动作，按两个维度把router来分组。

### 设想的测试
* 针对动作，做两个测试：同一个资源下，有两个action，但他们对应的router是相同，我看看会怎么样：
	测试发现，生成代码成功，但启动服务出错，因为相同的router已经注册。由于action名称不同，生成的controller是两个，但他们对应的router是同一个，所以不行
* 同样的，资源不同，action相同时，也会出同样的错误。
* 也就是匹配的入口都是router，通过上下文来匹配，然后找到对应的action，再找对应的resource，然后定位对应的控制器、操作方法

### 总结
* add功能虽然简单，但也正因为简单，所以才能更好的理解它的功能。




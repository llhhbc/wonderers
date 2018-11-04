
+++
title = "fluentd使用说明"
description = "fluentd使用说明"
tags = [
    "kubernetes",
    "fluentd",
    "td-agent"
]
date = "2018-08-05T10:46:49+08:00"
categories = [
    "kubernetes",
]
+++


## fluentd配置说明
* 参考：https://docs.fluentd.org/v1.0/articles/filter-plugin-overview

### filter配置说明
* filter根据tag来匹配，可有多个filter对应同一个tag，处理按配置的顺序依次处理

筛选消息中包括cool的

```xml
<filter foo.bar>
  @type grep
  regexp1 message cool
</filter>
```

#### 目前自带的filter有4个

* filter_record_transformer  报文转换

语法格式：

```xml
<record>
  NEW_FIELD NEW_VALUE
</record>
```

tag的处理方法：

```ruby
//tag_parts[N] 表示tag的第N个部分
tag_prefix[0] = debug          tag_suffix[0] = debug.my.app
tag_prefix[1] = debug.my       tag_suffix[1] = my.app
tag_prefix[2] = debug.my.app   tag_suffix[2] = app
```


```xml
<filter foo.bar>
  @type record_transformer
  <record>
    hostname "#{Socket.gethostname}" #给报文增加两个域：hostname，tag
    tag ${tag}
    avg ${record["total"] / record["count"]}  ##增加一个avg域，计算报文中total和count的除数
    message yay, ${record["message"]}  ## 给message域增加个前缀
  </record>
</filter>
```

* filter_grep 报文筛选

```xml
<filter foo.bar>
  @type grep
  # 默认多个匹配之前是and的关系
  <regexp>  #只选择有cool的
    key message
    pattern cool
  </regexp>
  <regexp>  #按正则匹配hostname的
    key hostname
    pattern ^web\d+\.example\.com$
  </regexp>
  <exclude>   # 不能有uncool
    key message
    pattern uncool
  </exclude>
  <or>
  	#外面和这个是or的关系
  </or>
</filter>
```

* filter_parser 报文处理

```xml
<filter foo.bar>
  @type parser
  key_name message
  <parse>
    @type regexp
    expression /^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^ ]*) +\S*)?" (?<code>[^ ]*) (?<size>[^ ]*)$/
    time_format %d/%b/%Y:%H:%M:%S %z
  </parse>
</filter>
```

使用的正则匹配：
比如，apache的日志解析：

```
expression /^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^ ]*) +\S*)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?$/
time_format %d/%b/%Y:%H:%M:%S %z

#input
192.168.0.1 - - [28/Feb/2013:12:00:00 +0900] "GET / HTTP/1.1" 200 777 "-" "Opera/12.0"

#output
time:
1362020400 (28/Feb/2013:12:00:00 +0900)

record:
{
  "user"   : nil,
  "method" : "GET",
  "code"   : 200,
  "size"   : 777,
  "host"   : "192.168.0.1",
  "path"   : "/",
  "referer": nil,
  "agent"  : "Opera/12.0"
}



#匹配练习
expression /^(?<time1>[^\[]*)\[(?<level>[^\]]*)\] (I\[(?<i>[^\]]*)\] )?(N\[(?<node>[^\]]*)\] )?(G\[(?<gid>[^\]]*)\] )?(O\[(?<orderid>[^\]]*)\] )?(C\[(?<corder>[^\]]*)\] )?(S\[(?<sorder>[^\]]*)\] )?(T\[(?<t>[^\]]*)\] )?(A\[(?<a>[^\]]*)\] )?(F\[(?<file>[^\]]*)(.\]|\]\])? )?M\[(?<msg>[^$]*)/



"message":"2018/08/16 09:51:25.053236 [INFO] I[0] N[HTTPSSERVER] G[3434] O[] C[201808160022302] S[201808166883389] T[] F[httpsServer.go:150] M[交易处理完成]

里面针对了F后面会有两个[[]]的情况，还有可选标签A

正则测试工具：https://regex101.com/

```

* filter_stdout 调试输出

```xml
<filter pattern>
  @type stdout
</filter>
```







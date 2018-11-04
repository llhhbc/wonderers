
+++
title = "kuber log analysis"
description = "kuber log analysis"
tags = [
    "kubernetes",
    "fluentd",
]
date = "2018-08-05T10:46:49+08:00"
categories = [
    "kubernetes",
]
+++

## kubernetes日志管理

参考资料：https://logz.io/blog/kubernetes-log-analysis/

### 1. 安装fluentd

* 参考官方文档：https://docs.fluentd.org/v1.0/articles/install-by-rpm#redhat-/-centos

* td-agent是对fluentd的封装，并加入了管理工具，比如java有集成的应用包

```sh

curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent3.sh | sh

#启动td-agent
systemctl start td-agent

#安装td-agent es插件

sudo /usr/sbin/td-agent-gem install fluent-plugin-elasticsearch --no-document



```

### 2. 配置说明

* 配置td-agent： 备份 `/etc/td-agent/td-agent.conf`

```conf
## 增加一个测试的日志输入，用于测试解析日志并写入es
<source>
  @type http
  @id input_http
  port 42185
  tag http.test
</source>

# 配置将收到的日志输入到控制台
<match **>
  @type stdout
  @id output_stdout
</match>

# 配置将日志写入es
<match http.test>    #一个source的tag只会匹配一个match，有多个时，不会都匹配
  @type elasticsearch
  logstash_format true
  host localhost
  port 9200
  #hosts host1:port1,host2:port2,host3:port3
  # or
  #hosts https://customhost.com:443/path,https://username:password@host-failover.com:443
  index_name fluentd.${tag}.%Y%m%d
  ## 用%{}来限定，当用户名或密码有特殊符号时使用
  #hosts https://%{j+hn}:%{passw@rd}@host1:443/elastic/,http://host2
</match>

<system>
  log_level debug
</system>

```

* source标签定义了数据来源，类型type有两种，http和forward（对应tcp），
* tag是给数据加标签，在数据分类处理时，标签用于给数据归类
* match是根据匹配的标签，给数据做处理：type和对应的处理插件相关
* filter的使用和match功能相似，但filter是可以多个叠加，如果有3个filter，数据会依次经过这3个filter处理，得到最终的输出
* system里面定义的是配置参数，包括日志级别等
* label定义的是一套规则的集合，用于给source来使用，命名需要以@开头
* 匹配说明： `a.*`匹配a.b,但不匹配a.b.c， `a.**`匹配所有a开头的，{X,y,Z}匹配当中的任意一个

### 3. 测试服务配置

```sh
curl http://localhost:42185/debug.a? -d 'json={"a":"b"}'

#日志文件/var/log/td-agent/td-agent.log能看到对应输出：
#2018-08-06 18:14:51.434990526 +0800 debug.a: {"a":"b"}

curl http://localhost:42185/debug.a/b? -d 'json={"a":"b"}'
#2018-08-06 18:17:41.018904116 +0800 debug.a.b: {"a":"b"}


```

## 4. 本地文件监听配置

```conf
<source>
  @type tail
  @id input_tail
  path /var/log/a.log,/var/log/b.log,/var/log/msg/*.log
  pos_file /var/log/a.log.pos
  tag eslog.a
  from_encoding utf-8
  encoding utf-8
  <parse>
    @type none
  </parse>
</source>
```




+++
title = "es 入门"
description = "es 入门"
tags = [
    "elastic",
]
date = "2018-04-27T09:01:00+08:00"
categories = [
    "elastic",
]
esid="ISsjgGMB-LOJRgD483Td"
+++
### es安装
* 官网下载 es https://www.elastic.co/downloads/elasticsearch
```shell
unzip elasticsearch-6.2.4.zip
cd elasticsearch-6.2.4/config

#修改集群名字和端口,数据目录等
vi elasticsearch.yml

# 启动es
cd elasticsearch-6.2.4/bin
./elasticsearch

# 验证启动状态
curl http://127.0.0.1:9200
```
### 安装中文分词
> 参考 https://github.com/medcl/elasticsearch-analysis-ik

> ./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.2.4/elasticsearch-analysis-ik-6.2.4.zip


### es简单使用
#### 创建一个index mapping（相当于一个表）
```shell
curl -XPUT 'localhost:9200/wonderbook?pretty' -H 'Content-type:application/json' -d '
{
"mappings": {
	"articles": {
	"properties": {
	"title": {"type" : "text", "analyzer": "ik_max_word", "search_analyzer": "ik_max_word"},
	"description": {"type" : "text", "analyzer": "ik_max_word", "search_analyzer": "ik_max_word"},
	"tags": {"type" : "text", "analyzer": "ik_max_word", "search_analyzer": "ik_max_word"},
	"date": {"type" : "date"},
	"categories": {"type" : "text", "analyzer": "ik_max_word", "search_analyzer": "ik_max_word"},
	"context": {"type" : "text", "analyzer": "ik_max_word", "search_analyzer": "ik_max_word"}
}
}
}
}
'

```


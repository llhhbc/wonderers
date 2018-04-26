
+++
title = "Learn markdown"
description = "学习markdown格式的使用"
tags = [
    "markdown"
]
date = "2018-04-25T12:02:28+08:00"
categories = [
    "learning"
]
+++

#### 标题
* 利用=（最高阶标题） 和 - （第二阶标题）
* 在行首插入1到6个#，对应标题1到6阶

#### 区块使用
* 在每行前面，或者段落最前面加上> 表示区块引用,如：

> aa

>> aa dsafas

#### 列表
* 用星号、加号或减号来表示无序列表
* 用数字加英文句点（不在乎数字是几）表示有序列表，数字会重新自动生成

#### 代码区块
* 缩进4个空格或者一个制表符，就是代码区块
* 如果段内有一小段代码，可以用\`号包起来，如 

```
printf();
```

* 如果代码中也有\`号，可以用多个来标记开始和结束如： 

``` 
printf("`");
```

* 引用一段代码, 如：引用部分c++代码

``` c++
int a=1;
int b=2;
int c= a+b;
```

#### 分隔线
* 在一行中用3个以上的星号、减号、底线来建立一个分隔线

#### 链接
* 链接文字用[方括号]来标记，后面紧接着用圆括号闰插入网上链接 如：[test link](http://localhost:1313/)
* 链接标记： 两个方括号 [test link][linkID]  前一个是链接文字，后一个是标记，然后在后面标记这个id
[linkID]: http://localhost:1313/  "my test link"

#### 强调
* 使用星号、底线 作为标志强调字词的符号 （用一个*或_包围的字词会转成EM标签，用两个会转成strong
*this is em*  **this is strong**

#### 图片
* 添加图片 `![Alt text](/path/to/img.jpg "this is Optional")` ![Alt text](/path/to/img.jpg "this is Optional")
* 也可用链接的那种id方式：`![Alt text][linkId]` ![Alt text][linkId]

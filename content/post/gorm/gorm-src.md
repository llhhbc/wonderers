+++
title = "gorm源码分析"
description = "gorm源码分析"
tags = [
    "golang",
    "gorm"
]
date = "2018-06-27T20:01:00+08:00"
categories = [
    "golang",
]
+++

## 总体分析
> 使用gorm的过程中，觉得它写的有意思，想了解下它的实现原理，所以就分析下源代码

## 源码分析
> 由于这个是个库，并没有执行程序，看到目录下有main.go，所以就从这个开始

1. main

> 定义了DB结构：

```golang
Value //是接口类型，可放任何数据
Error //是记录错误
RowsAffected //记录生效行数

//单个db私有属性
db  //定义的公共接口（Exec，Prepare，Query，QueryRow）  
	//暂时不明白为什么选这4个，从open中可看出，go标准库中的sql.DB是实现了这个接口的
blockGlobalUpdate  //记录全局更新标志
			//从BlockGlobalUpdate函数中可看出，这个标志为true时，update或者delete没有where时，会报错
logMode  //日志开关  2打开，1关闭
logger   //自定义日志接口(print)
search   //search结构指针（用来拼接sql语句的）
values   //map[string]interface{} 可保存任何东西的map，暂时不知道要保存什么

//全局db属性
parent //父DB对象
callbacks  //回调结构指针（记录了creates,updates,deletes,queries,rowQueries,processors类型的回调函数切片）
dialet  //sql格式化接口（针对不同的数据库定制化的差异）
singularTable  //bool类型，暂时不知道干什么的
```

> open函数，调用go标准库打开数据库连接，设置默认日志，默认回调函数，并根据数据库连接类型，设置sql格式对象，并调用ping测试连接

> 后面就是一些DB的常规set和get方法，还有就是拼接sql的方法
* 通过set函数，可以看到，values里面保存的单个db中的修改化配置，clone的时候会复制过去，不是共用

> main 大致过了一遍，对整个有点了解，再回看目录下的文件：
>
    1. association 处理表关系的，针对外键
    2. callback 开头的文件，处理回调函数的（等会重点看的）
    3. dialect 开头的文件，处理各种数据库之前语法差异的
    4. errors 定义了错误管理，所有的错误都在切片中
    5. interface 定义了公共类的接口
    6. join_table_handler 定义了n*n的表的关系接口
    7. logger 定义了默认日志打印
    8. scope 数据库操作的作用域管理
    9. search sql语句管理
    10. utils 基本工具类

2. callback

> CallbackProcessor中记录了所有回调函数的信息，然后排好序后，分类分别放到各个切片中

> 通过查看回调，我发现，callback中的回调，并不是真的实现的地方，只是将回调分类、排序（还包括一些配置检查），然后通过scope.CallMethod来调用真正的回调实现函数

3. scope

> 由于通过callback中可看到，回调在scope中实现，所以转而先看scope, scope中定义了当前操作信息

```golang
func (scope *Scope) callMethod(methodName string, reflectValue reflect.Value) {
	// Only get address from non-pointer
	if reflectValue.CanAddr() && reflectValue.Kind() != reflect.Ptr {
		reflectValue = reflectValue.Addr()
	}

	if methodValue := reflectValue.MethodByName(methodName); methodValue.IsValid() {
		switch method := methodValue.Interface().(type) {
		case func():
			method()
		case func(*Scope):
			method(scope)
		case func(*DB):
			newDB := scope.NewDB()
			method(newDB)
			scope.Err(newDB.Error)
		case func() error:
			scope.Err(method())
		case func(*Scope) error:
			scope.Err(method(scope))
		case func(*DB) error:
			newDB := scope.NewDB()
			scope.Err(method(newDB))
			scope.Err(newDB.Error)
		default:
			scope.Err(fmt.Errorf("unsupported function %v", methodName))
		}
	}
}
```
* 看着这个函数，我大慨了解了，它把一个结构体当成了一个有许多函数的容器，通过反射和名字，去调用这个容器中的函数，虽然函数模型就这几个，但是已经很全面了，而这个容器，是在创建scope的时候传入的
* 为了知道scope创建的时候，传入的是什么，我再看db的创建，发现没有，再看使用过程，比如查一条sql：db.First(&aa) 发现first中，把aa作为创建scope的传入参数了。但是aa并没有它定义的那些回调方法，这就很奇怪了
* 我想起更新表的时候，会自动设置时间辍：
```golang
func updateTimeStampForUpdateCallback(scope *Scope) {
	if _, ok := scope.Get("gorm:update_column"); !ok {
		scope.SetColumn("UpdatedAt", NowFunc())
	}
}
```
* 所以我决定跟踪这个函数的情况
```golang
DefaultCallback.Update().Register("gorm:update_time_stamp", updateTimeStampForUpdateCallback)
```
* 整个工程下，就只有这一处用了
* 然后，我想到，在创建DB对象的时候，DefaultCallback已经存到DB中了，于是我去查DB的callback变量的使用情况
```golang
func (s *DB) Updates(values interface{}, ignoreProtectedAttrs ...bool) *DB {
	return s.clone().NewScope(s.Value).
		Set("gorm:ignore_protected_attrs", len(ignoreProtectedAttrs) > 0).
		InstanceSet("gorm:update_interface", values).
		callCallbacks(s.parent.callbacks.updates).db
}
```
* 通过查询callbacks变量的使用，我再结合Updates的编写（因为我知道更新的时候会触发回调：设置时间），发现，库自带的回调是通过callCallbacks来调用的，他们有统一的一个方法头： `f(scope *Scope)`， 而上面看的callMethod，确实是由我们使用者自己定义的，所以我调用First(&aa)，它把aa作为scope创建的传入参数，完全是正常的。只是这个预留给我们自定义的回调，从来没用过。系统的回调两个之前不冲突，完全分离了。
* 下面这个是我模仿回调中的例子，自己写的自定义回调，由于我的时间列名和库自带的不相同，所以我自己写了这个回调，会在创建之前自动调用

```golang
func (t *DbBase) BeforeCreate(scope *gorm.Scope) (err error) {
	log.Debug("get in BeforeCreate")
	scope.SetColumn("RecUpdTs", time.Now().UTC())
	scope.SetColumn("RecCrtTs", time.Now().UTC())
	return nil
}
```
* 回调函数名称，在文档 `http://gorm.book.jasperxu.com/callbacks.html`中有明确说明：

```golang
//****创建
// begin transaction 开始事物
BeforeSave
BeforeCreate
// save before associations 保存前关联
// update timestamp `CreatedAt`, `UpdatedAt` 更新`CreatedAt`, `UpdatedAt`时间戳
// save self 保存自己
// reload fields that have default value and its value is blank 重新加载具有默认值且其值为空的字段
// save after associations 保存后关联
AfterCreate
AfterSave
// commit or rollback transaction 提交或回滚事务

//****更新
// begin transaction 开始事物
BeforeSave
BeforeUpdate
// save before associations 保存前关联
// update timestamp `UpdatedAt` 更新`UpdatedAt`时间戳
// save self 保存自己
// save after associations 保存后关联
AfterUpdate
AfterSave
// commit or rollback transaction 提交或回滚事务

//****删除
// begin transaction 开始事物
BeforeDelete
// delete self 删除自己
AfterDelete
// commit or rollback transaction 提交或回滚事务

//****查询
// load data from database 从数据库加载数据
// Preloading (edger loading) 预加载（加载）
AfterFind

//****高级用法
//如果想替换库自带的回调，可能通过：
db.Callback().Create().Replace("gorm:create", newCreateFunction)
// 使用新函数`newCreateFunction`替换回调`gorm:create`用于创建过程

//如果要自定义回调函数
db.Callback().Create().Before("gorm:create").Register("update_created_at", updateCreated)
//在callback_system_test.go 中有很多的关于回调函数测试的例子，当然，这里的函数只有一个原型： f(s *Scope)，也就是用callCallbacks来调用的。

```

> 作用域就像一个大的上下文，每个作用域之前，只有db的数据库连接是共用的，其它都是各自独立的。等会看完search，我想再和它比较下。作用域里面，定义的是列、属性、表名、引号等的处理，还有语句的执行、变量的替换、防sql注入。search作为scope的成员，所有的信息在scope这汇聚，然后去完成相应的功能。

4. search

> search比较简单，它是个信息收集模块，所有的函数调用都会再返回自身，而错误都通过db.AddError来管理。有一点要注意，search的clone，虽然创建的是新的search对象，但里面的切片、指针、map都原样拷贝，是对应的同一个地址，修改的时候是一起生效，只有基本类型（表名）会不同

5. dialet

> dialet针对不同的数据库，对接口做了不同的实现，在打开数据库连接的时候，根据数据库类型做初始化




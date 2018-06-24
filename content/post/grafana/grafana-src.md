
+++
title = "grafana源码学习"
description = "grafana源码学习"
tags = [
    "go",
    "golang",
    "grafana",
    "development",
]
date = "2018-04-25T12:02:28+08:00"
categories = [
    "Development",
    "golang",
    "grafana",
]
+++

## grafana学习

### 1.整体流程了解
#### grafana-server(从main开始)
1. 根据profile标志判断是否开启pprof
1. 初始化版本、时间缀信息
1. 初始化metrics包的版本信息
	* 在prometheus 中记录版本值1

1. 创建grafanaServer
	1. init加载的清单
		1. api
			1. 通过registry.RegisterService注册http服务：HTTPServer
		1. log
			1. 创建根root日志对象
		1. login
			1. 在bus上注册句柄："auth", UpsertUser  扩展用户管理
		1. setting
			1. 记录系统标志（是否是windows）

		1. extensions
			1. errors 引入github.com/pkg/errors包，在出错时，会记录栈信息，还有详细的函数信息
		1. metrics
			1. 初始化prometheus统计变量
		1. plugins
			1. 通过registry.RegisterService注册插件管理器：PluginManager
			```
				type Service interface {
					Init() error
				}
			```
			所有的插件都实现这个接口
			1. 在bus上注册句柄："plugins"：ImportDashboard
			1. 在bus上注册事件监听：handlePluginStateChanged

		1. services/alerting
			1. 在bus上注册句柄："alerting", updateDashboardAlerts
			1. 在bus上注册句柄："alerting", validateDashboardAlerts
			1. 通过registry.RegisterService注册告警服务：AlertingService
			1. 在bus上注册句柄："alerting", handleNotificationTestCommand
			1. 在bus上注册句柄："alerting", handleAlertTestCommand

		1. services/cleanup
			1. 注册清理服务：CleanUpService
		1. services/notifications
			1. 注册通知服务：NotificationService
		1. services/provisionint
			1. 注册供给服务：ProvisioningService （提供界面和数据源）
		1. services/renderint
			1. 注册展现服务：RenderingService （插件展示，phantomjs的调用）
		1. services/search
			1. 注册搜索服务：SearchService 
			> 搜索有它自己的专有bus
			1. 在专有bus上注册句柄：searchHandler 用于搜索显示面板
		1. services/sqlstore
			1. 以高优先级方式注册数据库管理服务：SqlStore （用xorm来管理数据库连接）
			> alert类句柄
			1. 在bus上注册句柄： "sql", SaveAlerts
			1. 在bus上注册句柄： "sql"：HandleAlertsQuery
			1. 在bus上注册句柄： "sql"：GetAlertById
			1. 在bus上注册句柄： "sql"：GetAllAlertQueryHandler
			1. 在bus上注册句柄： "sql"：SetAlertState
			1. 在bus上注册句柄： "sql"：GetAlertStatesForDashboard
			1. 在bus上注册句柄： "sql"：PauseAlert
			1. 在bus上注册句柄： "sql"：PauseAllAlerts
			> ntoi类句柄
			1. "sql", GetAlertNotifications
			1. "sql", CreateAlertNotificationCommand
			1. "sql", UpdateAlertNotification
			1. "sql", DeleteAlertNotification
			1. "sql", GetAlertNotificationsToSend
			1. "sql", GetAllAlertNotifications
			> apikey类句柄
			1. "sql", GetApiKeys
			1. "sql", GetApiKeyById
			1. "sql", GetApiKeyByName
			1. "sql", DeleteApiKey
			1. "sql", AddApiKey
			> 面板类句柄
			1. "sql", SaveDashboard
			1. "sql", GetDashboard
			1. "sql", GetDashboards
			1. "sql", DeleteDashboard
			1. "sql", SearchDashboards
			1. "sql", GetDashboardTags
			1. "sql", GetDashboardSlugById
			1. "sql", GetDashboardUIDById
			1. "sql", GetDashboardsByPluginId
			1. "sql", GetDashboardPermissionsForUser
			1. "sql", GetDashboardsBySlug
			1. "sql", ValidateDashboardBeforeSave
			1. "sql", HasEditPermissionInFolders
			> 面板权限类句柄
			1. "sql", UpdateDashboardAcl
			1. "sql", GetDashboardAclInfoList
			> 面板数据供给类句柄
			1. "sql", GetProvisionedDashboardDataQuery
			1. "sql", SaveProvisionedDashboard
			1. "sql", GetProvisionedDataByDashboardId
			> 面板快照类句柄
			1. "sql", CreateDashboardSnapshot
			1. "sql", GetDashboardSnapshot
			1. "sql", DeleteDashboardSnapshot
			1. "sql", SearchDashboardSnapshots
			1. "sql", DeleteExpiredSnapshots
			> 面板版本类句柄
			1. "sql", GetDashboardVersion
			1. "sql", GetDashboardVersions
			1. "sql", DeleteExpiredVersions
			> 数据源类句柄
			1. "sql", GetDataSources
			1. "sql", GetAllDataSources
			1. "sql", AddDataSource
			1. "sql", DeleteDataSourceById
			1. "sql", DeleteDataSourceByName
			1. "sql", UpdateDataSource
			1. "sql", GetDataSourceById
			1. "sql", GetDataSourceByName
			> 数据库健康检查类句柄
			1. "sql", GetDBHealthQuery
			> 登录尝试类句柄
			1. "sql", CreateLoginAttempt
			1. "sql", DeleteOldLoginAttempts
			1. "sql", GetUserLoginAttemptCount
			> 组织类句柄
			1. "sql", GetOrgById
			1. "sql", CreateOrg
			1. "sql", UpdateOrg
			1. "sql", UpdateOrgAddress
			1. "sql", GetOrgByName
			1. "sql", SearchOrgs
			1. "sql", DeleteOrg
			> 组织用户句柄
			1. "sql", AddOrgUser
			1. "sql", RemoveOrgUser
			1. "sql", GetOrgUsers
			1. "sql", UpdateOrgUser
			> 播放类句柄
			1. "sql", CreatePlaylist
			1. "sql", UpdatePlaylist
			1. "sql", DeletePlaylist
			1. "sql", SearchPlaylists
			1. "sql", GetPlaylist
			1. "sql", GetPlaylistItem
			> 插件管理类句柄
			1. "sql", GetPluginSettings
			1. "sql", GetPluginSettingById
			1. "sql", UpdatePluginSetting
			1. "sql", UpdatePluginSettingVersion
			> 偏爱类句柄
			1. "sql", GetPreferences
			1. "sql", GetPreferencesWithDefaults
			1. "sql", SavePreferences
			> 限额控制类句柄（控制组织、用户限额）
			1. "sql", GetOrgQuotaByTarget
			1. "sql", GetOrgQuotas
			1. "sql", UpdateOrgQuota
			1. "sql", GetUserQuotaByTarget
			1. "sql", GetUserQuotas
			1. "sql", UpdateUserQuota
			1. "sql", GetGlobalQuotaByTarget
			>  测试类
			1. "sql", InsertSqlTestData
			> 评分类句柄
			1. "sql", StarDashboard
			1. "sql", UnstarDashboard
			1. "sql", GetUserStars
			1. "sql", IsStarredByUser
			> 状态类句柄
			1. "sql", GetSystemStats
			1. "sql", GetDataSourceStats
			1. "sql", GetDataSourceAccessStats
			1. "sql", GetAdminStats
			1. "sql", GetSystemUserCountStats
			> 队类句柄
			1. "sql", CreateTeam
			1. "sql", UpdateTeam
			1. "sql", DeleteTeam
			1. "sql", SearchTeams
			1. "sql", GetTeamById
			1. "sql", GetTeamsByUser

			1. "sql", AddTeamMember
			1. "sql", RemoveTeamMember
			1. "sql", GetTeamMembers
			> 临时用户类句柄
			1. "sql", CreateTempUser
			1. "sql", GetTempUsersQuery
			1. "sql", UpdateTempUserStatus
			1. "sql", GetTempUserByCode
			1. "sql", UpdateTempUserWithEmailSent
			> 用户类句柄
			1. "sql", CreateUser
			1. "sql", GetUserById
			1. "sql", UpdateUser
			1. "sql", ChangeUserPassword
			1. "sql", GetUserByLogin
			1. "sql", GetUserByEmail
			1. "sql", SetUsingOrg
			1. "sql", UpdateUserLastSeenAt
			1. "sql", GetUserProfile
			1. "sql", GetSignedInUser
			1. "sql", SearchUsers
			1. "sql", GetUserOrgList
			1. "sql", DeleteUser
			1. "sql", UpdateUserPermissions
			1. "sql", SetUserHelpFlag
			> 用户权限类句柄
			1. "sql", GetUserByAuthInfo
			1. "sql", GetAuthInfo
			1. "sql", SetAuthInfo
			1. "sql", DeleteAuthInfo

		1. tracing
			* 注册跟踪 ：TracingService

	1. 创建根上下文
	1. 创建childRoutines组，组上下文
	1. 创建grafanaServerImpl对象
1. 创建协程监听信号
1. 启动服务
	1. 加载全局配置信息
	1. 如果设置pid文件，则写入pid进程信息
	1. 注册权限句柄 AuthenticateUser， 初始化LDAP目录配置
	1. 初始化OAuther 第三方登录服务
	1. 创建一个图（对象注入图）
	1. 图中添加总线bus、配置cfg、路由中间件
	1. 获取所有registry中的服务清单
	1. 将所有服务，并注入图中
	1. 将grafanaServer注入图中
	1. 完成图的初始化（初始化所有对象，包括信赖的对象）
	1. 调用所有服务的Init方法来初始化所有服务
	1. 后台运行所有实现了后台服务接口 registry.BackgroundService{ Run(ctx context.Context) error} 的服务（调用Run方法），统一管理在childRoutines组中

	1. 发送系统状态通知（启动成功）
	1. 等待所有子协程执行
1. 停止trace（保证trace能正常写入文件）
1. 关闭日志
1. 服务退出

##### 总结
> 启动过程中所看到的代码，都是在pkg目录下的，主要有如下：（按程序中引入包的顺序来）
1. bus 
	设计很独特的bus结构，可以在上面挂载功能函数，分3种：不带上下文函数、带上下文函数、监听函数。各个模块提前将功能注册后，根据调用的函数类型来自动调用对应的函数，而监听函数是会在触发监听后全部调用
1. middleware
	请求拦截器管理，实现了：macaron.Handler，用于登录拦截、权限拦截等
1. registry
	服务注册包，用于提供服务统一注册
1. api
	http服务在这里注册，包括路由、登录、页面展示、用户管理等
1. log
	日志库的管理，以log15为原型，在这个基础上对日志做了封装
1. login
	登录模块的管理，包括扩展用户的管理
1. setting
	程序加载的配置文件管理，用到的配置都从这管理
1. social
	第三方授权登录的管理
1. extensions
	做的扩展，主要是针对error库，将错误时候，带上错误的堆栈信息，更好的跟踪错误
1. metrics
	统计信息管理，主要是prometheus统计信息初始化
1. plugins
	注册插件管理器
1. services/alerting
	管理警告模块，在监控设置中，管理触发的警告
1. services/cleanup
	服务清理，清理临时文件、其它的快照、过期的组件版本、过期的登录临时文件
1. services/notifications
	通知服务管理，管理邮件通知等功能，还包括通过邮件重置密码功能
1. services/provisioning
	供给服务，提供页面和数据库源信息
1. services/rendering
	展现服务，提供页面的渲染
1. services/search
	提供组件搜索功能
1. services/sqlstore
	数据库数据库源管理
1. tracing
	程序性能跟踪

> 代码总结
* 通过整体启动流程的梳理，对grafana的整体有了一个大慨的了解：
* 通过bus来管理所有的服务和事件，各个服务之前，也是通过bus来相互沟通。

#### 服务分析
* 从前面可看出，所有的注册都是通过 registry.RegisterService来注册的，我为了验证服务是否有遗漏，我在这个函数中增加了一行输出：
```fmt.Println("registry:", reflect.TypeOf(instance))```， 我自己编译运行，能看到如下输出：
```shell
registry: *search.SearchService
registry: *plugins.PluginManager
registry: *metrics.InternalMetricsService
registry: *rendering.RenderingService
registry: *alerting.AlertingService
registry: *api.HTTPServer
registry: *cleanup.CleanUpService
registry: *notifications.NotificationService
registry: *provisioning.ProvisioningService
registry: *tracing.TracingService
```
> 以程序输出的服务清单为索引，也了解各个服务的功能(都实现了接口registry.Service和registry.BackgroundService)，所以从Init和Run方法入手

##### search.SearchService 搜索服务
> search在Init中在专用bus上注册了搜索句柄，用于搜索面板信息
> 由于search服务未实现Run，所以无运行内容

##### plugins.PluginManager 插件管理服务
> Init
	1. 初始化日志对象
	1. 扫描项目目录app/plugins,加载所有插件
		根据插件类型寻找相应的加载器，加载插件配置
	1. 遍历所有面板插件，完成初始化
	1. 遍历所有数据源插件，完成初始化
	1. 遍历所有app插件，完成初始化
> Run
	1. 遍历所有面板，将需要后台启动的启动
	1. 检查新加载的插件和系统中的存量插件版本是否不同，如果不同则更新为新加载的
	1. 如果配置了检查更新，则访问官网，检查插件版本
	1. 每10分钟尝试一次，更新插件信息
	1. 收到退出信号（ctx完成），关闭所有后台运行的插件
	1. 服务退出

##### metrics.InternalMetricsService 性能参数收集
> Init
	1. 从cfg中按section为metrics读取配置信息
	1. 加载图表配置信息
> Run
	1. 如果图表配置信息不为空，则根据图表配置构建一个桥梁（完成Prometheus参数到图表中的数据交互）， 启动这个桥梁，按配置的间隔时间，推送参数指标
	1. 启动参数指标统计
	1. 调用bus上的参数指标查询函数，查询参数指标：面板、总用户、在线用户、总组织 （首次更新）
	1. 之后每分钟更新一次参数指标，每24小时上报一次参数指标（匿名上报给grafana，如果设置不上报，则不会上报）

##### rendering.RenderingService 页面渲染
> Init
	1. 初始化rs专用日志
> Run
	1. 如果配置RendererUrl，则支持远端生成页面（相当于页面代理）
	1. 如果插件中页面渲染未配置，则用默认的phantomJS
	1. 启动页面渲染插件，插件和主服务之前，通过rpc来通讯
	1. 每一秒检查一次，如果插件退出，则重新启动

##### alerting.AlertingService 警报服务
> Init
	1. 创建时钟
	1. 创建执行队列（1000个）
	1. 创建调试器
	1. 创建评价句柄
	1. 创建规则解析
	1. 创建alert日志
	1. 创建结果渲染服务
> Run
	1. 创建一个routine组
	1. 组内运行时钟
		1. 当收到10次心跳后，从规则解析中取出所有报警规则，将规则放到调度器中
		1. 调度任务，将任务按情况放到执行队列中（按经常性、是否已报警过等）
	1. 组内运行任务分发
		1. 从队列中取出任务，执行
	1. 等待执行结束

##### api.HTTPServer 主服务
> Init
	1. 初始化http服务日志
	1. 创建gocache（默认保存5分钟，每10分钟清理一次）
> Run
	1. 记录主上下文
	1. 创建流管理器
	1. 创建macaron（http路由管理）
		1. 加载所有插件的静态文件目录
		1. 加载主静态目录 public/build
		1. 加载主目录 public
		1. 加载robots.txt
		1. 如果图片上传设置为本地，则加载图片目录，默认为 public/img/attachments
		1. 设置主渲染器：静态目录为views，测试会生成json结构
		1. 注册心跳处理句柄 /api/health
		1. 注册性能参数句柄：/metrics
		1. 注册一般性检查句柄
			1. 检查renderKey合法性
			1. 检查Authorization 合法性
			1. 根据Authorization检查基本权限
			1. 如果设置了权限代理，则检查权限代理
			1. 检查用户会话id
			1. 允许匿名登录的话，检查匿名用户
			1. 初始化上下文日志
			1. 每5分钟更新一次用户会话场景
		1. 注册session超时管理句柄
		1. 根据orgId做组织重定向
		1. 如果配置了主机检查，注册主机检查句柄
		1. 注册默认应答head设置句柄（设置api请求和get请求的应答head参数）
	1. 注册初始路由  ----
	1. 启动流管理器  ----
	1. 创建http监听（支持http，https，socket）

##### cleanup.CleanUpService 清理服务
> Init
	1. 初始化清理日志
> Run
	1. 首次清理临时文件
	1. 创建心跳，10分钟一次
	1. 每10分钟清理一次临时文件、过期的快照、过期的面板版本、旧的用户日志

##### notifications.NotificationService 通知服务
> Init
	1. 初始化通知日志
	1. 创建消费队列（10个）
	1. 创建hook队列（10个）
	> 通知有它自己的专有bus，在专有bus上注册自己的句柄
		1. 专有bus上注册句柄：sendResetPasswordEmail
		1. 专有bus上注册句柄：validateResetPasswordCode
		1. 专有bus上注册句柄：sendEmailCommandHandler
		1. 专有bus上注册上下文句柄：sendEmailCommandHandlerSync
		1. 专有bus上注册上下文句柄：SendWebhookSync
		1. 专有bus上注册监听：signUpStartedHandler
		1. 专有bus上注册监听：signUpCompletedHandler
	1. 创建邮件发送模板
	1. 初始化邮件发送参数信息
> Run
	1. 从webhook中读取钩子，发送web请求
	1. 从邮件队列中读取邮件，发送邮件	

##### provisioning.ProvisioningService 供给服务
> Init
	1. 读取数据源配置，加载数据源
> Run
	1. 读取面板配置，加载面板信息
	1. 提供面板信息

##### tracing.TracingService 跟踪服务
> Init
	1. 初始化日志
	1. 加载配置信息
	1. 如果开启跟踪，则初始化全局跟踪
> Run
	1. 无（等待上下文退出）



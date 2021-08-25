---
title: CDH权限管理-Sentry
categories: Hadoop
tags: sentry
author: semon
date: 2021-06-21
---



# CDH集群权限管理

## Apache Sentry介绍

`Apache Sentry`是`Cloudera`公司发布的一个`Hadoop`开源组件，它提供了细粒度级、基于角色的授权及多租户管理模式。`Sentry`当前支持`Hive/HCatalog`、`Apache Solr`、`Impala`、`HDFS`及`Hbase`权限管理；

## Apache Sentry组件

Sentry的体系结构中有三个重要组件：`Binding`、`Policy Engine`及`Policy Provider`；

### `Binding`

`Binding`实现对不同的查询引擎授权，`Sentry`将自己的`Hook`函数插入到各`SQL`引擎的编译、执行阶段，这些`Hook`函数的作用为：

1. 过滤器：只放行具有相应数据对象访问权限的`SQL`查询；
2. 授权接管：通过执行引擎进行`grant/revoke`管理权限时，实际在`Sentry`中实现；

对于所有引擎的授权信息存储在`Sentry`设定的统一数据库中，实现权限的集中管理；

### `Policy Engine`

这是`Sentry`授权的核心组件，`Policy Engine`判断从`Binding`层获取的输入权限要求与服务体提供层以保存的权限描述是否匹配；

### `Policy Provider`

`Policy Provider`负责从文件或数据库中读取设定的访问权限，提供给`Policy Engine`进行鉴权匹配；

## CDH集群启用Sentry

### 安装`Sentry`组件

通过`CM`直接添加`Sentry`即可；（需提前创建`sentry`数据库）；

配置`Sentry`服务，搜索`sentry.service.admin.group`及`sentry.service.allow.connect`， 添加各服务同名用户至管理员列表（CDH默认以服务同名用户启动服务），

![image-20210621173202208](CDH权限管理/image-20210621173202208.png)

### `Sentry`集成

1. 在`Hive`配置中搜索`hive.server2.enable.doAs`，取消该配置勾选；

   ![image-20210621155829187](CDH权限管理/image-20210621155829187.png)

2. 在`Hive`配置中搜索`Enable Stored Notifications in Database`，启用该配置项；

   ![image-20210621160340622](CDH权限管理/image-20210621160340622.png)

3. 在`Hive`配置中搜索`sentry`，启用`Hive`集成`Sentry`；

   ![image-20210621160649210](CDH权限管理/image-20210621160649210.png)

4. 如需开启`Hive`列级权限控制，搜索`sentry-site.xml`，添加截图中K-V配置；

   ![image-20210621173814173](CDH权限管理/image-20210621173814173.png)

5. 在`Impala`配置中搜索`Sentry`，启用`Impala`集成`Sentry`;

   ![image-20210621161133818](CDH权限管理/image-20210621161133818.png)

5. 在`HDFS`中搜索`dfs.namenode.acls.enabled`,启用`acls`控制；

   ![image-20210621161721244](CDH权限管理/image-20210621161721244.png)

6. 在`HDFS`中搜索`sentry`，启用`sentry`同步；

   ![image-20210621161828535](CDH权限管理/image-20210621161828535.png)

7. 配置`YARN`服务，搜索`allowed.system.users`允许各服务同名账号提交任务至`YARN`上；

   ![image-20210621172609148](CDH权限管理/image-20210621172609148.png)

8. 配置`HUE`集成`Sentry`，搜索`Sentry`并勾选；

   ![image-20210621172804088](CDH权限管理/image-20210621172804088.png)

## 基于Hue使用Sentry授权

1. 待授权用户需在集群所有节点存在，如不存在，则需手动创建；

2. 在`Hue`中右上角选择管理用户，创建用户及组；

3. 点击左上角下拉菜单中`Security`创建`Role`并进行权限授予；

   ![image-20210621174417601](CDH权限管理/image-20210621174417601.png)
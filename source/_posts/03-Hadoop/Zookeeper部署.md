---
title: ZK介绍及使用
categories: Hadoop
tags: zookeeper
author: semon
date: 2021-04-27
---


#  ZK介绍

ZooKeeper诞生于Yahoo，后转入Apache孵化，最终孵化成Apache的顶级项目，是Hadoop和Hbase的重要组件。ZooKeeper是一种集中式服务，用于维护配置信息、命名、提供分布式同步和提供组服务。所有这些类型的服务都以分布式应用程序的某种形式使用。由于实现上述需求都需要做很多工作来修复不可避免的错误和竞争条件。因此，这些服务的实现变得非常困难，即使这些服务顺利完成，管理和运维的成本也非常高，所以zookeeper以救世主的身份出现，解决上述技术难题，降低了分布式应用程序的开发难度和工作量，让程序员专注于分布式架构的设计。

# ZK部署的三种模式

+ 独立部署模式：在单机上部署一个zookeeper服务，适用于学习、了解ZK基础功能；
+ 伪分布式模式：在单机上部署多个zookeeper服务，形成虚拟的分布式zk集群，适用于学习、开发及测试，不适用于生产环境；
+ 分布式模式：在多台主机上部署多个zookeeper服务，形成真正的分布式zk集群，可投入到生产环境使用；

# ZK应用场景

## 集群管理

+ 节点监控：集群环境下，服务不属于多个节点之上，当因为网络或节点主机故障导致服务无法工作时，为保证集群能够正常提供服务，就需要将异常节点从集群中屏蔽，这时候使用zk的短暂节点与watcher机制，即可很好的实现集群的管理；
+ Leader选举：集群多节点协同工作，需要一个总览全局的领导者来承担对外交互及内部任务分发等职责，zk可实现集群leader节点的选举及当前leader故障后及时重新选举；

## 配置管理

应用可通过配置文件实现灵活变更，但在分布式环境下，配置文件修改及同步也开始变得复杂繁琐，此时可通过zk进行配置文件管理，分布式应用统一从zk上读取配置信息；此外，利用zk的watcher机制，当检测到zk上配置发生变更后，zk可通知各个节点配置信息已修改，各节点可通过刷新获取最新配置信息；

# ZK下载及部署

```bash
# 下载软件包
wget https://downloads.apache.org/zookeeper/zookeeper-3.4.14/zookeeper-3.4.14.tar.gz

# 创建zk数据目录
mkdir zk_data

cd $ZOOKEEPER_HOME/conf

#配置zk  vi  zoo.cfg
# 定义访问ZK端口
clientPort=2181

# 定义zk 主从心跳检活限制次数
syncLimit=5

# zk自动清理日志，单位为小时
autopurge.purgeInterval=24

# zk自动清理保留文件数，默认为3
autopurge.snapRetainCount=3 

# 定义单客户端与单服务器最大连接数
maxClientCnxns=500

# 定义zk数据文件存储目录
dataDir=/mnt/data01/hadoop/zookeeper

# 服务启动时，从节点从主节点同步数据限制心跳次数
initLimit=10

# 定义zk中最小时间单元，单位为毫秒
tickTime=2000

# 定义zk服务器及通信、选举端口
# server.A=B:C:D   A为zk节点标签，由myid文件定义，B为主机名或IP，需与A保持一一对应，C为ZK节点间通讯端口  D为ZK选举端口
server.1=demo03.bigdata.163.com:2888:3888
server.2=demo04.bigdata.163.com:2888:3888
server.3=demo05.bigdata.163.com:2888:3888

# 定义ZK ACL检查类
authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider

# 定义验证授权刷新时间间隔
jaasLoginRenew=3600000

#定义kerberos认证相关
kerberos.removeHostFromPrincipal=true
kerberos.removeRealmFromPrincipal=true


cd $dataDir
# 根据配置文件定义服务器与IP关系配置myid
echo "1">myid


# 启动服务
$ZOOKEEPER_HOME/bin/zkServer.sh start
```



# ZK常用命令

```bash
# 链接指定zk服务器
bin/zkCli.sh -server ip:port

# 创建节点，-s表示顺序，-e表示临时，默认是持久节点，acl缺省表示不做任何权限限制
create -s -e path data [acl]    

# 查看节点目录
ls /

# 查看当前节点下的节点及当前节点的信息
ls2 /

# 删除节点，不能递归删除，只可以删除叶子节点
delete path

# 递归删除节点
rmr path

# 设置acl
setacl path auth:username:password:acl

# 查看acl
getacl path

# 退出
quit
```


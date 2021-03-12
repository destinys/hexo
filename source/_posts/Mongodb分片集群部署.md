---
title: Mongo分片集群部署
categories: Database
tags: mongo
author: semon
date: 2021-03-12
---



#  Mongodb 分片集群部署

mongodb可主要有四个组件：mongos、config、shard、replica set。

Mongos：数据库集群请求的入口，所有的请求都通过mongos进行协调，不需要在应用程序添加一个路由选择器，mongos自己就是一个请求分发中心，它负责把对应的数据请求请求转发到对应的shard服务器上。在生产环境通常有多mongos作为请求的入口，防止其中一个挂掉所有的mongodb请求都没有办法操作。

Config：顾名思义为配置服务器，存储所有数据库元信息（路由、分片）的配置。mongos本身没有物理存储分片服务器和数据路由信息，只是缓存在内存里，配置服务器则实际存储这些数据。mongos第一次启动或者关掉重启就会从 config 加载配置信息，以后如果配置服务器信息变化会通知到所有的 mongos 更新自己的状态，这样 mongos 就能继续准确路由。在生产环境通常有多个 config server 配置服务器，因为它存储了分片路由的元数据，防止数据丢失！

Shard：将数据库拆分，将其分散在不同的机器上的过程。将数据分散到不同的机器上，可以通过廉价PC集群模式替代昂贵服务器。基本思想就是将集合切成小块，这些块分散到若干片里，每个片只负责总数据的一部分，最后通过一个均衡器来对各个分片进行均衡（数据迁移）。

Replica set：副本集，通过副本集可实现数据读写分离；通过多副本模式实现数据冗余备份，提高了数据的可用性， 并可以保证数据的安全性。

Primary：承担副本集中数据写入工作；

Secondary：主要承担副本集中数据读取工作；

Arbiter：用于Primary异常时重新选主；作用类似zookeeper；



MongoDB的工作流程可以简单总结为：应用请求mongos对MongoDB进行增删改查请求，config存储MongoDB的元数据信息，并与mongos进行同步，shard存储MongoDB的主数据，为提高性能与安全性，Replica set实现多副本存储；



## MongoDB服务及架构

以三节点集群为例，每个节点需启动一个config、一个mongos及三个shard；

### 服务规划

| NodeA  | NodeB  | NodeC  |
| :----: | :----: | :----: |
| config | config | config |
| mongos | mongos | mongos |
| shard0 | shard0 | shard0 |
| shard1 | shard1 | shard1 |
| Shard2 | Shard2 | Shard2 |





### 端口规划

| 服务名 |       端口        |
| :----: | :---------------: |
| mongos |       20000       |
| config |       21000       |
| shard  | 27000/27001/27002 |



## MongoDB安装

### 安装包下载

通过官网下载所需版本压缩包，解压至规划路径，并添加环境变量；

```bash
# 下载压缩包
wget   http://downloads.mongodb.org/linux/mongodb-linux-x86_64-rhel70-v4.2-latest.tgz

# debian 
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian81-3.2.22.tgz
# 解压
gunzip mongodb-linux-x86_64-rhel70-v4.2-latest.tgz

# 添加环境变量至/etc/profile
export MONGODB_HOME=mongodb
export PATH=$PATH:$MONGODB_HOME/bin
source /etc/profile
```



### 目录创建

在每个节点上创建conf、auth、pid、logs、data/0、data/1、data/2、data/config目录

```bash
cd $MONGODB_HOME
mkdir -p conf auth pid logs data/0 data/1 data/2 data/config
```



### 配置文件生成

建议以下配置文件除keyfile外均生成三份，然后分发至各节点用于服务启动

```BASH
#生成keyfile

openssl rand -base64 753 >/usr/ndp/mongodb/auth/mongo-keyfile
chmod 600 /usr/ndp/mongodb/auth/mongo-keyfile
```



```yaml
# conf/config.yaml

systemLog:
  destination: file
  #日志存储位置
  path: "/usr/ndp/mongodb/logs/config.log"
  logAppend: true
storage:
  journal:
    enabled: true
  #数据文件存储位置
  dbPath: "/usr/ndp/mongodb/data/config"
  #是否一个库一个文件夹
  directoryPerDB: true
  #WT引擎配置
  wiredTiger:
    engineConfig:
      #WT最大使用cache（根据服务器实际情况调节）
      cacheSizeGB: 1
      #是否将索引也按数据库名单独存储
      directoryForIndexes: true
    #表压缩配置
    collectionConfig:
      blockCompressor: zlib
    #索引配置
    indexConfig:
      prefixCompression: true
#端口配置
net:
  bindIp: NodeA-ip  ################根据节点进行修改######################
  port: 21000
replication:
  oplogSizeMB: 2048
  replSetName: configs         ### 初始化时需与此处保持一致
sharding:
  clusterRole: configsvr
processManagement:
  fork: true
## 初始化时需注释掉一下安全相关配置
security:
  keyFile: /usr/ndp/mongodb/auth/mongo-keyfile
  authorization: enabled 
  
  
# conf/shard0.yaml
  
systemLog:
   destination: file
   path: "/usr/ndp/mongodb/logs/shard0.log"    # 日志文件名需根据分片同步变更
   logAppend: true
storage:
   journal:
      enabled: true
   dbPath: "/usr/ndp/mongodb/data/0"     # 数据文件路径需根据分片同步变更
processManagement:
   fork: true
net:
   bindIp: 0.0.0.0
   port: 27000                      ########不同分片对应端口需进行变更
setParameter:
   enableLocalhostAuthBypass: false
replication:
   replSetName: "rs0"  # 副本集跟随分片变更
sharding:
   clusterRole: shardsvr

## 初始化时需注释掉一下安全相关配置
security:
  keyFile: /usr/ndp/mongodb/auth/mongo-keyfile
  authorization: enabled


# conf/mongos.yaml
systemLog:
  destination: file
  path: "/usr/ndp/mongodb/logs/mongos.log"
  logAppend: true
net:
  bindIp: 10.173.32.226          ############根据启动服务节点IP进行修改
  port: 20000
# 将confige server 添加到路由
sharding:
	########### 以下列表为所有启动config服务的主机IP及对应端口
  configDB: configs/10.173.32.226:21000,10.173.32.227:21000,10.173.32.228:21000
processManagement:
  fork: true

## 初始化时需注释掉一下安全相关配置
security:
  keyFile: /usr/ndp/mongodb/auth/mongo-keyfile
```



### 启动服务

启动服务顺序为：config--> shard --> mongos

首先将每个节点的config服务全部启动，然后启动每个节点上的所有shard服务，最后启动mongos服务；

```bash
# config服务
# 每个节点启动一个服务，但需根据节点修改bindIp，启动所有节点config
mongod -f /usr/ndp/mongodb/conf/config.yaml


# shard服务
# 每个节点启动三个服务，不同服务需修改端口号
mongod -f /usr/ndp/mongodb/conf/shard0.yaml
mongod -f /usr/ndp/mongodb/conf/shard1.yaml
mongod -f /usr/ndp/mongodb/conf/shard2.yaml

#初始化副本集
mongo -port 27000
> rs.initiate( {
   _id : "rs0",
   members: [
      { _id: 0, host: "10.173.32.226:27000" },
      { _id: 1, host: "10.173.32.227:27000" },
      { _id: 2, host: "10.173.32.228:27000" }
   ]
})

mongo -port 27001
> rs.initiate( {
   _id : "rs1",
   members: [
      { _id: 0, host: "10.173.32.226:27001" },
      { _id: 1, host: "10.173.32.227:27001" },
      { _id: 2, host: "10.173.32.228:27001" }
   ]
})

mongo -port 27002
rs.initiate( {
   _id : "rs2",
   members: [
      { _id: 0, host: "10.173.32.226:27002" },
      { _id: 1, host: "10.173.32.227:27002" },
      { _id: 2, host: "10.173.32.228:27002" }
   ]
})

# 配置服务器初始化
mongo -port 21000 -host NodeA-ip  # 需与配置文件保持一致，同为IP或主机名
> rs.initiate( {
   _id : "configs",
   configsvr: true,
   members: [
      { _id: 0, host: "10.173.32.226:21000" },
      { _id: 1, host: "10.173.32.227:21000" },
      { _id: 2, host: "10.173.32.228:21000" }
   ]
})

# mongos服务
# 每个节点启动一个服务，但需根据节点修改bindIp
mongos -f /usr/ndp/mongodb/conf/mongos.yaml


# 添加分片
mongo -port 20000 -host 10.173.32.226
> use admin
> db.runCommand( { addshard:"rs0/10.173.32.226:27000,10.173.32.227:27000,10.173.32.228:27000",name:"shard0"} )

> db.runCommand( { addshard:"rs1/10.173.32.226:27001,10.173.32.227:27001,10.173.32.228:27001",name:"shard1"} )

> db.runCommand( { addshard:"rs2/10.173.32.226:27002,10.173.32.227:27002,10.173.32.228:27002",name:"shard2"} )
 
> db.runCommand( { enablesharding : "testdb" } )
> db.runCommand( { shardcollection : "testdb.users",key : {id: 1} } )

# 测试数据
mongo -port 20000 -host 10.173.32.226
> var arr=[];
for(var i=0;i<20000;i++){
var uid = i;
var name = "mongodb"+i;
arr.push({"id":uid,"name":name});
}

db.users.insertMany(arr);

# 添加身份认证
use admin
db.createUser({user: "admin",pwd: "mongodb",roles: [ { role: "root", db: "admin" } ]}) #root所有权限
db.auth("admin","mongodb")

#创建用户
#用户是分DB的，在哪个db下创建，就是该db专有用户
use metahub_lineage
db.createUser({user: "metahub",pwd: "metahub",roles: [ { role: "readWrite", db: "metahub_lineage" } ]})

# 创建集合
db.createCollection("metahub_task_lineage_msg_v2") 


# 带身份认证登陆mongo
 mongo --host 10.173.32.226 --port 20000  -u "metahub" -p "metahub" --authenticationDatabase "metahub_lineage"
```



### 关闭服务

服务关闭顺序为 mongos --> config --> shard

mongos为无状态服务，可直接通过kill -9进行终止服务；

config服务：`mongod --shutdown -f /usr/ndp/mongodb/conf/config.yaml`

shard服务：`mongod --shutdown -f /usr/ndp/mongodb/conf/shard0.yaml`



### 滚动日志

```bash
mongod_pid=`ps aux|grep mongo |grep -v grep|grep config|awk '{ print $2}'`
kill -SIGUSR1 mongod_pid
```


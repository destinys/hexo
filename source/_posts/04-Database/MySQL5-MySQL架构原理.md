---
title: MySQL架构原理
categories: Database
tags: mysql
author: semon
date: 2021-08-24
---

# MySQL体系架构

<img src="MySQL5-MySQL架构原理/image-20210824220653235.png" alt="MySQL体系架构" style="zoom:80%;" />

MySQL Server架构自顶向下大致可以分为网络连接层、服务层、存储引擎层和系统文件层；

## 网络连接层

客户端连接器（Client Connectors）：提供与MySQL服务器建立的支持；目前几乎支持所有主流的服务端编程技术，例如常见的Java、C、Python、.NET等，它们通过各自API技术与MySQL建立连接；

## 服务层（MySQL Server）

服务层是MySQL Server的核心，主要包含系统管理和控制工具、连接池、SQL接口、解析器、查询优化器和缓存六部分；

+ 系统控制与管理工具（Management Services & Utilities）：用于备份恢复、安全管理、集群管理等；
+ 连接池（Connection Pool）：负责存储和管理客户端与数据库的连接，一个线程负责管理一个链接；
+ SQL接口（SQL Interface）：用于接收客户端发送的各种SQL命令，并且返回用户需要查询的结果；如DML、DDL、存储过程、视图、触发器等；
+ 解析器（Parser）：负责将请求的SQL解析生成一个“解析树”；然后根据一些MySQL规则进一步检查解析树是否合法；
+ 查询优化器（Optimizer）：当“解析树”通过解析器语法检查后，将交由优化器将其转化成执行计划，然后与存储引擎交互；
+ 缓存（Cache & Buffer）：缓存机制是由一系列小缓存组成的；比如表缓存、记录缓存、权限缓存、引擎缓存等；如果查询缓存有命中的查询结果，查询语句就可以直接去查询缓存中取数据；

## 存储引擎层（Pluggable Storage Engines）

存储引擎负责MySQL中数据的存储与提取，与底层文件系统进行交互；MySQL存储引擎是插件式的，服务器中的查询执行引擎通过接口与存储引擎进行通信，接口屏蔽了不同存储引擎之间的差异；MySQL现在支持多种存储引擎，各有各的特点，最常见的是MyISAM和InnoDB；

## 系统文件层（File System）

该层负责将数据库的数据和日志存储在文件系统之上，并完成与存储引擎的交互，是文件的物理存储层。主要包含日志文件、数据文件、配置文件、pid文件、socket文件；

+ 日志文件

+ 错误日志：默认开启，通过`show variable like'%log_error%'`查询配置；

+ 通用查询日志：记录一般查询语句，通过`show variable like '%general%'`查询配置；

+ 二进制日志：记录了对MySQL数据库执行的更改操作，并记录语句的发生时间、执行时长；但不记录`select`、`show`等不修改数据库的SQL；主要用于数据库恢复和主从复制；

  ```sql
  --查看是否开启binlog参数
  show variables like '%log_bin%' 
  --查看binlog参数
  show variables like '%binlog%'
  --查看日志文件
  show binary logs
  ```

+ 慢查询日志：记录所有执行时间超时的查询SQL，默认是10秒；

  ```sql
  --是否开启慢查询
  show variables like '%slow_query%'
  --慢查询记录日志阈值
  show variables like '%long_query_time%'
  ```

+ 配置文件：用于存放MySQL所有的配置信息文件，比如`my.cnf`、`my.ini`等；

+ 数据文件

  + `db.opt`：记录这个库的默认使用的字符集和校验规则；
  + `frm`文件：存储与表相关的元数据(meta)信息，包括表结构的定义信息等，每一张表都有一个`frm`文件；
  + `MYD`文件：MyISAM存储引擎专用，存放MyISAM表的数据（data），每一张表都会有一个`.MYD`文件；
  + `MYI`文件：MyISAM存储引擎专用，存放MyISAM表的索引相关信息，每一张MyISAM表对应一个`.MYI`文件；
  + `ibd`文件及`ibdata`文件：存放InnoDB的数据文件（包括索引）。InnoDB存储引擎有两种表空间方式：独享表空间和共享表空间；
    + 独享表空间：使用`.ibd`文件来存放数据，且每一张InnoDB表对应一个`.ibd`文件；
    + 共享表空间：使用`.ibdata`文件存放数据，所有表共同使用一个（或多个，自行配置）`.ibdata`文件；

  + `ibdata1`文件：系统表空间数据文件，存储表元数据、Undo日志等；
  + `ib_logfile0`文件：Redo Log日志文件；

+ `pid`文件：`pid`文件是`mysqld`应用程序在Unix/Linux环境下的一个进程文件，存放自己的进程ID；

+ `socket`文件：`socket`文件也是在Unix/Linux环境下才有的，用户在Unix/Linux环境下客户端链接可以不通过TCP/IP网络而直接使用Unix Socket来链接MySQL；

# MySQL运行机制

<img src="MySQL5-MySQL架构原理/image-20210824224000764.png" alt="MySQL运行机制" style="zoom:80%;" />

## 建立连接

通过客户端/服务器通信协议与MySQL建立链接。MySQL客户端与服务端的通信方式是“半双工”；对于每一个MySQL的连接，时刻都有一个线程状态来标识这个连接正在做什么；

**通信机制**

+ 全双工：能同时发送和接收数据，例如打电话；
+ 半双工：指的是某一时刻，要么发送数据，要么接收数据，但不能同时触发；例如对讲机；
+ 单工：只能发送或只能接受数据；例如单行车道；

**线程状态**

通过`show processlist`查看正在运行的线程信息，root用户可查看所有线程，其他用户仅可查看自己名下线程；

```sql
id：线程ID
user：线程启动用户
host：发送请求的客户端的ip和端口号
db：当前执行命令的数据库
command：进程正在执行的命令
create db：正在创建库操作
drop db：正在删除库操作
execute：正在执行的一个PreparedStatement
close stmt：正在关闭一个preparedStatement
query：正在执行一个语句
sleep：正在等待客户端发送语句
quit：正在退出
shutdown：正在关闭服务器
time：表示该线程正处于当前状态的时间，单位为秒
state：线程状态
updating：正在搜索匹配记录，进行修改
sleeping：正在等待客户端发送新请求
starting：正在执行请求处理
checking table：正在检查数据表
closing table：正在将表中数据刷新到磁盘
locked：被其他查询锁住记录
sending data：正在处理select查询，同时将结果发送给客户端
info：一般记录线程执行的语句，默认显示前100个字符；想看完整信息，使用show full processlist命令
```

## 查询缓存

这是MySQL的一个优化查询方案，如果开启查询缓存且在查询缓存过程中查询到完全相同的SQL语句，则将查询结果直接返回给客户端；如果没有开启查询缓存或者没有查询到完全相同的SQL语句则会由解析器进行语法语义解析，并生成“解析树”；

## 解析器

将客户端发送的SQL进行语法解析，生成“解析树”；预处理器根据一些MySQL规则进一步检查“解析树”是否合法，最后生成“解析树”；

## 查询优化器

根据“解析树”生成最优的执行计划；MySQL使用喝多优化策略生成最优的执行计划；优化可分为两类：静态优化（编译时优化）、动态优化（运行时优化）；

+ 等价变换策略；
+ 基于联合索引，调整条件位置；
+ 优化`count`、`max`、`min`等函数；
  + InnoDB引擎`min`只需要查找索引最左边，`max`只需要查找最右边；
  + MyISAM引擎`count`不需要计算，直接返回；
+ 提前终止查询
+ 使用`limit`查询，仅返回`limit`所需，不继续遍历后续数据；
+ `in`优化；`in`查询会先进行排序，在采用二分法查找数据；

## 查询执行引擎

查询执行引擎会根据SQL语句中表的存储引擎类型，以及对应的API接口与底层存储引擎缓存或者物理文件的交互，得到查询结果并返回给客户端；若开启查询缓存，会将SQL语句和结果完整地保存到查询缓存中，以后有相同SQL语句执行，则直接返回结果；

+ 如果开启了查询缓存，先将查询结果缓存；
+ 返回结果过多，则采用增量模式返回；

# MySQL存储引擎

存储引擎在MySQL的体系架构中位于第三层，负责MySQL中的数据存储和提取，是与文件打交道的子系统，它是根据MySQL提供的文件访问层抽象接口定制的一种文件访问机制，这种机制就叫做存储引擎；

使用`show engines`命令，可查看当前数据库支持的引擎信息；在5.5版本之前默认采用MyISAM存储引擎，从5.5开始采用InnoDB存储引擎；

+ InnoDB：支持事务，具有提交、回滚和崩溃恢复能力，事务安全；
+ MyISAM：不支持事务和外键，访问速度快；
+ Memory：利用内存创建表，访问速度非常快，因为数据在内存，而且默认使用Hash索引，但一旦关闭，数据就会丢失；
+ Archive：归档类型引擎，仅能支持`insert`和`select`语句；
+ `CSV`：以CSV文件进行数据存储，由于文件限制，所有列必须强制指定`not null`另外CSV引擎也不支持索引和分区，适合做数据交换的中间表；
+ BlackHole：黑洞，只进不出，进来就会消失，所有插入数据都不会保存；
+ Federated：可以访问远端MySQL数据库中的表，一个本地表，不保存数据，访问远程表内容；
+ MRG_MyISAM：一组MyISAM表的组合，这些MyISAM表必须结构相同，Merge表本身没有数据，对Merge操作可以对一组MyISAM表进行操作；

## InnoDB与MyISAM对比

InnoDB与MyISAM是MySQL最常用的两种引擎类型；两者主要区别如下：

+ 事务和外键

  InnoDB支持事务和外键，具有安全性和完整性，适合大量`insert`或`update`操作；

  MyISAM不支持事务和外键，提供高速存储和检索，适合大量的`select`查询操作；

+ 锁机制

  InnoDB支持行级锁，锁定指定记录；基于索引来加锁实现；

  MyISAM支持表级锁，锁定整张表；

+ 索引结构

  InnoDB使用聚集索引，索引和记录在一起存储，既缓存索引也缓存记录；

  MyISAM使用非聚集索引，索引与记录分开；

+ 并发处理能力

  MyISAM使用表锁，会导致写操作并发率低，读之间并不阻塞，读写阻塞；

  InnoDB读写阻塞可以与隔离级别有关，可以采用多版本并发控制(MVCC)来支持高并发；

+ 存储文件

  InnoDB表对应两个文件，一个`.frm`表结构文件，一个`.ibd`数据文件；InnoDB表最大支持64TB；

  MyISAM表对应三个文件，一个`.frm`表结构文件，一个`MYD`表数据文件，一个`MYI`索引文件；从MySQL 5.0开始默认限制为256TB；

<img src="MySQL5-MySQL架构原理/image-20210824231945397.png" alt="InnoDB数据文件" style="zoom:80%;" />

+ 适用场景

  MyISAM特点

  + 不需要事务支持
  + 并发相对较低
  + 数据修改相对较少，以读为主
  + 数据一致性要求不高

  InnoDB

  + 需要事务支持
  + 行级锁实现高并发能力
  + 数据更新较为频繁
  + 数据一致性要求高
  + 硬件设备内存大

  总结

  + 是否需要事务？是，选择InnoDB；
  + 是否存在并发修改？是，选择InnoDB；
  + 是否最求快速查询，且修改少？是，选择MyISAM；
  + 其他情况，推荐使用InnoDB；

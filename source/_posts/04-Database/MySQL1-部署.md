---
title: MySQL部署
categories: Database
tags: mysql
author: semon
date: 2021-03-12
---



# MySQL部署

##  YUM安装

在具备外网环境或配置本地yum源的情况下，可直接通过yum安装mysql

```bash
yum isntall -y mysql-server
```

## Tar`包安装`

```bash
# 通过官网下载mysql对应tar包
wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.30-el7-x86_64.tar

# 解包
tar -xvf mysql-5.7.30-el7-x86_64.tar

# 配置环境变量
export MYSQL_HOME=~/mysql-5.7.30-el7-x86_64
export PATH=$MYSQL_HOME/bin:$PATH

# 添加mysql至系统服务

## vim /usr/lib/systemd/system/mysql.service
[Unit]
Description=MySQL Server
Documentation=man:mysqld
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
User=mysql
Group=mysql

# 按照实际pid文件路径配置
PIDFile=/data/mysql/pid/mysqld.pid
# Disable service start and stop timeout logic of systemd for mysqld service.
TimeoutSec=0
# Execute pre and post scripts as root
PermissionsStartOnly=true
# Needed to create system tables
#ExecStartPre=/usr/bin/mysqld_pre_systemd
# Start main service
# 按照实际mysql安装路径配置
ExecStart=/usr/local/mysql/bin/mysqld --daemonize --pid-file=/data/mysql/pid/mysqld.pid
#注意这里要加上 --daemonize
# Use this to switch malloc implementation
#EnvironmentFile=-/etc/sysconfig/mysql
# Sets open_files_limit
LimitNOFILE = 5000
Restart=on-failure
RestartPreventExitStatus=1
PrivateTmp=false

# systemctl模块重新加载
systemctl daemon-reload
```



# MySQL初始化

修改配置文件my.cnf，并进行初始化；



```bash
# 软件安装
yum install -y mysql-community-server

# 创建mysql相关目录
mkdir -p /mnt/data01/mysql/data  /mnt/data01/mysql/logs  /mnt/data01/mysql/binlogs
chown -R mysql:mysql /mnt/data01/mysql

# 修改配置文件 /etc/my.cnf
[mysqld]
character-set-server=utf8
datadir=/mnt/data01/mysql/data
log-error=/mnt/data01/mysql/logs/mysqld.log
socket=/mnt/data01/mysql/mysql.sock
pid-file=/mnt/data01/mysql/mysqld.pid

# 主从相关配置，单节点不需要
server-id=1
log_bin=/mnt/data01/mysql/binlogs/mysql-bin.log
binlog_format=row
binlog_rows_query_log_events=on
binlog_row_image=minimal
log_slave_updates=on
expire_logs_days=7
binlog_cache_size=65535
sync_binlog=1
slave-preserve-commit-order=ON
gtid_mode=on
enforce_gtid_consistency=on
sql_mode=STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
log_bin_trust_function_creators=1
max_connections = 3000
wait_timeout=28800

[client]
socket=/mnt/data01/mysql/mysql.sock
default-character-set=utf8

# 初始化MYSQL
mysqld --initialize --user=mysql


# 启动mysql服务
systemctl start mysqld  && systemctl enable mysqld

# 查看root初始密码
cat /mnt/data01/mysql/logs/mysqld.log|grep pass
```



## MYSQL主从配置

参考单节点MYSQL安装从库，然后进行主从同步操作；

> master节点mysql数据库环境下操作

```sql
--修改默认root密码
set password=password('u19cMtBGd0');
flush privileges;

--创建复制账号
create user repl;

--复制授权
grant replication slave on *.* to 'repl'@'%' identified by 'vyeIzGQ91n';

flush privileges;
```



> os环境下操作

```BASH
# master node
## 备份主库数据
cd /mnt/data01/mysql

mysqldump -P3306 -uroot -pu19cMtBGd0 --all-databases --triggers --routines --events --single-transaction >all.sql

## 备份数据传输至从库
scp all.sql demo02:/mnt/data01/mysql

# slave node
## 获取gtid信息
cat all.sql |grep GLOBAL.GTID_PURGED
```



> slave节点mysql数据库环境下操作

```sql
-- 加载主节点备份数据
source /mnt/data01/mysql/all.sql;

--初始化主节点信息
reset master;

--配置GTID信息(从上一步骤获取)
SET @@GLOBAL.GTID_PURGED=xxxx;

-- 配置master信息
change master to master_host='demo01', master_port=3306,master_user='repl',master_password='vyeIzGQ91n',master_auto_position=1;

-- 启动从节点
start slave;

-- 查看从节点状态 (Slave_IO_Running及Slave_SQL_Running为yes即表示主从配置成功)
show slave status \G;
```



## 预置数据库

```BASH
# 预置数据库
mysql -u root -pu19cMtBGd0 -e "CREATE USER 'ambari'@'%' IDENTIFIED BY 'AfQUktZcJg'; GRANT ALL PRIVILEGES ON ambari.* TO 'ambari'@'%'; DELETE FROM mysql.user WHERE user=''; flush privileges; create database ambari;"
```

# 最佳实践

## 脏页刷新

### 什么是脏页？

MySQL InnoDB表基本都是基于B+树索引进行存储的，而数据存储的最小单元就是数据页；而当内存中的数据页与磁盘中的不一致时，该数据页就叫做脏页；当执行`flush`操作将磁盘数据页和内存数据页进行合并之后，内存和磁盘的数据页同步，称为干净页；

> MySQL物理存储结构：表 –> 表空间（索引）--> 段 –> 区 –> 页 –> 行 –> 列；
>
> Buffer Pool中数据页状态：
>
> 1. 尚未使用的数据页；
> 2. 使用了但已完成`flush`的干净页；
> 3. 使用了尚未`flush`的脏页；

### 为什么会出现脏页？

MySQL数据库在执行`select`、`update`、`delete`操作时，InnoDB使用`change buffer`进行加速写操作，可以将写操作的随机磁盘访问调整为局部顺序操作，而随机磁盘访问是数据库操作中性能影响较大的点；当非唯一索引记录的缓存页发生写操作时，修改完成`change buffer`就可以立刻返回了；

当我们需要执行一个简单的查询操作时，可能发生抖动，即某次查询的耗时骤增，外在整体表现就是tp50非常低，但tp999非常高的现象；因为执行某查询操作时，发生了刷脏页的操作，并且更可怕的是发生多次间接的连坐（`innodb_flush_neighbors`）；

### 脏页刷新的刷新时机

+ InnoDB的`redo log`日志写满

  此时操作系统不得不停止所有更新操作，将`check point`向前推，`redo log`可以留出更多的空间，并把该部分的脏页`flush`到磁盘中；（`flush`动作期间该段不可写）

+ 系统内存不足

  需要新的数据页但是发现需要淘汰部分数据页，而数据页存在脏页，则需要先执行`flush`操作，才能进行淘汰；

+ 后端线程刷新脏页

  即`Buffer Pool`中的`page cleaner Thread`；

+ MySQL关闭实例时

  服务实例关闭时，需刷新所有脏页；

### 脏页刷新影响因素

+ 脏页比例

  `innodb_max_dirty_pages_pct`参数可设置脏页的比例，超过该比例就触发刷新机制，默认值为75%；

+ `redo log`写速度

  `innodb_io_capacity`参数可设置磁盘刷新的页数，该值可设置为磁盘的IOPS；具体值可使用工具进行测试；

  ```bash
  fio -filename=$filename -direct=1 -iodepth 1 -thread -rw=randrw -ioengine=psync -bs=16k -size=500M -numjobs=10 -runtime=10 -group_reporting -name=mytest 
  ```



## 存储引擎层优化

```bash
#缓存池大小，一般为物理内存的 60% - 80%
innodb_buffer_pool_size=
#如果 innodb_buffer_pool_size 大小超过 1GB，innodb_buffer_pool_instances 值就默认为 8；否则，默认为 1；
innodb_buffer_pool_instances= 4
#
innodb_file_per_table=(1,0)
# 1-最安全  0-高性能  2-折中
innodb_flush_log_at_trx_commit= 0
Innodb_flush_method
innodb_log_buffer_size
innodb_log_files_in_group
innodb_max_dirty_pages_pct
innodb_additional_mem_pool_size

max_binlog_cache_size
max_binlog_size

```


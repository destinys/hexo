---
title: Hive存储过程
categories: Hadoop
tags: hive
author: semon
date: 2021-04-27
---


# Hive存储过程

Hive能够提供将简单SQL转换成MR任务进行运行，极大的降低了其入门成本，通过类SQL语句快速实现简单的MapReduce统计，不必开发专门的MapReduce应用，但相比于Oracle、MySQL等关系型数据库，Hive中没有提供类似存储过程的功能，使用Hive做数据开发时候，一般是将一段一段的HQL语句封装在Shell或者其他脚本中，然后以命令行的方式调用，对于从关系型数据库迁移过来的程序员不够友好；

HQL/SQL(HPL/SQL –Procedural SQL on Hadoop)作为Hive存储过程的解决方案，不仅支持Hive，还支持在SparkSQL，其他NoSQL，甚至是RDBMS中使用类似于Oracle PL/SQL的功能，这将极大的方便数据开发者的工作，Hive中很多之前比较难实现的功能，现在可以很方便的实现，比如自定义变量、基于一个结果集的游标、循环等等。

## hpl/sql部署

通过官网从http://www.hplsql.org/download 下载hpl/sql，建议下载最新版本；
该压缩包解压后结构如下：
.
|-- antlr-runtime-4.5.jar
|-- hplsql--------------------*环境变量配置*
|-- hplsql-0.3.31.jar
|-- hplsql.cmd
|-- hplsql-site.xml----------*hive链接地址配置*
|-- LICENSE.txt
`-- README.txt

### hplsql配置修改如下：

```bash
#配置Hive客户端路径
export "HIVE_HOME=/usr/ndp/current/hive_client"
#配置Hadoop客户端路径
export "HADOOP_HOME=/usr/ndp/current/yarn_client"

export "HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$HIVE_HOME/lib/*"
export "HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$HIVE_HOME/conf"


export "HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$HADOOP_HOME/conf:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*;$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HIVE_HOME/lib/hive-metastore-*.jar:$HIVE_HOME/lib/libthrift-*.jar:$HIVE_HOME/lib/libfb*.jar:$HIVE_HOME/lib/hive-exec-*.jar:$HIVE_HOME/conf:"

export HADOOP_OPTS="$HADOOP_OPTS -Djava.library.path=$HADOOP_HOME/lib/native"


SCRIPTPATH=${0%/*}

java -cp $SCRIPTPATH:$HADOOP_CLASSPATH:$SCRIPTPATH/hplsql-0.3.31.jar:$SCRIPTPATH/antlr-runtime-4.5.jar $HADOOP_OPTS org.apache.hive.hplsql.Hplsql "$@"
```

### hplsql-site.xml配置

```xml
<!--配置hplsql链接Hive-->
<property>
<name>hplsql.conn.hive2conn</name>
<value>org.apache.hive.jdbc.HiveDriver;jdbc:hive2://hadoop283.lt.163.org:2181,hadoop284.lt.163.org:2181,hadoop285.lt.163.org:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2;principal=hive/_HOST@BDMS.163.COM</value>
<description>HiveServer2 JDBC connection，支持zk模式</description>
</property>

<!--配置hplsql链接mysql-->
<!--如需链接mysql，需在HIVE_HOME/lib下添加mysql-jdbc链接架包-->
<property>
  <name>hplsql.conn.mysqlconn</name>
  <value>com.mysql.jdbc.Driver;jdbc:mysql://hadoop290.lt.163.org/demo;semon;semon</value>
  <description>MySQL connection</description>
</property>
```
### hplsql常用参数
    + -d：用于定义变量，多个变量需多个参数指定
    + -hiveconf：用于定义变量，多个变量需多个参数指定
    + -hivevar：用于定义变量，多个变量需多个参数指定
    + -e：启用命令行执行后接命令
    + -f：启用命令行执行后接文件内容
    + -main：仅执行指定存储过程
    + -trace：打印debug信息


```bash
#定义变量范例
root@hadoop283:/usr/ndp/current/hive_client/hplsql# ./hplsql -e "print a||','||b" -d a='hello' -d b='jack'
hello,jack

#执行文件范例
root@hadoop283:/usr/ndp/current/hive_client/hplsql# cat demo.sql
print a||','||b;
root@hadoop283:/usr/ndp/current/hive_client/hplsql# ./hplsql -f demo.sql -d a='hello' -d b='jack'
hello,jack

#执行存储过程范例
root@hadoop283:/usr/ndp/current/hive_client/hplsql# cat demo_main.sql
create procedure welcome(in arg string)
begin
set result = 'Hello,hplsql!'
print result ||' '||arg;
end;

print "this is a test sentense."
call welcome("by call...");
select * from wangbin.demo;

root@hadoop283:/usr/ndp/current/hive_client/hplsql# ./hplsql -f demo_main.sql -main welcome
Hello,hplsql!

#未指定main参数范例
root@hadoop283:/usr/ndp/current/hive_client/hplsql# ./hplsql -f demo_main.sql
"this is a test sentense."
Hello,hplsql!
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/mnt/dfs/0/ndp/5.4.0/hive_client/lib/log4j-slf4j-impl-2.8.2.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/mnt/dfs/0/ndp/5.4.0/yarn_client/share/hadoop/common/lib/slf4j-log4j12-1.7.10.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.apache.logging.slf4j.Log4jLoggerFactory]
Open connection: jdbc:hive2://hadoop283.lt.163.org:2181,hadoop284.lt.163.org:2181,hadoop285.lt.163.org:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2;principal=hive/_HOST@BDMS.163.COM (857 ms)
Starting query
Query executed successfully (4.38 sec)
2	john
1	jack

#打印debug日志
root@hadoop283:/usr/ndp/current/hive_client/hplsql# ./hplsql -f f_hello.sql -trace
Configuration file: file:/mnt/dfs/0/ndp/5.4.0/hive_client/hplsql/hplsql-site.xml
Parser tree: (program (block (stmt (create_function_stmt create function (ident hello) (create_routine_params ( (create_routine_param_item (ident text) (dtype string)) )) (create_function_return returns (dtype string)) (single_block_stmt begin (block (stmt (return_stmt return (expr (expr_concat (expr_concat_item (expr_atom (string 'hello, '))) || (expr_concat_item (expr_atom (ident text))) || (expr_concat_item (expr_atom (string '!'))))))) (stmt (semicolon_stmt ;))) (block_end end)))) (stmt (semicolon_stmt ;)) (stmt (for_cursor_stmt for item in ( (select_stmt (fullselect_stmt (fullselect_stmt_item (subselect_stmt select (select_list (select_list_item (expr (expr_atom (ident id)))) , (select_list_item (expr (expr_atom (ident name))))) (from_clause from (from_table_clause (from_table_name_clause (table_name (ident wangbin . demo))))))))) ) loop (block (stmt (print_stmt print (expr (expr_concat (expr_concat_item (expr_atom (ident item . id))) || (expr_concat_item (expr_atom (string '|'))) || (expr_concat_item (expr_atom (ident item . name))) || (expr_concat_item (expr_atom (string '|'))) || (expr_concat_item (expr_func (ident hello) ( (expr_func_params (func_param (expr (expr_atom (ident item . name))))) ))))))) (stmt (semicolon_stmt ;))) end loop)) (stmt (semicolon_stmt ;))))
Ln:1 CREATE FUNCTION hello
Ln:8 FOR CURSOR - ENTERED
Ln:8 select id, name from wangbin.demo
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/mnt/dfs/0/ndp/5.4.0/hive_client/lib/log4j-slf4j-impl-2.8.2.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/mnt/dfs/0/ndp/5.4.0/yarn_client/share/hadoop/common/lib/slf4j-log4j12-1.7.10.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.apache.logging.slf4j.Log4jLoggerFactory]
Open connection: jdbc:hive2://hadoop283.lt.163.org:2181,hadoop284.lt.163.org:2181,hadoop285.lt.163.org:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2;principal=hive/_HOST@BDMS.163.COM (914 ms)
Starting query
Query executed successfully (2.06 sec)
Ln:8 SELECT completed successfully
Ln:8 COLUMN: id, int
Ln:8 SET id = 2
Ln:8 COLUMN: name, string
Ln:8 SET name = john
Ln:10 PRINT
Ln:10 EXEC FUNCTION hello
Ln:10 SET PARAM text = john
Ln:5 RETURN
2|john|hello, john!
Ln:8 COLUMN: id, int
Ln:8 SET id = 1
Ln:8 COLUMN: name, string
Ln:8 SET name = jack
Ln:10 PRINT
Ln:10 EXEC FUNCTION hello
Ln:10 SET PARAM text = jack
Ln:5 RETURN
1|jack|hello, jack!
Ln:8 FOR CURSOR - LEFT
```

### hplsql操作mysql
在hplsql中操作mysql数据库表，需先将mysql目标表映射到mysql连接器对象上，映射语法为：`map object obj_xxx to db.tablename at mysql.conn;`

以下为一个hive存储过程执行并将日志记录到mysql库范例：

```bash
#映射mysql表
map object obj_log to demo.demo at mysql.conn;

#定义存储过程
declare 
start_time varchar2(20);
end_time varchar2(20);
ret_code varchar2(20);
begin
start_time = SYSDATE||'';
use wangbin;
insert into wangbin.demo
values(3,'wangbin');
end_time = SYSDATE||'';
ret_code = SQLCODE;

insert into obj_log (`start_time`,`end_time`,`ret_code`)  values(start_time,end_time,ret_code);

exception when others then 
     end_time = SYSDATE||'';
     ret_code = SQLCODE;
     insert into obj_log(`start_time`,`end_time`,`ret_code`) values(start_time,end_time,ret_code);
     dbms_output.putline('SQL error is :' || ret_code);
end;

#执行结果如下：
root@hadoop283:/usr/ndp/current/hive_client/hplsql# ./hplsql -f demo_mysql.sql
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/mnt/dfs/0/ndp/5.4.0/hive_client/lib/log4j-slf4j-impl-2.8.2.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/mnt/dfs/0/ndp/5.4.0/yarn_client/share/hadoop/common/lib/slf4j-log4j12-1.7.10.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.apache.logging.slf4j.Log4jLoggerFactory]
Open connection: jdbc:hive2://hadoop283.lt.163.org:2181,hadoop284.lt.163.org:2181,hadoop285.lt.163.org:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2;principal=hive/_HOST@BDMS.163.COM (970 ms)
Starting SQL statement
SQL statement executed successfully (1.08 sec)
Starting SQL statement
SQL statement executed successfully (21.42 sec)
Tue Apr 02 17:08:08 CST 2019 WARN: Establishing SSL connection without server's identity verification is not recommended. According to MySQL 5.5.45+, 5.6.26+ and 5.7.6+ requirements SSL connection must be established by default if explicit option isn't set. For compliance with existing applications not using SSL the verifyServerCertificate property is set to 'false'. You need either to explicitly disable SSL by setting useSSL=false, or set useSSL=true and provide truststore for server certificate verification.
Open connection: jdbc:mysql://hadoop290.lt.163.org:3306/demo (243 ms)
Starting SQL statement
SQL statement executed successfully (4 ms)

#查询mysql插入数据
root@hadoop283:/usr/ndp/current/hive_client/hplsql# mysql -h hadoop290.lt.163.org -usemon -psemon
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 20
Server version: 5.7.25 MySQL Community Server (GPL)

Copyright (c) 2000, 2015, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> select * from demo.demo;
+----------------------+----------------------+----------+
| start_time           | end_time             | ret_code |
+----------------------+----------------------+----------+
| 2019-04-02 17:07:44. | 2019-04-02 17:08:08. | 0        |
+----------------------+----------------------+----------+
1 row in set (0.00 sec)
```
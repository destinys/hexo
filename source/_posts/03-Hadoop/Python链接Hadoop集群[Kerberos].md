---

title: Python链接Hadoop集群[Kerberos]
categories: Hadoop
tags: 
  - hive
  - python
author: Semon
date: 2021-04-26 15:00:00
top: true
---

# Python链接Hadoop集群[Kerberos]

## 环境准备

###  环境变量

```bash
# 配置环境变量  其中xxx替换为节点上jdk实际安装目录）
echo  "export JAVA_HOME=xxx" >~/.bash_profile
source ~/.bash_profile
```

### 安装系统依赖包

```bash
# 安装kerberos客户端
yum install -y krb5-lib krb5-workstation

# 安装python相关模块系统依赖包
yum install  libffi-devel python-devel openssl-devel  cyrus-sasl cyrus-sasl-devel cyrus-sasl-lib  gcc-c++ -y
```

### 安装python模块

```bash
pip install --upgrade setuptools
pip install sasl
pip install thrift
pip install thrift-sasl
pip install impyla
pip install krbcontext

## 以下为ibis依赖
pip install ibis-framework
pip install future
pip install PyHive
pip install thriftpy
pip install --ignore-installed requests hdfs[kerberos]
```



### 网络端口授权

> KDC：750 88
>
> Namenode：8020
>
> ResourceManager：8030 8031 8032
>
> Hiveserver2：9999
>
> Metastore：9083
>
> MySQL：3306



### 客户端配置

1. 从集群节点拷贝`krb5.conf`配置文件至客户端主机`/etc/`目录下；

2. 从集群执行节点拷贝spark及hdfs文件夹至客户端主机；

3. 拷贝`hive-site.xml`配置文件至`spark/conf`文件夹下；

4. 确认hdfs配置文件路径为`$HADOOP_HOME/etc/hadoop`下，否则需手动拷贝配置文件至该路径下；（仅需要保留`hdfs-site.xml`、`core-site.xml`、`yarn-site.xml`及`hadoop-env.sh`）

5. 删除所有配置文件中关于集群路径信息相关配置参数，避免日志打印异常信息干扰；

6. 如需自定义`krb5.conf`及认证缓存文件路径，则在`hadoop-env.sh`中添加以下环境该变量

   ```bash
   export KRB5_CONFIG="$HADOOP_CONF_DIR"/krb5.conf
   export KRB5CCNAME="$HADOOP_CONF_DIR"/krb5cc_$UID
   export HADOOP_OPTS="-Djava.security.krb5.conf=$KRB5_CONFIG"
   ```

   

## python链接Hive脚本

### 方案一：提交至默认队列

```python
#!/usr/bin/python

from impala.dbapi import connect
from krbcontext import krbcontext

config = {
    "kerberos_principal": "hive/bigdata-demo1.jdlt.163.org@BDMS.163.COM",
    "keytab_file": '/home/wangsong03/hive.service.keytab',
    "kerberos_ccache_file": '/home/wangsong03/hive_ccache_uid',
    "AUTH_MECHANISM": "GSSAPI"
}
with krbcontext(using_keytab=True,
                               principal=config['kerberos_principal'],
                               keytab_file=config['keytab_file'],
                               ccache_file=config['kerberos_ccache_file']):
    conn = connect(host='bigdata-demo1.jdlt.163.org', port=9999, auth_mechanism='GSSAPI',kerberos_service_name='hive')
    cur = conn.cursor()
    cur.execute('SHOW databases')
    print(cur.fetchall())
    cur.close()
    conn.close()
```

### 方案二：提交至指定队列

```python
#!/usr/bin/python
from pyhive import hive
from krbcontext import krbcontext
config = {
    "kerberos_principal": "jzt_dmp/dev@BDMS.163.COM",
    "keytab_file": '/root/jzt_dmp.keytab',
    "kerberos_ccache_file": './hive_ccache_uid',
    "AUTH_MECHANISM": "GSSAPI"
}
with krbcontext(using_keytab=True,
                               principal=config['kerberos_principal'],
                               keytab_file=config['keytab_file'],
                               ccache_file=config['kerberos_ccache_file']):
    conn = hive.connection(host='bigdata004.dmp.jztweb.com', port=9999, auth_mechanism='GSSAPI',kerberos_service_name='hive',configuration={"mapreduce.job.queuename":"root.schedule_queue"})
    cur = conn.cursor()
    cur.execute('select count(1) from b2b_ods.dim_plat');

    print(cur.fetchone())
    cur.close()
    conn.close()
```



## python链接Impala脚本

```python
#!/usr/bin/python

from impala.dbapi import connect
from krbcontext import krbcontext

config = {
    "kerberos_principal": "bdms_wangsong03/dev@BDMS.163.COM",
    "keytab_file": '/home/wangsong03/bdms_wangsong03.keytab',
    "kerberos_ccache_file": '/home/wangsong03/wangsong03_ccache_uid',
    "AUTH_MECHANISM": "GSSAPI"
}
with krbcontext(using_keytab=True,
                               principal=config['kerberos_principal'],
                               keytab_file=config['keytab_file'],
                               ccache_file=config['kerberos_ccache_file']):
    conn = connect(host='bigdata-demo5.jdlt.163.org', port=21050, auth_mechanism='GSSAPI',kerberos_service_name='impala')
    cur = conn.cursor()
    cur.execute('SHOW databases')
    print(cur.fetchall())
    cur.close()
    conn.close()
```

## python链接hdfs脚本

```python
#!/usr/bin/python

import ibis

from krbcontext import krbcontext



conf={
"impala_host":"bigdata-demo5.jdlt.163.org",
"impala_port":21050,
"kerberos_service_name":"impala",
"auth_mechanism":"GSSAPI",
"webhdfs_host1":"bigdata-demo1.jdlt.163.org",
"webhdfs_host2":"bigdata-demo2.jdlt.163.org",
"webhdfs_port":50070
}


config = {
    "kerberos_principal": "bdms_wangsong03/dev@BDMS.163.COM",
    "keytab_file": '/home/wangsong03/bdms_wangsong03.keytab',
    "kerberos_ccache_file": '/home/wangsong03/wangsong03_ccache_uid',
    "AUTH_MECHANISM": "GSSAPI"
}
with krbcontext(using_keytab=True,
                               principal=config['kerberos_principal'],
                               keytab_file=config['keytab_file'],
                               ccache_file=config['kerberos_ccache_file']):

  # get hdfs_connect
  try:
    hdfs_client=ibis.hdfs_connect(host=conf["webhdfs_host1"],port=conf["webhdfs_port"],auth_mechanism=conf["auth_mechanism"],use_https=False,verify=True)
    hdfs_client.ls("/")
  except:
    hdfs_client=ibis.hdfs_connect(host=conf["webhdfs_host2"],port=conf["webhdfs_port"],auth_mechanism=conf["auth_mechanism"],use_https=False,verify=False)
    hdfs_client.ls("/")

  print(hdfs_client.ls('/user'))

  # connect impala method2
  impala_client=ibis.impala.connect(host=conf["impala_host"],port=conf["impala_port"],hdfs_client = hdfs_client, auth_mechanism=conf["auth_mechanism"], timeout = 300)
  res=impala_client.sql("""select * from poc.demo limit 10""")
  print(res.execute())
```



## pyspark提交任务至kerberos集群

```python
# _*_ coding: utf-8 _*_
import findspark
findspark.init()

import os
os.environ['JAVA_HOME']='/usr/lib64/jdk8'
os.environ['SPARK_HOME']='~/spark2'
os.environ['HADOOP_HOME']='~/hadoop'
os.environ['HADOOP_CONF_DIR']='~/hadoop/etc/hadoop'


# 增加client模式driver内存
memory = '10g'
pyspark_submit_args = ' --driver-memory ' + memory + '   pyspark-shell'
os.environ["PYSPARK_SUBMIT_ARGS"] = pyspark_submit_args


from krbcontext import krbcontext
from pyspark import SparkConf, SparkContext


class CreateSparksession():

    def createSpark(self):
        conf = {"appname": "demo", "driver_memory": "4g", "executor_memory": "4g", "executor_cores": 2, "executor_num": 2, "master": "yarn", "deploy_mode": "client"}
        sc = SparkConf()
        sc.setMaster(conf['master']) \
            .setAppName(conf['appname']) \
            .set('spark.driver.memory', conf['driver_memory']) \
            .set('spark.executor.memory', conf['executor_memory']) \
            .set('spark.executor.cores', conf['executor_cores']) \
            .set('spark.deploy_mode', conf["deploy_mode"])\
            .set('spark.yarn.queue', 'root.poc')\
            .set('spark.executor.memoryOverhead', '2g')\
            .set('spark.driver.memoryOverhead', '2g')
        spark= SparkSession.builder.config(conf=sc).enableHiveSupport().getOrCreate()
        sctx = spark.sparkContext
        return spark, sctx


config = {
    "kerberos_principal": "bdms_wangsong03/dev@BDMS.163.COM",
    "keytab_file": '/home/wangsong03/bdms_wangsong03.keytab',
    "kerberos_ccache_file": '/home/wangsong03/wangsong03_ccache_uid',
    "AUTH_MECHANISM": "GSSAPI"
}
with krbcontext(using_keytab=True,
                principal=config['kerberos_principal'],
                keytab_file=config['keytab_file'],
                ccache_file=config['kerberos_ccache_file']):
    spark, sctx = CreateSparksession().createSpark()
    rdd = sctx.textFile("hdfs://easyops-cluster/user/poc/pysparkdemo/demo.txt")
    print(rdd.collect())
    spark.sql("select count(*) from poc.demo").show()
	sctx.stop()
    spark.stop()
```



## 通过python基础模块实现kerberos认证

### 创建上下文管理器

```python
import os,sys
import subprocess
from contextlib import contextmanager


def KRB5KinitError(Exception):
  	pass

def kinit_with_keytab(keytab_file,principal,ccache_file):
	''' 
 	 initialize kerberos using keytab file
	return the tgt filename
	'''
	cmd = 'kinit -kt %(keytab_file)s -c %(ccache_file)s %(principal)s'
    args = {}

	args['keytab_file'] = keytab_file
	args['principal'] = principal
	args['ccache_file'] = ccache_file

	kinit_proc = subprocess.Popen(
		(cmd % args).split(),
		stderr = subprocess.PIPE)
		stdout_data,stderr_data = kinit_proc.communicate()

	if kinit_proc.returncode >0:
  		raise KRB5KinitError(stderr_data)
    
	return ccache_file


@contextmanager
def krbcontext(using_keytab=False,**kwargs):
  '''
  A context manager for krberos-related actions
  Using_keytab: specify to use keytab file in kerberos context  if true, or be as a regular user.
  kwargs:contains the necessary arguments used in kerberos context, it can contain principal,keytab_file, ccache_file
  '''
  env_name='KRB5CCNAME'
  h_ccache = os.getenv(env_name)
  ccache_file = kinit_with_keytab(**kwargs)
  os.environ[env_name] = ccache_file
  yield


```



> 使用非默认python执行任务，需在代码中指定目标python环境变量  `PYSPARK_PYTHON`
>



## FAQ

**Q**: `sys.stderr.write(f"ERROR: {exc}")`

**A**: 因python2 已经停止支持导致pip进行安装时报错，从官网下载2.7版本的get-pip.py，然后安装

```bash
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
python get-pip.py
```



**Q**：`ImportError: cannot import name TFrozenDict`

**A**：安装pyhive时需添加[hive]后缀，否则有些关联的包装不上，会导致报错



**Q**: `gcc: error trying to exec 'cc1plus' : execvp: No such file or directory`

**A**: 因操作系统缺少基础gcc依赖包导致，通过yum安装即可

```bash
yum install gcc-c++
```



**Q**：`AttributeError: 'SparkConf' object has no attribute '_get_object_id'`

**A**：`SparkSession.builder.config(conf = sc)` 括号中必须使用`conf =sc`



**Q**：`Caused by: io.netty.channel.AbstractChannel$AnnotatedConnectException: Connection refused: bigdata11/10.4.9.68:39005`

**A**：问题表象spark am Container链接client失败，如测试节点间网络端口确实不通，则需申请权限；如测试网络端口正常，则一般为客户端多网卡问题导致；

​		方案一：调整客户端与集群节点`/etc/hosts`中ip主机名映射一致，且映射IP与集群可正常通讯；
​		方案二：调整集群与客户端hdfs-site.xml配置文件，增加以下参数		

```xml
<property>
    <name>dfs.client.use.datanode.hostname</name>
    <value>true</value>
</property>
```


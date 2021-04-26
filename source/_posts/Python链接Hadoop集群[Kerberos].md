---
title: Python链接Hadoop集群[Kerberos]
categories: Hadoop
tags: hive,python
author: Semon
date: 2021-04-26 15:00:00
top: true
---

# Python链接Hadoop集群[Kerberos]

## 安装系统依赖包
```bash
# 安装系统基础依赖包
yum install  libffi-devel python-devel openssl-devel  cyrus-sasl cyrus-sasl-devel cyrus-sasl-lib  -y
```

## 安装python模块

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

## python链接Hive脚本

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


## FAQ
Q: `sys.stderr.write(f"ERROR: {exc}")`

A: 因python2 已经停止支持导致pip进行安装时报错，从官网下载2.7版本的get-pip.py，然后安装

```bash
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
python get-pip.py
```

---
title: Kerberos安装
categories: Hadoop
tags: kerberos
author: semon
date: 2021-06-21
---

# Kerberos部署

```bash
#停用服务
systemctl stop krb5kdc; 
systemctl disable krb5kdc;
systemctl stop kadmin; 
systemctl disable kadmin;

# 卸载已安装软件包
yum -y remove krb5-server   krb5-libs    krb5-workstation

# 删除配置文件
rm -rf /var/kerberos; 
rm -rf /etc/krb5.keytab ;


# 安装软件包
yum -y install krb5-server krb5-libs krb5-workstation

# 停用服务
systemctl stop krb5kdc && systemctl stop kadmin

# 配置/var/kerberos/krb5kdc/kdc.conf
[kdcdefaults]
	kdc_ports = 750,88

[realms]
	DEMO.163.COM = {
		database_name = /var/kerberos/krb5kdc/principal
		admin_keytab = FILE:/etc/kadm5.keytab
		acl_file = /var/kerberos/krb5kdc/kadm5.acl
		key_stash_file = /var/kerberos/krb5kdc/stash
		kdc_ports = 750,88
		max_life = 10h 0m 0s
		max_renewable_life = 7d 0h 0m 0s
		master_key_type = des3-hmac-sha1
		supported_enctypes = arcfour-hmac:normal des3-hmac-sha1:normal des-cbc-crc:normal des:normal des:v4 des:norealm des:onlyrealm des:afs3
		default_principal_flags = +preauth
	}

[logging]
	kdc = FILE:/var/log/krb5kdc.log
	admin_server = FILE:/var/log/kadmin.log
	default = FILE:/var/log/krb5lib.log
	

# 配置/var/kerberos/krb5kdc/kadm5.acl
hadoop/admin *
* i

# 初始化数据库
kdb5_util create -r DEMO.163.COM -s
< LazSxNqFkg

# 配置/etc/krb5.conf
[libdefaults]
	renew_lifetime = 7d
	forwardable = true
	default_realm = DEMO.163.COM
	ticket_lifetime = 24h
	dns_lookup_realm = false
	dns_lookup_kdc = false
	default_ccache_name = /tmp/krb5cc_%{uid}
	default_tgs_enctypes = aes des3-cbc-sha1 rc4 des-cbc-md5
	default_tkt_enctypes = aes des3-cbc-sha1 rc4 des-cbc-md5

[domain_realm]
	163.com = DEMO.163.COM
	.163.com = DEMO.163.COM

[logging]
	default = FILE:/var/log/krb5kdc.log
	admin_server = FILE:/var/log/kadmind.log
	kdc = FILE:/var/log/krb5kdc.log

[realms]
	DEMO.163.COM = {
		admin_server = demo01.bigdata.163.com
		kdc = demo01.bigdata.163.com
		kdc = demo02.bigdata.163.com
		}
		
# 添加krb管理员
kadmin.local
> addprinc hadoop/admin@DEMO.163.COM
< ek72djNnES
< ek72djNnES
> exit


# 重启服务
systemctl start krb5kdc.service && systemctl enable krb5kdc.service;
systemctl start kadmin.service && systemctl enable kadmin.service;

systemctl status krb5kdc.service
systemctl status kadmin.service

## HA master节点

# 生成主从节点principal及keytab
kadmin.local
> addprinc -randkey host/demo01.bigdata.163.com@DEMO.163.COM
> addprinc -randkey host/demo02.bigdata.163.com@DEMO.163.COM
> ktadd host/demo01.bigdata.163.com@DEMO.163.COM
> ktadd host/demo02.bigdata.163.com@DEMO.163.COM


## HA slave节点

#停用服务
systemctl stop krb5kdc; 
systemctl disable krb5kdc;
systemctl stop kadmin; 
systemctl disable kadmin;

# 卸载已安装软件包
yum -y remove krb5-server  remove krb5-libs   remove krb5-workstation

# 删除配置文件
rm -rf /var/kerberos; 
rm -rf /etc/krb5.keytab;


# 安装软件包
yum -y install krb5-server

# 删除默认配置
rm -rf /etc/krb5.conf

# 停用服务
systemctl stop krb5kdc

# 创建/var/kerberos/krb5kdc/kpropd.acl
host/demo01.bigdata.163.com@DEMO.163.COM
host/demo02.bigdata.163.com@DEMO.163.COM

## HA master节点
# 从主节点拷贝配置文件 kdc.conf、kadm5.acl及krb5.keytab
cd /var/kerberos/krb5kdc
scp kdc.conf  demo02:/var/kerberos/krb5kdc
scp kadm5.acl  demo02:/var/kerberos/krb5kdc
scp /etc/krb5.keytab  demo02:/etc
scp /etc/krb5.conf  demo02:/etc

## HA slave节点
# 初始化从库数据库

kdb5_util create -r DEMO.163.COM -s
< LazSxNqFkg

# 启动kpropd服务

systemctl start kprop.service && systemctl enable kprop.service


## HA master节点

# 数据dump及同步
kdb5_util dump /var/kerberos/krb5kdc/slave_datatrans

kprop -f /var/kerberos/krb5kdc/slave_datatrans demo02.bigdata.163.com
```










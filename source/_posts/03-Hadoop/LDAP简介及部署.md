---
title: LDAP简介
categories: Hadoop
tags: ldap
author: semon
date: 2021-04-28
---

# LDAP简介

LDAP是轻量目录访问协议，英文全称是Lightweight Directory Access Protocol，简称LDAP。LDAP的目录服务其实也是一种数据库系统（Berkeley DB），只是这种数据库是一种树形结构（B Tree），对于数据的读取、浏览、搜索有很好的效果，但不适合频繁写，不支持事务不能回滚。

LDAP是一个协议，而不是一款软件，基于LDAP协议的产品已经有很多，各大软件公司都在他们的产品中集成了LDAP服务，如Microsoft的ActiveDirectory、Lotus的Domino Directory、IBM的WebSphere中也集成了LDAP服务。LDAP的开源实现是OpenLDAP，它比商业产品一点也不差，而且源码开放。这些软件提供了目录服务的所有功能，包括目录搜索、身份认证、安全通道、过滤器等等。

LDAP数据操作访问可分为四类10种操作：

+ 查询类操作，如搜索、比较；
+ 更新类操作，如添加条目、删除条目、修改条目、修改条目名；
+ 认证类操作，如绑定、解绑定；
+ 其它操作，如放弃和扩展操作；

我们用LDAP实现多个组件的用户管理，比如把gitlab和harbor等组件的用户放在LDAP一起管理，组件只负责权限管理。用户在这些组件登录时都走LDAP的认证，让用户可以用一套用户名密码即可登录所有组件。



## LDAP 关键字

Schema：用来指定一个目录中所包含的对象(Object)的类型(ObjectClass)，以及每一个类型中必须提供的属性和可选属性；

+ Object：用来表示一个具体的条目

+ ObjectClass：用于规范条目值的属性类型
+ DN（Distinguished Name）：唯一标识
+ RDN（Relative DN）：相对标识（CN、SN、UID均可作为RDN）

+ DC（Domain Component）：域名的一部分，每一层为一个DC
+ OU（Organization Unit）：组织单元
+ CN（Common Name）：用户名字
+ SN（Surname）：用户姓氏
+ UID（UserID）：用户登陆ID



举个栗子：A公司B部门经理王小二登陆ID wangxiaoer@demo.com

Schema用来定义Object的格式为 公司-部门-姓名-登陆ID

Object为王小二这个条目

ObjectClass用来定义公司、部门、姓名、登陆ID的约束，如登陆ID必须符合邮箱格式

DN："DC=A公司,DC=B部门,OU=经理,UID=wangxiaoer@demo.com"

RDN：UID=wangxiaoer@demo.com 或SN=王或CN=小二

DC：DC=A公司，DC=B部门

OU：OU=经理

CN：CN=小二

SN：SN=王

UID：UID=wangxiaoer@demo.com



# LDAP部署



## 安装软件及依赖包

```bash
yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel

# 启动服务
systemctl start slapd.service && systemctl enable slapd.service

# 初始化DB数据
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown -R ldap:ldap /var/lib/ldap/
systemctl restart slapd.service
```



## 设置LDAP管理员密码

```bash
slappasswd
< UnAZe2xGI5
< UnAZe2xGI5
>密文密码
```



## 创建ch-domain.ldif

```bash
# dc需根据实际情况进行更改
# olcRootPW值修改为设置密码时返回的密文密码
# /etc/openldap/ch-domain.ldif

dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=admin,dc=demo,dc=163,dc=com" read by * none

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=demo,dc=163,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=admin,dc=demo,dc=163,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: {SSHA}Sx34vYufqmmghi0idoXgwHnRLgr+qCuG

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by dn="cn=admin,dc=demo,dc=163,dc=com" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=admin,dc=demo,dc=163,dc=com" write by * read
```



## 创建init.ldif

```bash
# 修改dn、dc及cn信息
# /etc/openldap/init.ldif
dn: dc=demo,dc=163,dc=com
objectclass: top
objectclass: dcObject
objectclass: organization
o: demo.163.com
dc: demo

dn: cn=admin,dc=demo,dc=163,dc=com
objectclass: organizationalRole
cn: admin

dn: ou=groups,dc=demo,dc=163,dc=com
objectclass: organizationalUnit
objectclass: top
ou: groups

dn: cn=demo_default_group,ou=groups,dc=demo,dc=163,dc=com
cn: demo_default_group
gidnumber: 6000
objectclass: posixGroup
objectclass: top

dn: ou=people,dc=demo,dc=163,dc=com
objectclass: organizationalUnit
objectclass: top
ou: people

dn: cn=anonymous,ou=people,dc=demo,dc=163,dc=com
cn: anonymous
gidnumber: 6000
homedirectory: /home/anonymous
loginshell: /bin/bash
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: anonymous
uid: anonymous
uidnumber: 10000
userpassword: anonymous
```



## 配置加载至LDAP

```BASH
# 将初始配置添加至ldap
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

# 将ch-domain.ldif配置添加至ldap
ldapmodify -Y EXTERNAL -H ldapi:/// -f ch-domain.ldif

#目录授权
chown -R ldap:ldap /etc/openldap

#重启服务
systemctl restart slapd.service && systemctl enable slapd

#将init.ldif添加至ldap
ldapadd -x -D 'cn=admin,dc=demo,dc=163,dc=com' -w 'UnAZe2xGI5' -f ./init.ldif

#验证
ldapsearch -x -b "dc=demo,dc=163,dc=com" '(objectclass=*)'

ldapwhoami -x -D 'cn=admin,dc=demo,dc=163,dc=com' -w 'UnAZe2xGI5'

ldapwhoami -x -D 'cn=anonymous,ou=people,dc=demo,dc=163,dc=com' -w 'anonymous'
```



## LDAP HA配置

### 创建syncprov.ldif

```bash
# 文件内容不需要修改
# /etc/openldap/syncprov.ldif
dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulePath: /usr/lib64/openldap
olcModuleLoad: syncprov.la


dn: olcOverlay=syncprov,olcDatabase={2}hdb,cn=config
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
olcSpSessionLog: 100
```



```BASH
# MASTER
ldapadd -Y EXTERNAL -H ldapi:/// -f syncprov.ldif

# SLAVE
ldapadd -Y EXTERNAL -H ldapi:/// -f syncprov.ldif
```



### 创建master.ldif

```bash
# olcServerID 为唯一标识，master与slave需区分
# provider 指定ha节点，master指定slave主机名，slave指定master主机名
# dc需根据实际进行修改
# 保留文件缩进格式
# /etc/openldap/master01.ldif

dn: cn=config
changetype: modify
replace: olcServerID
# specify uniq ID number on each server
olcServerID: 1		

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcSyncRepl
olcSyncRepl: rid=001
  provider=ldap://demo02.bigdata.163.com:389/
  bindmethod=simple
  binddn="cn=admin,dc=demo,dc=163,dc=com"
  credentials=UnAZe2xGI5
  searchbase="dc=demo,dc=163,dc=com"
  scope=sub
  schemachecking=on
  type=refreshAndPersist
  retry="30 5 300 +"
  interval=00:00:00:10
-
add: olcMirrorMode
olcMirrorMode: TRUE
```



```BASH
# MASTER
ldapmodify -Y EXTERNAL -H ldapi:/// -f master01.ldif
# 重启服务
systemctl restart slapd.service

#SLAVE
ldapmodify -Y EXTERNAL -H ldapi:/// -f master02.ldif
# 重启服务
systemctl restart slapd.service
```



## 验证HA

### 创建user1.ldif

```bash
# user1.ldif
dn: cn=user1,ou=people,dc=demo,dc=163,dc=com
cn: user1
gidnumber: 6000
homedirectory: /home/user1
loginshell: /bin/bash
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: user1
uid: user1
uidnumber: 9999
userpassword: user1
```



```bash
# master
## 添加user1
ldapadd -x -D 'cn=admin,dc=demo,dc=163,dc=com' -w 'UnAZe2xGI5' -f ./user1.ldif

# slave
## 查询user1
ldapwhoami -x -D 'cn=user1,ou=people,dc=demo,dc=163,dc=com' -w 'user1'
## 删除user1
ldapdelete -x -D 'cn=admin,dc=demo,dc=163,dc=com' -w 'UnAZe2xGI5' 'cn=user1,ou=people,dc=demo,dc=163,dc=com'

# master
## 查询user1
ldapwhoami -x -D 'cn=user1,ou=people,dc=demo,dc=163,dc=com' -w 'user1'
```



## 卸载LDAP

```
systemctl stop slapd && systemctl disable slapd 
yum -y remove openldap-servers openldap-clients 
rm -rf /var/lib/ldap /etc/openldap/
```

## 常见问题

### No such user

该问题一般为nslcd服务异常导致，排查步骤如下：

```bash
#核查ldap server及base dn配置是否正常
authconfig --test | egrep -i 'ldap|sss' |grep -iE 'server|base'

# 修改配置
authconfig --ldapbasedn=dc=bigdata,dc=deppon,dc=com,dc=cn --update

# 修改配置文件
# vi /etc/nslcd.conf 注释以下两行
# ssl start_tls
# tls_cacertdir /etc/openldap/cacerts

# vi /etc/nsswitch.conf 追加行尾ldap
passwd: files sss ldap
shadow: files sss ldap
group: files sss ldap

# 重启nslcd服务
systemctl status nslcd
```


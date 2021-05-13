---
title: Vsftp部署
categories: Dev
tags: vsftp
date: 2021-01-10
author: Semon
---



# VSFTP简介

FTP服务器(File Transfer Protocol Server)是在互联网上提供文件存储和访问服务的计算机，它们依照FTP协议提供服务。 FTP是File Transfer Protocol(文件传输协议)。顾名思义，就是专门用来传输文件的协议。简单地说，支持FTP协议的服务器就是FTP服务器。

VSFTP是一个基于GPL发布的类Unix系统上使用的FTP服务器软件，它的全称是Very Secure FTP 从此名称可以看出来，编制者的初衷是代码的安全。

## 特点

1. 它是一个安全、高速、稳定的FTP服务器;
2. 它可以做基于多个IP的虚拟FTP主机服务器;
3. 匿名服务设置十分方便;
4. 匿名FTP的根目录不需要任何特殊的目录结构，或系统程序或其它的系统文件;
5. 不执行任何外部程序，从而减少了安全隐患;
6. 支持虚拟用户，并且每个虚拟用户可以具有独立的属性配置;
7. 可以设置从inetd中启动，或者独立的FTP服务器两种运行方式;
8. 支持两种认证方式(PAP或xinetd/ tcp_wrappers);
9. 支持带宽限制;

##  优点

1. 稳定：在RedHat系统下测试，可支持15000个并发；

2. 速度：在千兆网卡下下载速度可达86MB/S；



#  VSFTP登陆方式

vsftp有多种登录方式：包括匿名登录方式、本地系统用户登录方式和虚拟用户登录，其中虚拟用户登陆安全级别最高。

## 特点

1. 只能访问服务器为其提供的FTP服务，而不能访问系统的其他资源。
2. 虚拟用户支持多用户，且可以配置独立密码，可根据用户适应不同场景。

##  原理

以本地系统用户为宿主（一般是不能登录系统的本地用户），然后通过虚拟用户和本地系统用户建立映射关系，实现虚拟用户登录FTP服务功能。

# VSFTP搭建

## 安装VSFTP

```bash
yum install vsftpd libdb-utils
```

#### 用户配置

```bash
mkdir /opt/ftp_server   #创建ftp根目录
useradd  -d  /opt/sftp/ftp_server -s /sbin/nologin virftp  # 指定用户组为sftp  家目录为/opt/sftp/myftp  无法登陆OS
echo 'passwordstr' |passwd --stdin.  #设置用户密码为passwordstr
```

#### 目录配置

```bash
# 属主与权限必须严格按照以下配置，如需写权限可在此基础上创建子目录用于写
chown virftp:virftp /opt/ftp_server
```

#### 重启VSFTPD服务

```bash
systemctl restart vsftpd
```

### 配置虚拟用户（方案一）

#### 虚拟用户创建

1. 创建虚拟用户密码文件；

   ```bash
   # vi /etc/vsftpd/vir_conf/vir_user
   # 虚拟用户名与密码分行存储
   deppon      #虚拟用户名
   deppon@123  #虚拟用户对应密码
   
   chmod 600 /etc/vsftpd/conf/vir_user
   ```

2. 生成虚拟用户数据库

   ```bash
   db_load -T -t hash -f /etc/vsftpd/conf/vir_user /etc/vsftpd/conf/vir_user.db
   chmod 600 /etc/vsftpd/conf/vir_user.db
   ```

3. 配置虚拟用户验证文件

   ```bash
   # vi /etc/pam.d/vsftpd   注释文件中所有配置项，新增以下配置项
   auth	required	/lib64/security/pam_userdb.so	db=/etc/vsftpd/conf/vir_user
   account	required	/lib64/security/pam_userdb.so	db=/etc/vsftpd/conf/vir_user
   ```


#### VSFTP服务配置

```bash
# vi /etc/vsftpd/vsftpd.conf

#禁止匿名用户登录
anonymous_enable=NO

# 允许用户创建上传
write_enable=YES

#允许本地用户登录，虚拟用户需映射本地用户，需开启该配置
local_enable=YES
#限制本地用户仅可访问家目录
chroot_local_user=YES
#启用虚拟账户映射 
guest_enable=YES
#指定虚拟用户映射本地用户名               
guest_username=virftp
#使用虚拟用户验证（PAM验证），对应/etc/pam.d目录下配置文件名
pam_service_name=vsftpd
#设置存放各虚拟用户配置文件的目录（此目录下与虚拟用户名相同的文件为用户专属配置文件）
user_config_dir=/etc/vsftpd/vir_conf
#启用chroot时，虚拟用户根目录允许写入
allow_writeable_chroot=YES
#是否启用用户清单，启用后根据userlist_deny参数配置判定清单中用户是否可以登陆,与user_list配合使用  ftpusers为禁止登陆用户列表，无开关控制
userlist_enable=NO
# 指定清单属性，YES为拒绝清单，NO为允许清单
userlist_deny=NO
#禁用反向解析，提升登陆ftp速度
reverse_lookup_enable=NO
#指定上传文档umask
local_umask=022

#***************
#以下配置为可选
#****************
# 自定义登陆提示语
ftpd_banner=Welcome to blah FTP service.
#开启日志
xferlog_enable=YES
#使用标准文件日志
xferlog_std_format=YES
#配置日志文件路径
xferlog_file=/var/log/vsftpd.log
#会话超时，客户端连接到ftp但未操作
idle_session_timeout=600
#数据传输超时
data_connection_timeout=120
#是否允许ascii码方式上传文件
ascii_upload_enable=NO
#是否允许ascii码方式下载二进制文件
ascii_download_enable=NO
#配置最大连接数
max_clients=300
#配置单个IP最大链接数
max_per_ip=10

#是否启动主动模式
port_enable=YES
#指定主动模式是否使用20端口传输数据，为NO时，可结合ftp_data_port配置数据传输端口
connect_from_port_20=NO
ftp_data_port=23

#是否启用被动模式
pasv_enable=YES
#配置被动模式端口上下限
pasv_min_port=60000
pasv_max_port=65535
#是否允许使用ls -R等命令
ls_recurse_enable=YES


#是否启用监听
listen=YES
#指定监听端口，默认为21
listen_port=21
```

> 1. 主动模式：服务端只需防火墙开放固定端口，客户端使用高位随机端口访问服务端
>
> 2. 被动模式：服务端需要防火墙开放监听端口与高位范围端口，客户端发起请求后，服务端从指定范围端口中随机分配端口供客户端连接
> 3. 变更监听端口：修改listen_port及/etc/services配置文件中ftp项端口

#### VSFTP用户级配置

```bash
# 为虚拟用户创建ftp根目录
mkdir -p /opt/ftp_server/demo
#确保映射用户对所有ftp目录均具备读写权限
chown virftp:virftp  /opt/ftp_server/demo

# vim /etc/vsftpd/vir_conf/deppon
# 配置文件与虚拟用户名保持一致

#允许浏览FTP目录和下载
anon_world_readable_only=NO
#允许虚拟用户上传文件
anon_upload_enable=YES
#允许虚拟用户创建目录
anon_mkdir_write_enable=YES
#允许虚拟用户执行其他操作（如改名、删除）
anon_other_write_enable=YES
#上传文件的掩码,如022时，上传目录权限为755,文件权限为644
anon_umask=022
#指定虚拟用户的虚拟目录（虚拟用户登录后的主目录）
local_root= /opt/ftp_server/demo
```

#### 禁止登陆用户清单

注释配置文件中所有用户，配置文件为：/etc/vsftpd/ftpusers

#### 重启VSFTPD服务

```bash
systemctl restart vsftpd
```

# 登陆验证

```bash
ftp localhost
```

###  SFTP方案 （方案二）

####  用户配置

```bash
# 指定ftp工作区
mkdir /opt/sftp
# 创建用户指定家目录,且不允许登陆OS
useradd -d /opt/sftp -s /bin/nologin sftp
# 修改工作区根目录权限，必须严格按照以下配置，根目录只允许下载，不允许上传，如需上传可在根目录下创建子目录
chown root:sftp  /opt/sftp
chmod 755 /opt/sftp
```



#### SSH服务配置

```bash
# vi /etc/ssh/sshd_config

PasswordAuthentication	yes  # yes：允许使用密码登陆   no：只能使用公钥登陆
# 注释原有 Subsystem
# Subsystem sftp /usr/lib/openssh/sftp-server
Subsystem sftp internal-sftp   # 使用sshd的内置sftp代码，不另外启动sftp-server进程

# Match 必须位于文件末尾，否则会导致其后其他配置丢失
# 限制sftp用户组用户
Match Group sftp
	#指定ftp用户的根目录
	ChrootDirectory /opt/sftp/%u
	# 不允许tcp转发
	AllowTcpForwarding no
	# 不允许图形化转发
	X11Forwarding no
```

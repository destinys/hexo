---
title: Linux端口转发
categories: Linux
tags: ssh
author: semon
date: 2021-08-06
---

# SSH端口转发

`Linux`的`ssh`服务不仅能够远程登陆和管理,还可以在本地计算机与远程服务器之间建立`tcp`通道，实现代理、内网穿透、暴露内网服务等功能，简单可靠；

`ssh`常用参数详解：

+ `C`：请求压缩所有数据；
+ `T`：禁用终端模拟；
+ `N`：不执行远程指令，仅用于端口转发；
+ `D[local_ip:]port`：动态端口转发，实现代理服务器，支持`SOCKET4`和`SOCKET5`协议；
+ `L[local_ip:]port:remote_ip:remote_port`：建立本地端口与远程服务器端口的`TCP`隧道；
+ `R[ssh_server_ip:]ssh_server_port:local_ip:local_port`：建立远端`ssh`服务器到本地的`tcp`隧道 ；（如果失败，则需要调整`ssh`服务器上的`/etc/ssh/sshd_config`配置文件，添加或修改`GatewayPorts yes`选项，并重启`ssh`服务）；
+ `f`：后台执行`ssh`指令；
+ `g`：允许远程主机连接主机的转发端口；
+ `i`：指定ssh访问秘钥；
+ `P`：指定`ssh`访问端口；

## 动态端口转发

将向本地指定端口发送的请求通过`ssh`服务器向外转发；

```bash
#~/bin/bash
ssh -C -T -N -D 127.0.0.1:8000  semon@10.0.0.10
```

> 将`127.0.0.1：8000`作为一个`SOCKET4/5`的代理，比如`curl --proxy socks5://127.0.0.1:8000 https://www.baidu.com`

## 本地端口转发

将远程服务器的指定端口通过`ssh`服务器转发到本地计算机端口；

```ssh
#!/bin/bash
ssh -C -T -N -L  127.0.0.1:3390:59.111.211.50:3389  semon@10.0.0.10
```

> 将内网服务器的远程桌面(59.111.211.50:3389)经过`ssh`服务器转发到本地计算机`127.0.0.1:3390`；
>
> 即本地访问127.0.0.1:3390就相当于访问59.111.211.50:3389

## 远程端口转发

将本地计算机的指定端口经过`ssh`服务器转发到远程服务器的指定端口；

```bash
#!/bin/bash 
ssh -T -C -N -R 59.111.211.50:3389:10.0.0.10:3390  semon@10.0.0.10
```

> 用于将本地局域网计算机的服务经过`ssh`服务器暴露出去，访问59.111.211.50:3389相当于访问10.0.0.10:3390

# Nginx端口转发

`Nginx`除了能够支持域名转发之外，也支持`TCP`端口转发；

通过`Nginx`进行`tcp`端口转发，需使用源码编译版本添加`stream`支持；

## Nginx编译

编译步骤为：

1. 通过官网下载稳定版`nginx`；

2. 解压源码表并进入解压目录；

3. 通过命令行进行软件编译：

   ```bash
   #!/bin/bash
   ./configure --prefix=/opt/nginx  -with-stream --with-stream_ssl_module --with-http_ssl_module --with-http_stub_status_module
   make && make install
   ```

4. 修改`nginx.conf`配置文件，添加`stream`模块配置，实现端口转发：

   ```text
   stream {
   	server {
   		listen 3307;
   		proxy_pass 59.111.211.50:3306;
   	}
   }
   ```

5. 启动服务：

   ```bash
   #!/bin/bash
   # 启动服务
   nginx 
   
   # 测试并加载配置
   nginx -t
   nginx -s reload
   
   # 停止服务
   ## 快速停止
   nginx -s stop
   ## 完整有序停止
   nginx -s quit
   ```

6. 验证监听端口

   ```bash
   #！/bin/bash
   netstat -anp |grep 3307
   ```

   


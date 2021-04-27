---
title: Nginx架构原理及使用
categories: Background
tags: nginx
author: semon
date: 2021-03-13
---



# Nginx详解

## 1. 序言

Nginx是lgor Sysoev为俄罗斯访问量第二的rambler.ru站点设计开发的。从2004年发布至今，凭借开源的力量，已经接近成熟与完善。

Nginx功能丰富，可作为HTTP服务器，也可作为反向代理服务器，邮件服务器。支持FastCGI、SSL、Virtual Host、URL Rewrite、Gzip等功能。并且支持很多第三方的模块扩展。

另外，一些厂商基于Nginx进行了衍生版本开发，其中较为成功的版本为Tengine，官方的简介说针对大访问量网站的需求，添加了很多高级功能和特性。Tengine的性能和稳定性已经在大型的网站如淘宝网，天猫商城等得到了很好的检验。它的最终目标是打造一个高效、稳定、安全、易用的Web平台。

传统的 Web 服务器，每个客户端连接作为一个单独的进程或线程处理，需在切换任务时将 CPU 切换到新的任务并创建一个新的运行时上下文，消耗额外的内存和 CPU 时间，当并发请求增加时，服务器响应变慢，从而对性能产生负面影响。

Nginx 是开源、高性能、高可靠的 Web 和反向代理服务器，而且支持热部署，几乎可以做到 7 * 24 小时不间断运行，即使运行几个月也不需要重新启动，还能在不间断服务的情况下对软件版本进行热更新。性能是 Nginx 最重要的考量，其占用内存少、并发能力强、能支持高达 5w 个并发连接数，最重要的是，Nginx 是免费的并可以商业化，配置使用也比较简单。

Nginx 的最重要的几个使用场景：

1. 静态资源服务，通过本地文件系统提供服务；
2. 反向代理服务，延伸出包括缓存、负载均衡等；
3. API 服务，OpenResty ；



## 2. 相关概念

### 2.1 简单请求与非简单请求

同时满足一下条件的请求即为简单请求：

a. 请求方法为HEAD、GET、POST三种之一；

b. HTTP头部不超过以下键值：

```html
Accept
Accept-Language
Content-Language
Last-Event-ID
Content-Type: application/x-www-form-urlencoded、multipart/form-data、text/plain
```

浏览器在处理简单请求与非简单请求的方式存在很大差别：

**简单请求**

对于简单请求，浏览器会自动在头部信息中增加`Origin`字段后直接发出,`Origin`字段用来说明本次请求来自哪个源，源的格式为"协议+域名+端口"。

服务器对于存在`Origin`字段的请求会优先检测源是否在许可范围内，如果源在许可范围内，服务器返回的响应会添加`Access-Control-`开头的信息字段，反之则会返回一个正常的HTTP响应；浏览器接收到返回的响应后，会检查响应头是否包含`Access-Control-Allow-Origin`字段，如果没有则抛出一个XHR的`error`事件；

**非简单请求**

非简单请求即对服务器有特殊操作的请求，比如方法为`PUT`或`DELETE`，或者`Content-Type`的值为`application/json`。浏览器再省事通信前，或发送一次HTTP遇见`OPTION`请求，询问服务器当前网页所在域名是否在服务器许可名单之内，以及可用HTTP请求方法及请求头字段信息。验证通过，浏览器才会发起正式的`XHR`请求，否则直接报错。



### 2.2 跨域请求

在浏览器上当前访问的网站向另一个网站发送请求获取数据的过程就是跨域请求。

跨域是浏览器的同源策略决定的，是一个重要的浏览器安全策略，用于限制一个origin的文档或者它加载的脚本与另一个源的资源进行交互，他能够帮助阻隔恶意文档，减少可能被公技的媒介，可以使用CORS配置解除跨域限制。

以下举例说明：

```html
# 非跨域 同源不同目录
http://demo.com/app1/index.html
http://demo.com/app2/index.html

# 跨域 协议不同
http://demo.com
https://demo.com

# 跨域 端口不同  默认端口为80，可省略
http://demo.com:81
http://demo.com

# 跨域 主机不同
http://demo.com
http://demo01.com
```



### 2.3 代理

代理分为正向代理(Forward Proxy)与反向代理(Reverse Proxy)，他们的区别为：

**正向代理**：一般的访问流程为客户端直接向目标服务器发送请求并获取内容，使用正向代理后，客户端想代理服务器发送请求，并指定目标服务器，然后由代理服务器和目标服务器通信，转交请求并获取内容，再返回给客户端。正向代理隐藏了真实的客户端，为客户端收发请求，使真实客户端对服务器不可见。

**反向代理**：反向代理的流程仍然是客户端向代理服务器发送请求，但不需要客户端指定目标服务器，代理服务器根据规则进行客户端的请求转发，获取内容并返回给客户端；反向代理隐藏了真实的服务器，为服务器收发请求，使真实的服务器对客户端不可见。一般在处理跨域请求的时候比较常用。



举个栗子：

1、某天我想吃雪糕，拿起手机下单让外卖小哥帮我去XX超市买箱雪糕给我送过来；此时，我是客户端，外卖小哥是代理服务器，XX超市是目标服务器。

2、某天我又想吃雪糕了，拿起手机在某东下单购买一箱雪糕送货上门；此时，我仍然是客户端，某东是反向代理服务器，雪糕厂是目标服务器；对于我来说，我不用管雪糕是哪个厂商生产的，我只要知道找某东可以买到雪糕即可，雪糕厂对我不可见，只有某东才知道这箱雪糕采购自哪个厂商。

原理参见下图：

![image-20200521214542628](./Nginx介绍及部署/image-20200521214542628.png)

![image-20200521214557656](./Nginx介绍及部署/image-20200521214557656.png)



### 2.4 负载均衡

一般情况下，客户端发送多个请求到服务器，服务器处理请求，处理完毕后，将结果返回给客户端。

随着互联网时代到来，访问量与数据量飞速增长，业务系统复杂度持续上升，并发量激增很容易导致服务器宕机。此时除了升级服务器外，性价比最高的做法就是多台服务器组成集群实现负载均衡；负载均衡的核心是分摊压力。

![image-20200521215100663](./Nginx介绍及部署/image-20200521215100663.png)


### 2.5 动静分离

为了加快网站的解析速度，可以把动态页面和静态页面由不同的服务器来完成解析，加快解析速度，降低单个服务器压力。

![image-20200521215204551](./Nginx介绍及部署/image-20200521215204551.png)

一般来说，大型应用都需要进行动静分离，由于Nginx的高并发及静态资源缓存等特性，经常将静态资源部署在Nginx上。如果请求的是静态资源，直接到静态资源目录获取资源，如果是动态资源请求，则利用反向代理，把请求转发给对应服务器进行处理，从而实现动静分离。

使用前后端分离，可以很大程度提升静态资源访问速度，即使动态服务不可用，静态资源访问仍不受影响。



## 3. Nginx部署

### 3.1 YUM安装

最简单的安装方式为通过linux自带包管理服务yum进行安装。

```bash
# nginx安装
yum install nginx

# nginx版本查看
nginx -v
```

### 3.2 源码包安装

```BASH
# 下载源码包
wget http://nginx.org/download/nginx-1.16.1.tar.gz 

# 安装依赖包
yum install -y openssl zlib pcre-devel

#编译安装
tar -zxvf nginx-1.16.1.tar.gz 
./configure --prefix=/usr/ndp/5.4.0/nginx-1.16.1 
make & make install
/usr/ndp/5.4.0/nginx-1.16.1/sbin/nginx

# 添加第三方模块-健康检查
wget http://github.com/yaoweibin/nginx_upstream_check_module
unzip nginx_upstream_check_module
patch -p1 < /home/semon/nginx_upstream_check_module/check_1.16.1+.patch
cd ~/nginx-1.16.1
./configure --prefix=/usr/ndp/5.4.0/nginx-1.16.1  --add-module=/home/semon/nginx_upstream_check_module
make 
cd /usr/ndp/5.4.0/nginx-1.16.1/sbin
cp  nginx  nginx.bak
cp ~/nginx-1.16.1/objs/nginx  /usr/ndp/5.4.0/nginx-1.16.1/sbin
```

## 4. Nginx常用命令

Nginx的命令可以通过`nginx -h`查看所有命令，以下为常用命令：

```bash
nginx -s reload  # 动态加载配置文件，也叫热重启
nginx -s reopen  # 重启nginx
nginx -s stop   # 快速停止nginx
nginx -s quit   # 等待释放所有进程后停止nginx
nginx -T   # 测试配置文件是否异常
nginx -t -c  <指定目录>  #检查nginx配置目录外的配置文件
```



## 5. Nginx配置语法

Nginx的主配置文件为`nginx.conf`，整体结构图概括如下：

```bash
main          # 全局配置
├── events  # 配置影Nginx服务器或与用户的网络连接
├── http    # 配置代理，缓存，日志定义等绝大多数功能和第三方模块的配置
│   ├── upstream # 配置反向代理服务器地址
│   ├── server   # 配置虚拟主机的相关参数，一个 http 块中可以有多个 server 块
│   ├── server
│   │   ├── location  # server 块可以包含多个 location 块，location 指令用于匹配 uri
│   │   ├── location
│   │   └── ...
│   └── ...
└── ...
```

nginx配置文件语法规则如下：

1. 配置文件由指令与指令块构成；
2. 每条指令以`；`结尾，指令与参数间以空格进行分隔；
3. 指令块以`{}`将多条指令组织在一起；
4. `include`语句允许组合多个配置文件以提升维护性；
5. 使用`#`进行注释，提高代码可读性；
6. 使用`$`引用变量；
7. 部分指令参数，如location支持正则表达式；

### 5.1 Nginx配置样例

Nginx 的样例配置如下：

```bash
## main块
user nginx nginx;  #配置用户或者用户组，用户组为可选项，默认为nobody:nobody
worker_processess 2; # 指定了Nginx要开启的进程数。每个Nginx进程平均耗费10M~12M内存。建议指定和CPU的数量一致即可，默认为1，可配置为auto，由nginx自行检测
pid /nginx/pid/nginx.pid  #指定进行运行文件存放路径
error_log log/error.log debug  #指定日志文件存放路径及日志级别， 级别枚举：debug|info|notice|warn|error|crit|alert|emerg

### events块
events {
	accept_mutex on; # 设置网络连接序列化，防止惊群现象，默认为on；惊群现象：一个网路连接到来，多个睡眠的进程被同事叫醒，但只有一个进程能获得链接，这样会影响系统性能。
	multi_accept on; #设置一个进程是否可同时接受多个网络连接，默认为off
	use epoll; #设置时间驱动模型，枚举类型为select|poll|kqueue|epoll|resig|/dev/poll|eventport；select|poll为标准工作模式，kqueue|epoll为高效工作模式，linux系统推荐为epoll，BSD系统推荐为kqueue
	worker_connection 1024; #最大连接数，默认为1024
}

# http块
http {
	include mime.types;  #引入文件扩展名与文件类型映射关系表
	default_type	application/octet-stream;  # 默认文件类型，octet-stream为二进制流，当文件类型未定义时，使用application/octet-stream
	log_format myFormat '$remote_addr–$remote_user [$time_local] $request $status $body_bytes_sent $http_referer $http_user_agent $http_x_forwarded_for'; #自定义日志存储格式，默认为combined格式
	sendfile on; #允许sendfile方式传输文件，默认为off；on表示开启高效文件传输模式
	sendfile_max_chunk 0; #每个进程单词调用传输数量上限值，0为无上限
	keepalive_timeout 65  # 链接超时时间，单位为s
	
	
	# server块
	server {
		listen 80; # 配置监听端口，转发至虚拟主机
		server 912.168.1.100 demo01; #指定虚拟主机IP或域名 多个域名用空格分隔
		
		# 启用https相关配置
		ssl on;
    ssl_certificate /data/nginx/conf/ssl/kevin.cer;
    ssl_certificate_key /data/nginx/conf/ssl/kevin.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_session_cache    shared:SSL:1m;
    ssl_session_timeout  5m;
    ssl_ciphers  ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4:!DH:!DHE;
    ssl_prefer_server_ciphers  on;
		
		index	index.html	index.htm	index.php;  # 指定默认访问首页文件
		root	/www/www.demo.com	# 指定虚拟主机网页根目录
		charset gb2312	#指定网页默认编码格式
		access_log	logs/access.log main; #指定本虚拟主机日志访问存放路径，main表示继承全局日志格式输出
		
		# location块
		location ~ .*\.(gif|jpg)$ {  # location支持正则匹配  ~ 为区分大小写匹配   ~* 为不区分大小写匹配 （|）表示匹配其中任意项，|用于分割
			root /www/www.demo.com;  # 配置请求根目录
			index	a.txt;	# 设置默认页
			proxy_pass	http://myserver; #请求转发至myserver定义的虚拟主机列表
      deny 192.168.1.201;	#拒绝IP
      allow 192.168.1.100； #允许你的IP
      
      ## 定义转发消息请求头内容
      proxy_set_header Host $host:1000;  #配置转发请求头中主机信息
      prox_set_header	X-Forwarded-For $proxy_add_x_forwarded_for; # 获取请求真实IP和上一次转发IP地址
      proxy_set_header X-From-IP $remote_addr;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_pass http://bdms-dev-http;
      proxy_redirect http:// https://;  # 修改返回请求头信息中服务器信息，支持变量，替换内容中服务器和端口可省略，server默认值为同名服务器，端口默认值为80 
      # proxy_redirect http://localhost:8000/two/ /; 实际返回头信息为http://localhost:80
      # proxy_redirect http://192.168.1.100:8000/two/ http://demo.com; 实际返回信息为 http://demo.com
		}
		
		# proxy_deirect 配置1
		location /one {
			proxy_pass http://myserver:port/two/;
			proxy_redirect  http://myserver:port/two/ /one;
		}
		
		# proxy_redirect 配置2   配置1与配置2等价  
		location /one {
			proxy_pass http://myserver:port/two/;
			proxy_redirect  default;
		}
	}
	
	# upstream块
	upstream myserver {   # myserver 自定义转发虚拟主机列表名称
		ip_hash;
		server	192.168.1.10:1000;	#转发主机1
		server	192.168.1.11:1000 backup; #转发主机2  backup：热备主机 down：正常情况不参与负载均衡  max_fails：允许最大失败次数 fail_timeout：最大失败次数后暂定服务时间
		check interval=30000 rise=2 fall=3 timeout=5000 type=http default_down=false;
    check_http_send "GET /login.jsp HTTP/1.0\r\n\r\n";
    check_http_expect_alive http_2xx http_3xx;
	}
}
```



server块可以包含多个location块，location指令用于匹配uri，语法：

```bash
location [ = | ~ | ~* | ^~] uri {
	...
}
```

正则说明：

1. `=`：精确匹配，用户不含正则表达式的uri前，匹配成功后，不再继续查找；
2. `^~`：用于不含正则表达式的uri前，表示该符号后面的字符为最佳匹配，匹配成功后，不在继续查找；
3. `~`：表示用该符号后面的正则去匹配路径，区分大小写；
4. `~*`：表示用该符号后面的正则去匹配，不区分大小写；

如果uri包含正则匹配，则必须使用`~`或`~*`标志，正则匹配优先级较低，如存在多个正则匹配，则使用表达式最长的那个。

### 5.2 全局变量

Nginx有一些常用的全局变量，可以在配置文件的任意位置引用。

| 全局变量名         | 功能                                                         |
| :----------------- | :----------------------------------------------------------- |
| `$host`            | 请求信息中的 `Host`，如果请求中没有 `Host` 行，则等于设置的服务器名，不包含端口 |
| `$request_method`  | 客户端请求类型，如 `GET`、`POST`                             |
| `$remote_addr`     | 客户端的 `IP` 地址                                           |
| `$args`            | 请求中的参数                                                 |
| `$arg_PARAMETER`   | `GET` 请求中变量名 PARAMETER 参数的值，例如：`$http_user_agent`(Uaer-Agent 值), `$http_referer`... |
| `$content_length`  | 请求头中的 `Content-length` 字段                             |
| `$http_user_agent` | 客户端agent信息                                              |
| `$http_cookie`     | 客户端cookie信息                                             |
| `$remote_addr`     | 客户端的IP地址                                               |
| `$remote_port`     | 客户端的端口                                                 |
| `$http_user_agent` | 客户端agent信息                                              |
| `$server_protocol` | 请求使用的协议，如 `HTTP/1.0`、`HTTP/1.1`                    |
| `$server_addr`     | 服务器地址                                                   |
| `$server_name`     | 服务器名称                                                   |
| `$server_port`     | 服务器的端口号                                               |
| `$scheme`          | HTTP 方法（如http，https）                                   |



## 6. gzip压缩

gzip压缩是一种常用的网页压缩技术，传输的网页经过gzip压缩之后大小通常可以缩减到原来的一般甚至更小，更小的网页体积意味着带宽的节约与传输速度的提升，特别是对于访问量巨大的大型应用来说，每个静态资源体积的缩小，都会带来相当可观的流量与带宽节省。

### 6.1 Nginx配置gzip

使用gzip压缩不仅需要Nginx配置，浏览器端也需要配合，需要在请求消息头中包含`Accept-Encoding:gzip`（IE5之后浏览器默认配置）。一般在请求html和css等静态资源的时候，支持的浏览器再request请求静态资源的时候，会自动加上`Accept-Encoding:gzip`这个header，表示自己支持gzip压缩，nginx拿到这个请求的时候，如果nginx也启用了gzip，就会返回经过压缩后的文件给浏览器，并在request响应的时候加上`content-encoding:gzip`告诉浏览器返回的响应内容采用了压缩，浏览器拿到压缩的文件后，会根据自己的解压方式进行解析。

为了便于管理，一般在`$NGINX_HOME/conf`下创建gzip.conf来定义gzip压缩相关配置，在http、server或location块中直接include即可，配置样例如下：

```bash
gzip on; # 默认off，是否开启gzip
gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

# 上面两个开启基本就能跑起了，下面的愿意折腾就了解一下
gzip_static on;
gzip_proxied any;
gzip_vary on;
gzip_comp_level 6;
gzip_buffers 16 8k;
# gzip_min_length 1k;
gzip_http_version 1.1;
```

配置说明：

1. **gzip_types**：要采用 gzip 压缩的 MIME 文件类型，其中 text/html 被系统强制启用；
2. **gzip_static**：默认 off，该模块启用后，Nginx 首先检查是否存在请求静态文件的 gz 结尾的文件，如果有则直接返回该 `.gz` 文件内容；
3. **gzip_proxied**：默认 off，nginx做为反向代理时启用，用于设置启用或禁用从代理服务器上收到相应内容 gzip 压缩；
4. **gzip_vary**：用于在响应消息头中添加 `Vary：Accept-Encoding`，使代理服务器根据请求头中的 `Accept-Encoding` 识别是否启用 gzip 压缩；
5. **gzip_comp_level**：gzip 压缩比，压缩级别是 1-9，1 压缩级别最低，9 最高，级别越高压缩率越大，压缩时间越长，建议 4-6；
6. **gzip_buffers**：获取多少内存用于缓存压缩结果，16 8k 表示以 8k*16 为单位获得；
7. **gzip_min_length**：允许压缩的页面最小字节数，页面字节数从header头中的 `Content-Length` 中进行获取。默认值是 0，不管页面多大都压缩。建议设置成大于 1k 的字节数，小于 1k 可能会越压越大；
8. **gzip_http_version**：默认 1.1，启用 gzip 所需的 HTTP 最低版本；



## 7. 负载均衡配置

负载均衡样例配置如下：

```bash
http {
  upstream myserver {
  	ip_hash;  # ip_hash 方式
    server 127.0.0.1:81;  # 负载均衡目的服务地址
    server 127.0.0.1:81;
    server 127.0.0.1:82 weight=10;  # weight 方式，不写默认为 1
  }
 
  server {
    location / {
    	proxy_pass http://myserver;
      proxy_connect_timeout 10;
    }
  }
}
```

Nginx默认提供了三种负载分配方式，默认为轮询。常用有以下几种分配方式：

1. 轮询：默认方式，每个请求按时间顺序逐一分配至不同的后端服务器，如果后端服务器宕机，可自动剔除；
2. weight：权重分配，指定轮询纪律，权重越高，被访问的概率就越大，用于调整后端服务器性能不均的情况；
3. ip_hash：每个请求按照客户端的IP进行hash后的结果分配，这样每个用户固定访问一个后端服务器，可以解决动态网页session共享问题。
4. fair：第三方分配算法，按照后端服务器的响应时间分配，响应时间短的优先分配，依赖第三方插件nginx-upstream-fair模块。



## 8. 动静分离配置

配置样例：

```bash
server {
  location /www/ {
  	root /data/;
    index index.html index.htm;
    expires 10d; # -1表示不缓存
  }
  
  location /image/ {
  	root /data/;
    autoindex on;
  }
}
```

通过location指定不同的后缀名实现不同的请求转发。通过expires参数配置浏览器缓存过期时间，减少与服务器之间的请求与流量。



## 9. 双机热备配置

双机热备可实现当Nginx服务器宕机之后，自动切换至备用Nginx服务器提供服务；

![image-20200521224507801](./Nginx介绍及部署/image-20200521224507801.png)



首先安装软件包keepalived：

```bash
yum install keepalived
```

配置文件样例：

```java
global_defs{
   notification_email {
        receive@demo.com
   }
   notification_email_from send@demo.com
   smtp_server 127.0.0.1
   smtp_connect_timeout 30 // 上面都是邮件配置，没卵用
   router_id DEMO01     // 当前服务器名字，用hostname命令来查看
}
vrrp_script chk_maintainace { // 检测机制的脚本名称为chk_maintainace
    script "[[ -e/etc/keepalived/nginx_check.sh ]] && exit 1 || exit 0"// 可以是脚本路径或脚本命令
    interval 2  // 每隔2秒检测一次
    weight -20  // 当脚本执行成立，那么把当前服务器优先级改为-20
}
vrrp_instanceVI_1 {   // 每一个vrrp_instance就是定义一个虚拟路由器
    state MASTER      // 主机为MASTER，备用机为BACKUP
    interface eth0    // 网卡名字，可以从ifconfig中查找
    virtual_router_id 51 // 虚拟路由的id号，一般小于255，主备机id需要一样
    priority 100      // 优先级，master的优先级比backup的大
    advert_int 1      // 默认心跳间隔
    authentication {  // 认证机制
        auth_type PASS
        auth_pass 0000   // 密码
    }
    virtual_ipaddress {  // 虚拟地址vip
       172.0.0.11
    }
}
```

nginx_check.sh脚本如下：

```bash
#!/bin/bash
A=`ps -C nginx --no-header | wc -l`
if [ $A -eq 0 ];then
    /usr/sbin/nginx # 尝试重新启动nginx
    sleep 2         # 睡眠2秒
    if [ `ps -C nginx --no-header | wc -l` -eq 0 ];then
        killall keepalived # 启动失败，将keepalived服务杀死。将vip漂移到其它备份节点
    fi
fi
```

复制一份配置到备份服务器，备份 Nginx 的配置要将 `state` 后改为 `BACKUP`，`priority` 改为比主机小。

设置完毕后各自 `service keepalived start` 启动，经过访问成功之后，可以把 Master 机的 keepalived 停掉，此时 Master 机就不再是主机了 `service keepalived stop`，看访问虚拟 IP 时是否能够自动切换到备机 `ip addr`。

再次启动 Master 的 keepalived，此时 vip 又变到了主机上。



## 10. HTTPS配置

配置HTTPS需要域名服务商提供对应的证书，下载证书的压缩文件，将其中的xx.crt和xx.key文件拷贝至服务器目录，修改server配置，添加以下内容即可：

```bash
server {  
  
  ssl_certificate /etc/nginx/https/1_sherlocked93.club_bundle.crt;   # 证书文件地址
  ssl_certificate_key /etc/nginx/https/2_sherlocked93.club.key;      # 私钥文件地址
  ssl_session_timeout 10m;

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;      #请按照以下协议配置
  ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE;
  ssl_prefer_server_ciphers on;
  
  #安全增强配置
  add_header X-Frame-Options DENY;           # 减少点击劫持
	add_header X-Content-Type-Options nosniff; # 禁止服务器自动解析资源类型
	add_header X-Xss-Protection 1;             # 防XSS攻击
  
  location / {
  ……
  ……
  }
}
```



## 11. 常用技巧

### 11.1 静态服务

```bash
server {
  listen       80;
  server_name  static.sherlocked93.club;
  charset utf-8;    # 防止中文文件名乱码

  location /download {
    alias	          /usr/share/nginx/html/static;  # 静态资源目录
    
    autoindex               on;    # 开启静态资源列目录
    autoindex_exact_size    off;   # on(默认)显示文件的确切大小，单位是byte；off显示文件大概大小，单位KB、MB、GB
    autoindex_localtime     off;   # off(默认)时显示的文件时间为GMT时间；on显示的文件时间为服务器时间
  }
}
```

### 11.2 图片防盗链

```bash
server {
  listen       80;
  server_name  *.sherlocked93.club;
  
  # 图片防盗链
  location ~* \.(gif|jpg|jpeg|png|bmp|swf)$ {
    valid_referers none blocked 192.168.0.2;  # 只允许本机 IP 外链引用
    if ($invalid_referer){
      return 403;
    }
  }
}
```

### 11.3 请求过滤

```bash
# 非指定请求全返回 403
if ( $request_method !~ ^(GET|POST|HEAD)$ ) {
  return 403;
}

location / {
  # IP访问限制（只允许IP是 192.168.0.2 机器访问）
  allow 192.168.0.2;
  deny all;
  
  root   html;
  index  index.html index.htm;
}
```

### 11.4 HTTP转发HTTPS

配置完 HTTPS 后，浏览器还是可以访问 HTTP 的地址 `http://www.demo.com/` 的，可以做一个 301 跳转，把对应域名的 HTTP 请求重定向到 HTTPS 上

```bash
server {
    listen      80;
    server_name www.demo.com;

    # 单域名重定向
    if ($host = 'www.demo.com'){
        return 301 https://www.demo.com$request_uri;
    }
    # 全局非 https 协议时重定向
    if ($scheme != 'https') {
        return 301 https://$server_name$request_uri;
    }

    # 或者全部重定向
    return 301 https://$server_name$request_uri;

    # 以上配置选择自己需要的即可，不用全部加
}
```

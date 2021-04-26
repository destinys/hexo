---
title: Docker架构原理及使用
categories: Dev
tags: docker
author: semon
top: true
---



# Docker安装与配置

从2017年3月开始，docker分裂为两个分支版本docker CE与docker EE。

Docker CE即社区免费版；

Docker EE即企业版，强调安全，但需付费使用；

Docker采用Linux内核技术，所以docker只能运行在Linux系统上，官网说明要求Linux kernel至少3.8以上版本；

```bash
# 移除自带旧版本docker
yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine
                  
# 配置aliyun yum源地址后通过yum安装docker
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

yum makecache fast

# 安装指定版本docker-ce


```



> docker默认安装路径为/var/lib/docker，如果/var没有单独挂载至数据盘，容器出现磁盘空间问题，可将/var/lib/docker目录软链至数据盘规避磁盘空间问题；

# Docker网络

Docker默认支持四中网络模式

| 网络模式  | 说明                                                         |
| --------- | :----------------------------------------------------------- |
| host      | 容器和宿主机共享Network namespace。                          |
| container | 创建的容器不会创建自己的网卡，配置自己的IP，而是和一个指定的容器共享IP、端口范围。 |
| none      | 容器有独立的Network namespace，但并没有对其进行任何网络设置，如分配veth pair 和网桥连接，配置IP等。 |
| bridge    | （默认为该模式）此模式会为每一个容器分配、设置IP等，并将容器连接到一个docker0虚拟网桥，通过docker0网桥以及Iptables nat表配置与宿主机通信 |

## 默认网络

当安装Docker时，它会自动创建三个网络，即bridge、host和none，通过`docker network ls`可以查看；docker运行容器时，可以通过`—net`标志来指定容器网络模式，默认模式为bridge；



## Host模式

Host模式相当于vmware虚拟机中的桥接模式，容器与宿主机在同一个网络中，但容器没有独立的IP地址；容器与宿主机共用同一个Network Namespace。容器内部不会虚拟网卡，而是直接使用宿主机的IP和端口。

Host模式可以直接使用宿主机的IP地址与外界进行通信，容器内部服务端口也可以直接使用宿主机端口，不需要进行NAT转发，host网络模式的最大优势是网络性能较好，但网络隔离性较差；

## Container模式

Container网络模式指定一个新创建的容器与一个已有容器进行Network Namespace进行共享，而不是与宿主机共享。新创建的容器不会创建自己的网卡，而是与一个已存在的容器进行共享，两个容器的进程可以通过lo网卡设备进行通信；

## None模式

None模式下，容器拥有自己的Network Namespace，但是并不会对容器进行任何网络 配置，即容器没有网卡、IP、路由等信息。用户可自行为容器添加网卡、配置IP路由等；

None网络模式下容器仅具有lo回环网络，容器无法联网，但是封闭的网络环境能够很好的保证容器的安全性；

## Bridge模式

Bridge模式相当于vmware虚拟机中的nat模式，容器使用独立的Network Namespace，并链接到docker0虚拟网桥上；虚拟网桥的工作模式与物理交换机类似，相当于Bridge模式的容器通过bridge0链接在一个二层网络中。

Bridge网络模式下，容器启动后会在宿主机上创建一堆虚拟网卡veth pair设备，veth pair设配一端位于容器中，作为容器的网卡设备，一般命名为eth0；另一端位于宿主机中，作为网卡设备加入到docker0网桥中，一般以vethxxxx形式命名；



# Docker镜像管理

docker官方镜像库地址：https://hub.docker.com/

可在官方镜像仓库按照需要拉取对应仓库基础镜像，启动docker加载镜像后，在官方基础镜像基础上安装所需依赖软件；所有基础环境安装完毕后，可重新保存为新的镜像进行分享或个人存档；

## 镜像加载

docker默认从hub.docker拉取镜像，如主机环境不通公网，也可自定搭建私有镜像库或直接使用离线文件加载镜像至本地；

+ **官方镜像**

```bash
docker image pull ubuntu:v1
# ubuntu为仓库名
# v1为标签名，当标签名为latest时可省略
```

+ **本地镜像**

docker import：加载镜像文件时，可自定义镜像名称及标签；

docker load：无法自定义镜像名称及标签；

```bash
docker import - ubuntu:20.0.4 < alibaba-ubuntu-20.0.4.tar.gz
# ubuntu为导入后自定义的镜像名
# 20.0.4为导入后的自定义标签名

docker load < alibaba-ubuntu-20.0.4.tar.gz
```

> 镜像文件必须为tar.gz格式

## 镜像保存

docker支持基于容器创建新的镜像，用于备份或分享；

```bash
docker commit -a "semon" -m "remark"  ubuntu_vm ubuntu_dev:v2
# ubuntu_vm为容器名 
# ubuntu_dev为镜像名
# v2为标签名
```

## 镜像导出

docker支持用户将容器导出或保存为镜像，也支持将镜像导出为本地镜像文件；

+ **容器导出**

```bash
docker export ubuntu_vm > ubuntu_vm.tar.gz
# ubuntu_vm为容器名，支持容器名或容器ID
# 仅导出当前容器的文件目录

docker save -o docker_con.tar.gz ubuntu_vm
# -o 指定导出本地镜像文件名
# ubuntu_vm为容器名
```

> docker save 保存容器实际上保存的是容器所加载的镜像，与直接保存镜像结果一致；

+ **镜像导出**

```bash
docker save -o docker_img.tar.gz ubuntu:latest 6fc15b302f3a
# -o指定导出本地镜像文件名
# 支持通过镜像ID或镜像仓库:标签名指定要导出的镜像
# 支持一次性导出多个镜像至同一个文件，多个镜像通过空格分隔
```

## 镜像删除

```bash
docker rmi
```



## 注意事项

+ `docker export` 与`docker import`配套使用，`docker save`与`docker load`配套使用；
+ `docker export`将容器导出为本地文件，实际为linux系统的文件目录，故文件较小，无法回滚历史操作，常用于制作通用环境镜像；
+ `docker import`仅支持将`docker export`导出的文件加载为镜像，加载时可自定义镜像名称及标签，如指定的镜像名及标签与已有镜像冲突，则抢占镜像名与标签，已有镜像被抹除镜像名及标签，但镜像仍然存在，可通过镜像ID进行操作；
+ `docker save`将镜像或指定容器所加载的镜像导出为本地文件，导出的本地文件实际为一个多层文件目录，重新加载后，可回滚历史操作，故文件较大；
+ `docker load`仅支持将`docker save`导出的文件加载为镜像，加载后镜像名称与导出镜像保持一致；

# Docker常用操作

容器相当于一个小型的虚拟机，而镜像就相当于这个虚拟机的操作系统；

## 启停容器

启动容器有两种情况，一种是基于镜像新建一个容器并启动，另一种是将终止状态的容器重新启动；

+ **新建容器并启动**

```bash
docker run --name ubuntu-dev -it -p 8000:8000 -v /opt/wks/versions/app:/opt/wks/app --restart=always --privileged=true  --net net-udf --ip 172.10.0.10 ubuntu:latest /bin/bash
# --name指定启动的容器名称
# -i 打开标准输入，用于控制台交互
# -t 分配tty，支持命令行登陆
# -p 用于指定本地端口与容器端口映射，可用多个-p指定多个端口映射
# -v 指定本地与容器目录映射
# --privileged 指定容器内root真正拥有root权限，否则容器内root仅相当于本地系统的普通用于，无法完整拥有映射目录权限；
# --restart 指定容器终止后的重启策略 always-总是重启 on-failure-故障退出重启  no-不重启
# ubuntu:latest 指定容器加载的镜像
# /bin/bash 指定以/bin/bash登陆容器
# 容器启动后无法再更改宿主机与容器的映射关系
```

>  -d, --detach=false， 指定容器运行于前台还是后台，默认为false
>  -i, --interactive=false， 打开STDIN，用于控制台交互
>  -t, --tty=false， 分配tty设备，该可以支持终端登录，默认为false
>  -u, --user=""， 指定容器的用户
>  -a, --attach=[]， 登录容器（必须是以docker run -d启动的容器）
>  -w, --workdir=""， 指定容器的工作目录
>  -c, --cpu-shares=0， 设置容器CPU权重，在CPU共享场景使用
>  -e, --env=[]， 指定环境变量，容器中可以使用该环境变量
>  -m, --memory=""， 指定容器的内存上限
>  -P, --publish-all=false， 指定容器暴露的端口
>  -p, --publish=[]， 指定容器暴露的端口
>  -h, --hostname=""， 指定容器的主机名
>  -v, --volume=[]， 给容器挂载存储卷，挂载到容器的某个目录
>  --volumes-from=[]， 给容器挂载其他容器上的卷，挂载到容器的某个目录
>  --cap-add=[]， 添加权限，权限清单详见：http://linux.die.net/man/7/capabilities
>  --cap-drop=[]， 删除权限，权限清单详见：http://linux.die.net/man/7/capabilities
>  --cidfile=""， 运行容器后，在指定文件中写入容器PID值，一种典型的监控系统用法
>  --cpuset=""， 设置容器可以使用哪些CPU，此参数可以用来容器独占CPU
>  --device=[]， 添加主机设备给容器，相当于设备直通
>  --dns=[]， 指定容器的dns服务器
>  --dns-search=[]， 指定容器的dns搜索域名，写入到容器的/etc/resolv.conf文件
>  --entrypoint=""， 覆盖image的入口点
>  --env-file=[]， 指定环境变量文件，文件格式为每行一个环境变量
>  --expose=[]， 指定容器暴露的端口，即修改镜像的暴露端口
>  --link=[]， 指定容器间的关联，使用其他容器的IP、env等信息
>  --lxc-conf=[]， 指定容器的配置文件，只有在指定--exec-driver=lxc时使用
>  --name=""， 指定容器名字，后续可以通过名字进行容器管理，links特性需要使用名字
>  --net=“bridge”，指定容器网络设置:
>
> ​				bridge 使用docker daemon指定的网桥
>
> ​				host //容器使用主机的网络
>
> ​				container:NAME_or_ID >//使用其他容器的网路，共享IP和PORT等网络资源
>
> ​				none 容器使用自己的网络（类似--net=bridge），但是不进行配置
>
> --rm=false， 指定容器停止后自动删除容器(不支持以docker run -d启动的容器)
> --sig-proxy=true， 设置由代理接受并处理信号，但是SIGCHLD、SIGSTOP和SIGKILL不能被代理

+ **启动已有容器**

```bash
docker start ubuntu-dev
# ubuntu-dev为容器名，也可指定容器ID来启动容器
```

+ **停止容器**

```bash
docker stop ubuntu-dev
# ubuntu-dev为容器名，也可指定容器ID来启动容器
```



## 登陆容器

+ **attach**

```bash
docker attach ubuntu-dev
# ubuntu-dev为容器名
```

+ **exec**

```bash
docker exec -it ubuntu-dev
```

> 以上两种方式均可登陆容器，但通过`attach`登陆容器，通过`exit`退出登陆时，会导致容器停止，建议使用`exec`进行容器登陆

## 查看容器

```bash
# 查看当前运行中容器
docker ps

# 查看所有状态容器
docker ps -a

# 仅查看容器id
docker ps -a -q

# 查看容器或镜像元数据
docker inspect ubuntu-dev
# 可指定容器名/容器ID/镜像名/镜像ID
```



## 删除容器

```bash
docker rm ubuntu-dev
# 指定容器名或容器ID均可
```

> **小技巧**
>
> ```bash
> #批量停止容器
> docker stop ${docker ps -a -q}
> # 批量删除容器
> docker rm ${docker ps -a -q}
> ```



## 创建网络

```BASH
# 不指定类型默认为bridge模式网络;
docker network create  --subnet=172.10.0.0/16  net_udf;
```



# Docker Compose

Compose是定义和运行多容器Docker应用程序的工具。 使用Compose，您可以使用YAML文件来配置应用程序的服务。 然后，使用单个命令，您可以创建并启动配置中的所有服务。

使用Compose 基本上分为三步：

1. Dockerfile 定义应用的运行环境
2. docker-compose.yml 定义组成应用的各服务
3. docker-compose up 启动整个应用

Docker有很多优势，但对于运维或开发者来说，Docker最大的有点在于它提供了一种全新的发布机制。这种发布机制，指的是我们使用Docker镜像作为统一的软件制品载体，使用Docker容器提供独立的软件运行上下文环境，使用Docker Hub提供镜像统一协作，最重要的是该机制使用Dockerfile定义容器内部行为和容器关键属性来支撑软件运行。

 Dockerfile作为整个机制的核心。这是一个非常了不起的创新，因为在Dockerfile中，不但能够定义使用者在容器中需要进行的操作，而且能够定义容器中运行软件需要的配置，于是软件开发和运维终于能够在一个配置文件上达成统一。运维人员使用同一个Dockerfile能在不同的场合下“重现”与开发者环境中一模一样的运行单元（Docker容器）出来。

## 安装docker-compose

直接从github下载即可，需依赖docker 1.9.1以上；

```bash
# 安装
curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 验证
docker-compose --version
```

 **Docker-compose用法**

> Usage:
> docker-compose [-f <arg>...] [options] [COMMAND] [ARGS...]

**docker-compose常用命令：**
build  构建或重建服务
kill   杀掉容器
logs  显示容器的输出内容
port  打印绑定的开放端口
ps   显示容器
pull  拉取服务镜像
restart 重启服务
rm  删除停止的容器
run  运行一个一次性命令
scale 设置服务的容器数目
exec 在容器里搪行命令
start 开启服务
stop 停止服务
up  创建并启动容器

其实这些常用命令用docker的命令功能是一样的。

## Docker-compose配置

Compose允许用户通过一个docker-compose.yml模板文件（YAML 格式）来定义一组相关联的应用容器为一个项目（project）。
Compose模板文件是一个定义服务、网络和卷的YAML文件。Compose模板文件默认路径是当前目录下的docker-compose.yml，可以使用.yml或.yaml作为文件扩展名。
Docker-Compose标准模板文件应该包含version、services、networks 三大部分，最关键的是services和networks两个部分。

**举例说明：**

```yml
version: '3'
services:
  nginx:
    hostname: nginx
    build:
      context: ./nginx
      dockerfile: Dockerfile
      args:
      	- password=secret
    depends_on:
    	- mysql
    ports:
      - 80:80
    networks:
      - front
    volumes:
      - ./wwwroot:/usr/local/nginx/html
    container_name: "nginx"
    links:
    	- mysql
    external_links:
    	- mysql1
    extra_hosts:
    	- "nginx 10.0.0.2"
    	- "mysql 10.0.0.3"
    dns:
    	- 8.8.8.8
    	- 9.9.9.9

  mysql:
    hostname: mysql
    image: mysql:5.6
    ports:
      - 3306:3306
    networks:
      - back
    volumes:
      - ./mysql/conf:/etc/mysql/conf.d
      - ./mysql/data:/var/lib/mysql
    command: --character-set-server=utf8
    env_file:
    	- ./common.env
    environment:
      MYSQL_ROOT_PASSWORD: 123456
      MYSQL_DATABASE: bookstack
      MYSQL_USER: bookstack
      MYSQL_PASSWORD: passWD
 
networks:
  front:
    driver: bridge
  back:
    driver: bridge
```

可以看到一份标准配置文件应该包含 version、services、networks 三大部分，共有三级标签，每一级都是缩进两个空格。下面来详细说明一下里面的内容：

### version

定义compose的版本号为version 3，可以参考官方文档详细了解具体有哪些版本 https://docs.docker.com/compose/compose-file/

### services

+ **nginx**：这是services下面的二级标签，名字用户自己定义，它将是服务运行后的名称；

  + hostname:  这是定义容器的主机名，将写入到/etc/hostname中；
  + image：指定容器启动加载镜像；
  + build：指定基于dockerfile自动构建镜像并使用该镜像启动容器
    + context：指定基于当前命令执行时的相对路径；
    + dockerfile：指定通过上面指定路径中的Dockerilfe来构建；context拼接dockerfile后可定位dockerfile文件；
    + args：指定构建过程中的环境变量，构建成功后销毁；等价于dockerfile中ARG指定
  + depends_on：指定当前容器需要依赖与其他容器间的依赖关系；
  + environment：指定容器加载环境变量；
  + command：指定命令覆盖容器启动后默认指定的命令；
  + ports：指定宿主机与容器端口映射；
  + networks：指定容器加入网络，与一级标签networks配合使用；
  + volumes：指定宿主机与容器目录映射；
  + container_name：指定容器名称；
  + links：指定链接容器，相当于``docker client --link`并将自动将关联容器主机名映射添加至当前容器的`/etc/hosts`中；
  + external_links：指定链接非当前Docker-compose编排的容器；
  + extra_hosts：指定容器内`/etc/hosts`追加主机名映射；
  + dns： 指定容器内域名解析DNS地址；
  + env_file：指定环境变量配置文件（可配置多个文件），与environment冲突时，以environment为准；

  ### networks

  + front：networks下面的二级标签，由用户自定义，宿主机会根据Docker-compose运行目录名及标签名拼接生成对应的网络名称，拼接格式为：目录名__标签名
    + driver：指定网络模式，如host、none、bridge等；

# Docker swarm集群

　Swarm是Docker公司推出的用来管理docker集群的平台，几乎全部用GO语言来完成的开发的，代码开源在https://github.com/docker/swarm， 它是将一群Docker宿主机变成一个单一的虚拟主机，Swarm使用标准的Docker API接口作为其前端的访问入口，换言之，各种形式的Docker

Client(compose,docker-py等)均可以直接与Swarm通信，甚至Docker本身都可以很容易的与Swarm集成，这大大方便了用户将原本基于单节点的系统移植到Swarm上，同时Swarm内置了对Docker网络插件的支持，用户也很容易的部署跨主机的容器集群服务。

　　Docker Swarm 和 Docker Compose 一样，都是 Docker 官方容器编排项目，但不同的是，Docker Compose 是一个在单个服务器或主机上创建多个容器的工具，而 Docker Swarm 则可以在多个服务器或主机上创建容器集群服务，对于微服务的部署，显然 Docker Swarm 会更加适合。

从 Docker 1.12.0 版本开始，Docker Swarm 已经包含在 Docker 引擎中（docker swarm），并且已经内置了服务发现工具，我们就不需要像之前一样，再配置 Etcd 或者 Consul 来进行服务发现配置了。

　　Swarm deamon只是一个调度器(Scheduler)加路由器(router),Swarm自己不运行容器，它只是接受Docker客户端发来的请求，调度适合的节点来运行容器，这就意味着，即使Swarm由于某些原因挂掉了，集群中的节点也会照常运行，放Swarm重新恢复运行之后，他会收集重建集群信息。

## Docker Swarm架构

![image-20210223114006497](Dcoker%E9%95%9C%E5%83%8F%E7%AE%A1%E7%90%86/image-20210223114006497.png)

Swarm是典型的master-slave结构，通过发现服务来选举manager。manager是中心管理节点，各个node上运行agent接受manager的统一管理，集群会自动通过Raft协议分布式选举出manager节点，无需额外的发现服务支持，避免了单点的瓶颈问题，同时也内置了DNS的负载均衡和对外部负载均衡机制的集成支持；

**Docker API**：用于管理镜像的生命周期；

**Swarm Cli**：提供用户进行Swarm集群管理入口；

**LeaderShip**：提供集群Manager角色HA，防止单点故障；

**Discovery Service**：Swarm集群的发现服务，它会在所有的Node上注册Agent，通过Agent将Node信息上报给Manager；发现服务的常用实现方式有以下集中：

1. Hosted Discovery with Docker Hub

   通过Docker Hub提供发现服务，需联通公网环境；

   ```bash
   docker run -d -p <manager_port>:2375 token://<cluster_id>
   # token在创建Swarm集群时生成，全球唯一
   ```

2. 基于KV分布式存储系统

   支持的分布式系统有etcd、consul、zookeeper等；

   ```bash
   swarm join --advertise=<node_ip:2375> consul://<consul_addr>/<optional path prefix>
   ```

3. 静态描述文件

   ```bash
   swarm manage -H tcp://<Swarm_ip:swarm_port> file:///opt/mycluster
   ```

4. 静态IP列表

   ```bash
   swarm manage -H <swarm_ip:swarm_port> nodes://<node_ip1:2375>,<node_ip2:2375>
   ```

**Schedule**：用于容器调度时选择最优节点：

1. Filter（过滤）

   当创建或运行容器时，filter会告诉调度器哪些节点是符合要求的。按照类型可分为节点过滤与容器过滤

   + 节点过滤
     + Constraints：约束过滤器，可根据当前操作系统、内核版本、存储类型等条件进行过滤，当然也可以自定义约束，在启动Daemon的时候，通过Label来指定当前主机所具有的特点；
     + Health filter：根据节点状态进行过滤，移除故障节点；
   + 容器过滤
     + Affnity：亲和性过滤器，支持容器亲和性和镜像亲和性，如部署应用时，想将前端容器和数据库容器放在一起，即可通过亲和性过滤器实现；
     + Dependency：依赖过滤器，如创建容器时指定了目录映射、链接某个容器时，则创建的容器或和依赖的容器部署在同一个节点上；
     + Ports filter：根据端口使用情况进行过滤；

2. Strategy（策略）

   Swarm在scheduler节点（Leader节点）运行容器的时候，会根据指定的策略来计算最适合运行容器的节点，目前支持的策略有：spread，binpack及random；

   + Spread：选择运行容器最少的的宿主机来创建新的容器，Spread策略会使容器均衡的分布在集群的各个节点上，节点宕机损失较小；
   + Binpack：尽可能的在当前容器比较集中且资源足够的节点上创建新的容器，最大可能避免容器碎片化，但一旦该节点宕机随时可能比较大；
   + Random：顾名思义，就是随机选择一个节点来创建新的容器，一般用于调试；

## Swarm关键概念

+ Swarm

集群的管理和编排是使用嵌入docker引擎的SwarmKit，可以在docker初始化时启动swarm模式或者加入已存在的swarm；

+ Node（节点）

Node是加入到swarm集群的Docker引擎实例；按照功能可分为Manager(管理节点)与Worker(工作节点)：
  1. Manager：接收客户端服务定义，将任务发送到worker节点；维护集群期望状态和集群管理功能及Leader选举。默认情况下manager节点也会运行任务，也可以配置只做管理任务。提供对外的接口，部署我们的应用；Manager是整个Swarm集群的大脑，为避免单点故障，Manager至少有两个节点，通过raft协议进行状态同步；
  2. Worker：接收并执行从管理节点分配的任务，并报告任务当前状态，以便管理节点维护每个服务期望状态。

+ Service（服务）

Service是要在Worker上执行的Task的定义，它运行于Worker上；Service在创建时，需为对应Worker指定镜像；

+ Task（任务）

Task是Service的执行实体，一个Task包含了一个容器及其运行的命令；Manager根据指定数量的Task副本分配至对应Worker上；

## Swarm Cluster特性

1. Dcoker Engine集成集群管理

   使用Docker Engine CLI创建一个Docker Engine的Swarm模式，在集群中部署应用程序服务；

2. 去中心化设计

   Swarm按角色分为Manager与Worker，Manager故障不影响应用使用；

3. 动态扩容缩容

   可以声明每个服务运行的容器数量，通过添加或删除容器数量自动调整期望的状态；

4. 期望状态协调

   Swarm Manager监控集群状态，并调整当前状态与期望状态之间的差异。例如，配置一个服务运行副本为5，当某个副本所在服务器宕机后，Manager将自动创建1个新的副本，并根据调度策略分配至可用的Worker；

5. 多主机网络

   可以为服务制定overlay网络。当初始化或更新应用程序时，Swarm Manager会自动为overlay网络上的容器分配IP地址；

6. 服务发现

   Swarm Manager节点为集群中的每个服务分配唯一的DNS记录和负载均衡VIP。可以通过Swarm内置的DNS服务器查询集群中每个运行的容器；

7. 负载均衡

   实现服务副本间负载均衡，提供入口访问。也可将服务入口暴露给外部负载均衡器再次进行负载均衡；

8. 安全传输

   Swarm中每个节点使用TLS相互验证和加密，确保安全的节点间通信；

9. 滚动更新

   集群容器内应用进行更新/升级时，可逐步将应用服务更新至节点，出现问题回滚至历史版本即可；

## Swarm Cluster管理

**集群管理**

```bash
# 创建swarm集群
docker swarm init --advertise-addr 10.0.0.10

# 加入集群
docker swarm join --token "token_id" 10.0.0.10:2377

# 离开集群
docker swarm leave

# 更新集群配置
docker swarm update
```

**堆栈管理**

创建编排文件

```yml
# helloworld.yml
version: '3'
services:

  mynginx:
    image: hub.test.com:5000/almi/nginx:0.1
    ports:
     - "8081:80"
    deploy:
      replicas: 3

  busybox:
    image: hub.test.com:5000/busybox:latest
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      replicas: 2
```



```bash
# 部署堆栈并创建任务
docker stack -c helloworld.yml helloworld

# 查看堆栈中的任务
docker stack ps helloworld

# 查看现有堆栈
docker stack ls

# 删除堆栈
docker stack rm helloworld

# 查看堆栈中服务
docker stack services helloworld
```

**服务管理**

```bash
# 创建服务 
docker service
  # 创建一个服务
  - docker service create
    # 创建的副本数
    - docker service create --replicas 副本数
    # 指定容器名称
    - docker service create --name 名字
    # 每次容器与容器之间的更新时间间隔。
    - docker service create --update-delay s秒
    # 更新时同时并行更新数量，默认1
    - docker service create --update-parallelism 个数
    # 任务容器更新失败时的模式，（“pause”停止|”continue“继续），默认pause。
    - docker service create --update-failure-action 类型
    # 每次容器与容器之间的回滚时间间隔。
    - docker service create --rollback-monitor 20s
    # 回滚故障率如果小于百分比允许运行
    - docker service create --rollback-max-failure-ratio .数值（列“.2”为%20）
    # 添加网络
    - docker service create --network 网络名
    # 创建volume类型数据卷
    - docker service create --mount type=volume,src=volume名称,dst=容器目录
    # 创建bind读写目录挂载
    - docker service create --mount type=bind,src=宿主目录,dst=容器目录
    # 创建bind只读目录挂载
    - docker service create --mount type=bind,src=宿主目录,dst=容器目录,readonly
    # 创建dnsrr负载均衡模式
    - docker service create --endpoint-mode dnsrr 服务名
    # 创建docker配置文件到容器本地目录
    - docker service create --config source=docker配置文件,target=配置文件路径
    # 创建添加端口
    - docker service create --publish 暴露端口:容器端口 服务名
  # 查看服务详细信息，默认json格式
  - docker service inspect
      # 查看服务信息平铺形式
      - docker service inspect --pretty 服务名
  # 查看服务内输出
  - docker service logs
  # 列出服务
  - docker service ls
  # 列出服务任务信息
  - docker service ps　　　　
      # 查看服务启动信息
      - docker service ps 服务名
      # 过滤只运行的任务信息
      - docker service ps -f "desired-state=running" 服务名
  # 删除服务
  - docker service rm
  # 缩容扩容服务
  - docker service scale
      # 扩展服务容器副本数量
      - docker service scale 服务名=副本数
  # 更新服务相关配置
  - docker service update
      # 容器加入指令
      - docker service update --args “指令” 服务名
      # 更新服务容器版本
      - docker service update --image 更新版本 服务名         
       回滚服务容器版本
       docker service update --rollback 回滚服务名
      # 添加容器网络
      - docker service update --network-add 网络名 服务名
      # 删除容器网络
      - docker service update --network-rm 网络名 服务名
      # 服务添加暴露端口
      - docker service update --publish-add 暴露端口:容器端口 服务名
      # 移除暴露端口
      - docker service update --publish-rm 暴露端口:容器端口 服务名
      # 修改负载均衡模式为dnsrr
      - docker service update --endpoint-mode dnsrr 服务名
			# 更新服务动态命令设置
      docker service update --env-add
      docker service update --env-rm  
      docker service update --host-add 
      docker service update --host-rm
      docker service update --hostname
      docker service update --mount-add type=volume,source=/data,target=/data
      docker service update --mount-rm  type=volume,source=/data,target=/data
      docker service update --network-add name=my-network,alias=web1   # Add a network
      docker service update --network-rm  name=my-network,alias=web1
      docker service update --publish-add published=8080,target=80 # Add or update a published port
      docker service update --publish-rm  published=8080,target=80  # Remove a published port by its target port


# 查看swarm集群中服务对应IP
docker service inspect --format '{{ .Endpoint.VirtualIPs }}'  服务名
```



**节点管理**

```bash
# 查看集群所有节点
docker node ls

# 删除节点
docker node rm <node_id>

# 查看节点详情，[--pretty]显示格式化后信息
docker node inspect <node_id> [--pretty]

# 节点降级，由管理节点降级为工作节点
docker node demote <node_id>

# 节点升级，由工作节点升级为管理节点，
docker node premote <node_id> [node_id2]

# 查看节点中task
docker node ps <node_id>

# 节点更新 可用状态有 active pause drain
## 排除节点node01
docker node update --availability drain node01
## 恢复排除的节点node01
docker node update --availability active node01
```


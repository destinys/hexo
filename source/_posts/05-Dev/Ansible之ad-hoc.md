---
title: Ansible之ad-hoc（二）
categories: Dev
tags: ansible
author: semon
date: 2021-05-22
---

# `Ansible之ad-hoc`

`ad-hoc`是`ansible`临时命令，就像我们执行的shell命令一样，执行完即结束，ad-hoc模式的命令格式如下：`ansible <host-pattern> [-f forks] [-m module_name] [-a args]`

> `-a MODULE_ARGS`　　　#模块的参数，如果执行默认COMMAND的模块，即是命令参数，如： “date”，“pwd”等等
> `-k`，`--ask-pass` #ask for SSH password。登录密码，提示输入SSH密码而不是假设基于密钥的验证
> `--ask-su-pass` #ask for su password。su切换密码
> `-K`，`--ask-sudo-pass` #ask for sudo password。提示密码使用sudo，sudo表示提权操作
> `--ask-vault-pass` #ask for vault password。假设我们设定了加密的密码，则用该选项进行访问
> `-B SECONDS` #后台运行超时时间
> `-C` #模拟运行环境并进行预运行，可以进行查错测试
> `-c CONNECTION` #连接类型使用
> `-f FORKS` #并行任务数，默认为5
> `-i INVENTORY` #指定主机清单的路径，默认为`/etc/ansible/hosts`
> `--list-hosts` #查看有哪些主机组
> `-m MODULE_NAME` #执行模块的名字，默认使用 command 模块，所以如果是只执行单一命令可以不用 -m参数
> `-o` #压缩输出，尝试将所有结果在一行输出，一般针对收集工具使用
> `-S` #用 su 命令
> `-R SU_USER` #指定 su 的用户，默认为 root 用户
> `-s` #用 sudo 命令
> `-U SUDO_USER` #指定 sudo 到哪个用户，默认为 root 用户
> `-T TIMEOUT` #指定 ssh 默认超时时间，默认为10s，也可在配置文件中修改
> `-u REMOTE_USER` #远程用户，默认为 root 用户
> `-v` #查看详细信息，同时支持`-vvv`，`-vvvv`可查看更详细信息
>
> 
>
> 执行命令返回的结果颜色代表的含义：
> 绿色：被管理端没有被修改
> 黄色：被管理端发生变更
> 红色：执行出现故障



## `ansible`常用模块

1. `ping`模块

   主要用于主机连通性测试：`ansible db -m ping`

2. `command`模块

   主要用户直接在远程主机上执行命令，并将结果返回本机；（默认模块，可省略）：`ansible db -m command -a 'ss -ntl'`

   命令模块接受命令名称，后面是空格分隔的列表参数。给定的命令将在所有选定的节点上执行。它不会通过`shell`进行处理；该命令不支持`|` 管道命令。
   下面来看一看该模块下常用的几个命令：

   > chdir　　　   # 在执行命令之前，先切换到该目录
   > executable    # 切换shell来执行命令，需要使用命令的绝对路径
   > free_form 　 # 要执行的Linux指令，一般使用Ansible的-a参数代替。
   > creates 　    # 一个文件名，当这个文件存在，则该命令不执行,可以用来做判断
   > removes      # 一个文件名，这个文件不存在，则该命令不执行

3. `shell`模块

   支持远程主机上调用`shell`解释器运行命令，支持`shell`的各种功能，例如管道等；`ansible db -m shell -a 'cat /etc/passwd |grep root'`

4. `copy`模块

   主要用于将文件复制到远程主机，同时支持给定内容生成文件和修改权限等； `ansible db -m copy -a 'src=~/hello  dest=/data/hello mode=755'`

   相关选项如下：

   > `src`　　　　            #被复制到远程主机的本地文件。可以是绝对路径，也可以是相对路径。如果路径是一个目录，则会递归复制，用法类似于"rsync"
   > `content`　　　         #用于替换"src"，可以直接指定文件的值
   > `dest`　　　　          #必选项，将源文件复制到的远程主机的**绝对路径**
   > `backup`　　　         #当文件内容发生改变后，在覆盖之前把源文件备份，备份文件包含时间信息
   > `directory_mode`　　#递归设定目录的权限，默认为系统默认权限
   > `force`　　　　        #当目标主机包含该文件，但内容不同时，设为"yes"，表示强制覆盖；设为"no"，表示目标主机的目标位置不存在该文件才复制。默认为"yes"
   > `others`　　　　      #所有的 file 模块中的选项可以在这里使用

5. `file`模块

   主要用于设置文件属性，如创建文件、创建软链、删除文件等；`ansible db -m file -a 'path=/data/hello  state=directory'`

   常用命令如下：

   > `force`　　   #需要在两种情况下强制创建软链接，一种是源文件不存在，但之后会建立的情况下；另一种是目标软链接已存在，需要先取消之前的软链，然后创建新的软链，有两个选项：yes|no
   > `group`　　  #定义文件/目录的属组。后面可以加上`mode`：定义文件/目录的权限
   > `owner`　　  #定义文件/目录的属主。后面必须跟上`path`：定义文件/目录的路径
   > `recurse`　　#递归设置文件的属性，只对目录有效，后面跟上`src`：被链接的源文件路径，只应用于`state=link`的情况
   > `dest`　　	 #被链接到的路径，只应用于`state=link`的情况
   > `state`　　   #状态，有以下选项：
   >
   > > `directory`：如果目录不存在，就创建目录
   > > `file`：即使文件不存在，也不会被创建
   > > `link`：创建软链接
   > > `hard`：创建硬链接
   > > `touch`：如果文件不存在，则会创建一个新的文件，如果文件或目录已存在，则更新其最后修改时间
   > > `absent`：删除目录、文件或者取消链接文件

6. `fetch`模块

   主要用于从远程主机获取/复制文件到本地； `ansible db -m fetch -a 'src=/data/hello'`

   常用选项如下：

   > `dest`：用来存放文件的目录
   > `src`：在远程拉取的文件，并且必须是一个**file**，不能是**目录**

7. `cron`模块

   主要用于管理远程主机`cron`计划任务，语法与本地`crontab`一致; `ansible db -m -a ' name="ntp update every 10 min" minute=*/10 job="/sbin/ntpdate 10.0.0.2 &>/dev/null"'`

   常用选项如下：

   > `day=`     #日应该运行的工作( 1-31, *, */2, )
   > `hour=`    # 小时 ( 0-23, *, */2, )
   > `minute=` #分钟( 0-59, *, */2, )
   > `month=` # 月( 1-12, *, /2, )
   > `weekday=` # 周 ( 0-6 for Sunday-Saturday,, )
   > `job=`     #指明运行的命令是什么
   > `name=` #定时任务描述
   > `reboot` # 任务在重启时运行，不建议使用，建议使用special_time
   > `special_time` #特殊的时间范围，参数：reboot（重启时），annually（每年），monthly（每月），weekly（每周），daily（每天），hourly（每小时）
   > `state`   #指定状态，present表示添加定时任务，也是默认设置，absent表示删除定时任务
   > `user`    # 以哪个用户的身份执行

8. `yum`模块

   主要用于受控主机软件安装；`ansible -m yum -a 'name=httpd state=present'`

   > `name=`　　#所安装的包的名称
   > `state=`　　#`present`--->安装， `latest`--->安装最新的, `absent`---> 卸载软件。
   > `update_cache`　　#强制更新yum的缓存
   > `conf_file`　　#指定远程yum安装时所依赖的配置文件（安装本地已有的包）。
   > `disable_pgp_check`　　#是否禁止GPG checking，只用于`present`or `latest`。
   > `disablerepo`　　#临时禁止使用yum库。 只用于安装或更新时。
   > `enablerepo`　　#临时使用的yum库。只用于安装或更新时。

9. `service`模块

   主要用于服务程序管理；`ansible -m service -a 'name=nginx state=started enabled=true'`

   常用选项如下：

   > `arguments` #命令行提供额外的参数
   > `enabled` #设置开机启动。
   > `name=` #服务名称
   > `runlevel` #开机启动的级别，一般不用指定。
   > `sleep` #在重启服务的过程中，是否等待。如在服务关闭以后等待2秒再启动。(定义在剧本中。)
   > `state` #有四种状态，分别为：`started`--->启动服务， `stopped`--->停止服务， `restarted`--->重启服务， `reloaded`--->重载配置

10. `user`模块

    主要用于管理受控主机用户账号；`ansible -m user -a 'name=semon uid=12345'`

    主要选项如下：

    > `comment`　　# 用户的描述信息
    > `createhome`　　# 是否创建家目录
    > `force`　　# 在使用state=absent时, 行为与userdel –force一致.
    > `group`　　# 指定基本组
    > `groups`　　# 指定附加组，如果指定为(groups=)表示删除所有组
    > `home`　　# 指定用户家目录
    > `move_home`　　# 如果设置为home=时, 试图将用户主目录移动到指定的目录
    > `name`　　# 指定用户名
    > `non_unique`　　# 该选项允许改变非唯一的用户ID值
    > `password`　　# 指定用户密码
    > `remove`　　# 在使用state=absent时, 行为是与userdel –remove一致
    > `shell`　　# 指定默认shell
    > `state`　　# 设置帐号状态，不指定为创建，指定值为absent表示删除
    > `system`　　# 当创建一个用户，设置这个用户是系统用户。这个设置不能更改现有用户
    > `uid`　　# 指定用户的uid

11. `group`模块

    主要用于管理受控主机用户组信息；`ansible -m group -a 'name=semon gid=12345'`

    常用选项如下：

    > `gid=`　　#设置组的GID号
    > `name=`　　#指定组的名称
    > `state=`　　#指定组的状态，默认为创建，设置值为`absent`为删除
    > `system=`　　#设置值为`yes`，表示创建为系统组

12. `script`模块

    主要用于将本地脚本在受控主机上执行；`ansible -m script -a '/data/env.sh'`

13. `setup`模块

    主要用于手机信息，通过调用`facts`组件来实现；`ansible db -m setup -a 'filter=”*mem*“'`

    > facts组件是Ansible用于采集被管机器设备信息的一个功能，我们可以使用setup模块查机器的所有facts信息，可以使用filter来查看指定信息。整个facts信息被包装在一个JSON格式的数据结构中，ansible_facts是最上层的值。
    > facts就是变量，内建变量 。每个主机的各种信息，cpu颗数、内存大小等。会存在facts中的某个变量中。调用后返回很多对应主机的信息，在后面的操作中可以根据不同的信息来做不同的操作。如redhat系列用yum安装，而debian系列用apt来安装软件。

14. `get_url`模块

    主要用于从指定url下载文件； `ansible db -m get_url -a 'url=http://easydata-demo.163yun.com dest=/home/demo.txt mode=750'`

    常用选项如下：

    > `url=`       #地址 
    >
    > `dest=`    #目标文件 
    >
    > `mode=`  #文件权限

15. `git`模块

    主要用于管理git仓库；`ansible db -m git -a 'repo=https://gitee.com/jasonminghao/dubbo-demo-service.git dest=/data/git_repo/dubbo-demo-service version=78d5d96 accept_hostkey=yes'`

    常用选项如下：

    > `- repo    # git仓库地址(https/ssh)`
    >
    > `- dest    # 将代码克隆到指定路径`
    >
    > `- version # 克隆指定版本分支/commit id`
    >
    > `- accept_hostkey # 类似于-o StrictHostKeyChecking=no`
    >
    > ​	` yes`
    >
    > ​	`no`


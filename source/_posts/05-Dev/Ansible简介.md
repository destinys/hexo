---
title: Ansible简介（一）
categories: Dev
tags: ansible
author: semon
date: 2021-05-22
---



# 自动化运维工具之`Ansible`

## `Ansible`简介

### `Ansible`是什么**

`ansible`是新出现的自动化运维工具，基于Python开发，集合了众多运维工具（`puppet`、`chef`、`func`、`fabric`）的优点，实现了批量系统配置、批量程序部署、批量运行命令等功能。

`ansible`是基于 `paramiko` 开发的,并且基于模块化工作，本身没有批量部署的能力。真正具有批量部署的是`ansible`所运行的模块，`ansible`只是提供一种框架。`ansible`不需要在远程主机上安装`client/agents`，因为它们是基于ssh来和远程主机通讯的。ansible目前已经已经被红帽官方收购，是自动化运维工具中大家认可度最高的，并且上手容易，学习简单

### `Ansible`特点

1. 部署简单，只需在主控端部署`Ansible`环境，被控端无需做任何操作；
2. 默认使用`SSH`协议对设备进行管理；
3. 有大量常规运维操作模块，可实现日常绝大部分操作；
4. 配置简单、功能强大、扩展性强；
5. 支持`API`及自定义模块，可通过Python轻松扩展；
6. 通过`Playbooks`来定制强大的配置、状态管理；
7. 轻量级，无需在客户端安装`agent`，更新时，只需在操作机上进行一次更新即可；
8. 提供一个功能强大、操作性强的Web管理界面和`REST API`接口——AWX平台。

<img src="Ansible简介/image-20210521212738243.png" alt="image-20210521212738243" style="float:left; zoom:67%;" />

​		上图中主要模块如下：

​		`Ansible`：`Ansible`核心程序;

​		`HostInventory`：`Ansible`管理主机信息列表，包括主机地址、端口、密码等信息以及针对主机/组定义的变量；

​		`Playbooks`：剧本/任务集，编排定义任务集的配置文件，通常为`json`或`YML`文件；

​		`CoreMoudles`：核心模块，实现各项功能的基础模块，供任务调用执行；

​		`CustomModules`：自定义模块，主要由用户自行开发核心模块无法支持的功能，支持多种语言；

​		`ConnectionPlugins`：链接插件，`Ansible`与主机通信时使用；



## `Ansible`安装配置

### `Ansible`安装

+ `pip`安装

  如果主机当前没有安装`pip`模块，可通过`yum`先进行`pip`模块安装；

  ```bash
    # 方案一
  yum install python-pip
  # 方案二
  wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
  python get-pip.py
  
  pip install ansible
  ```

+ `yum`安装

  通过Linux常用包管理工具安装；

  ```bash
  yum install epel-release -y
  yum install ansible -y
  ```

### `Ansible`配置

#### 服务配置文件

配置文件名为`ansible.cfg`，主要定义主机的默认配置参数，如主机组位置、默认端口、秘钥文件路径等；

```bash
#inventory = /etc/ansible/hosts 该参数表示资源清单inventory文件的位置，资源清单就是一些Ansible需要连接管理的主机列表

#library = /usr/share/my_modules/ Ansible的操作动作，无论是本地或远程，都使用一小段代码来执行，这小段代码称为模块，这个library参数就是指向存放Ansible模块的目录

#module_utils= /usr/share/my_module_utils/

#remote_tmp= ~/.ansible/tmp指定远程执行的路径

#local_tmp= ~/.ansible/tmpansible管理节点的执行路径

#forks = 5 forks 设置默认情况下Ansible最多能有多少个进程同时工作，默认设置最多5个进程并行处理。具体需要设置多少个，可以根据控制主机的性能和被管理节点的数量来确定。

#poll_interval= 15 轮询间隔

#sudo_user= root sudo使用的默认用户，默认是root

#ask_sudo_pass= True 是否需要用户输入sudo密码

#ask_pass= True 是否需要用户输入连接密码

#remote_port= 22 这是指定连接对端节点的管理端口，默认是22，除非设置了特殊的SSH端口，不然这个参数一般是不需要修改的

#module_lang= C 这是默认模块和系统之间通信的计算机语言,默认为'C'语言.

#host_key_checking= False 跳过ssh首次连接提示验证部分，False表示跳过。

#timeout = 10 连接超时时间

#module_name= command 指定ansible默认的执行模块

#nocolor= 1 默认ansible会为输出结果加上颜色,用来更好的区分状态信息和失败信息.如果你想关闭这一功能,可以把'nocolor'设置为'1':
#private_key_file=/path/to/file.pem在使用ssh公钥私钥登录系统时候，使用的密钥路径。
```



> 配置文件加载顺序：
>
> 1. 环境变量定义路径：`ANSIBLE_CONFIG`;
> 2. 当前执行目录下配置文件：`ansible.cfg`
> 3. 当前用户家目录下配置文件：`~/.ansible.cfg`
> 4. 系统默认配置文件：`/etc/ansible/ansible.cfg`

#### `Inventory`配置文件

+ 主机/组列表配置文件，默认配置文件为`/etc/ansible/hosts`；

  ```
  # 主机/组配置列表，主机列表需在主机组上方
  
  # 主机配置
  ## IP地址 + 端口
  10.0.0.1:22
  ## 主机名 + 端口 + 变量定义
  bigdata-demo1.jd.163.org:22 ansible_ssh_user = root
  
  # 主机组配置，支持通配符
  [db]
  bigdata-demo2.jd.163.org:22
  bigdata-demo3.jd.163.org:22	ansible_ssh_user=root
  
  # 主机组继承
  [cluster:children]
  bigdata-demo[4-6].jd.163.org
  db
  
  # 主机/组变量配置，也可创建独立配置文件
  [db:vars]
  ansible_ssh_user=root
  ansible_ssh_pass=123456
  
  # ansible包含两个默认组
  # all ： 包含所有主机
  # ungrouped：除了all组之外没有其他组的主机
  ```

+ 变量配置文件，默认配置文件路径为`/etc/ansible/`

  + 主机变量配置文件，配置文件与主机名或IP地址一致，格式为`yml`

    ```bash
    # 主机变量：在/etc/ansible/目录下创建目录host_vars，然后创建配置文件bigdata-demo1.jd.163.org.yml  （配置文件名与主机名保持一致）
    vim /etc/ansible/hosts_vars/bigdata-demo1.jd.163.org.yml 
    ansible_ssh_user=root
    ansible_ssh_pass=123456
    ```

  + 主机组变量配置文件，配置文件名与主机组一致，格式为`yml`

    ```bash
    # 主机组变量：在/etc/ansible目录下创建目录group_vars，然后再创建文件web.yml，以组名命名的yml文件
    vim /etc/ansible/group_vars/db.yml
    
    ansible_ssh_user=root
    ansible_ssh_pass=123456
    ```

  + 常用配置参数

    | ansible_ssh_host             | 将要连接的远程主机名.与你想要设定的主机的别名不同的话,可通过此变量设置 |
    | ---------------------------- | ------------------------------------------------------------ |
    | ansible_ssh_port             | ssh端口号。如果不是默认的端口号，通过此变量设置              |
    | ansible_ssh_user             | 默认的 ssh 用户名                                            |
    | ansible_ssh_pass             | ssh 密码(这种方式并不安全,我们强烈建议使用 --ask-pass 或 SSH 密钥) |
    | ansible_sudo_pass            | sudo 密码(这种方式并不安全,我们强烈建议使用 --ask-sudo-pass) |
    | ansible_sudo_exe             | sudo 命令路径(适用于1.8及以上版本)                           |
    | ansible_connection           | 与主机的连接类型.比如:local, ssh 或者 paramiko. Ansible 1.2 以前默认使用 paramiko.1.2 以后默认使用 'smart','smart' 方式会根据是否支持 ControlPersist, 来判断'ssh' 方式是否可行. |
    | ansible_ssh_private_key_file | ssh 使用的私钥文件.适用于有多个密钥,而你不想使用 SSH 代理的情况. |
    | ansible_shell_type           | 目标系统的shell类型.默认情况下,命令的执行使用 'sh' 语法,可设置为 'csh' 或 'fish'. |
    | ansible_python_interpreter   | 目标主机的 python 路径。适用于的情况: 系统中有多个 Python, 或者命令路径不是"/usr/bin/python"，比如 \*BSD， 或者 /usr/bin/python 不是 2.X 版本的 Python。我们不使用 "/usr/bin/env" 机制,因为这要求远程用户的路径设置正确，且要求 "python" 可执行程序名不可为 python以外的名字(实际有可能名为python26)。与 ansible_python_interpreter 的工作方式相同，可设定如 ruby 或 perl 的路径.... |



### `Ansible`常用命令

#### `ansible`命令集

> **`ansible`**：`ad-hoc`临时命令执行工具; （常用）
>
> `ansible-doc`：模块功能查看命令集;
>
> `ansible-galaxy`：上传/下载优秀代码或Roles的官网平台，基于互联网；
>
> **`ansible-playbook`**：定制自动化任务集编排工具；（常用）
>
> `ansible-pull`：远程执行命令工具，常用于海量机器拉取配置；
>
> `ansible-vault`：文件加密工具；
>
> `ansible-console`：基于`linux consoble`界面与用户交互的命令执行工具；

## `Ansible`任务执行

+ **`Ansible`执行模式**

  `Ansible`由控制主机对被控主机的操作方式分为两类，`ad-hoc`及`playbook`：

  + `ad-hoc`：点对点模式，使用单个模块，支持多主机批量执行单条命令；`ad-hoc`操作主机类似通过终端操作Linux主机，一条`ad-hoc`命令相当于在终端中对Linux进行一次简单操作；
  + `playbook`：剧本模式，是`Ansible`的主要管理方式，也是`Ansible`的强大的关键所在；`playbook`通过组合多个任务完成一类功能，如服务安装部署、数据库备份等；可以简单理解为`playbook`是多多条`ad-hoc`命令进行的封装；

+ **`Ansible`执行流程**

  1. 加载配置文件，默认配置文件路径为`/etc/ansible/ansible.cfg`;
  2. 根据`inventory`配置文件找到对应主机/组，并加载相关变量；
  3. 加载任务对应模块文件；
  4. 通过`ansible`将模块或命令转化为对应的临时`python`文件，并推送至受控主机/组;
  5. 对推送至受控主机/组的python文件授予执行权限;(`python`文件保存在受控主机/组执行用户家目录下`.ansible/tmp/xxx/xxx.py`)；
  6. 执行`python`文件，并返回结果至主控端；
  7. 删除临时文件并退出；

  

  <img src="Ansible简介/image-20210521213842013.png" alt="image-20210521213842013" style="float:left; zoom:67%;" />

  ​	
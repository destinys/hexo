---
title: Ansible之playbook（三）
categories: Dev
tags: ansible
author: semon
date: 2021-05-22
---

# `Ansible之playbook`

`Playbook`与`ad-hoc`相比,是一种完全不同的运用ansible的方式，类似与`saltstack`的`state`状态文件。`ad-hoc`无法持久使用，`playbook`可以持久使用。
`playbook`是由一个或多个`play`组成的列表，`play`的主要功能在于将事先归并为一组的主机装扮成事先通过`ansible`中的`task`定义好的角色。从根本上来讲，所谓的`task`无非是调用`ansible`的一个`module`。将多个`play`组织在一个`playbook`中，即可以让它们联合起来按事先编排的机制完成某一任务；

## `playbook核心元素`

* `Hosts` 执行的远程主机列表
* `Tasks` 任务集
* `Varniables` 内置变量或自定义变量在`playbook`中调用
* `Templates` 模板，即使用模板语法的文件，比如配置文件等
* `Handlers` 和`notity`结合使用，由特定条件触发的操作，满足条件方才执行，否则不执行
* `tags` 标签，指定某条任务执行，用于选择运行`playbook`中的部分代码。

## `playbook`语法

`playbook`使用`yaml`语法格式，后缀可以是`yaml`,也可以是`yml`。

* 在单一一个`playbook`文件中，可以连续三个连子号(`---`)区分多个`play`。还有选择性的连续三个点好(`...`)用来表示`play`的结尾，也可省略。
* 次行开始正常写`playbook`的内容，一般都会写上描述该`playbook`的功能。
* 使用#号注释代码。
* 缩进必须统一，不能空格和`tab`混用。
* 缩进的级别也必须是一致的，同样的缩进代表同样的级别，程序判别配置的级别是通过缩进结合换行实现的。
* `YAML`文件内容和`Linux`系统大小写判断方式保持一致，是区分大小写的，`k/v`的值均需大小写敏感
* `k/v`的值可同行写也可以换行写。同行使用:分隔。
* `v`可以是个字符串，也可以是一个列表
* 一个完整的代码块功能需要最少元素包括 `name: task`

## `playbook`执行

通过`ansible-playbook`命令运行格式为：`ansible-playbook <filename.yml> ... [options]`

常用选项如下：

> --check  or -C    #只检测可能会发生的改变，但不真正执行操作
> --list-hosts      #列出运行任务的主机
> --list-tags       #列出playbook文件中定义所有的tags
> --list-tasks      #列出playbook文件中定义的所以任务集
> --limit           #主机列表 只针对主机列表中的某个主机或者某个组执行
> -f                #指定并发数，默认为5个
> -t                #指定tags运行，运行某一个或者多个tags。（前提playbook中有定义tags）
> -v                #显示过程  -vv  -vvv更详细

## `playbook`元素

+ 主机与用户

  在一个`playbook`开始时，最先定义的是要操作的主机和用户；

  ```yml
  tasks: 
    - name: run df -h
      remote_user: test
      shell: name=df -h
  ```

+ `tasks`

  每一个`task`必须有一个名称`name`,这样在运行`playbook`时，从其输出的任务执行信息中可以很清楚的辨别是属于哪一个`task`的，如果没有定义 `name`，`action`的值将会用作输出信息中标记特定的`task`。
  每一个`playbook`中可以包含一个或者多个`tasks`任务列表，每一个`tasks`完成具体的一件事，（任务模块）比如创建一个用户或者安装一个软件等，在`hosts`中定义的主机或者主机组都将会执行这个被定义的`tasks`。

  ```yml
  tasks:
    - name: create new file
      file: path=/tmp/test01.txt state=touch
    - name: create new user
      user: name=test001 state=present
  ```

+ `handler`与`notify`

  当配置发生变更时，`notify actions`会在`playbook`的每一个task结束时被触发，而且即使有多个不同task通知改动的发生，`notify actions`知会被触发一次；比如多个`resources`指出因为一个配置文件被改动，所以`apache`需要重启，但是重新启动的操作知会被执行一次。

  ```yml
  [root@ansible ~]# cat httpd.yml 
  #用于安装httpd并配置启动
  ---
  - hosts: 192.168.1.31
    remote_user: root
  
    tasks:
    - name: install httpd
      yum: name=httpd state=installed
    - name: config httpd
      template: src=/root/httpd.conf dest=/etc/httpd/conf/httpd.conf
      notify:
        - restart httpd
    - name: start httpd
      service: name=httpd state=started
  
    handlers:
      - name: restart httpd
        service: name=httpd state=restarted
  
  #这里只要对httpd.conf配置文件作出了修改，修改后需要重启生效，在tasks中定义了restart httpd这个action，然后在handlers中引用上面tasks中定义的notify。
  ```

+ 变量使用

  1. 配置文件定义变量；
  2. 命令行指定变量：执行`playbook`时候通过参数`-e`传入变量，这样传入的变量在整个`playbook`中都可以被调用，属于全局变量；
  3. 编写`playbook`时，直接在里面定义变量，然后直接引用，可以定义多个变量；注意：如果在执行`playbook`时，又通过`-e`参数指定变量的值，那么会以`-e`参数指定的为准。
  4. `setup`模块默认是获取主机信息的，有时候在`playbook`中需要用到，所以可以直接调用；
  5. 将所有的变量统一放在一个独立的变量`YAML`文件中，`playbook`文件直接引用文件调用变量即可。

  ```yml
  [root@ansible PlayBook]# cat variables.yml 
  ---
  - hosts: all
    remote_user: root
  
    tasks:
      - name: install pkg
        yum: name={{ pkg }}
  
  #执行playbook 指定pkg
  [root@ansible PlayBook]# ansible-playbook -e "pkg=httpd" variables.yml
  ```

+ `tags`

  一个`playbook`文件中，执行时如果想执行某一个任务，那么可以给每个任务集进行打标签，这样在执行的时候可以通过`-t`选择指定标签执行，还可以通过`--skip-tags`选择除了某个标签外全部执行等。

  ```
  # 通过-t选项指定tags进行执行
  ansible-playbook -t rshttpd httpd.yml 
  
  通过--skip-tags选项排除不执行的tags
  ansible-playbook --skip-tags inhttpd httpd.yml 
  ```

+ `template`

  `template`模板为我们提供了动态配置服务，使用`jinja2`语言，里面支持多种条件判断、循环、逻辑运算、比较操作等。其实说白了也就是一个文件，和之前配置文件使用`copy`一样，只是使用`copy`，不能根据服务器配置不一样进行不同动态的配置。这样就不利于管理。
  说明：
  1、多数情况下都将`template`文件放在和`playbook`文件同级的`templates`目录下（手动创建），这样`playbook`文件中可以直接引用，会自动去找这个文件。如果放在别的地方，也可以通过绝对路径去指定。
  2、模板文件后缀名为`.j2`。

## `playbook`模板

### `template`之`when`

条件测试：如果需要根据变量、`facts`或此前任务的执行结果来做为某`task`执行与否的前提时要用到条件测试，通过`when`语句执行，在`task`中使用`jinja2`的语法格式、
when语句：
在`task`后添加`when`子句即可使用条件测试；`when`语句支持`jinja2`表达式语法。

```yml
[root@ansible PlayBook]# cat testtmp.yml 
#when示例
---
- hosts: all
  remote_user: root
  vars:
    - listen_port: 88

  tasks:
    - name: Install Httpd
      yum: name=httpd state=installed
    - name: Config System6 Httpd
      template: src=httpd6.conf.j2 dest=/etc/httpd/conf/httpd.conf
      when: ansible_distribution_major_version == "6"   #判断系统版本，为6便执行上面的template配置6的配置文件
      notify: Restart Httpd
    - name: Config System7 Httpd
      template: src=httpd7.conf.j2 dest=/etc/httpd/conf/httpd.conf
      when: ansible_distribution_major_version == "7"   #判断系统版本，为7便执行上面的template配置7的配置文件
      notify: Restart Httpd
    - name: Start Httpd
      service: name=httpd state=started

  handlers:
    - name: Restart Httpd
      service: name=httpd state=restarted
```



### `template`之`items`

`with_items`迭代，当有需要重复性执行的任务时，可以使用迭代机制。
对迭代项的引用，固定变量名为`“item”`，要在task中使用with_items给定要迭代的元素列表。
列表格式：
  字符串
  字典

```yml
[root@ansible PlayBook]# cat testwith.yml 
# 示例with_items
---
- hosts: all
  remote_user: root

  tasks:
    - name: Install Package
      yum: name={{ item }} state=installed   #引用item获取值
      with_items:     #定义with_items
        - httpd
        - vsftpd
        - nginx
```



### 	`template`之`if`

通过使用`for`，`if`可以更加灵活的生成配置文件等需求，还可以在里面根据各种条件进行判断，然后生成不同的配置文件、或者服务器配置相关等。

```yml
# 循环playbook文件中定义的变量，依次赋值给port
[root@ansible PlayBook]# cat templates/nginx.conf.j2 
{% for port in nginx_vhost_port %}
server{
     listen: {{ port }};
     server_name: localhost;
}
{% endfor %}

# 说明：这里添加了判断，如果listen没有定义的话，默认端口使用8888，如果server_name有定义，那么生成的配置文件中才有这一项。
[root@ansible PlayBook]# cat templates/nginx.conf.j2 
{% for vhost in nginx_vhosts %}
server{
     {% if vhost.listen is defined %}
     listen:    {{ vhost.listen }};
     {% else %}
     listen: 8888;
     {% endif %}
     {% if vhost.server_name is defined %}
     server_name:    {{ vhost.server_name }};
     {% endif %}
     root:   {{ vhost.root }}; 
}
{% endfor %}
```


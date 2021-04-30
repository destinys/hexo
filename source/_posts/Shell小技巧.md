---
title: Shell编程小技巧
categories: Linux
tags: shell
author: Semon
date: 2021-04-27 12:00:00
top: true
---

#  Shell编程

## 系统函数调用

```bash
# 通用脚本执行后显示成功或失败

source /etc/init.d/functions
action /bin/true
```



## 日志筛选重定向

```bash
tail -f /usr/aa.log |awk '{ print $0 ;fflush()}' >>out.txt
```

> tail -f会产生一个未关闭的输出流，输出流向标准输出打印与写入文件的流程是不一致的，数据写入文件需先写出到pipe缓冲区，等待输出流关闭后，数据才会自动写到缓冲区中，完成文件写入；故需要调用ffush强制刷新数据到缓冲区中；



## 强制拷贝

```bash
\cp -f file1  file2
```

> 操作系统环境变量默认配置了cp alias = cp -i，故使用cp -f 拷贝覆盖一个已存在文件时仍然会出现提示，反斜线\ 强制系统不读取alias别名，直接使用环境变量中真实cp命令进行文件拷贝；



## 搜索增强

```bash
# 递归搜索包含软链
find -rL path -name 'keyword'
```

## 非交互式操作crontab

方案一：

```bash
crontab -l  >crontab.conf  # 导出现有定时任务

echo "* * * * * /bin/bash /home/user/demo.sh" >> crontab.conf  # 追加新增定时任务至任务列表

crontab crontab.conf  # 将列表配置项生效至定时任务（覆盖模式）

rm -rf crontab.conf   # 删除导出生成列表
```

方案二：

```bash
# 直接编辑定时任务列表文件  /var/spool/cron/目录下已用户名命名文件为对应用户下定时任务列表
echo "* * * * * /bin/bash demo.sh" >> /var/spool/cron/root
```


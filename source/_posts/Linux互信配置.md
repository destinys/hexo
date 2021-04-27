---
title: Linux互信配置
categories: Linux
tags: ssh
author: semon
date: 2021-03-12
---





```bash
#创建秘钥存储路径
mkdir ~/.ssh

# 生成公钥及私钥
ssh-keygen -t rsa  -P '' -f ~/.ssh/id_rsa

# 生成登陆认证文件
cat ~/.ssh/id_rsa.pub>authorized_keys

# 修改文件权限
chmod 600 ~/.ssh/*

chmod 700 ~/.ssh

# 手工跳转所有节点，将所有主机指纹添加至know_hosts中，避免后期跳转或scp时弹窗认证
ssh -p14816 bigdataXXX.deppon.com.cn
```


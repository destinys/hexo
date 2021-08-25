---
title: VNC服务配置
categories: Linux
tags: vnc
author: semon
date: 2021-04-30
---



# VNC服务配置

## Manjaro系统初始化

```bash
# 更换系统源地址
sudo pacman-mirrors -i -c China -m rank
sudo pacman-mirrors -g

# 安装yay并添加社区源
sudo pacman -Sy yay
yay --aururl “https://aur.tuna.tsinghua.edu.cn” --save

#更新源列表
yay -Sy

# 同步源并更新至系统
yay -Syu

# 更新系统
# 解决 breaks dependency 'libcanberra=0.30+2+gc0620e4-3
pacman -S pamac
pamac update
```



## 安装VNC服务及启动

```bash
#!/bin/bash
# x11vnc
pacman -Sy x11vnc

# tigervnc
nohup x0vncserver -rfbport 5901 -display :0   -geometry 2560x1440  -PasswordFile ~/.vnc/passwd >~/.vnc/vnc.log & 2>&1
```

想1

## VNC桌面启动

```bash
sudo x11vnc -xkb -forever -passwd semon@123 -display :0  -rfbport 5901 -forever -o /var/log/x11vnc.log -bg
```

https://wiki.archlinux.org/title/x11vnc_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)

https://man.archlinux.org/man/x11vnc.1

## 安装virtualbox

```bash
sudo pacman-mirrors -f5 && sudo pacman -Scc && sudo pacman -Syyu virtualbox virtualbox-guest-iso linux54-virtualbox-host-modules

# 重启系统
reboot
# 加载
sudo modprobe vboxdrv
```


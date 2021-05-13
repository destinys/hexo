---
title: Java读取文件
categories: Program
tags: java
date: 2020-02-02 13:00:00
author: Semon
---

# Java读取文件
## 常用获取文件路径方法

```java
//该方法获取的路径为class文件当前路径，后面可接相对class文件的相对路径文件或classpath为根目录的绝对路径；
getClass.getResource():

//该方法获取的路径为classpath的根目录，即'/'，故其后只能跟以非'/'开头的相对路径；
getClass().getClassLoader().getResource():

//获取执行jar操作系统路径
System.getProperty("user.dir")：
```

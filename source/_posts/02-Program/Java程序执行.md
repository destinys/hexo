---
title: Java运行环境变量
categories: Program
tags: java
date: 2020-04-01
author: Semon
---
# Java执行及classpath
## java jar包执行
+ java -jar jarname param1：直接指定需要运行的jar包名称，可接参数；
+ java -cp .：/etc/*:/conf classname param1：可通过cp指定classpath路径，支持通配符，后接入口main class名称，可接参数
    + 指定配置文件时，只能指定到目录，后不可添加/或/*
    + 指定jar包通配时，需使用目录名后接/*,或枚举所有jar名称(jdk6以前仅支持枚举)；
        + java -cp $(echo /data/apps/ilb/*.jar | tr ' ' ':') com.chinacache.Main param1

        ## 查询jar包中类名
        
```bash
for file in *.jar; do echo ${file}; jar vtf ${file} | grep 'content'; done
```

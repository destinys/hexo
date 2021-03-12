---
title: JavaIO流
categories: Program
tags: Java
author: Semon
date: 2020-01-01 15:00:00
top: true
---
# IO流相关
## Java IO流分类：
按流向分类： 
+ 输入流：从文件中读到程序中
+ 输出流：从程序中输出到文件中

按操作对象分配：
+ 字节流：以字节为最小单位进行数据读写
+ 字符流：以字符为最小单位进行数据读写

按功能分类：
+ 节点流：直接与数据源相连进行读写操作
+ 处理流：在节点流上进行套接，实现节点流读写功能增强

IO流的设计模式为装饰设计模式，节点流为原始流，实现流的基本功能，处理流包装节点流，进行功能增强，如编码、缓冲等；

## 常用IO流
### 输入流
+ InputStream/Reader：抽象类，所有输入流的父类，前者为字节流，后者为字符流
    + FileInputStream/FileReader：文件输入流，接受String型文件路径；
        + BufferedInputStream/BufferedReader：缓冲输入流，接受一个文件输入流对象，对输入流进行功能增强
        + InputStreamReader：转换输入流，接受一个InputStream输入流对象及String对象指定字符集，实现字节流向字符流的转换，实际上FileReader是通过转换流来进行实现的；
+ 常用方法：
    + int read();：从输入流中读取单个字节，返回所读取的字节数据（字节数据可直接转换为int类型）。
    + int read(byte[] b)从输入流中最多读取b.length个字节的数据，并将其存储在字节数组b中，返回实际读取的字节数。
    + int read(byte[] b,int off,int len); 从输入流中最多读取len个字节的数据，并将其存储在数组b中，放入数组b中时，并不是从数组起点开始，而是从off位置开始，返回实际读取的字节数。
    + int read(); 从输入流中读取单个字符，返回所读取的字符数据（字节数据可直接转换为int类型）。
    + int read(char[] b)从输入流中最多读取b.length个字符的数据，并将其存储在字节数组b中，返回实际读取的字符数。
    + int read(char[] b,int off,int len); 从输入流中最多读取len个字符的数据，并将其存储在数组b中，放入数组b中时，并不是从数组起点开始，而是从off位置开始，返回实际读取的字符数。

### 输出流
+ OutputStream/Writer：抽象类，所有输出流的父类，前者为字节流，后者为字符流
    + FileOutputStream/FileWriter：文件输出流，接受String型文件路径；
        + BufferedOutputStream/BufferedWriter：缓冲输入流，接受一个文件输入流对象，对输入流进行功能增强
        + OutputStreamReader：转换输入流，接受一个OutputStream输入流对象及String对象指定字符集，实现字节流向字符流的转换，实际上FileWriter是通过转换流来进行实现的；
+ 常用方法：
    + void write(int c); 将指定的字节/字符输出到输出流中，其中c即可以代表字节，也可以代表字符。
    + void write(byte[]/char[] buf); 将字节数组/字符数组中的数据输出到指定输出流中。
    + void write(byte[]/char[] buf, int off,int len ); 将字节数组/字符数组中从off位置开始，长度为len的字节/字符输出到输出流中。
    + void write(String str); 将str字符串里包含的字符输出到指定输出流中。
    + void write (String str, int off, int len); 将str字符串里面从off位置开始，长度为len的字符输出到指定输出流中。

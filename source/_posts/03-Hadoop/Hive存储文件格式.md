---
title: Hive存储与压缩
categories: Hadoop
tags: hive
author: semon
date: 2021-06-26
---

## Hive文件存储

Hive在存储数据时支持通过不同的文件类型来主职，并且为了节省存储资源，也提供了多种压缩算法供用户选择；在创建表时配置正确的文件类型和压缩类型，Hive都可以按照预期读取文件并解析数据，不影响上层HQL语句的使用。Hive默认支持的文件类型有：TextFile、SequenceFile、RCFile、ORC、Parquet及Avro；

压缩算法的编解码器

<img src="Hive存储文件格式/image-20210626010909849.png" alt="image-20210626010909849" style="float:left; zoom:80%;" />

### TextFile

TextFile即为文本格式,Hive的默认存储格式,数据不做压缩,磁盘开销大,数据解析开销大;

### SequenceFile

SequenceFile是Hadoop提供的一种二进制文件格式,是Hadoop支持的标准文件格式,可直接将<key,value>对序列化到文件中,所以SequenceFile文件不能直接查看,但可以通过`hadoop fs -text`查看文件内容。具有使用方便，可分割、可压缩、可进行切片。支持NONE、RECORD、BLOCK（优先）等格式，可进行切片。

### RCFile

大多数的Hadoop和Hive存储是行式存储，在大数据环境下比较高效，因为大多数的表具有的字段数量都不会太多，对文件按块压缩对于除妖处理重复数据的情况比较高效，同事处理和调试工具(more、head、awk)都能很好的使用行式存储的数据；但当用于数仓搭建时，需要操作的表字段可能成百上千，而单次操作的只是一小部分字段，这往往会造成很大的浪费；此时采取列式存储只操作需要的列，可以大大提高性能。

RCFile（Record Columnar File）存储结构遵循的是“先水平划分，再垂直划分”的设计理念，它结合了行存储和列存储的优点：首先，RCFile保证同一行 的数据位于同一节点，因此元组重构的开销很低；其次，像列存储一样，RCFile能够利用列维度的数据压缩，并且能跳过不必要的列读取。

### ORC

ORC是对RCFile的优化，可以提高Hive的读、写、数据处理性能，提供更高的压缩效率。和RCFile格式相比，ORC具有以下有点：

* 每个task只输出单个文件,减轻NN负载；
* 支持复杂数据类型，比如：datetime、decimal以及复杂类型（struct、list、map、union）
* 文件存储了轻量级索引数据；
* 基于数据类型的块模式压缩：integer类型的列使用行程长度编码；string类型的列用字典编码；
* 用多个互相独立的RecordReader并行读取相同的文件；
* 无需扫描makers就可以分割文件；
* 绑定读写所需要的内存；
* metadata的存储是用的Protocol Buffers，支持添加和删除列；

### Parquet

Parquet格式是一种面向分析型的列式存储格式，由Twitter和Cloudera合作开发，目前为Apache孵化的定级项目；

#### 特点：

+ 可跳过不符合条件的数据，只读取需要的数据，降低IO数据量；
+ 压缩编码可以降低磁盘存储空间（由于同一列的数据类型是一样的，可以使用高效的压缩编码进一步节约存储空间）
+ 只读取需要的列，支持向量运算，能够获取更好的扫描性能
+ Spark SQL支持的默认数据源
+ 支持Schematic合并，可以先定义一个简单的schema，然后主键增加列描述
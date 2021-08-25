---
title: SparkCore性能调优
categories: Hadoop
tags: spark
author: semon
date: 2021-06-25
---

## SparkCore十大开发原则

### 避免创建重复的RDD

对于同一份数据，只应该创建一个RDD，避免Spark作业多次重复计算来创建多个代表相同数据的RDD，增加作业的性能开销；

### 尽可能复用同一个RDD

多个RDD的数据有重叠或包含关系时，应该尽量复用一个RDD，这样能够尽可能的减少RDD的数量，从而减少算子执行的次数。因为RDD如果不进行缓存，每次都会从头开始计算；

### 对多次使用的RDD进行持久化

对于持久化的RDD，spark会根据持久化策略，将RDD的数据保存到内存或磁盘中，后续对这个RDD进行算子操作时，直接从内存或磁盘中提取持久化的数据，然后执行算子，而不会从头重新计算；

| 持久化策略                        | 策略说明                                                     |
| --------------------------------- | ------------------------------------------------------------ |
| MEMORY_ONLY                       | 使用未序列化的Java对象格式，将数据保存至内存中，如内存不足，则可能不进行持久化，对应cache()； |
| MEMORY_AND_DISK                   | 使用为序列化的Java对象格式，优先将数据保存至内存中，如内存不足，则保存至硬盘中； |
| MEMORR_ONLY_SER                   | 与MEMORY_ONLY基本一致，区别在于持久化时会对RDD中的数据进行序列化，每个partition会被序列化成一个字节数组；节省内存 |
| MEMORY_AND_DISK_SER               | 与MEMORY_DISK_ONLY基本一致，区别在于持久化时会对RDD中的数据进行序列化，每个partition会被序列化成一个字节数组；节省内存 |
| DISK_ONLY                         | 使用为序列化的Java对象格式，将数据保存至硬盘中               |
| MEMORY_ONLY_2,MEMORY_AND_DISK_2…… | 添加后缀`_2`, 表示将持久化的数据，都复制一份到其他节点，提升容错能力，其他与不带后缀策略一致； |

### 尽量避免使用shuffle类算子

spark作业最小号性能的地方就是shuffle过程。shuffle过程简单来讲，就是将分赛在集群不同节点上的相同key值，拉取到某一个节点上进行聚合或者join等操作；shuffle过程中，各节点上相同key数据都会先写入本地磁盘文件中，通过shuffle service服务开放给其他节点通过网络传输拉取对应key至本节点，同时shuffle操作也可能因为数据倾斜导致内存不足而溢写至本地磁盘；因此，shuffle操作会引发大量的磁盘及网络IO操作，而磁盘与网络IO正式目前大数据集群的瓶颈所在；

### 尽量使用map-side预聚合

所谓的map-side预聚合，是指在每个节点对相同key进行一次聚合操作，然后在进行shuffle；map-side预聚合之后，每个节点上相同key只会有一条记录，大大减少shuffle过程的性能开销；典型例子为reduceByKey与groupByKey；

### 使用高性能算子

```scala
1. 使用reduceByKey、aggregateByKey代替groupByKey
2. 使用mapPartitions替代map
3. 使用foreachPartitions替代foreach
4. 使用repartitionAndSortWithinPartitions替代repartition与sort类操作
5. filter后在进行coalesce 
```

### 广播大变量

使用外部变量时，默认情况下，spark会将该变量复制多个副本，通过网络传输到task中，此时每个task都会有一个变量副本。如果变量本身比较大的话，那么变量在网络传输中将产生大量开销，甚至Executor也会因为变量使用过多内存导致频繁GC，严重影响性能；

鉴于此类情况，通过spark的广播变量功能，对该变量进行广播后，保证每个Executor的内存中，只驻留一份变量副本，同一个Executor中的task共享该变量，大大减少变量副本，减少Executor内存开销及网络开销；

简单来说，就是将每个task一份的变量副本通过广播变量功能缩减为每个Executor一份变量副本；

### 使用Kryo优化序列化性能

spark中主要有三个地方设计到了序列化：

1. 使用外部变量时，变量会被序列化后进行网络传输；
2. 自定义类型作为RDD的泛型类型时，所有自定义类型对象，都会进行序列化；故要求所有自定义类都必须实现Serializable接口；
3. 使用可序列化的持久化策略时，spark会将RDD中每个partition都序列化为一个大的字节数组；

通过使用kryo序列化类型，可提升序列化性能10倍左右；

### 优化数据结构

Java中，有三种类型比较耗费内存：

1. 对象，每个Java对象都有对象头、引用等额外信息，因此比较占用内存空间；
2. 字符串，每个字符串内部都有一个字符数组以及长度等额外信息；
3. 集合类型，比如HashMap、LinkedList等，因为集合内部通常会使用一些内部类封装集合元素，比如Map.Entry；

spark官方建议，在spark编码实现中，特别是对于算子函数中的代码，尽量不要使用以上三种数据类型，尽量使用字符串替代对象，使用原始类型（如int、long等）替代字符串，使用属组替代集合类型，尽可能减少内存占用，从而降低GC频率，提升性能；

优化建议：

1. 使用json替代对象，因为对象头额外消耗16个字节；
2. 使用原始类型替代字符串，因为字符串额外消耗40个字节，比如能用1就不要用“1”；
3. 尽量用数组代替集合类型；
4. 优化需兼顾代码可读性与开发效率；

### 尽可能数据本地化

数据本地化是指数据离计算他的代码尽量缩短距离；基于数据距离代码的距离，可以分为以下几种数据本地化级别（由高至低）：

1. PROCESS_LOCAL：数据与代码在同一个JVM进程中；
2. NODE_LOCAL：数据与代码在同一个节点，但不在同一个进程，如同一节点不同Executor中或在HDFS的block中；
3. NO_PREF：不关心数据位置，任何位置访问数据速度都一样；
4. RACK_LOCAL：数据与代码在同一个机架上；
5. ANY：数据可能在任何地方，如网络环境内，或其他机架上；

对应超时参数为：

| 参数名                      | 默认值              | 说明                                                         |
| --------------------------- | ------------------- | ------------------------------------------------------------ |
| spark.locality.wait         | 3s                  | 定义放弃高级别本地化任务等待超时时间                         |
| spark.locality.wait.node    | spark.locality.wait | 自定义本地节点任务等待时间，配置为0时，跳过节点位置立即搜索机架位置； |
| spark.locality.wait.process | spark.locality.wait | 自定义本地进程任务等待时间                                   |
| spark.locality.wait.rack    | spark.locality.wait | 自定义本地机架启动任务等待时间                               |

## 内存模型调优

### 静态内存模型

spark1.6之前使用静态内存模型，spark1.6开始，多增加了一个统一内存模型。通过`spark.memory.useLegacyMode`参数配置，默认值为`false`，即使用新型动态内存模型；使用静态内存模型，则调整参数值为`true`。

```bash
# 静态内存控制参数
spark.storage.memoryFraction:  # 默认0.6
spark.shuffle.memoryFraction:  # 默认0.2
```

<img src="SparkCore性能调优/image-20210628213216361.png" alt="image-20210628213216361" style="zoom:80%;" />

静态内存模型的缺点：

当配置好了Storage和execution区域内存比例后，假设任务execution内存不足，但是storage内存区域存在空闲，但两者之间不能互相借用，不够灵活，所以才开发出新的统一内存模型；

### 统一内存模型

统一内存模型与静态内存管理模型的区别在于存储内存和执行内存共享同一块空间，可以动态占用对方的空闲区域，如图：

<img src="SparkCore性能调优/image-20210628213731118.png" alt="image-20210628213731118" style="float:left;zoom:40%;" />



<img src="SparkCore性能调优/image-20210628213936506.png" alt="image-20210628213936506" style="float:left;zoom:80%;" />

其中最重要的优化在于动态占用机制，其规则如下：

1. 设定基本的存储内存和执行内存区域（spark.storage.storageFraction参数控制），该设定定义双方各自拥有的空间范围；
2. 双方空间都不足时，则将数据存储到硬盘；若己方内存不足而对方空间空闲时，可借用对方空间；
3. 执行内存的空间被对方占用后，可让对方将占用的部分数据转存至硬盘，然后“归还”借用的空间；
4. 存储内存的空间被对方占用后，无法让对方“归还”，只能等待对方使用完毕后释放；

<img src="SparkCore性能调优/image-20210628214611509.png" alt="image-20210628214611509" style="float:left;zoom:40%;" />

统一内存管理机制，在 一定程度上提高了堆内核堆外内存资源的使用率，降低了开发者维护spark内存的难度。但存储内存空间过大将会导致频繁的FullGC，降低任务执行性能。

## 资源调优

### num-executors

该参数用于设置spark作业总共要用多少个Executor进程来执行。

调优建议：配置为集群节点数量的1/10比较合适；

### executor-memory

该参数用于设置spark作业中每个Executor进程的内存。

调优建议：每个Executor进程内存设置为4G~8G较为合适；但是还需要考虑整个可用队列的资源情况；任务使用内存总大小最好不要超过队列的1/2，避免单个任务占用过多资源影响其他作业调度；

### executor-cores

该参数用于配置spark作业中每个Executor进程可用的CPU core数量。该参数决定了每个Executor进程并行执行task能力；每个CPU core同一时间只能执行一个task进程；

调优建议：Executor的CPU core数量设置为2~4个比较合适。单个任务申请的CPU core不要超过队列的1/2比较合适；另外，任务申请的CPU core与task数量比例保持在1:3较为 合适；

### driver-memory

该参数用于配置spark任务driver进程的内存大小；

调优建议：Driver内存一般不需要配置过大，1G到2G左右即可，但需注意不要使用collect算子将RDD数据拉取到driver上进行处理；

### spark.default.parallelism

该参数用于设置每个stage的默认task数量。该参数或直接影响spark作业性能；

调优建议：spark作业的默认task数量设置为500~1000个较为合适；如果不配置该参数，则会根据HDFS文件的block数量来设置task数量，一般task数量会偏少；

### spark.storage.memoryFraction

该参数用于设置RDD持久化数据在Executor内存中的占比，默认为0.6；

调优建议：根据作业情况，如果有较多的RDD持久化操作，则该参数的值可以适当提高，保证持久化的数据能够容纳在内存中；如果作业shuffle类操作较多，而持久化操作较少，或者作业频繁GC，则建议调低该参数；

### spark.shuffle.memoryFraction

该参数用于设置shuffle过程中一个task拉取到上个stage的task的输出，进行聚合操作时能够使用的Executor内存的比例，默认为0.2；即shuffle操作在进行聚合时，内存使用超出参数配置阈值，则将对于的数据溢写到磁盘文件中，会极大的降低性能；

调优建议：根据作业情况，如果RDD持久化操作较少，shuffle操作较多，建议降低持久化操作的内存占比，提高shuffle操作的内存占比，避免shuffle过程中数据过多时内存不足，作业频繁GC同样需要调低该参数；

## 数据倾斜调优

### 数据倾斜症状

1. 绝大多数的task执行非常快，个别task执行极慢；例如，一个作业总共1000个task，其中990+个task都在快速执行结束，剩余几个task持续运行；
2. 原本能够正常执行的任务，某次运行突然爆出OOM异常，且重复运行仍然爆出OOM；

### 数据倾斜原理

数据倾斜原理很简单：在进行shuffle的时候，将各个节点上相同的key拉取到各自节点上的一个task来进行处理，比如按照key进行聚合或join等操作，当某个key的数量特别大的话，就会发生数据倾斜；因此出现数据倾斜时，spark作业看起来会运行特别慢，甚至个别task会因处理的数据过大导致OOM；

### 数据倾斜代码定位

数据倾斜只会发生在shuffle过程中。常用且可能触发数据倾斜的算子主要有：distinct、groupByKey、reduceByKey、aggregateByKey、join、cogroup、repartition等；出现数据倾斜时，可能就是代码中使用了这些算子中的某一个所导致；

一个Application会生成多个Job，job根据action算子分割，每个job由多个stage组成，stage根据shuffle类算子界定，通过异常的task（处理数据量大、执行时间长）归属job及stage对应代码中的action及shuffle算子，定位触发数据倾斜的具体算子；

### 数据倾斜的解决方案

#### 1. Hive ETL预处理

适用于HIve表中的数据本身不均匀，且业务场景需要频繁使用Spark对Hive表进行统计分析；可以将费时或需要进行多表join的操作在凌晨提前进行处理，这样在业务场景的spark作业中就可以避免原来的shuffle类操作，提升作业效率；

#### 2. 过滤少数导致倾斜的key

如果可以判断作业中存在少数几个数据量特别多的key，且不影响最终计算结果的话，那么可以先进行数据过滤；但无法作为通用逻辑应用于所有任务；

#### 3. 提高shuffle并行度

增加shuffle read task的数量，可以让原本分配给一个task的key分配给多个task，从而让每个task处理的数据量减少，但如果出现极端情况，数据大量倾斜至一个key，提高并行度仍然无法解决数据倾斜问题；

#### 4. 两阶段聚合

对rdd执行reduceByKey等聚合类shuffle算子或Spark SQL使用group by语句进行分组聚合时，比较使用此方案；

实现思路为进行两阶段聚合：

1. 第一次是局部聚合，先给每个key拼接一个随机数，将原来可能存在倾斜的key重新进行分布；比如(hello,1)(hello,1)(hello,1)变成(1_hello,1)(2_hello,1)(2_hello,1)
2. 对重新生成的key进行reduceByKey等聚合操作，进行局部聚合，结果为(1_hello,1)(2_hello,2)
3. 对生成结果剔除拼接随机数，结果为(hello,1)(hello,2)
4. 再次进行全局聚合，即可获取最终结果(hello,3)

此方案仅适用于聚合类shuffle操作，使用范围相对较窄，对于join类的shuffle操作，需使用其他方案；

#### 5. reduce join转换为map join

在对RDD使用join类操作，或者是Spark SQL中使用join语句时，而且join操作中一个RDD或者表的数据量比较小，使用此方案；

普通join是会走shuffle过程的，而一旦shuffle，相当于会将相同的key的数据拉取到一个shuffle read task中在进行join，此时就是reduce join。如果是一个RDD比较小，则可以采用广播小RDD全量数据+map算子来实现与join相同的效果，也就是map join，此时就不会发生shuffle操作，也就不会出现数据倾斜；

优点：对join操作导致的数据倾斜，通过转换成map操作，规避了shuffle，也就不会发生数据倾斜；

缺点：使用场景较少，只适用于一个大表与一个小表的情况；且小表广播会消耗大量内存；

#### 6. 采样倾斜key并分拆join

两个RDD/Hive表进行join，如果数据量都很大，且其中一个RDD/Hive表中的少数几个key的数据量过大，而另一个RDD/Hive表key分布比较均匀，则可以采用此方案；

1. 通过抽样将存在数据倾斜的key抽取出来并拼接随机数形成单独的RDD，并将相同key从另一个RDD/Hive表中抽取同样拼接随机数生成新的RDD；
2. 将新生成的两个RDD按照方案5进行处理，步骤1剩余的两个RDD正常join；
3. 将步骤3的生成结果RDD进行UNION即可；

优点：对于join导致的数据倾斜，如果只有几个key导致了倾斜，则该方案可以有效的打散倾斜key，而且只需针对少数倾斜key进行拼接随机数扩容，避免大量内存浪费；

缺点：如果导致倾斜的key比较多，那么通过拼接随机数将导致数据量大量膨胀，可能导致OOM；

#### 使用随机前缀扩容RDD

1. 如果RDD中有大量的key导致数据倾斜，通过存在倾斜key的RDD/Hive，并对其所有key拼接一个n以内的随机数；
2. 对正常RDD的每条数据都打上一个0~n的前缀；
3. 将两个处理后的RDD进行join即可；

此方案需对整个RDD扩容，对内存要求较高；

## shuffle调优

#### 1. spark.shuffle.file.buffer

作用：提升性能

默认值：32k

说明：该参数用于设置shuffle write task的BufferedOutputStream的buffer缓冲大小；将数据写入磁盘前，会先写入buffer缓冲中，待缓冲写满之后，才会溢写到磁盘；

建议：如果可用内存资源较充足，可适当增加这个参数到64k，减少shuffle write过程中溢写磁盘文件的次数，减少磁盘IO次数；

#### 2. spark.reduce.maxSizeFlight

作用：提升性能

默认值：48m

说明：该参数用于设置shuffle read task的buffer缓冲大小，该buffer大小决定了每次能够拉取多少数据；

建议：如果可用内存资源充足，可适当增加这个参数到96m，从而减少拉取数据的次数，也可以减少网络传输的次数；

#### 3. spark.shuffle.io.maxRetries

作用：提升稳定性

默认值：3

说明：shuffle read task从shuffle write task坐在节点拉取属于本节点的数据时，如果因为网络异常导致拉取失败，会自动进行重试；该参数配置自动重试最大次数；超出最大重试次数，任务则已失败退出；

建议：对于包含了特别耗时的shuffle操作作业，建议增大重试次数，以避免因JVM的full gc或网络不稳定导致的数据拉取失败，对于超大数据集的shuffle过程，调节该参数可以大幅提升任务稳定性；

#### 4. spark.shuffle.io.retryWait

作用：提升稳定性

默认值：5s

说明：与参数3配合使用，设置重试时间间隔；

建议：增加重试时间间隔，提升shuffle操作稳定性；

#### 5. spark.memory.fraction

作用：内存优化

默认值：0.2

说明：该参数代表了Executor内存中，分配给shuffle read task进行聚合操作的内存比例。

建议：参考统一内存模型；

#### 6. spark.shuffle.manager

作用：

默认值：sort

说明：该参数用于设置ShuffleManager的类型，可选项为sort和tungsten-sort；tungsten-sort与sort类型，但使用tungsten-sort计划中的对外内存管理机制，内存使用效率更高；

建议：SortShuffleManager默认会对数据进行排序，如果业务逻辑中需要该排序机制，则使用默认的SortShuffleManager即可；如果业务逻辑不需要对数据进行排序，那么建议考虑后面的几个参数调优，通过bypass机制或优化的HashShuffleManager来避免排序操作，同事提供较好的磁盘读写性能，但tungsten-sort容易触发bug，需慎用；

#### 7. spark.shuffle.fort.bypassMergeThreshold

作用：

默认值：200

说明：当ShuffleManager为SortShuffleManager时，如果shuffle read task的数量小于这个阈值时，则shuffle write过程中不会进行排序操作，而是直接按照未经优化的HashShuffleManager的方式去写数据，但最后会将每个task产生的所有临时磁盘文件都合并成一个文件，并创建单独的索引文件。

建议：当使用SortShuffleManager时，如果不需要操作排序，那么建议将参数调大，大于shuffle read task的数量。那么此时启用bypass机制，map-side就不会进行排序，减少排序的性能开销；但此时会产生大量的磁盘文件，因此shuffle write性能有待提高。




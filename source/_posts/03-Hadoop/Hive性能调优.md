---
title: Hive性能调优
categories: Hadoop
tags: hive
author: semon
date: 2021-06-25
---

## 调优须知

Hive是一个常用的大数据组件，影响它的性能的从来都不是数据量过大问题，而是数据倾斜、MR分配不合理、IO瓶颈等；所以，我们可以从HIve的模型设计、Hive SQL优化、参数调优、MR调优等几个方向进行优化；

1. Hive SQL最终会转换为MR进行运行，了解转换逻辑，进行SQL优化，减少生成的Job数量； 
2. 启用mapper阶段的局部聚合和二次聚合优化统计分析函数造成的数据倾斜问题；
3. 设置合并的MR并行度；
4. 选择合适的建表设计；
5. 尽量使用group by替代count(distinct)；

## 建表设计优化

Hive表可以分为内部表、外部表、分区表、分桶表，其中内部表与外部表只是主数据的管理方式不同，在性能上没有区别；

### 分区表

分区表就是根据用户指定的维度（分区键）对数据进行分类存储，一个分区对应一个HDFS目录，当按照分区过滤查询时，Hive会直接读取对应分区目录数据，减少处理数据量；所以一张表大部分情况下都是使用某个字段进行过滤的话，建议以改字段为分区键进行模型重构；

```sql
create table poc.demo
(
  id int,
  name string
) partitioned by (month_id string)  --指定分区键为month_id
```

### 分桶表

分桶与分区概念稍微有些不同，它是将数据已制定列的值作为key进行hash到指定目的桶中，每个桶对应一个HDFS上的数据文件，目的也是避免遍历全表数据；分桶表Join优化的前提条件是：

1. 参与Join的表都是分桶表；
2. 两表分桶的key为join的关联键；
3. 两表的分桶数量为倍数关系；

优点:

1. 分桶表间join可自动转换为map-side join;
2. 取样sample操作更高效,不需要扫描完整数据集;

```sql
create table poc.demo_bucket
(
	id int ,
   name string
) clustered by (id) sorted by (id asc)  into 4 buckets;
--clustered by 指定分桶的键及分桶个数
--sorted by 指定桶内排序
```



### 合适的存储格式

Hive建表默认的存储格式为Textfile，当创建宽表(字段特别多)时，尽量使用orc、parquet等列存格式；

> 行存格式：典型代表为Textfile，每次进行数据读取时，必须读取该行全部数据后再进行剪裁；
>
> 列存格式：代表类型为parquet，自带schema及index信息，可直接读取指定列数据；

```sql
create table poc.demo_parquet
(
id int ,
name string
) stored as parquet;
```



### 合适的压缩格式

使用压缩算法，本质上是通过牺牲CPU换区减少磁盘及网络IO，所以压缩算法的选择需要判断任务是否为IO密集型任务，决定是否启用压缩算法；

压缩算法的选择主要从压缩率、压缩速率、是否可拆分来判断。一个文件被压缩之后会变成类似`header + body`形式，其中`header`存放元数据信息，记录数据压缩前后的大小及压缩的算法等信息；`body`存储实际数据；是否可拆分是指`header`的元数据信息，在原来的真实数据被切分之后，会不会给每个切分的块都保留一个`header`，避免切分后无法进行解压缩问题；

常用压缩格式对比如下：

| 压缩格式 | 是否可拆分 | 压缩率 | 压缩速度 | Hadoop是否内置 |
| :------: | :--------: | :----: | :------: | :------------: |
|   gzip   |     否     |   中   |    中    |       是       |
|   lzo    |     是     |   低   |    高    |       是       |
|  snappy  |     否     |   低   |    高    |       是       |
|  bzip2   |     是     |   高   |    低    |       否       |

#### 启用MR临时文件压缩

```sql
-- mr临时文件启用gzip压缩
set mapreduce.output.fileoutputformat.compress=true;  --启用压缩，默认为false
set mapreduce.output.fileoutputformat.compress.type=BLOCK  --按block压缩，默认为record
set mapreduce.output.fileoutputformat.compress.codec=org.apache.hadoop.io.compress.GzipCodec  --指定压缩算法，默认为org.apache.hadoop.io.compress.DefaultCodec
```

#### Map端输出结果压缩

```sql
set mapred.map.output.compress=true;  --启用map端输出压缩
set mapred.map.output.compress.codec=org.apache.hadoop.io.compress.GzipCodec; --指定map端输出结果压缩算法
```

#### Hive任务输出压缩

包括Hive任务生成的临时文件和最终落库的结果文件都启用压缩;

```sql
set hive.exec.compress.output=true;  --启用Hive输出文件压缩  默认为false;
set hive.exec.compress.intermediate=true; --设置转换的mr任务启用压缩,默认为false;
```

## HQL优化

HQL可通过执行计划了解其具体的转换过程；

```SQL
explain [extended]  hql  --extended关键字可打印更详细执行计划
```

### 列剪裁与分区剪裁

列剪裁是指Hive在进行查询时只读取需要的列，分区剪裁是指读取需要的分区；HQL编写时尽量指定需要查询的列，针对分区表使用分区键进行数据过滤；剪裁的目的是节省数据读取开销：中间表存储开销及数据整合开销；

在HQL解析阶段对应的是ColumnPruner逻辑优化器；

```sql
set hive.optimize.cp=true; --开启列剪裁,默认为true
set hive.optimize.pruner=true; --开启分区剪裁，默认为true；
```

> 列剪裁配合列式存储文件会有较好的优化效果;

### 谓词下推

所谓的谓词下推，是将任务中的数据过滤行为，下发到计算节点进行操作；尽可能将HQL中的`where`谓词逻辑尽可能提前执行，减少下游处理的数据量。

在HQL解析阶段对应的是PredicatePushDown；

```sql
set hive.optimize.ppd=true;  --启用谓词下推；

-- query1  自动谓词下推
select a.*,b.* from a join b on a.id = b.id where b.age > 20;

--query2  手动谓词下推
select a.*,c.* from a join (select  * from b where age>20 ) c on a.id = b.id;
```

### 合并小文件

#### Map端输入合并

在执行mr程序的时候,一般情况下是一个文件的一个数据分块需要一个MapTask来处理。但如果数据源是大量的小文件，就会启动大量的MapTask，这样将导致大量资源浪费（占用队列大量资源，启动container耗费时间）。可以在输入时将小文件进行合并，从而减少MapTask任务数量。

```sql
set hive.input.format=org.apache.hadoop.hive.ql.io.ConbineHiveInputFormat;  --启用map端输入合并小文件,默认为TextInputFormat
```

#### Map/Reduce输出合并

小文件过多将会给HDFS带来极大压力，且影响后续任务执行效率。可以通过合并Map和Reduce的结果文件来消除影响；

```sql
set hive.merge.mapfiles=true;  --启用map端输出文件合并,默认为true
set hive.merge.mapredfiles=true;  --启用reduce端输出文件合并，默认为false

set hive.input.format=org.apache.hadoop.hive.ql.io.ConbineHiveInputFormat;  --启用map端输入合并小文件,默认为TextInputFormat
set mapreduce.input.fileinputformat.split.maxsize=256000000;  --定义每个map处理的最大分片大小，单位为Byte   优先级最低
set mapreduce.input.fileinputformat.split.minsize=256000000;  --定义每个map处理的最小分片大小，单位为Byte  优先级低
set mapred.min.split.size.per.node=10000000;  --定义节点可以处理的最小分片大小，单位为Byte，小于该参数文件将暂存，用于节点间分片合并   优先级中
set mapred.min.split.size.per.rack=1;  --定义机架可以处理的最小分片大小，单位为Byte ，小于该参数文件暂存，用于机架分片合并   优先级高

set hive.merge.size.per.task=256000000;  --定义任务合并文件大小上限,默认256M
set hive.merge.smallfiles.avgsize=256000000;  --当输出文件平均大小小于该值时，启动一个独立的mr进行文件合并；
```

> 上限：mapreduce.input.fileinputformat.split.maxsize
>
> 下限：mapreduce.input.fileinputformat.split.minsize
>
> 块大小：dfs.block.size
>
> splitSize = Math.max(minSize, Math.min(maxSize, blockSize))
>
> splitSize最好与blockSize一致

`Map`读取文件流程如下:

1. 根据任务参数计算`splitSize`大小;
2. 获取输入目录下每个文件的大小,按照`splitSize`进行切片,切分剩余部分小于`splitSize`,但`mapred.min.split.size.per.node`,则直接生成一个切片,否则暂时保留；
3. 将不同节点下的保留碎片各自进行合并，长度超过`splitSize`就合并成一个切片，最后剩下的部分比`mapred.min.split.size.per.rack`大，则生成一个切片，否则暂时保留；
4. 将不同rack下的所有保留碎片，长度超过`splitSize`就合并成一个切片，剩下碎片合并成一个切片；

#### 合理设置MapTask并行度

根据业务逻辑增加或减少MapTask的数量，可显著提升任务的执行效率；

```sql
--增加map并行度
set mapred.reduce.tasks=10;   --仅适用于增加map数时使用，且需大于默认值时使用（默认值为2）

--降低map并行度
set mapred.max.split.size=256000000;        -- 决定每个map处理的最大的文件大小，单位为B
set mapred.min.split.size.per.node=256000000;         -- 节点中可以处理的最小的文件大小
set mapred.min.split.size.per.rack=256000000;          -- 机架中可以处理的最小的文件大小
```

#### 合理设置ReduceTask并行度

ReduceTask并行度过大将导致产生大量小文件,且初始化容器会耗费大量资源及时间;并行度过小将导致整个查询耗时延长,且容易触发数据倾斜;

```sql
--根据数据量设置ReduceTask并发
set hive.exec.reducers.max = 100;   --设置ReduceTask上限
set hive.exec.reducers.bytes.per.reducer=256000000;  --设置单个reduce数据数据量

--直接指定ReduceTask并行度
set mapreduce.job.reduces = 10;
```

### Join优化

#### 常规优化

1. 先过滤在 进行join操作,最大限度减少参与join的数据量;
2. 小表join大表,最好启用mapjoin,hive自动启用mapjoin;(Hive自动启用mapjoin对于限制小表大小不超过25M)

3. 多表join时,尽量使用相同字段进行链接,此时会转换为同一个job;
4. 尽量避免一个SQL包含复杂逻辑，可通过中间表来实现复杂逻辑；
5. 尽量避免数据倾斜；
   1. 空key过滤：当业务场景中存在大量空key且不影响join结果数据时，可直接过滤掉空值后再进行join；
   2. 空key转换：当业务场景中空key数据过多，且需包含在join结果中时，我们可以将key为空的字段赋予一个随机值，使数据随机分散至所有reducer中，避免数据倾斜；

#### MapJoin

MapJoin是将join中较小的表直接分发到各个MapTask的内存中，在map中直接进行join，不需要进行reduce，从而提升效率；

```sql
--指定启用mapJoin
set hive.auto.convert.join=true
set hive.mapjoin.smalltable.filesize=25000000;

--根据表大小 common join自动转换为map join，将小表刷入内存
set hive.auto.convert.join.noconditionaltask=true;
set hive.auto.convert.join.noconditionaltask.size=25000000;

--显示指定mapjoin
select /*MAPJOIN(b)*/  b.key,a.value from a join b on a.key=b.key;
```

#### SMB Join

SMB Join即Sort-Merge-Bucket Map Join,使用前提为所有表均为分桶表且排序;

1. 参与join的表需针对相同key做hash散列,桶内排序;

2. 两个桶的个数需为倍数关系;

   ```sql
   --smb join不能执行时,自动终止
   set  hive.enforce.sortmergebucketmapjoin=false;
   
   --是否自动转换为smb join
   set hive.auto.convert.sortmerge.join=true;
   
   --关联键是分桶键时,是否启用mapjoin
   set hive.optimize.bucketmapjoin=true;
   
   --bucket map join优化启用
   set hive.optimize.bucketmapjoin.sortedmerge=true;
   ```

#### Join数据倾斜优化

查询语句确认存在数据倾斜时,可以通过参数自动进行二次优化;

```sql
--启用自动均衡
set hive.optimize.skewjoin=false;
--关联键值记录数超过阈值启用自动均衡
set hive.skewjoin.key = 10000;

--配置自动均衡第二个job的mapper数量
set hive.skewjoin.mapjoin.map.tasks = 100;
```

#### CBO优化

CBO即成本优化器，代价最小的执行计划即为最优的执行计划。

```sql
set hive.cbo.enable=true;
set hive.compute.query.using.stats=true;
set hive.stats.fetch.column.stats=true;
set hive.stats.fetch.partition.stats=true;
```

#### 笛卡尔积配置

可默认关闭笛卡尔积,避免错误SQL影响集群稳定，需要使用笛卡尔积时，添加参数显示开启；

```sql
set hive.mapred.mode=strict;
```

#### Group By优化

##### Map端聚合

并不是所有的聚合操作都需要在Reduce中进行，如果支持可在Map端进行部分聚合，然后在Reduce端得出最终结果；

```sql
--开启map端聚合
set hive.map.aggr=true;
--配置map端聚合记录预置,超过就进行拆分
set hive.groupby.mapaggr.checkinterval=200000;
```

##### Groupby负载均衡

当HQL使用`group by`出现数据倾斜时，启用参数Hive自动进行负载均衡。策略为将MapReduce任务拆分为两个：预汇总，最终汇总；

1. 预汇总：在第一个MapReduce中，map的输出结果会随机分布到reduce中，每个reduce做部分聚合操作，并输出结果，这样处理的结果是相同的key可能分布到不同的reduce中，达到负载均衡的目的；
2. 最终汇总：第二个MapReduce中任务再根据预处理数据按照group by key分布到各个reduce中，完成最终的聚合操作；

##### Order By优化

`order by`为全局排序，只能在一个reduce中进行，当对一个大数据集进行`order by`，会导致一个reduce进程处理大量的数据，造成查询执行缓慢甚至OOM；

1. 在最终结果上进行`order by`，尽量不在中间数据集上进行排序。最终结果数据较少，能够缓解性能问题；

2. 提取`Top N`结果，可使用`distribute by` + `sort by`在各个reduce上排序后，取`Top N`，然后再合并到一个Reduce中进行全局排序，再取`Top N`，能够大幅提升效率；

   > order by：全局排序，缺陷为只能使用一个reduce；
   >
   > sort by：单点排序，单个reduce中结果有序；
   >
   > cluster by：对同一字段分桶并排序，不能与sort by连用；
   >
   > distribute by：分桶，保证同一字段只存在同一个结果文件中，可结合sort by保证每个reduceTask内结果有序；

##### Count Distinct优化

当需要统计某一列去重数据时，如果数据量大，`count(distinct)`会非常慢，原理与`order by`类似，建议通过`group by`进行改写；

```sql
--优化前
select count(distinct id) from demo;  --只有一个reduce

--优化后
select count(*) from (select id from demo group by id) t
```

##### Left semi join

使用left semi join替代exists/in语法；

##### 压缩

可根据业务需要启用map输出压缩、中间数据压缩及结果数据压缩等；

1. map输出压缩

   ```sql
   set mapreduce.map.output.compress=true;
   set mapreduce.map.output.compress.codec=org.apache.hadoop.io.compress.SnappyCodec;
   ```

2. 中间数据压缩（HIve查询多个job间输出数据）

   ```sql
   set hive.exec.compress.intermediate=true;
   set hive.intermediate.compression.codec=org.apache.hadoop.io.compress.SnappyCodec;
   set hive.intermediate.compression.type=BLOCK;
   ```

3. 结果数据压缩

   ```sql
   set hive.exec.compress.output=true;
   set mapreduce.output.fileoutputformat.compress=true;
   set mapreduce.output.fileoutputformat.compress.codec=org.apache.hadoop.io.compress.GzipCodec;
   set mapreduce.output.fileoutputformat.compress.type=BLOCK;
   ```

   > Hadoop默认支持的压缩算法：
   >
   > org.apache.hadoop.io.compress.DefaultCodec
   >
   > org.apache.hadoop.io.compress.GzipCodec
   >
   > org.apache.hadoop.io.compress.BZip2Codec
   >
   > org.apache.hadoop.io.compress.DeflateCodec
   >
   > org.apache.hadoop.io.compress.SnappyCodec
   >
   > org.apache.hadoop.io.compress.Lz4Codec
   >
   > com.hadoop.compression.lzo.LzoCodec
   >
   > com.hadoop.compression.lzo.LzopCodec

## Hive架构优化

### 启用本地抽样

1. 部分HQL在转换过程中会进行优化，不用转换成MR任务；

   ```sql
   --只有select * 的语句
   select * from demo
   
   --针对分区过滤筛选
   select * from  demo where dt='202106'
   
   --带有limit分支语句
   select * from demo limit 10；
   ```

2. Hive读取HDFS数据有两种模式：MR读取和直接抓取。直接抓取比MR读取性能要高很多，但只有少数操作支持直接抓取。可通过参数配置启用情况；

   ```sql
   -- minimal：至于场景1情况的三种情况启用直接抓取；
   -- more: 在select、where筛选及limit场景时，都启用直接抓取；
   
   set hive.fetch.task.conversion=minimal;
   ```

### 本地执行优化

Hive在集群上查询时,默认在集群的多个节点运行,需要在多个节点进行协调运行.但在HIve查询处理的数据量比较小的时候,其实没有必要启动分布式执行,可通过本地模式,在单节点处理所有任务,执行时间会明显缩短.

```sql
--自动判断是否启用本地模式
set hive.exec.mode.local.auto=true;

-- map任务最大值,超过则启用分布式
set hive.exec.mode.local.auto.input.files.max=6;

-- map输入文件最大大小,超过则启用分布式
set hive.exec.mode.local.auto.inputbytes.max=128000000;
```

以上参数即task数量小于6,单个文件大小小于128M则启用本地模式执行；

### JVM重用

HQL语句最终会转换为一系列的MR任务，每个Task都会启动一个JVM进程，Task执行结束，JVM就会推出。下一个MR又需要花费大量时间启用JVM，而JVM的启动与销毁会变成一个非常大的消耗，可以通过JVM重用来解决；

```SQL
set mapred.job.reuse.jvm.num.tasks=10;
```

> 开启JVM重用会一直占用使用到的Task插槽，一遍进行重用，知道任务完成后才会释放。如果某个Job存在数据倾斜，将导致大量JVM空闲无法被其他Job使用，直到所有task都结束才会释放；

### 并行执行

部分查询语句，Hive会将其转化为一个或多个阶段，包括：MR、抽样、合并、limit等。默认情况下，一次只执行一个阶段，如果某些阶段不存在依赖，则可以并行执行，但多阶段并行将导致资源消耗明显增加；

```sql
--启用并行
set hive.exec.parallel=true;

--定义sql最大并行度
set hive.exec.parallel.thread.number=10;
```

### 推测执行

分布式环境下,因为程序Bug、负载不均衡、资源分布不均等情况，都会造成同一个作业的多个任务之间运行速度不一致，部分任务可能会拖慢整体执行进度。为避免这种情况，Hadoop采用了推测执行机制，根据一定的算法推测出“拖后腿”任务，并为这样的任务启用一个备份任务，让该任务与原始任务同时执行，并最终选中最先成功运行完成任务的计算结果作为最终结果。

```sql
-- mapper阶段启用推测执行
set mapreduce.map.speculative=true;

--reducer阶段启用推测执行
set mapreduce.reduce.speculative=true;
```

> 当任务处理的数据量非常大时,推测执行将早场严重的资源浪费;

### Hive严格模式

所谓严格模式,就是强制不允许用户执行有风险的HQL语句，一旦执行直接失败；

```sql
--启用严格模式
set hive.mapred.mode=strict;
set hive.exec.dynamic.partition.mode=nostrict;
```

> 启用严格模式后,存在以下限制:
>
> 1. 对于分区表必须添加`where`分区字段条件过滤;
> 2. `order by`语句必须与`limit`组合使用，限制输出；
> 3. 限制笛卡尔积查询；
> 4. 动态分区模式下，必须制定一个分区列为静态分区；


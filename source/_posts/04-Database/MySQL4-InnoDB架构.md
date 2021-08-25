---
title: MySQL之InnoDB架构
categories: Database
tags: mysql
author: semon
date: 2021-08-12
---

# InnoDB架构

<img src="MySQL4-InnoDB架构/image-20210817105408063.png" alt="InnoDB架构图" style="zoom:80%;" />

InnoDB架构分为两部分：内存中的结构和磁盘上的结构；InnoDB使用日志先行策略，将数据修改先在内存中完成，并将事务记录成重做日志(Redo Log)，转换为顺序IO高效的提交事务；

这里日志先行，说的是日志记录到数据库以后，对应的事务就可以返回给用户，表示事务完成；但实际上，这个数据可能还只在内存中修改完，并没有刷到磁盘中；内存数据是非持久化的，一旦断电或机器故障，数据将会丢失；

InnoDB通过Redo Log来保证数据的一致性，如果保存所有的Redo Log，便于在系统崩溃时根据日志重建数据；每次系统崩溃使用所有的Redo Log重建数据太过笨拙，索引InnoDB引入了检查点机制，即定期检查，保证检查点之前的日志都已经刷写到磁盘，则碰到系统崩溃只需从最近的检查点开始重建即可；

# InnoDB内存结构

InnoDB内存结构主要包括`Buffer Pool`、`Change Buffer`、`Adaptive Hash Index`以及`Log Buffer`四部分；

单纯从内存角度来看，`Change Buffer`和`Adaptive Hash Index`占用的内存都属于`Buffer Pool`，`Log Buffer`占用独立内存；

## Buffer Pool

Buffer Pool简称BP，也叫缓冲池，其中存储的数据包括`Page Cache`、`Change Buffer`、`Data dictionary Cache`等，通常MySQL服务器80%的内存会分配给`Buffer Pool`；

基于效率考虑，InnoDB中数据管理的最小单位为页，默认每页大小为16KB，每页包含若干行数据；

为了提高缓存管理效率，InnoDB的缓冲池通过一个页链表实现，很少访问的页会通过缓冲池的LRU算法淘汰出去；

InnoDB的缓冲池页链表分为两部分：Young区（默认占用缓冲池的5/8）和Old 区（默认占用缓冲池3/8），其中新读入的页会加入到Old区的头部，而Old区中的页被命中，则移动到Young区头部；

> `innodb_old_blocks_pct`参数可修改Young区与Old区比例，默认值为37；

## Adaptive Hash Index

### 什么是Hash索引

哈希索引基于哈希表实现，只有精确匹配索引所有列的查询才有效，对于每一行数据，存储引擎都会对所有的索引列的值计算一个哈希值，哈希索引将所有的哈希值存储在索引中，同时在哈希表中保存指向每个数据行的指针；

+ 哈希索引只包含哈希值和行指针，而不存储字段值，所以不能使用哈希索引来做覆盖索引扫描；
+ 哈希索引数据并不是按照索引列的值顺序存储，所以无法应用于排序；
+ 哈希索引不支持部分索引列匹配查找，因为哈希索引始终是使用索引的全部列值内容来计算哈希值的；哈希索引只支持等值比较查询；
+ 访问哈希索引的数据效率很高，除非出现哈希冲突，当出现哈希冲突时，存储引擎必须遍历链表中所有的行指针，逐行进行比较，直到找到所有符合条件的行；如果哈希冲突很多，索引维护操作的代价也会很高；

### 什么是自适应Hash索引

在MySQL中，哈希索引只有Memory、NDB两种引擎支持，Memory引擎默认支持哈希索引，如果多个哈希值相同，出现哈希碰撞，那么索引以链表方式存储；对于常用的InnoDB引擎，是不支持哈希索引的；要使InnoDB支持哈希索引，可以通过伪哈希索引来实现，即自适应哈希索引；

自适应哈希索引就是当InnoDB注意到某些索引值被使用的非常频繁时，MySQL会在内存中基于BTree索引之上再创建一个哈希索引，这样就可以进行哈希查找了；

### 自适应哈希索引

InnoDB存储引擎会监控对表上索引的查找，如果观察到建立哈希索引可以带来速度的提升，则建立自适应哈希索引（`Adaptive Hash Index`，简称AHI），其本质上就是一个哈希表：从某个检索条件到某个数据页的哈希表；

#### 索引使用大于17次

AHI是为某个索引树建立的（当索引树层数过多时，AHI才能发挥效用）；如果索引只被使用一两次，就为其简历AHI，会导致AHI过大,维护成本高于收益;默认当索引使用次数大于17次时，即通过筛选；

#### Hash info使用次数大于100

对使用次数大于17次的索引建立Hash info，Hash info是用来描述一次检索的条件与索引匹配程度；建立AHI时，就可以根据匹配程度，抽取数据中匹配的部分，作为AHI的键；当Hash info使用次数大于100则代表该Hash info为经常使用的Hash info；

+ Hash info结构：匹配索引列数，下一列匹配字节数，是否从左匹配；

#### Hash info命中页数据大于1/16

如果我们为表中所有数据建立AHI，那么AHI就失去了缓存的意义，所以需要找出该索引树上经常使用的数据页，通过该步骤筛选后就可以开始建立哈希索引；

#### Hash热点分散

MySQL在Hash索引的设计上还采用了热点分散技术，Hash索引在MySQL上默认是启动8个，可以将热点数据分散到不同的Hash索引上，提升并发访性能；

InnoDB默认开启自适应Hash索引，可通过参数`Innodb_adaptive_hash_index=off`关闭；自适应Hash索引使用分片实现，分片数可以通过参数`innodb_adaptive_hash_index_parts=512`来配置，默认值为8，最大支持512；

> 自适应哈希索引适用于使用`=`或`in`操作符的等值查询；同时应尽量避免使用`like`和`%`的范围查询和高并发关联操作；
>
> MySQL5.7之前Hash索引所有分片公用一把锁，Hash索引反而称为了并发性能瓶颈；

## Change Buffer

通常来说，InnoDB辅助索引不同于聚餐索引的顺序插入，如果每次修改二级索引都直接写入磁盘，则会有大量频繁的随机IO。`Change Buffer`的主要目的是将对非唯一索引页的操作缓存下来，以此减少辅助索引的随机IO，并达到操作合并的效果，其实际使用的是BP的内存空间；

在MySQL5.5以前，`Change Buffer`叫做`Insert Buffer`，最初仅支持`insert`操作的缓存，随着支持操作类型的增加，更名为`Change Buffer`；

如果辅助索引页命中缓冲区，则直接修改即可；如果未命中，则先修改操作保存到`Change Buffer`；`Change Buffer`的数据在对应索引页读取到缓冲区时将进行合并；`Change Buffer`内部实现也是使用B+树；

> `innodb_change_buffering`参数可配置是否启用`Change Buffer`，默认为启用，对应参数为`all`；即缓存所有`insert、delete-mark及purge`操作；
>
> MySQL删除数据分为两步：`delete-mark`（标记）和`purge`（删除）

## Log Buffer

Log Buffer是重做日志在内存中的缓冲区，大小由`innodb_log_buffer_size`定义，默认为16MB；一个达大的Log Buffer可以让大事务在提交前不必将日志中途刷写到磁盘中，可以提高效率；如果系统有很多修改行记录的大事务，可以增大该值；

参数`innodb_flush_log_at_trx_commit`用于控制Log Buffer如何写入及输入磁盘：

+ 默认为1，表示每次事务提交都会将Log Buffer写入操作系统缓冲，并调用配置的`flush`方法将数据写到磁盘；该策略会频繁刷写磁盘，效率较低但安全性高，最多丢失1个事务数据；
+ 配置为0，表示每秒将Log Buffer写入内核缓冲区并调用`flush`方法将数据写到磁盘；此策略可能丢失1秒以上事务数据；
+ 配置为2，表示每次事务提交都将Log Buffer写入内核缓冲区，但是每秒才调用`flush`将内核缓冲区的数据刷写到磁盘；此策略可能丢失1秒以上事务数据；

参数`innodb_flush_log_at_timeout`用于配置刷新日志缓存到磁盘的频率，默认为1秒；

参数`Innodb_flush_method`用于配置日志写入磁盘的方法，默认为`fsync`，即日志和数据都通过`fsync`系统调用刷到磁盘；

InnoDB中使用的redo log和undo log是分开存储的；

+ redo log在内存中有Log Buffer，在磁盘对应ib_logfile文件；

+ undo log在内存中会生成undo页，在磁盘对应ibd文件；

redo log必须在数据落盘前线落盘（Write Ahead Log），从而保证数据持久性和一致性；而数据本身的修改可以先主流在内存缓冲池中，再根据特定的策略定期刷写磁盘；

## Double Write Buffer

Double Write Buffer即双写缓冲区，是InnoDB引擎为了保证数据安全性、完整性而开发的；

双写缓冲区位于系统表空间中；InnoDB会在磁盘上划分出连续的两个区的范围：1个区包含64个页，一个页16K，因此一个双写缓冲区大小为16K * 64  * 2 = 2MB；

MySQL在进行数据写入时，InnoDB会先把数据从缓冲池分写入到双写缓冲区中，之后通过双写缓冲区分两次，每次写入1MB到系统表空间，然后立即调用`fsync`函数，同步至磁盘，避免缓冲带来问题；在这个过程中，双写缓冲区是循序写；在完成双写缓冲区写入后，再将双写缓冲区写入各个表空间文件中，此时为离线写入；

### 双写缓冲区对性能影响

在系统表空间上的双写缓冲区实际上也是一个文件，写DWB会导致系统有更多的`fsync`操作，而`fsync`的性能较差，所以才操作会导致MySQL的整体性能下降，性能损失通常约为5%~25%，这主要是因为：

1. 双写缓冲区是一个连续的存储空间，硬盘写数据时为顺序写，而非随机写，性能较高；
2. 将数据从双写缓冲区写入到表空间文件中，系统会自动合并连接空间刷新的方式，每次可以刷新多个页；

### 双写缓冲区恢复数据

**双写缓冲区写入失败**

如果数据库在写入双写缓冲区本身就失败了，那么这些数据并不会被写入磁盘，InnoDB直接从磁盘加载原始数据，结合Redo Log计算出正确的数据，重新想双写缓冲区写入即可；

**双写缓冲区写入成功**

如果数据库写入双写缓冲区成功，但是写入表空间文件失败，此时InnoDB将不需要通过Redo Log日志来进行计算，直接对双写缓冲区中的页数据进行校验，业数据与校验和匹配则直接将双写缓冲区页数据写入表空间文件即可；如果页数据与校验和不匹配，则使用Redo Log + 原始叶数据重新计算；

> 1. 校验和`checksum`其实就是数据页的最后事务号，如果页已经损坏，找不到页中的事务号，就无法进行恢复；
>
> 2. 通过双写缓冲区恢复数据效率比使用Redo Log要高，而且部分情况原始页损坏或被修改，无法通过Redo Log恢复完整页数据（Redo Log仅记录要修改的字段值，而非完整数据页）
> 3. Fursion-io原子写，如果每次写16k就是16k或特定文件系统（如b-tree文件系统）支持原子写，就可以禁用双写缓冲区；

**相关参数**

```bash
innodb_page_size=16KB;   # 默认为16KB，可设置为32KB或64KB；
innodb_doublewrite=1;   #默认为1，启用双写缓冲区，0为禁用双写缓冲区；
innodb_flush_method=O_DIRECT;  # 数据写入方式，该参数有三个值：fdatasync(默认)，O_DSYNC，O_DIRECT;
binlog_group_commit_sync_delay=xx;  # 组提交执行fsync延迟毫秒数，延迟越大，IO次数越少，性能越高；
binlog_group_commit_sync_no_delay_count=xxx; # 组提交执行fsync的批个数
```

> fdatasync：写入日志或数据文件时，仅需写入到操作系统Buffer中立即返回，fsync系统调用完成数据落盘；
>
> O_DSYNC：日志文件由写操作直接写入磁盘，数据文件写入到操作系统Buffer后，fsync系统调用完成数据落盘；
>
> O_DIRECT：数据文件由sync直接从BP写入磁盘，日志文件写入操作系统Buffer中立即返回，fsync系统调用完成数据落盘；

# InnoDB磁盘结构

InnoDB磁盘主要包含Tablespaces、InnoDB Data Dictionary、Doublewrite  Buffer、Redo Log和Undo Logs；

## 表空间（Tablespaces）：

用于存储表结构和数据；表空间又分为系统表空间、独立表空间、通用表空间、临时表空间、Undo表空间等类型；

+ 系统表空间（System Tablespace）

  包含InnoDB数据字典、Doublewrite Buffer、Change Buffer、Undo Logs的存储区域；系统表空间也默认包含任何用户在系统表空间创建的表数据和索引数据；系统表空间是一个共享的表空间；该空间的数据文件通过参数`innodb_data_file_path`控制，默认值为`ibdata1:12M:autoextend`，参数含义为文件名ibdata1，初始大小为12M，自动扩展；

+ 独立表空间（File-Per-Table Tablespace）

  默认开启，独立表空间是一个单表表空间，该表创建于自己的数据文件中，而非创建于系统表空间中；当`innodb_file_per_table`选项开启时，表奖被创建于表文件表空间中，每个表文件表空间由一个`.ibd`数据文件代表，该文件默认被创建于数据库目录中，独立表空间的表文件支持动态和压缩行格式；否则，InnoDB将被创建于系统表空间中；

+ 通用表空间（General Tablespace）

  通用表空间为通过`create Tablespace`语法创建的共享表空间；通用表空间可以创建于mysql数据目录外的其他表空间，其可以容纳多张表，且支持所有的行格式；

+ 撤销表空间（Undo Tablespace）

  撤销表空间由一个或多个包含Undo日志文件组成；在MySQL 5.7版本之前Undo占用的是System Tablespace共享区，从5.7开始将Undo从System Tablespace分离了出来；InnoDB使用的Undo表空间由`innodb_undo_tablespaces`配置选项控制，默认为0；参数为0表示使用系统表空间的`ibdata1`；大于0表示使用undo_001、undo_002等；

+ 临时表空间（Temporary Tablespace）

  分为`session temporary tablespaces`和`global temporary tablespace`两种；mysql服务器正常关闭或异常终止时，临时表空间将被移除，每次启动时会被重新创建；

  + `session temporary tablespaces`存储的是用户创建的临时表和磁盘内部的临时表；
  + `global temporary tablespaces`存储的是用户临时表的回滚段；

+ 数据字典（InnoDB Data Dictionary）

  InnoDB数据字典由内部系统表组成，这些表包含用于查找表、索引和表字段等对象的元数据；元数据物理上位于InnoDB系统表空间中；由于历史原因，数据资源元数据在一定程度上与InnoDB表元数据文件（`.frm`文件）中存储的信息重叠；

+ 双写缓冲区（Doublewrite Buffer）

  位于系统表空间，是一个存储区域；在BufferPage的page页刷新到磁盘真正的位置前，会先将数据存在Doublewrite Buffer中；如果在page页写入过程中出现操作系统、存储子系统或mysqld进程崩溃，InnoDB可以在崩溃恢复期间从Doublewrite Buffer中找到页的一个完好的备份；在大多数情况下，默认情况下启用双写缓冲区；如果要禁用双写缓冲区，可通过配置参数`innodb_doublewrite=0`；使用Doublewrite Buffer时，建议将`innodb_flush_method`设置为`O_DIRECT`；

  + MySQL的`innodb_flush_method`这个参数控制着InnoDB数据文件及redo log的打开、刷写模式；该参数有三个值：
  + fsync：默认值，表示文件先写入操作系统缓存，然后再调用fsync去异步刷数据文件与redo log的缓存信息；
  + O_DIRECT：表示文件写入操作会通知操作系统不要缓存数据，也不用预读，直接从InnoDB Buffer写入磁盘文件；
  + O_DSYNC：表示使用O_SYNC写日志，fsync写数据；InnoDB不会直接使用O_DSYNC（仅刷写数据不刷元数据），因为在很多系统中存在问题，一般不使用；

+ 重做日志（Redo Log）

  重做日志是一种基于磁盘的数据结构，用于在崩溃恢复期间更正不完整事务写入的数据；MySQL以循环方式写入重做日志文件，记录InnoDB中所有对Buffer Pool修改的日志；当出现故障，导致数据未能更新到数据文件，则数据库重启时必须redo，重新把数据更新到数据文件；读写事务在执行的过程中，都会不断产生Redo Log；默认情况下，Redo Log在磁盘上由两个名为ib_logfile0和ib_logfile1的文件物理表示；

+ 撤销日志（Undo Log）

  撤销日志是在事务开始之前保存的被修改数据的备份，用于例外情况时回滚事务；撤销日志属于逻辑日志，根据每行记录进行记录；撤销日志存在于系统表空间、撤销表空间和临时表空间中；

> MySQL 5.7版本
>
> * 将 Undo日志表空间从共享表空间 ibdata 文件中分离出来，可以在安装 MySQL 时由用
>   户自行指定文件大小和数量。
> * 增加了 temporary 临时表空间，里面存储着临时表或临时查询结果集的数据。
> * Buffer Pool 大小可以动态修改，无需重启数据库实例。
>
> MySQL 8.0 版本
>
> * 将InnoDB表的数据字典和Undo都从共享表空间ibdata中彻底分离出来了，以前需要
>   ibdata中数据字典与独立表空间ibd文件中数据字典一致才行，8.0版本就不需要了。
> * temporary 临时表空间也可以配置多个物理文件，而且均为 InnoDB 存储引擎并能创建
>   索引，这样加快了处理的速度。
> * 用户可以像 Oracle 数据库那样设置一些表空间，每个表空间对应多个物理文件，每个
>   表空间可以给多个表使用，但一个表只能存储在一个表空间中。
> * 将Doublewrite Buffer从共享表空间ibdata中也分离出来了。

# InnoDB数据文件

## InnoDB文件存储结构

<img src="MySQL4-InnoDB架构/image-20210824202855307.png" alt="表空间文件结构" style="zoom:90%;" />

InnoDB数据文件存储结构：

Tablespace（表空间）–>`ibd数据文件`–> Segment（段） –> Extent（区）–> Page（页） –> Row（行）

+ Tablespace

  表空间，用于存储多个`ibd`数据文件；

+ `ibd`数据文件

  `ibd`数据文件用于存储表的记录和索引；一个文件包含多个段；

+ Segment

  段，用于管理多个Extent，分为数据段（Leaf node segment）、索引段（Non-leaf node segment）、回滚段（Rollback segment）；一个表至少会有两个segment，一个管理数据，一个管理索引；每多创建一个索引，会多两个segment；

+ Extent

  区，一个区固定包含64个连续的页，大小为1M；当表空间不足，需要分配新的页资源，不会一页一页分配，而是直接分配一个区；

+ Page

  页，用于存储多个Row行记录，大小为16KB；包含很多种页类型，比如数据页、Undo页、系统页、事务数据页、大BLOB对象页；

+ Row

  行，包含了记录的字段值，事务ID（Trx id）、滚动指针（Roll pointer）、字段指针（Field pointers）等信息；

## InnoDB文件存储格式

可通过`show table status`查看文件存储格式；

一般情况下，如果`row_format`为REDUNDANT、COMPACT，文件格式为Antelope；如果`row_format`为DYNAMIC和COMPRESSED，文件格式为Barracuda；

通过`select * from information_schema.innodb_sys_tables`可查看指定表的文件格式；

## File文件格式

在早期的InnoDB版本中，文件格式只有一种，随着InnoDB引擎的发展，出现了新文件格式，用于支持新的功能；目前InnoDB只支持两种文件格式：Antelope和Barracuda；

+ Antelope：原始的InnoDB文件格式，支持两种行格式：COMPACT和 REDUNDANT，MySQL5.6以前的默认格式；
+ Barracuda：新的文件格式，支持InnoDB所有行格式，包括新的行格式：COMPRESSED和DYNAMIC；

> 文件格式可通过`innodb_file_format`参数配置；

## Row行格式

表的行格式决定了它的行是如何物理存储的，这反过来优惠影响查询和DML操作的性能；如果在单个page页中容纳更多行，查询和索引查找可以更快地工作，缓冲池中所需的内存更少，写入更新时所需的IO更少；

每个表的数据分成若干页来存储，每个页中采用B树结构存储；

如果字段信息过长，无法存储在B树节点中，这时候会被单独分配空间，此时被称为溢出页，该字段称为页外列；

InnoDB存储引擎支持四种行格式：REDUNDANT、COMPACT、DYNAMIC和COMPRESSED；DYNAMIC和COMPRESSED新格式引入的功能有：数据压缩、增强型长列数据的野外存储和大索引前缀；

+ REDUNDANT行格式

  使用REDUNDANT行格式，表会将变长列值的前768字节存储在B树节点的索引记录中，其余的存储在溢出页上；对于大于等于768字节的固定长度字段InnoDB会转换为变长字段，以便能够在页外存储；

+ COMPACT行格式

  与REDUNDANT行格式相比，COMPACT行格式减少了约20%的行存储空间，但代价是增加了某些操作的CPU使用量；如果系统负载是受缓存命中率和磁盘速度限制，那么COMPACT格式可能更快；如果系统负载收到CPU速度的限制，那么COMPACT格式可能会慢一些；

+ DYNAMIC行格式

  使用DYNAMIC行格式，InnoDB会将表中长可变长度的列值完全存储在页外，而索引记录只包含指向溢出页的20字节指针；大于或等于768字节的固定长度字段编码为可变长度字段；DYNAMIC行格式支持大索引前缀，最多可以为3072字节，可通过`innodb_large_prefix`参数控制；

+ COMPRESSED行格式

  COMPRESSED行格式提供与DYNAMIC行格式相同的存储特性和功能，但增加了对表和索引数据压缩的支持；

在创建表和索引时，文件格式都被用于每个InnoDB表数据文件；修改文件格式的方法是重新创建表及其索引，最简单方法是对要修改的每个表应用以下命令`alter table  tablename ROW_FORMAT=格式类型`

# Undo Log

## Undo Log介绍

Undo：以为撤销或取消，以撤销操作为目的，返回指定某个状态的操作；

Undo Log：数据库事务开始之前，会将要修改的记录存放到Undo日志里，当事务回滚或数据库崩溃时，可以利用Undo日志，撤销未提交事务对数据库产生的影响；

Undo Log产生和销毁：undo Log在事务开始前产生；事务在提交时，并不会立刻删除undo log，InnoDB会将该事务对应的undo log放入到删除列表中，后面会通过后台线程`purge thread`进行回收处理；Undo Log属于逻辑日志，记录一个变化过程；

Undo Log存储：undo log采用段的方式管理和记录；在InnoDB数据文件中包含一种rollback segment回滚段，内部包含1024个undo log segment；可通过命令`show variables like '%innodb_undo%'`控制undo log存储；

## Undo Log作用

### 实现事务的原子性

Undo Log是为了实现事务的原子性而出现的产物；事务处理过程中，如果出现了错误或者用户执行了ROLLBACK语句，MySQL利用Undo Log中的备份数据将数据恢复到事务开始之前的状态；

### 实现多版本并发控制(MVCC)

Undo Log在MySQL InnoDB存储引擎中用来实现多版本并发控制；事务未提交前，Undo Log保存了未提交之前的版本数据，Undo Log中的数据可作为数据旧版本快照供其他并发事务进行快照读；

## Redo Log和Binlog

### Redo Log日志

#### Redo Log介绍

Redo：顾名思义就是重做；以恢复操作为目的，在数据库发生意外时重现操作；

Redo Log：指事务中修改的任何数据，将最新的数据备份存储的位置，被称为重做日志；

Redo Log的生成与释放：随着事务操作的执行，就会生成redo log，在事务提交时会将产生redo log写入Log Buffer，并不是随着事务的提交就立刻写入磁盘文件；等事务操作的脏页写入到磁盘之后，redo log的使命就完成了，redo log占用的空间就可以重用；

#### Redo Log工作原理

redo log是为了实现事务的持久性而出现的产物；防止在发生故障的时间点，尚有脏页未写入表的`ibd`文件中，在重启MySQL服务时，根据redo log进行重做，从而达到事务的未入磁盘数据进行持久化这一特性；

#### Redo Log写入机制

Redo Log问价你内容是以顺序循环写入文件，写满时则回溯到第一个文件，进行覆写；

#### Redo Log配置参数

每个InnoDB存储越年轻至少有一个重做日志文件组，每个文件组至少有2个重做日志文件，默认为`ib_logfile0`和`ib_logfile1`；

Redo Buffer持久化到Redo Log的策略，可通过`innodb_flush_log_at_trx_commit`配置：

+ 0：每秒提交Redo Buffer –> OS Cache —> flush cache to disk，可能丢失一秒内的事务数据；由后台Master线程每隔1秒执行一次操作；
+ 1：默认值，每次事务提交执行Redo Buffer –> OS Cache –> flush cache to disk，最安全但性能最差的方式；
+ 2：每次事务提交执行 Redo Buffer –> OS Cache，然后由后台Master线程再每隔1秒执行 OS Cache –> flush cache to disk操作；

一般建议选择策略2，因为MySQL挂了数据没有损失，服务器怪了只会损失1秒的事务提交数据；

### Binlog日志

#### Binlog记录模式

Redo Log是属于InnoDB引擎所特有的日志，而MySQL Server也有自己的日志，即Binary Log（二进制日志），简称Binlog；

Binlog是记录所有数据库表结构变更以及表数据修改的二进制日志，不会记录`select`和`show`这类操作；

Binlog日志是以时间形式记录，还包含语句锁执行的消耗时间，开启Binlog日志有以下两个最重要的使用场景：

+ 主从复制：在主库中开启Binlog功能，这样主库就可以把Binlog传递给从库，从库拿到Binlog后实现数据恢复达到主从数据一致性；
+ 数据恢复：通过mysqlbinlog工具来恢复数据；

Binlog文件名默认为“主机名_binlog-序列号”格式，例如`demo_binlog-000001`，也可以在配置文件中指定名称；文件记录模式有STATMENT、ROW和MIXED三种，具体含义如下：

+ ROW（row-based replication，RBR）：日志中会记录每一行数据被修改的情况，然后在slave端对相同数据进行修改；
  + 优点：能清楚记录每个行数据的修改细节，能完全实现主从数据同步和数据的恢复；
  + 缺点：批量操作，会产生大量的日志，尤其是alter table会让日志暴涨；
+ STATMENT（statment-based replication，SBR）：每一条被修改数据的SQL都会记录到master的binlog中，slave在复制的时候SQL进程会解析成和原来master端执行过的相同的SQL再次执行，简称SQL语句复制；
  + 优点：日志量小，减少磁盘IO，提升存储和恢复速度；
  + 缺点：在某些情况下会导致主从数据不一致，比如last_insert_id()，now()等函数；
+ MIXED（mixed-based replication，MBR）：以上两种模式的混合使用，一般会使用STATEMENT模式保存binlog，对于STATEMENT模式无法复制的操作使用ROW模式保存binlog，MySQL会根据执行的SQL语句选择写入模式；

#### Binlog文件结构

MySQL的binlog文件中记录的是对数据库的各种修改操作，用来表示修改操作的数据结构是Log event；不同的修改操作对应的不同的log event；比较常见的log event有：Query event、Row event、Xid event等；binlog文件的内容就是各种Log event的集合；

BInlog文件中Log event结构如下图所示：

<img src="MySQL4-InnoDB架构/image-20210825012539972.png" alt="Log event结构" style="zoom:80%;" />

#### Binlog写入机制

+ 根据记录模式和操作触发event事件生成log event（事件触发执行机制）
+ 将事务执行过程中产生的log event写入缓冲区，每个事务线程都有一个缓冲区；Log Event保存在一个binlog_cache_mngr数据结构中，该结构中有两个缓冲区，一个是stmt_cache，用于存放不支持事务的信息；另一个是trx_cache，用于存放支持事务的信息；
+ 事务在提交阶段会将产生的log event写入到外部binlog文件中；不同事物以串行方式将log event写入binlog文件中，所以一个事务包含的log event信息在binlog文件中是连续的，中间不会插入其他事务的log event；

#### Binlog文件操作

+ Binlog状态查看：`show variables like '%log_bin%'`

+ 开启Binlog功能

  + 命令行模式：`set global log_bin=mysqllogbin;`

  + 配置文件模式：

    ```bash
    log-bin=mysqlbinlog
    binlog-format=ROW
    ```

+ 查看binlog日志

  + 查看日志：`show binlog events in 'mysqlbinlog.000001'`
  + 解析日志：`mysqlbinlog 'mysqlbinlog.00001' >test.sql `

+ Binlog恢复数据

  + 按指定时间恢复：`mysqlbinlog --start-datetime="2020-01-01 11:00:00" --stop-datetime "2020-01-02 11:00:00" mysqlbinlog.00002|mysql -uroot -p1234`
  + 按事件位置号恢复：`mysqlbinlog --start-position=123 --stop-position=234 mysqlbinlog.00002 |mysql -uroot -p1234`

  + mysqldump：定期全部备份数据库数据，结合mysqlbinlog可实现增量备份和数据恢复；

+ Binlog删除

  + 删除指定文件：`purge binary logs to 'mysqlbinlog.00001'`
  + 删除指定时间之前的文件：`purge binary logs before '2020-01-01 00:00:00'`
  + 清除所有日志文件：`reset master`

+ Binlog自动清理

  Binlog可通过设置`expire_logs_days`参数来启动日志自动清理功能；默认值为0，表示不启用自动清理；参数设置为1，表示超过1天binlog文件会自动删除；

### Redo Log与Binlog区别

+ Redo Log是属于InnoDB引擎功能，Binlog是属于MySQL Server自带功能，并且是以二进制文件记录；
+ Redo Log是属于物理日志，记录该数据页更新状态内容，Binlog是逻辑日志，记录更新过程；
+ Redo Log日志是循环写，日志空间大小是固定，Binlog是追加写入，不会覆盖使用；
+ Redo Log作为服务器异常宕机后事务数据自动恢复使用，Binlog可以作为主从复制和数据恢复使用；Binlog没有自动crash-safe能力；

# InnoDB事务隔离

InnoDB的多版本并发控制是基于事务隔离级别实现的，而事务隔离级别则是依托前面提到的Undo Log实现的；当读取一个数据记录时，每个事务会使用一个读视图（`Read View`），读视图用于控制事务能读取到的记录的版本；

InnoDB的事务隔离级别分为：`Read UnCommitted`、`Read Committed`、`Repeatable Read`以及`Serializable`，其中`Serializable`是基于锁实现的串行化方式，严格来说不是事务可见性范畴；

+ `Read Uncommitted`

  未提交读，也称为脏读，它读取的是当前最新修改的记录，即便这个修改最后并为生效；

+ `Read Committed`

  提交读，它基于的是当前事务内的语句开始执行时的最大的事务ID；如果其他事务修改同一个记录，在没有提交前，则该语句读取的记录还是不会变；但是这种情况会产生不可重复读，即一个事务内多次读取同一条记录可能得到不同的结果；

+ `Repeatable Read`

  可重复读，它基于的是事物开始时的读视图，直到事务结束；不读取其他新的事务对该记录的修改，保证同一个事务内的可重复读取；InnoDB提供了`next-key lock`来解决幻读问题，在一些特殊场景下，可重复读还是可能出现幻读的情况；

# InnoDB和ACID模型

事务有ACID四个属性，InnoDB是支持事务的，它实现ACID的机制如下：

+ Atomicity

  InnoDB的原子性主要是通过提供的事务机制实现；

+ Consistency

  InnoDB的一致性主要是指保护数据不受系统崩溃影响，相关特性包括：

  + InnoDB的双写缓冲区
  + InnoDB的故障恢复机制

+ Isolation

  InnoDB的隔离性也是主要通过事务机制实现，特别是为事务提供的多种隔离级别，相关特性包括：

  + Autocommit设置
  + SET ISOLATION LEVEL语句
  + InnoDB锁机制

+ Durability

  InnoDB的持久性相关特性：

  + Redo Log

  + 双写缓冲

    通过`innodb_doublewrite`开启或关闭

  + 配置`innodb_flush_log_at_trx_commit`

    用于配置InnoDB如何写入和刷新redo日志缓冲到磁盘；

    `innodb_lock_wait_timeout`可以配置刷新日志缓存到磁盘的频率，默认为1秒；

  + 配置`sync_binlog`

    用于设置同步binlog到磁盘的频率：

    为0表示禁止MySQL同步binlog到磁盘，binlog刷到磁盘的频率由操作系统决定，性能最好但最不安全；

    为1表示每次事务提交前同步到磁盘，性能最差但最安全；

    MySQL文档推荐`sync_binlog`和`innodb_flush_log_at_trx_commit`都设置为1；

  + 操作系统的`fsync`系统调用

  + UPS设备和备份策略

    

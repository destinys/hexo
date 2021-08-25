---
title: Java编程自学之路：JVM调优及常用工具
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# JVM调优实战

## JVM调优概述

### GC性能指标

对于JVM调优来说，需要先明确调优的目标。从性能角度来看，通常关注三个指标：

+ 吞吐量（`throughtput`）：指不考虑GC引起的停顿时间或内存消耗，垃圾收集器能支撑应用达到的最高性能指标；
+ 停顿时间（`latency`）：其度量标准为缩短由于垃圾收集器引起的停顿时间或完全消除因垃圾收集所引起的停顿，避免应用运行时发生抖动；
+ 垃圾回收频率：通常垃圾回收的频率越低越好，增大堆内存空间可以有效降低垃圾回收发生的频率，但同时也意味着堆积的回收对象越多，最终也会增加回收时的停顿时间。所以我们只要适当地增大堆内存空间，保证正常的垃圾回收频率即可；

### 调优原则

GC优化的两个目标：

+ 降低`Full GC`频率；
+ 减少`Full GC`执行时间；

GC优化基本原则是：将不同的GC参数应用到两个及以上的服务器上然后比较他们的性能，将能够提高性能或减少GC执行时间的参数应用于最终的工作服务器上

**降低Minor GC频率**

单次`Minor GC`时间由两部分组成：T1-扫描新生代，T2-复制存活对象；通常在JVM中，复制对象的成本要远高于扫描成本。

如果新生代空间较小，`Eden`区很快被填满，就会导致频繁`Minor GC`因此我们可以通过增大新生代空间来降低`Minor GC`的频率；

如果堆内存中存在较多的长期存活的对象，此时增加年轻代空间，反而会增加`Minor GC`的时间。如果堆中的短期对象较多，那么扩展新生代，单次`Minor GC`时间不会显著增加。因此，单次`Minor GC`时间更多取决于GC后存活对象的数量，而非`Eden`区的大小。

**降低Full GC频率**

`Full GC`相对来说会比`Minor GC`更耗时，减少进入老年代的对象数量可以显著降低`Full GC`的频率。

减少创建大对象：如果对象占用内存过大，在`Eden`区被创建后会直接传入老年代。

增大堆内存空间：在堆内存不足的情况下，增大堆内存空间，且设置初始化堆内存为最大堆内存，也可以降低`Full GC`的频率。

**降低Full GC时间**

`Full GC`的执行时间比`Minor GC`要长很多，因此`Full GC`花费时间过长，将可能出现超时错误。

+ 如果通过减小老年代内存来减少`Full GC时间，可能会引起`OutOfMemoryError或导致`Full GC`频率升高；
+ 通过增加老年代内存来降低`Full GC`频率，`Full GC`时间将会增加；

因此，老年代的大小需要设置为一个“恰当”的值；

**GC优化参数**

| 类型   | 参数                | 描述                   |
| ------ | ------------------- | ---------------------- |
| 堆内存 | `-Xms`              | 堆内存初始值           |
| 堆内存 | `-Xmx`              | 堆内存最大值           |
| 新生代 | `-XX:NewRatio`      | 新生代与老年代占比     |
| 新生代 | `-XX:NewSize`       | 新生代内存值           |
| 新生代 | `-XX:SurvivorRatio` | `Eden`与`Survivor`占比 |

GC优化时最常用参数为`-Xms`、`-Xmx`和`-XX:NewRatio`。

**GC优化过程**

GC优化大概可分为以下步骤：

+ 监控GC状态

  监控GC从而检查系统中运行的GC的各种状态；

+ 分析GC日志

  可以通过`jmap`工具来创建堆快照，来检查java内存中的对象和数据的内存文件；分析监控结构并决定是否需要进行GC优化。

+ 选择合适的GC回收器

+ 分析结果

  设置完GC参数后，收集数据，分析输入日志并检查分配的内存，不断调整GC类型/内存大小来找到系统的最佳参数。

+ 应用优化配置

  GC优化结果达到预期，即可应用于服务器上。

## GC日志

### 获取GC日志

获取GC日志有两种方式：

+ 使用`jstat`命令动态查看
+ 容器中设置相关参数打印GC日志

**jstat命令查看GC**

```bash
jstat -gc 进程号  时间间隔  输出次数
```

**打印GC参数**

通过JVM参数预设GC日志，通常有以下几种参数设置：

```
-XX:+PrintGC 输出 GC 日志
-XX:+PrintGCDetails 输出 GC 的详细日志
-XX:+PrintGCTimeStamps 输出 GC 的时间戳（以基准时间的形式）
-XX:+PrintGCDateStamps 输出 GC 的时间戳（以日期的形式，如 2013-05-04T21:53:59.234+0800）
-XX:+PrintHeapAtGC 在进行 GC 的前后打印出堆的信息
-verbose:gc -Xloggc:../logs/gc.log 日志文件的输出路径
```

### 分析GC日志

**CPU过高**

定位步骤：

1. 通过`top -c`找到CPU最高的进程ID；
2. `jstack PID`导出Java应用程序的线程堆栈信息；
3. 定位`CPU`高的线程打印其`nid`

## GC配置

### 堆大小设置

新生代的设置很关键。

JVM中最大堆大小有三方面限制：

1. 相关操作系统的数据模型限制（32bit/64bit）；
2. 系统的可用虚拟内存；
3. 系统的可用物理内存；

> 堆大小=新生代大小 + 老年代大小 + 永久代大小

+ 永久代一般为固定大小：64m。可使用`-XX:PermSize`设置；
+ 官方推荐新生代栈整个堆的3/8。 使用`-Xmn`设置；

### JVM内存配置

| 参数                | 描述                                             |
| ------------------- | ------------------------------------------------ |
| `-Xss`              | JVM栈大小                                        |
| `-Xms`              | JVM堆初始值                                      |
| `-Xmx`              | JVM堆最大值                                      |
| `-Xmn`              | JVM新生代大小                                    |
| `-XX:NewSize`       | 新生代初始值                                     |
| `-XX:MaxNewSize`    | 新生代最大值                                     |
| `-XX:NewRatio`      | 新生代与老年代比例；默认为2，即老年代是新生代2倍 |
| `-XX:SurvivorRatio` | 新生代`Eden`与`Survivor`比例。默认为8            |
| `-XX:PermSize`      | 永久代初始值                                     |
| `-XX:MaxPermSize`   | 永久代最大值                                     |

### GC类型配置

| 配置                     | 说明                                               |
| ------------------------ | -------------------------------------------------- |
| `-XX:+UseSerialGC`       | 使用`Serial+Serial Old`垃圾回收组合                |
| `-XX:+UseParallelGC`     | 使用`Parallel Scavenge + Parallel Old`垃圾回收组合 |
| `-XX:UseParNewGC`        | 使用`ParNew + Serial Old`垃圾回收组合              |
| `-XX:UseConcMarkSweepGC` | 使用`CMS+ParNew + Serial Old`垃圾回收组合          |
| `-XX:UseG1GC`            | 使用G1垃圾回收器                                   |
| `-XX:ParallelCMSThreads` | 并发标记扫描垃圾回收器；并发数=线程数              |

### 垃圾回收通用参数

| 配置                     | 描述                                |
| ------------------------ | ----------------------------------- |
| `PretenureSizeThreshold` | 设置默认晋升老年代对象大小。默认为0 |
| `MaxTenuringThreshold`   | 设置晋升老年代最大年龄，默认为15；  |
| `DisableExplicitGC`      | 禁用`System.gc()`                   |

### JMX

开启JMX后，可以使用`jconsole`或`jvisualvm`进行监控java程序的基本信息和运行情况。

```bash
-Dcom.sun.management.jmxremote=true
-Dcom.sun.management.jmxremote.ssl=false
-Dcom.sun.management.jmxremote.authenticate=false
-Djava.rmi.server.hostname=127.0.0.1
-Dcom.sun.management.jmxremote.port=18888
```

`-Djava.rmi.server.hostname`：指定Java程序运行的服务器；

`-Dcom.sun.management.jmxremote.port`：指定服务监听端口；

### 远程DEBUG

如果需要开启Java应用的远程Debug功能，需指定以下参数：

```bash
-Xdebug
-Xnoagent
-Djava.compiler=NONE
-Xrunjdwp:transport=dt_socket,address=28888,server=y,suspend=n
```

`address`即为远程debug的监听端口；

### HeapDump

```bash
-XX:-OmitStackTraceInFastThrow -XX:+HeapDumpOnOutOfMemoryError
```

### 辅助配置

| 配置                              | 描述                     |
| --------------------------------- | ------------------------ |
| `-XX:+PrintGCDetials`             | 打印GC日志               |
| `-Xloggc:<filename>`              | 指定GC日志文件名         |
| `-XX:+HeapDumpOnOutOfMemoryError` | 内存溢出时输出堆快照文件 |

# JVM命令行工具

Java程序员免不了故障排查工作，所以经常需要使用一些JVM工具；

JDK自带了一些使用的命令行工具来监控、分析JVM信息，掌握他们，非常有助于我们进行Troubleshooting；

常用JDK命令行工具：

| 名称     | 描述                                                         |
| -------- | ------------------------------------------------------------ |
| `jps`    | JVM级才能拿状态工具，显示系统内所有JVM进程                   |
| `jstat`  | JVM统计监控工具。监控虚拟机运行时状态，可以显示JVM进程中的类装载、内存、GC、JIT编译等运行数据 |
| `jmap`   | JVM堆内存分析工具，用于打印JVM进程对象直方图、类加载统计；生成堆转存快照 |
| `jstack` | JVM栈查看工具。用于打印JVM进程的线程和锁情况；兵器可以生成线程快照 |
| `jhat`   | 用来分析`jmap`的转储文件                                     |
| `jinfo`  | JVM信息查看工具，用于实时查看和调整JVM进程参数               |
| `jcmd`   | JVM命令行调试工具，用于向JVM发送调试命令                     |

## jps

`jps（JVM Process Status Tool）` 是虚拟机进程状态工具。它可以显示指定系统内所有的`Hotspot`虚拟机进程状态信息。`jps`通过`RMI`协议查询开启了`RMI`服务的远程虚拟机进程状态。

## jps 命令用法

```bash
jps [option] [hostid]
```

如果不指定`hostid`就默认为当前主机；

常用参数：

+ `option`
  + `-m`：输出JVM启动时传递给`main()`的参数;
  + `-l`：输出主类的全名，如果是执行的`jar`包，则输出`jar`路径；
  + `-v`：显示传递给JVM的参数；
  + `-q`：仅输出本地JVM进程ID；
  + `-V`：仅输出本地JVM标识符；
+ `hostid`：`RMI`注册表中注册的主机名，如果不指定则默认当前主机；

## jstat

`jstat（JVM statistics Monitoring）`是虚拟机统计信息监视工具。它可以用于监视虚拟机运行时状态信息，显示出虚拟机级进程中的类状态、内存、垃圾收集、JIT编译等运行数据。

### jstat命令用法

```bash
jstat [option] VMID [interval] [count]
```

常用参数：

+ `option`
  + `-class`：监视类状态、卸载数量、总空间以及类状态所耗费时间；
  + `-compiler`：显示JIT编译的相关信息；
  + `-gc`：监视java堆状况。显示`Eden`、`Survivor`、老年代、永久代等容量、已用空间、GC时间等；
  + `-gccapacity`：显示各个代的容量以及使用情况；
  + `-gcmetacapacity`：显示Metaspace大小；
  + `-gcnew`：显示新生代信息；
  + `-gcnewcapacity`：显示新生代大小及使用情况；
  + `-gcold`：显示老年代和永久代信息；
  + `-gcoldcapacity`：显示老年代的大小；
  + `-gcutil`：显示垃圾回收统计信息；
  + `-gccause`：显示垃圾回收的相关信息，同时显示最后一次或当前正在发生的垃圾回收诱因；
  + `-printcompilation`：输出JIT编译的方法信息
+ `VMID`：如果是本地虚拟机进程，则VMID与LVMID一致；如果是远程虚拟机进程，那么VMID格式为`[protocol:][//]lvmid[@hostname[:port]/servername]`
+ `interval`：查询间隔
+ `count`：查询次数

#### jstat使用示例

**类加载统计**

使用 `jstat -class pid` 命令可以查看编译统计信息。

【参数】

* Loaded - 加载 class 的数量
* Bytes - 所占用空间大小
* Unloaded - 未加载数量
* Bytes - 未加载占用空间
* Time - 时间

```bash
jstat -class 7129
Loaded  Bytes  Unloaded  Bytes     Time
 26749 50405.3      873  1216.8      19.75
```

**编译统计**

使用 `jstat -compiler pid` 命令可以查看编译统计信息。

【参数】

* Compiled - 编译数量
* Failed - 失败数量
* Invalid - 不可用数量
* Time - 时间
* FailedType - 失败类型
* FailedMethod - 失败的方法

```bash
jstat -compiler 7129
Compiled Failed Invalid   Time   FailedType FailedMethod
   42030      2       0   302.53          1 org/apache/felix/framework/BundleWiringImpl$BundleClassLoader findClass

```

**GC 统计**

使用 `jstat -gc pid time` 命令可以查看 GC 统计信息。

参数说明：

* `S0C`：年轻代中 To Survivor 的容量（单位 KB）；
* `S1C`：年轻代中 From Survivor 的容量（单位 KB）；
* `S0U`：年轻代中 To Survivor 目前已使用空间（单位 KB）；
* `S1U`：年轻代中 From Survivor 目前已使用空间（单位 KB）；
* `EC`：年轻代中 Eden 的容量（单位 KB）；
* `EU`：年轻代中 Eden 目前已使用空间（单位 KB）；
* `OC`：Old 代的容量（单位 KB）；
* `OU`：Old 代目前已使用空间（单位 KB）；
* `MC`：Metaspace 的容量（单位 KB）；
* `MU`：Metaspace 目前已使用空间（单位 KB）；
* `YGC`：从应用程序启动到采样时年轻代中 gc 次数；
* `YGCT`：从应用程序启动到采样时年轻代中 gc 所用时间 (s)；
* `FGC`：从应用程序启动到采样时 old 代（全 gc）gc 次数；
* `FGCT`：从应用程序启动到采样时 old 代（全 gc）gc 所用时间 (s)；
* `GCT`：从应用程序启动到采样时 gc 用的总时间 (s)。

```bash
jstat -gc 25196 1s 4
 S0C    S1C    S0U    S1U      EC       EU        OC         OU       MC     MU    CCSC   CCSU   YGC     YGCT    FGC    FGCT     GCT
20928.0 20928.0  0.0    0.0   167936.0  8880.5   838912.0   80291.2   106668.0 100032.1 12772.0 11602.2    760   14.332  580   656.218  670.550
20928.0 20928.0  0.0    0.0   167936.0  8880.5   838912.0   80291.2   106668.0 100032.1 12772.0 11602.2    760   14.332  580   656.218  670.550
20928.0 20928.0  0.0    0.0   167936.0  8880.5   838912.0   80291.2   106668.0 100032.1 12772.0 11602.2    760   14.332  580   656.218  670.550
20928.0 20928.0  0.0    0.0   167936.0  8880.5   838912.0   80291.2   106668.0 100032.1 12772.0 11602.2    760   14.332  580   656.218  670.550
```

## jmap

`jmap（JVM Memory Map）`是Java内存映射工具。`jmap`用于生成堆转储快照。

### jmap命令用法

命令格式：

```text
jmap [option] pid
```

+ `option` 选项参数：
  + `-dump` - 生成堆转储快照。`-dump:live` 只保存堆中的存活对象。
  + `-finalizerinfo` - 显示在 F-Queue 队列等待执行 `finalizer` 方法的对象
  + `-heap` - 显示 Java 堆详细信息。
  + `-histo` - 显示堆中对象的统计信息，包括类、实例数量、合计容量。`-histo:live` 只统计堆中的存活对象。
  + `-permstat` - to print permanent generation statistics
  + `-F` - 当-dump 没有响应时，强制生成 dump 快照

### jmap使用示例

**生成 heapdump 快照**

dump 堆到文件，format 指定输出格式，live 指明是活着的对象，file 指定文件名

```bash
jmap -dump:live,format=b,file=dump.hprof 28920
Dumping heap to /home/xxx/dump.hprof ...
Heap dump file created
```

dump.hprof 这个后缀是为了后续可以直接用 MAT(Memory Anlysis Tool)等工具打开。

**查看实例数最多的类**

```bash
jmap -histo 29527 | head -n 6

 num     #instances         #bytes  class name
----------------------------------------------
   1:      13673280     1438961864  [C
   2:       1207166      411277184  [I
   3:       7382322      347307096  [Ljava.lang.Object;
```

**查看指定进程的堆信息**

注意：使用 CMS GC 情况下，`jmap -heap PID` 的执行有可能会导致 java 进程挂起。

```bash
jmap -heap 12379
Attaching to process ID 12379, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 17.0-b16

using thread-local object allocation.
Parallel GC with 6 thread(s)

Heap Configuration:
   MinHeapFreeRatio = 40
   MaxHeapFreeRatio = 70
   MaxHeapSize      = 83886080 (80.0MB)
   NewSize          = 1310720 (1.25MB)
   MaxNewSize       = 17592186044415 MB
   OldSize          = 5439488 (5.1875MB)
   NewRatio         = 2
   SurvivorRatio    = 8
   PermSize         = 20971520 (20.0MB)
   MaxPermSize      = 88080384 (84.0MB)

Heap Usage:
PS Young Generation
Eden Space:
   capacity = 9306112 (8.875MB)
   used     = 5375360 (5.1263427734375MB)
   free     = 3930752 (3.7486572265625MB)
   57.761608714788736% used
From Space:
   capacity = 9306112 (8.875MB)
   used     = 3425240 (3.2665634155273438MB)
   free     = 5880872 (5.608436584472656MB)
   36.80634834397007% used
To Space:
   capacity = 9306112 (8.875MB)
   used     = 0 (0.0MB)
   free     = 9306112 (8.875MB)
   0.0% used
PS Old Generation
   capacity = 55967744 (53.375MB)
   used     = 48354640 (46.11457824707031MB)
   free     = 7613104 (7.2604217529296875MB)
   86.39733629427693% used
PS Perm Generation
   capacity = 62062592 (59.1875MB)
   used     = 60243112 (57.452308654785156MB)
   free     = 1819480 (1.7351913452148438MB)
   97.06831451706046% used
```

## jstack

`jstack(Stack Trace for Java)`是Java堆跟踪工具。jstack 用来打印目标 Java 进程中各个线程的栈轨迹，以及这些线程所持有的锁，并可以生成 java 虚拟机当前时刻的线程快照（一般称为 threaddump 或 javacore 文件）。

线程快照是当前虚拟机内每一条线程正在执行的方法堆栈的集合，生成线程快照的主要目的是定位线程出现长时间停顿的原因，如线程间死锁、死循环、请求外部资源导致的长时间等待等。

`jstack` 通常会结合 `top -Hp pid` 或 `pidstat -p pid -t` 一起查看具体线程的状态，也经常用来排查一些死锁的异常。

线程出现停顿的时候通过 jstack 来查看各个线程的调用堆栈，就可以知道没有响应的线程到底在后台做什么事情，或者等待什么资源。 如果 java 程序崩溃生成 core 文件，jstack 工具可以用来获得 core 文件的 java stack 和 native stack 的信息，从而可以轻松地知道 java 程序是如何崩溃和在程序何处发生问题。另外，jstack 工具还可以附属到正在运行的 java 程序中，看到当时运行的 java 程序的 java stack 和 native stack 的信息, 如果现在运行的 java 程序呈现 hung 的状态，jstack 是非常有用的。

### jstack命令用法

命令格式：

```shell
jstack [option] pid
```

+ `option` 选项参数
  + `-F` - 当正常输出请求不被响应时，强制输出线程堆栈
  + `-l` - 除堆栈外，显示关于锁的附加信息
  + `-m` - 打印 java 和 jni 框架的所有栈信息

### thread dump 文件

<img src="./Java编程自学之路27-JVM工具/image-20210729021242309.png" alt="thread dump文件" style="zoom:80%;" />

一个 Thread Dump 文件大致可以分为五个部分。

**第一部分：Full thread dump identifier**

这一部分是内容最开始的部分，展示了快照文件的生成时间和 JVM 的版本信息。

```text
2017-10-19 10:46:44
Full thread dump Java HotSpot(TM) 64-Bit Server VM (24.79-b02 mixed mode):
```

**第二部分：Java EE middleware, third party & custom application Threads**

这是整个文件的核心部分，里面展示了 JavaEE 容器（如 tomcat、resin 等）、自己的程序中所使用的线程信息。

```text
"resin-22129" daemon prio=10 tid=0x00007fbe5c34e000 nid=0x4cb1 waiting on condition [0x00007fbe4ff7c000]
   java.lang.Thread.State: WAITING (parking)
    at sun.misc.Unsafe.park(Native Method)
    at java.util.concurrent.locks.LockSupport.park(LockSupport.java:315)
    at com.caucho.env.thread2.ResinThread2.park(ResinThread2.java:196)
    at com.caucho.env.thread2.ResinThread2.runTasks(ResinThread2.java:147)
    at com.caucho.env.thread2.ResinThread2.run(ResinThread2.java:118)
```

参数说明：

* `"resin-22129"` **线程名称：**如果使用 java.lang.Thread 类生成一个线程的时候，线程名称为 Thread-(数字) 的形式，这里是 resin 生成的线程；
* `daemon` **线程类型：**线程分为守护线程 (daemon) 和非守护线程 (non-daemon) 两种，通常都是守护线程；
* `prio=10` **线程优先级：**默认为 5，数字越大优先级越高；
* `tid=0x00007fbe5c34e000` **JVM 线程的 id：**JVM 内部线程的唯一标识，通过 java.lang.Thread.getId()获取，通常用自增的方式实现；
* `nid=0x4cb1` **系统线程 id：**对应的系统线程 id（Native Thread ID)，可以通过 top 命令进行查看，现场 id 是十六进制的形式；
* `waiting on condition` **系统线程状态：**这里是系统的线程状态；
* `[0x00007fbe4ff7c000]` **起始栈地址：**线程堆栈调用的其实内存地址；
* `java.lang.Thread.State: WAITING (parking)` **JVM 线程状态：**这里标明了线程在代码级别的状态。
* **线程调用栈信息：**下面就是当前线程调用的详细栈信息，用于代码的分析。堆栈信息应该从下向上解读，因为程序调用的顺序是从下向上的。

 **第三部分：HotSpot VM Thread**

这一部分展示了 JVM 内部线程的信息，用于执行内部的原生操作。下面常见的集中内置线程：

`Attach Listener`

该线程负责接收外部命令，执行该命令并把结果返回给调用者，此种类型的线程通常在桌面程序中出现。

```text
"Attach Listener" daemon prio=5 tid=0x00007fc6b6800800 nid=0x3b07 waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE
```

`DestroyJavaVM`

执行 `main()` 的线程在执行完之后调用 JNI 中的 `jni_DestroyJavaVM()` 方法会唤起 `DestroyJavaVM` 线程，处于等待状态，等待其它线程（java 线程和 native 线程）退出时通知它卸载 JVM。

```text
"DestroyJavaVM" prio=5 tid=0x00007fc6b3001000 nid=0x1903 waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE
```

`Service Thread`

用于启动服务的线程

```TEXT
"Service Thread" daemon prio=10 tid=0x00007fbea81b3000 nid=0x5f2 runnable [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE
```

`CompilerThread`

用来调用 JITing，实时编译装卸类。通常 JVM 会启动多个线程来处理这部分工作，线程名称后面的数字也会累加，比如 CompilerThread1。

```TEXT
"C2 CompilerThread1" daemon prio=10 tid=0x00007fbea814b000 nid=0x5f1 waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"C2 CompilerThread0" daemon prio=10 tid=0x00007fbea8142000 nid=0x5f0 waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE
```

`Signal Dispatcher`

Attach Listener 线程的职责是接收外部 jvm 命令，当命令接收成功后，会交给 signal dispather 线程去进行分发到各个不同的模块处理命令，并且返回处理结果。 signal dispather 线程也是在第一次接收外部 jvm 命令时，进行初始化工作。

```TEXT
"Signal Dispatcher" daemon prio=10 tid=0x00007fbea81bf800 nid=0x5ef runnable [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE
```

`Finalizer`

这个线程也是在 main 线程之后创建的，其优先级为 10，主要用于在垃圾收集前，调用对象的 `finalize()` 方法；关于 Finalizer 线程的几点：

* 只有当开始一轮垃圾收集时，才会开始调用 finalize()方法；因此并不是所有对象的 finalize()方法都会被执行；
* 该线程也是 daemon 线程，因此如果虚拟机中没有其他非 daemon 线程，不管该线程有没有执行完 finalize()方法，JVM 也会退出；
* JVM 在垃圾收集时会将失去引用的对象包装成 Finalizer 对象（Reference 的实现），并放入 ReferenceQueue，由 Finalizer 线程来处理；最后将该 Finalizer 对象的引用置为 null，由垃圾收集器来回收；

JVM 为什么要单独用一个线程来执行 `finalize()` 方法呢？

如果 JVM 的垃圾收集线程自己来做，很有可能由于在 finalize()方法中误操作导致 GC 线程停止或不可控，这对 GC 线程来说是一种灾难。

```TEXT
"Finalizer" daemon prio=10 tid=0x00007fbea80da000 nid=0x5eb in Object.wait() [0x00007fbeac044000]
   java.lang.Thread.State: WAITING (on object monitor)
    at java.lang.Object.wait(Native Method)
    at java.lang.ref.ReferenceQueue.remove(ReferenceQueue.java:135)
    - locked <0x00000006d173c1a8> (a java.lang.ref.ReferenceQueue$Lock)
    at java.lang.ref.ReferenceQueue.remove(ReferenceQueue.java:151)
    at java.lang.ref.Finalizer$FinalizerThread.run(Finalizer.java:209)
```

`Reference Handler`

VM 在创建 main 线程后就创建 Reference Handler 线程，其优先级最高，为 10，它主要用于处理引用对象本身（软引用、弱引用、虚引用）的垃圾回收问题 。

```TEXT
"Reference Handler" daemon prio=10 tid=0x00007fbea80d8000 nid=0x5ea in Object.wait() [0x00007fbeac085000]
   java.lang.Thread.State: WAITING (on object monitor)
    at java.lang.Object.wait(Native Method)
    at java.lang.Object.wait(Object.java:503)
    at java.lang.ref.Reference$ReferenceHandler.run(Reference.java:133)
    - locked <0x00000006d173c1f0> (a java.lang.ref.Reference$Lock)
```

`VM Thread`

JVM 中线程的母体，根据 HotSpot 源码中关于 vmThread.hpp 里面的注释，它是一个单例的对象（最原始的线程）会产生或触发所有其他的线程，这个单例的 VM 线程是会被其他线程所使用来做一些 VM 操作（如清扫垃圾等）。 在 VM Thread 的结构体里有一个 VMOperationQueue 列队，所有的 VM 线程操作(vm_operation)都会被保存到这个列队当中，VMThread 本身就是一个线程，它的线程负责执行一个自轮询的 loop 函数(具体可以参考：VMThread.cpp 里面的 void VMThread::loop()) ，该 loop 函数从 VMOperationQueue 列队中按照优先级取出当前需要执行的操作对象(VM_Operation)，并且调用 VM_Operation->evaluate 函数去执行该操作类型本身的业务逻辑。 VM 操作类型被定义在 vm_operations.hpp 文件内，列举几个：ThreadStop、ThreadDump、PrintThreads、GenCollectFull、GenCollectFullConcurrent、CMS_Initial_Mark、CMS_Final_Remark….. 有兴趣的同学，可以自己去查看源文件。

```TEXT
"VM Thread" prio=10 tid=0x00007fbea80d3800 nid=0x5e9 runnable

```

**第四部分：HotSpot GC Thread**

JVM 中用于进行资源回收的线程，包括以下几种类型的线程：

`VM Periodic Task Thread`

该线程是 JVM 周期性任务调度的线程，它由 WatcherThread 创建，是一个单例对象。该线程在 JVM 内使用得比较频繁，比如：定期的内存监控、JVM 运行状况监控。

```text
"VM Periodic Task Thread" prio=10 tid=0x00007fbea82ae800 nid=0x5fa waiting on condition

```

可以使用 jstat 命令查看 GC 的情况，比如查看某个进程没有存活必要的引用可以使用命令 `jstat -gcutil 250 7` 参数中 pid 是进程 id，后面的 250 和 7 表示每 250 毫秒打印一次，总共打印 7 次。 这对于防止因为应用代码中直接使用 native 库或者第三方的一些监控工具的内存泄漏有非常大的帮助。

`GC task thread#0 (ParallelGC)`

垃圾回收线程，该线程会负责进行垃圾回收。通常 JVM 会启动多个线程来处理这个工作，线程名称中#后面的数字也会累加。

```TEXT
"GC task thread#0 (ParallelGC)" prio=5 tid=0x00007fc6b480d000 nid=0x2503 runnable

"GC task thread#1 (ParallelGC)" prio=5 tid=0x00007fc6b2812000 nid=0x2703 runnable

"GC task thread#2 (ParallelGC)" prio=5 tid=0x00007fc6b2812800 nid=0x2903 runnable

"GC task thread#3 (ParallelGC)" prio=5 tid=0x00007fc6b2813000 nid=0x2b03 runnable
```

如果在 JVM 中增加了 `-XX:+UseConcMarkSweepGC` 参数将会启用 CMS （Concurrent Mark-Sweep）GC Thread 方式，以下是该模式下的线程类型：

`Gang worker#0 (Parallel GC Threads)`

原来垃圾回收线程 GC task thread#0 (ParallelGC) 被替换为 Gang worker#0 (Parallel GC Threads)。Gang worker 是 JVM 用于年轻代垃圾回收(minor gc)的线程。

```TEXT
"Gang worker#0 (Parallel GC Threads)" prio=10 tid=0x00007fbea801b800 nid=0x5e4 runnable

"Gang worker#1 (Parallel GC Threads)" prio=10 tid=0x00007fbea801d800 nid=0x5e7 runnable
```

`Concurrent Mark-Sweep GC Thread`

并发标记清除垃圾回收器（就是通常所说的 CMS GC）线程， 该线程主要针对于年老代垃圾回收。

```text
"Concurrent Mark-Sweep GC Thread" prio=10 tid=0x00007fbea8073800 nid=0x5e8 runnable
```

`Surrogate Locker Thread (Concurrent GC)`

此线程主要配合 CMS 垃圾回收器来使用，是一个守护线程，主要负责处理 GC 过程中 Java 层的 Reference（指软引用、弱引用等等）与 jvm 内部层面的对象状态同步。

```text
"Surrogate Locker Thread (Concurrent GC)" daemon prio=10 tid=0x00007fbea8158800 nid=0x5ee waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE
```

这里以 WeakHashMap 为例进行说明，首先是一个关键点：

* WeakHashMap 和 HashMap 一样，内部有一个 Entry[]数组;
* WeakHashMap 的 Entry 比较特殊，它的继承体系结构为 Entry->WeakReference->Reference;
* Reference 里面有一个全局锁对象：Lock，它也被称为 pending_lock，注意：它是静态对象；
* Reference 里面有一个静态变量：pending；
* Reference 里面有一个静态内部类：ReferenceHandler 的线程，它在 static 块里面被初始化并且启动，启动完成后处于 wait 状态，它在一个 Lock 同步锁模块中等待；
* WeakHashMap 里面还实例化了一个 ReferenceQueue 列队

假设，WeakHashMap 对象里面已经保存了很多对象的引用，JVM 在进行 CMS GC 的时候会创建一个 ConcurrentMarkSweepThread（简称 CMST）线程去进行 GC。ConcurrentMarkSweepThread 线程被创建的同时会创建一个 SurrogateLockerThread（简称 SLT）线程并且启动它，SLT 启动之后，处于等待阶段。 CMST 开始 GC 时，会发一个消息给 SLT 让它去获取 Java 层 Reference 对象的全局锁：Lock。直到 CMS GC 完毕之后，JVM 会将 WeakHashMap 中所有被回收的对象所属的 WeakReference 容器对象放入到 Reference 的 pending 属性当中（每次 GC 完毕之后，pending 属性基本上都不会为 null 了），然后通知 SLT 释放并且 notify 全局锁:Lock。此时激活了 ReferenceHandler 线程的 run 方法，使其脱离 wait 状态，开始工作了。 ReferenceHandler 这个线程会将 pending 中的所有 WeakReference 对象都移动到它们各自的列队当中，比如当前这个 WeakReference 属于某个 WeakHashMap 对象，那么它就会被放入相应的 ReferenceQueue 列队里面（该列队是链表结构）。 当我们下次从 WeakHashMap 对象里面 get、put 数据或者调用 size 方法的时候，WeakHashMap 就会将 ReferenceQueue 列队中的 WeakReference 依依 poll 出来去和 Entry[]数据做比较，如果发现相同的，则说明这个 Entry 所保存的对象已经被 GC 掉了，那么将 Entry[]内的 Entry 对象剔除掉。

**第五部分：JNI global references count**

这一部分主要回收那些在 native 代码上被引用，但在 java 代码中却没有存活必要的引用，对于防止因为应用代码中直接使用 native 库或第三方的一些监控工具的内存泄漏有非常大的帮助。

```text
JNI global references: 830
```

#### 系统进程状态

系统线程有如下状态：

**deadlock**

死锁线程，一般指多个线程调用期间进入了相互资源占用，导致一直等待无法释放的情况。

**runable**

一般指该线程正在执行状态中，该线程占用了资源，正在处理某个操作，如通过 SQL 语句查询数据库、对某个文件进行写入等。

**blocked**

线程正处于阻塞状态，指当前线程执行过程中，所需要的资源长时间等待却一直未能获取到，被容器的线程管理器标识为阻塞状态，可以理解为等待资源超时的线程。

**waiting on condition**

线程正处于等待资源或等待某个条件的发生，具体的原因需要结合下面堆栈信息进行分析。

（1）如果堆栈信息明确是应用代码，则证明该线程正在等待资源，一般是大量读取某种资源且该资源采用了资源锁的情况下，线程进入等待状态，等待资源的读取，或者正在等待其他线程的执行等。

（2）如果发现有大量的线程都正处于这种状态，并且堆栈信息中得知正等待网络读写，这是因为网络阻塞导致线程无法执行，很有可能是一个网络瓶颈的征兆：

* 网络非常繁忙，几乎消耗了所有的带宽，仍然有大量数据等待网络读写；
* 网络可能是空闲的，但由于路由或防火墙等原因，导致包无法正常到达；

所以一定要结合系统的一些性能观察工具进行综合分析，比如 netstat 统计单位时间的发送包的数量，看是否很明显超过了所在网络带宽的限制；观察 CPU 的利用率，看系统态的 CPU 时间是否明显大于用户态的 CPU 时间。这些都指向由于网络带宽所限导致的网络瓶颈。

（3）还有一种常见的情况是该线程在 sleep，等待 sleep 的时间到了，将被唤醒。

**waiting for monitor entry 或 in Object.wait()**

Moniter 是 Java 中用以实现线程之间的互斥与协作的主要手段，它可以看成是对象或者 class 的锁，每个对象都有，也仅有一个 Monitor。

<img src="./Java编程自学之路27-JVM工具/image-20210729022945748.png" alt="monitor entry" style="zoom:80%;" />

从上图可以看出，每个 Monitor 在某个时刻只能被一个线程拥有，该线程就是 "Active Thread"，而其他线程都是 "Waiting Thread"，分别在两个队列 "Entry Set"和"Waint Set"里面等待。其中在 "Entry Set" 中等待的线程状态是 `waiting for monitor entry`，在 "Wait Set" 中等待的线程状态是 `in Object.wait()`。

（1）"Entry Set"里面的线程。

我们称被 `synchronized` 保护起来的代码段为临界区，对应的代码如下：

```java
synchronized(obj) {
}
```

当一个线程申请进入临界区时，它就进入了 "Entry Set" 队列中，这时候有两种可能性：

* 该 Monitor 不被其他线程拥有，"Entry Set"里面也没有其他等待的线程。本线程即成为相应类或者对象的 Monitor 的 Owner，执行临界区里面的代码；此时在 Thread Dump 中显示线程处于 "Runnable" 状态。
* 该 Monitor 被其他线程拥有，本线程在 "Entry Set" 队列中等待。此时在 Thread Dump 中显示线程处于 "waiting for monity entry" 状态。

临界区的设置是为了保证其内部的代码执行的原子性和完整性，但因为临界区在任何时间只允许线程串行通过，这和我们使用多线程的初衷是相反的。如果在多线程程序中大量使用 synchronized，或者不适当的使用它，会造成大量线程在临界区的入口等待，造成系统的性能大幅下降。如果在 Thread Dump 中发现这个情况，应该审视源码并对其进行改进。

（2）"Wait Set"里面的线程

当线程获得了 Monitor，进入了临界区之后，如果发现线程继续运行的条件没有满足，它则调用对象（通常是被 synchronized 的对象）的 wait()方法，放弃 Monitor，进入 "Wait Set"队列。只有当别的线程在该对象上调用了 notify()或者 notifyAll()方法，"Wait Set"队列中的线程才得到机会去竞争，但是只有一个线程获得对象的 Monitor，恢复到运行态。"Wait Set"中的线程在 Thread Dump 中显示的状态为 in Object.wait()。通常来说，当 CPU 很忙的时候关注 Runnable 状态的线程，反之则关注 waiting for monitor entry 状态的线程。

## jinfo

`jinfo(JVM Configuration info)`，是Java配置信息工具。`jinfo`用于实时查看和调整虚拟机运行参数。

jinfo 命令格式：

```shell
jinfo [option] pid
```

+ `option` 选项参数：
  + `-flag` - 输出指定 args 参数的值
  + `-sysprops` - 输出系统属性，等同于 `System.getProperties()`

## jhat

`jhat（JVM Heap Analysis Tool）`是虚拟机堆转储快照分析工具。

命令格式：

```shell
jhat [dumpfile]
```

# JVM GUI工具

Java程序员在进行故障排查工作时，除了可以使用JDK自带的命令行工具外，还可以使用一些常用的GUI工具；

## jconsole

jconsole是JDK自带的GUI工具。jconsole（Java Monitor and Management Console）是一种基于JVM的可视化监视与管理工具；

jconsole的管理功能是是针对JMV MBean进行管理，由于MBean可以使用代码、中间服务器的管理控制台或所有符合JMX规范的软件进行访问；

> jconsole的前提是Java应用开启JMX;

### 开启JMX

Java应用开启JMX后，可以使用`jconsole`或`jvisualvm`进行监控Java程序的基本信息和运行情况；

开启方法是，在`java`执行后，添加以下参数：

```java
-Dcom.sun.management.jmxremote=true
-Dcom.sun.management.jmxremote.ssl=false
-Dcom.sun.management.jmxremote.authenticate=false
-Djava.rmi.server.hostname=127.0.0.1
-Dcom.sun.management.jmxremote.port=18888
```

+ `-Djava.rmi.server.hostname` - 指定 Java 程序运行的服务器
+ `-Dcom.sun.management.jmxremote.port` - 指定 JMX 服务监听端口

### 连接jconsole

如果是本地Java进程，jconsole可以直接绑定连接；

如果是远程Java进行，需要连接Java进程的JMX端口；

### jconsole界面

进入jconsole应用后，可以看到以下`tab`页面：

+ 概述：显示有关Java VM的监视值的概述信息；
+ 内存：显示有关内存使用的信息；相当于可视化的`jstat`命令；
+ 线程：显示有关线程使用的信息；
+ 类：显示有关类加载的信息；
+ VM摘要：显示有关Java VM的信息；
+ MBean：显示有关MBean的信息；

## jvisualvm

jvisualvm 是 JDK 自带的 GUI 工具。**jvisualvm(All-In-One Java Troubleshooting Tool) 是多合一故障处理工具**。它支持运行监视、故障处理、性能分析等功能。

### jvisualvm概述页面

jvisualvm概述页面可以查看当前Java进程的基本信息，如：JDK版本、Java进程、JVM参数 等；

### jvisualvm监控页面

在jvisualvm监控页面，可以看到Java进程的CPU、内存、类加载、线程的实时变化；

### jvisualvm线程页面

jvisualvm线程页面展示了当前的线程状态；

jvisualvm还可以生成线程的Dump文件，帮助进一步分析线程栈信息；

### jvisualvm抽样器页面

jvisualvm可以对CPU、内存进行抽样，可以帮助我们进行性能分析；

> 相较jconsole而言，jvisualvm更好用；

## MAT

MAT解压后，安装目录下有个`MemoryAnalyzer.ini`配置文件；

`MemoryAnalyzer.ini`中有个重要的参数`-Xmx`表示最大内存，默认为：`-vmargs -Xmx1024m`

如果试图使用MAT导入的dump文件超过1024M，会触发`An internal error occurred during: "Parsing heap dump from XXX"`报错，此时可适当调整`Xmx`大小；

### MAT分析

`Leak Suspects`可以进入内存泄露页面；

+ 查看饼图了解内存整体消耗情况；
+ 缩小范围，寻找问题可疑点；

## Arthas

Arthas是Alibaba开源的Java诊断工具，深受Java程序员喜爱。在线排查问题，无需重启；动态跟踪Java代码；实时监控JVM状态；

### Arthas 基础命令

help——查看命令帮助信息
cat (opens new window)——打印文件内容，和 linux 里的 cat 命令类似
echo (opens new window)–打印参数，和 linux 里的 echo 命令类似
grep (opens new window)——匹配查找，和 linux 里的 grep 命令类似
tee (opens new window)——复制标准输入到标准输出和指定的文件，和 linux 里的 tee 命令类似
pwd (opens new window)——返回当前的工作目录，和 linux 命令类似
cls——清空当前屏幕区域
session——查看当前会话的信息
reset (opens new window)——重置增强类，将被 Arthas 增强过的类全部还原，Arthas 服务端关闭时会重置所有增强过的类
version——输出当前目标 Java 进程所加载的 Arthas 版本号
history——打印命令历史
quit——退出当前 Arthas 客户端，其他 Arthas 客户端不受影响
stop——关闭 Arthas 服务端，所有 Arthas 客户端全部退出
keymap (opens new window)——Arthas 快捷键列表及自定义快捷键

### Arthas jvm 相关命令

dashboard (opens new window)——当前系统的实时数据面板
thread (opens new window)——查看当前 JVM 的线程堆栈信息
jvm (opens new window)——查看当前 JVM 的信息
sysprop (opens new window)——查看和修改 JVM 的系统属性
sysenv (opens new window)——查看 JVM 的环境变量
vmoption (opens new window)——查看和修改 JVM 里诊断相关的 option
perfcounter (opens new window)——查看当前 JVM 的 Perf Counter 信息
logger (opens new window)——查看和修改 logger
getstatic (opens new window)——查看类的静态属性
ognl (opens new window)——执行 ognl 表达式
mbean (opens new window)——查看 Mbean 的信息
heapdump (opens new window)——dump java heap, 类似 jmap 命令的 heap dump 功能

### Arthas class/classloader 相关命令

sc (opens new window)——查看 JVM 已加载的类信息
sm (opens new window)——查看已加载类的方法信息
jad (opens new window)——反编译指定已加载类的源码
mc (opens new window)——内存编译器，内存编译.java文件为.class文件
redefine (opens new window)——加载外部的.class文件，redefine 到 JVM 里
dump (opens new window)——dump 已加载类的 byte code 到特定目录
classloader (opens new window)——查看 classloader 的继承树，urls，类加载信息，使用 classloader 去 getResource

### Arthas monitor/watch/trace 相关命令

请注意，这些命令，都通过字节码增强技术来实现的，会在指定类的方法中插入一些切面来实现数据统计和观测，因此在线上、预发使用时，请尽量明确需要观测的类、方法以及条件，诊断结束要执行 stop 或将增强过的类执行 reset 命令。

monitor (opens new window)——方法执行监控
watch (opens new window)——方法执行数据观测
trace (opens new window)——方法内部调用路径，并输出方法路径上的每个节点上耗时
stack (opens new window)——输出当前方法被调用的调用路径
tt (opens new window)——方法执行数据的时空隧道，记录下指定方法每次调用的入参和返回信息，并能对这些不同的时间下调用进行观测

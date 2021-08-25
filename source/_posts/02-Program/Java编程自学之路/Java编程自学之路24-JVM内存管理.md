---
title: Java编程自学之路：JVM内存管理
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# JVM体系结构

JVM能够跨平台工作，主要是由于JVM屏蔽了与各个计算机平台相关的软件、硬件之间的差异。

## JVM简介

### 计算机体系结构

真实的计算机体系结构的核心部分包含：

+ 指令集
+ 计算单元（CPU）
+ 寻址方式
+ 集群器
+ 存储单元

### JVM体系结构

JVM体系结构与计算机体系结构相似，它的核心部分包括：

+ JVM指令集
+ 类加载器
+ 执行引擎—相当于JVM的CPU
+ 内存区
+ 本地方法调用

## Hotspot架构

`Hotspot`是当前最流行的JVM。

Java虚拟机的主要组件，包括类加载器、运行时数据区和执行引擎。

`Hotspot`虚拟机拥有一个架构，它支持强大特性和能力的基础平台，支持实现高性能和强大的可伸缩的能力。

<img src="./Java编程自学之路24-JVM内存管理/image-20210727221408299.png" alt="JVM虚拟机架构" style="zoom:80%;" />

### Hotspot性能指标

Java虚拟机的性能指标主要有两点：

+ 停顿时间：响应延迟是指一个应用回应一个请求的速度有多快。对关注响应能力的应用来说，长暂停时间是不可接受的，重点是在短的时间周期内内能做出响应。
+ 吞吐量：吞吐量关注在特定的时间周期内一个应用的工作量的最大值。对关注吞吐量的应用来说长暂停时间是可以接受的。由于高吞吐量的应用关注的基准在更长周期时间上，所以快速响应时间不在考虑之内。

# Java内存管理

## 内存介绍

### 物理内存与虚拟内存

物理内存就是通常所说的RAM（随机存储器）。

虚拟内存使得多个进程在同事运行时可以共享物理内存，这里的共享只是空间上共享，在逻辑上彼此依然是隔离的。

### 内核空间与用户空间

一个计算通常有固定大小的内存空间，但是程序并不能使用全部的空间。因为这些空间被划分为内核空间和用户空间，而程序只能使用用户空间的内存。

### 使用内存的Java组件

Java启动后，作为一个进程运行在操作系统中。

有哪些Java组件需要占用内存呢？

+ 堆内存：Java堆，类和类加载器；
+ 栈内存：线程
+ 本地内存：NIO、JNI

## 运行时数据区域

JVM在执行Java程序的过程中会把它所管理的内存划分为若干个不同的数据区域。这些区域都有各自的用途，以及创建和销毁的时间，有的区域随着虚拟机进程的启动而存在，有些区域则依赖用户线程的启动和结束而简历和销毁。

<img src="./Java编程自学之路24-JVM内存管理/image-20210727222623699.png" alt="JVM运行时数据区" style="zoom:80%;" />

### 程序计数器

程序计数器（`Program Counter Register`）是一块较小的内存空间，它可以看做是当前线程所执行的字节码的行号指示器。分支、循环、跳转、异常、线程恢复等都依赖于计数器。

当执行的线程数量超过CPU数量时，线程之间会根据时间片轮询争夺CPU资源。如果一个线程的时间片耗尽，或者其它原因导致这个线程的CPU资源被提前抢夺，那么这个退出的线程就需要单独的一个程序计数器，来记录下一条运行的指令，从而在线程切换后能恢复到正确的执行位置。各条线程间的计数器互不影响，独立存储，我们称这类内存区域为“线程私有”的内存。

+ 如果线程正在执行的是一个Java方法，这个计数器记录的是正在执行的虚拟机字节码指令的地址；
+ 如果正在执行的是` Native`方法，这个计数器值则为空；

### Java虚拟机栈

Java虚拟机栈（`Java Virtual Machine Stacks`）也是线程私有的，它的生命周期与线程相同。

每个Java方法在执行的同事都会创建一个栈帧（`Stack Frame`）用于存储局部变量表、操作数栈、常量池引用等信息。每个方法从调用直至执行完成的过程，就对应着一个栈帧在java虚拟机栈中入栈和出栈的过程。

+ 局部变量表：32位变量槽，存放了编译期克制的各种基本数据类型、对象引用、`ReturnAddress`类型；
+ 操作数栈：基于栈的执行引擎，虚拟机把操作数栈作为它的工作区，大多数指令都要从这里弹出数据、执行运算，然后把结果压回操作数栈；
+ 动态链接：每个栈帧都包含一个指向运行时常量池中该栈帧所属方法的引用。持有这个引用是为了支持方法调用过程中的动态链接。Class文件的常量池中有大量的符号引用，字节码中的方法调用指令就以常量池中指向方法的符号引用为参数。这些符号引用一部分会在类加载阶段或第一次使用的时候转化为直接引用，这种转化称为静态解析。另一部分将在每一次的运行期间转化为直接引用，这部分称为动态链接；
+ 方法出口：返回方法被调用的位置，恢复上层方法的局部变量和操作数栈，如果无返回值，则把它压入调用者的操作数栈；

> 该区域可能抛出以下异常：
>
> + 线程请求的栈深度超过最大值，会抛出`StackOverflowError`异常；
> + 如果虚拟机栈进行动态扩展时，无法申请到足够内存，就会抛出`OutOfMemoryError`；
>
> 参数配置：
>
> 可通过`-Xss`这个虚拟机参数来指定一个程序的Java虚拟机栈内存大小；
>
> `java -Xss512M HackTheJava`

### 本地方法栈

本地方法栈（`Native Method Stack`）与虚拟机栈的作用相似。

二者的区别在于：虚拟机栈为Java方法服务，而本地方法区为Native方法服务。本地方法由C语言实现。

> 本地方法栈也会抛出`StackOverflowError`和`OutOfMemoryError`异常；

### Java堆

Java堆（`Java Heap`）的作用就是存放对象实例，几乎所有的对象实例都是在这里分配内存。

Java堆是垃圾收集的主要区域（因此也叫GC堆）。现代的垃圾收集器基本都是采用分代收集算法，该算法的思想是针对不同的对象采取不同的垃圾回收算法。

虚拟机将Java堆分为以下三块：

+ 新生代：`Young Generation`
  + `Eden`：占比80%
  + `From Survivor`：占比10%
  + `To Survivor`：占比10%
+ 老年代：`Old Generation`
+ 永久代：`Permanent Generation`

当一个对象被创建时，它首先进入新生代，之后有可能被转移到老年代中。新生代存放着大量的生命很短的对象，因此新生代在三个区域中垃圾回收的频率最高。

> Java堆不需要连续内存，并可以动态扩展其内存，扩展失败会抛出`OutOfMemoryError`异常；
>
> 可以通过`-Xms`和`-Xmx`两个虚拟机参数来制定一个程序的Java堆内存大小，第一个参数设置初始值，第二个设置最大值；
>
> `java -Xm=1M -Xmx=10M HackTheJava`

### 方法区

方法区（`Method Area`）也被称为永久代。方法区用于存放已被加载的类信息、常量、静态变量、即时编译器编译后的代码等数据。

对这块区域进行垃圾回收的主要目标是对常量池的回收和对类的卸载，但一般比较难实现。

> 方法区不需要连续的内存，并且可以动态扩展，扩展失败会抛出`OutOfMemoryError`异常；
>
> + JDK8之前，Hotspot虚拟机把它当成永久代来进行来及回收，可通过`-XX:PermSize`和`-XX:MaxPermSize`设置；
> + JDK8开始，取消了永久代，用`metaspace`（元数据）区替代，可通过参数`-XX:MaxMetaspaceSize`设置；

### 运行时常量池

运行时常量池（`Runtime Constant Pool`）是方法区的一部分，`Class`文件中除了有类的版本、字段、方法、接口等描述信息，还有一项信息是常量池（`Constant Pool Table`），用于存放编译器生成的各种字面量和符号引用，这部分内容会在类加载后被放入这个区域。

+ 字面量：文本字符串、声明为`final`的常量值等；
+ 符号引用：类和接口的完全限定名、字段名称和描述符、方法名称和描述符；

除了在编译器生成的常量，还允许动态生成，例如`String`类的`intern()`。这部分常量也会被放入运行时常量池。

> 运行时常量池无法申请到内存时也会抛出`OutOfMemoryError`异常；

### 直接内存

直接内存（`Direct Memory`）并不是虚拟机运行时数据区的一部分，也不是JVM规范中的内存区域。

在Java 1.4中新加入了NIO类，它可以使用`Native`函数库直接分配堆外内存，然后通过一个存储在Java堆里的`DirectByteBuffer`对象作为这块内存的引用进行操作。这样能在一些场景中显著提高性能，因为避免了在Java堆和`Native`堆中来回复制数据。

> 直接内存这部分也被频繁的使用，也可能导致`OutOfMemoryError`异常；
>
> 直接内存可以通过`-XX:MaxDirectMemorySize`指定，如果不指定，则默认与Java堆最大值(`-Xmx`)一样；

### Java内存区域作用范围

| 内存区域     | 内存作用范围   | 常见异常                                 |
| ------------ | -------------- | ---------------------------------------- |
| 程序计数器   | 线程私有       | 无                                       |
| Java虚拟机栈 | 线程私有       | `StackOverflowError`及`OutOfMemoryError` |
| 本地方法栈   | 线程私有       | `StackOverflowError`及`OutOfMemoryError` |
| Java堆       | 线程共享       | `OutOfMemoryError`                       |
| 方法区       | 线程共享       | `OutOfMemoryError`                       |
| 运行时常量池 | 线程共享       | `OutOfMemoryError`                       |
| 直接内存     | 非运行时数据区 | `OutOfMemoryError`                       |

## JVM运行原理

```java
public  class JVMCase {
  //常量
  public final static String MAN_SEX_TYPE = "man";
  //静态变量
  public static String WOMAN_SEX_TYPE = "woman";
  
  public static void main(String[] args) {
    
    Student  stu = new Student();
    stu.setName("nick");
    stu.setSexType(MAN_SEX_TYPE);
    stu.setAge(20);
    
    JVMCase jvmcase = new JVMCase();
    //调用静态方法
    print(stu);
    //调用非静态方法
    jvmcase.sayHi(stu);
  }
  
  public static void print(Student stu) {
    System.out.println(" name : " + stu.getName() + " ; sex: " + stu.getSexType + " ; age : " + stu.getAge());
  }
  
  public void sayHi(Student stu) {
    System.out.println(stu.getName() + " say: hello!");
  }
}

class Student {
  String name;
  String sexType;
  int age;
  
  public String getName() {
    return name;
  }
  
  public void setName(String name) {
    this.name = name;
  }
  
  public String getSexType() {
    return sexType;
  }
  
  public void setSexType(String sexType) {
    this.sexType = sexType;
  }
  
  public int getAge() {
    return age;
  }
  
  public void setAge(age) {
    this.age = age;
  }
}
```

1. JVM向操作系统申请内存，根据内存大小找到具体的内存分配表，然后将内存段开始地址和终止地址分配给JVM，接下来进行内部分配；
2. JVM获得内存空间后，会根据配置参数分配对、栈及方法区大小；
3. 完成`class`文件加载、验证、准备及解析，其中准备节点会为类的静态变量分配内存；
4. JVM执行构造器`<clinit>`方法，编译器会在`.java`文件被编译成`.class`文件时，手机所有类的初始化代码，包括静态变量赋值、静态代码块、静态方法，收集在一起组合成`<clinit>()`方法；
5. 执行`<clinit>()`方法，启动`main`线程，执行`main`方法；执行第一行代码，堆内存中创建一个`student`对象，`student`对象引用存放在栈中；
6. 创建`JVMCase`对象，存入堆内存中，并将其引用存入栈中；通过`JVMCase`对象调用其方法；

## JVM异常

#### OutOfMemoryError

`OutOfMemoryError`简称`OOM`。Java中对`OOM`的解释是，没有空闲内存，并且垃圾收集器也无法提供更多内存，通俗的解释就是：JVM内存不足。

在JVM规范中，除了程序计数器区域外，其他运行时区域都可能发生`OutOfMemoryError`异常。

##### 堆内存溢出

`java.lang.OutOfMemoryError:Java heap space`这个错误意味着：堆空间溢出。

堆空间溢出有可能是`内存泄露（Memory Leak）`或`内存溢出（Memory Overflow）`。可通过使用`jstack`和`jmap`生成`threaddump`和`heapdump`，然后使用内存分析工具如MAT进行分析。

**Java heap space分析步骤**

1. 使用`jmap`或`-XX:+HeapDumpOnOutOfMemoryError`获取堆快照；
2. 使用内存分析工具（`visualvm、mat、jProfile`等）对堆快照进行分析；
3. 根据分析图，重点是确认内存中的对象是否是必要的，分析究竟是内存泄露还是内存溢出；

**内存泄露**

内存泄露是指由于疏忽或错误造成程序未能释放已经不在使用的内存的情况。

内存泄露并非指内存在物理上的消失，而是应用程序分配某段内存后，由于设计错误，时区了对该段内存的控制，因而造成了内存的浪费。内存泄露随着被执行的次数不断增加，最终导致内存溢出。

内存泄露常见场景：

+ 静态容器
  + 声明为静态（`static`）的`HashMap`、`Vector`等集合；
  + 通俗来讲A中有B，当前只把B设置为空，A没有设置为空，回收时B无法回收。因为B被A引用；
+ 监听器
  + 监听器被注册后释放对象时，没有删除监听器；
+ 物理链接
  + 各种连接池简历了链接，未通过`close()`关闭链接；
+ 内部类和外部模块引用

重点关注：

+ `FGC`：从应用程序启动到采样时发生`Full GC`的次数；
+ `FGCT`：从应用程序启动到采样时`Full GC`所用的时间（单位为毫秒）；
+ `FGC`次数越多，`FGCT`所需时间越多，越有可能发生内存泄露；

如果内存泄露，可以进一步查看泄露对象到`GC Roots`的对象引用链。这样就能找到泄露对象是怎样与`GC Roots`关联并导致`GC`无法回收它们的。

导致内存泄露的常见原因是使用容器，且不断想容器中添加元素，但没有清理，导致容器内存不断膨胀。

**内存溢出**

如果不存在内存泄露，即内存中的对象确实都必须存活着，则应当检查虚拟机的堆参数（`-Xms`和`-Xmx`），与机器物理内存进行对比，看看是否可以调大。

##### GC开销超过限制

`java.lang.OutOfMemoryError:GC overhead limit exceeded`这个错误，官方给出的定义是：超过`98%`的时间用来做GC并且回收了不到`2%`的堆内存时会抛出此异常。这意味着，发生在GC占用大量时间为释放很小空间的时候发生的，这是一种保护机制。导致异常的原因：一般是因为堆太小，没有足够的内存。

与`Java heap space`错误处理方法类似，先判断是否存在内存泄露。如果有，则修正代码，如果没有，则通过`-Xms`和`-Xmx`适当调整堆内存大小。

##### 永久代空间不足

`Perm`（永久代）空间主要用于存放`Class`和`Meta`信息，包括类的名称和字段，带有方法字节码的方法、常量池信息，与类关联的对象数组和类型数组以及即时编译器优化。GC在主程序运行期间不会对永久代空间进行清理，默认为64M大小。

根据上面的定义，可以得出`PermGen`大小要求取决于加载的类的数量以及此类声明的大小。造成该错误的主要原因是永久代中装入了太多的类或太大的类。

在JDK8之前的版本，可以通过`-XX:PermSize`和`-XX:MaxPermSize`设置永久代空间大小，在JDK8及之后的版本，可通过`--XX:MaxMetaspaceSize`从而限制方法区大小，并简介限制其中常量池的容量。

**PermGen space解决方案**

+ 解决初始化时的`OutOfMemoryError`

  在应用程序启动期间触发由于`PermGen`耗尽导致的`OOM`时，只需要扩大`PermGen`大小，，能够将所有类加载到`PermGen`即可；

+ 解决重新部署时的`OOM`

  冲洗部署应用程序 后立即发生`OOM`，一般为类加载器泄露导致。这种情况需要使用借助`jmap`等工具进行分析；

+ 解决运行时`OOM`

  第一步检查是否允许GC从`PermGen`卸载类。可通过添加JVM参数`-XX:CMSClassUnloadingEnabled=true;-XX:+UseConcMarkSweepGC`允许GC扫描`PermGen`并删除不在使用的类。

  第二步使用如`jmap`、`jstack`等分析工具进行分析；

##### 元数据空间不足

Java8以后，JVM内存空间发生了很大变化，取消了永久代，转换为元数据区。

元数据区的内存不足，即方法区和运行时常量池的空间不足。

一个类要被垃圾回收期回收，判断条件比较苛刻。

**解决方案**

+ 增加元数据区空间：通过参数`-XX:MaxMetaspaceSize=512M`扩大元数据区空间；
+ 删除此参数完全解除对元数据区的大小限制，JVM默认对元数据区的大小没有限制。但这可能会导致大量交换或到达本机物理内存而分配失败。

##### 无法创建本地线程

`java.lang.OutOfMemoryError:Unable to create new native thread`这个错误意味着：Java应用程序已达到其可以启动线程数的限制。

当发起一个线程的创建时，虚拟机在JVM内存中创建一个`Thread`对象同时创建一个操作系统线程，而这个系统线程的内存使用的不是JVM内存，而是系统中剩下的内存。

一个JVM能够创建多个线程呢？

```java
线程数=(MaxProcessMemory - JVMMemory - ReservedOsMemory) / ThreadStackSize
```

参数说明：

+ `MaxProcessMemory`：一个进程的最大内存；
+ `JVMMemory`：JVM内存；
+ `ReservedOsMemory`：保留的操作系统内存；
+ `ThreadStackSize`：线程栈大小；

给JVM分配的内存越多，那么能用来创建系统线程的内存就会越少，越容易发生`unable to create new native thread`。所以，JVM内存不是分配越大越好。

通常无法创建本地线程会经历以下几个阶段：

1. JVM内部运行的应用程序请求新的Java线程；
2. JVM本机代码代理为操作系统创建新本地线程的请求；
3. 操作系统尝试创建一个新的本机线程，该线程需要将内存分配给该线程；
4. 操作系统拒绝本机内存分配，原因是32位Java进程大小已耗尽其内存地址或操作系虚拟内存已耗尽；
5. 引发`java.lang.OutOfMemoryError:Unable to create new native thread`错误；

##### 直接内存溢出

由直接内存导致的内存溢出，一个明显的特征是在`Heap Dump`文件中不会看见明显的异常，如果发现`OOM`之后的`Dump`文件很小，而程序中又直接或间接使用了NIO，则可能是因为这个原因导致的。

#### StackOverflowError

对应`Hotspot`虚拟机来说，栈容量只由`-Xss`参数来决定如果线程请求的栈深度大于虚拟机所允许的最大深度，将抛出`StackOverflowError`异常。

从实战来说，栈溢出的常见原因：

+ 递归函数调用层数太深
+ 大量循环或死循环

---
title: Java编程自学之路：并发容器
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# 同步容器

## 同步容器简介

在Java中，同步容器主要包括2类：

+ ​	`Vector`、`Stack`、`Hashtable`
  + `Vector`：`Vector`实现了`List`接口，其实际上是一个数组，和`ArrayList`类似，但`Vector`中的方法都是`synchronized`方法，即进行了同步措施。
  + `Stack`：`Stack`是一个同步容器，它的方法也使用了`synchronized`进行了同步，实际上升是继承于`Vector`类。
  + `Hashtable`：`Hashtable`实现了`Map`接口，它和`HashMap`很相似，但是`Hashtable`进行了同步处理，而`HashMap`没有。
+ `Collections`类中提供的静态工厂方法创建的类（由`Collections.synchronizedXXX`等方法）

## 同步容器的问题

同步容器的同步原理就是在其`get`、`set`、`size`等主要方法上用`synchronized`修饰。

`synchronized`可以保证在同一时刻，只有一个线程可以执行某个方法或代码块。

**性能问题**

`synchronized`的互斥同步会产生阻塞和唤醒线程的开销。显然，这种方式比没有使用`synchronized`的容器性能差很多。

**安全问题**

同步容器是否绝对安全呢？

其实也未必。在进行复合操作（非原子操作）时，仍然需要加锁来保护。常见复合操作如下：

+ 迭代：反复访问元素，直至遍历完全部元素。
+ 跳转：根据指定顺序寻找当前元素的下1或N个元素。
+ 条件运算：例如若没有则添加等。

# 并发容器

## 并发容器简介

同步容器将所有对容器状态的访问都串行化，以保证线程安全性，这种策略会严重降低并发性。

JDK5后提供了多种并发容器，使用并发容器来代替同步容器，可以极大的提高伸缩性并降低风险。

J.U.C包中提供了一个非常有用的并发容器作为线程安全的容器：

| 并发容器                | 普通容器    | 描述                                                     |
| ----------------------- | ----------- | -------------------------------------------------------- |
| `ConcurrentHashMap`     | `HashMap`   | JDK8之前采用分段锁机制细化锁粒度，之后基于CAS实现。      |
| `ConcurrentSkipListMap` | `SortedMap` | 基于跳表实现                                             |
| `CopyOnWriteArrayList`  | `ArrayList` |                                                          |
| `CopyOnWriteArraySet`   | `Set`       | 基于`CopyWriteArrayList`实现                             |
| `ConcurrentSkipListSet` | `SortedSet` | 基于`ConcurrentSkipListMap`实现                          |
| `ConcurrentLinkedQueue` | `Queue`     | 线程安全的无界队列，底层采用单链表，支持FIFO             |
| `ConcurrentLinkedDeque` | `Deque`     | 线程安全的无界双端队列，底层采用双向链表，支持FIFO和FILO |
| `ArrayBlockingQueue`    | `Queue`     | 数组实现的阻塞队列                                       |
| `LinkedBlockingQueue`   | `Queue`     | 链表实现的阻塞队列                                       |
| `LinkedBlockingDeque`   | `Deque`     | 双向链表实现的双端阻塞队列                               |

J.U.C包中提供的并发容器命名一般分为三类：

+ `Concurrent*`：
  + 这类型的锁竞争相对于`CopyOnWrite*`要高一些，但写操作代价要小一些。
  + `Concurrent*`往往提供较低的遍历一致性；即：当利用迭代器遍历时，如果容器发生修改，迭代器仍然可以继续进行遍历。代价就是，在获取容器代销，容器是否为空等方法时，结果不一定完全精确，这是为了获取并发吞吐量的设计取舍；与之相比，如果使用同步容器，可能会出现`fail-fast`问题，即：检测到容器在遍历过程中发生了修改，则抛出`ConcurrentModificationException`，不在继续遍历。
+ `CopyOnWrite*`：
  + 一个线程写，多个线程读。读操作时不加锁，写操作时通过在副本上加锁保证并发安全，空间开销大。
+ `Blocking*`：
  + 内部实现一般是基于锁，提供阻塞队列的能力。

## 并发场景下Map

如果对数据有强一致性要求，则需使用`Hashtable`；在大部分场景通常都是弱一致性的情况下，使用`ConcurrentHashMap`即可；如果数据量达到千万级别，且存在大量增删改操作时，则可以考虑使用`ConcurrentSkipListMap`。

## 并发场景下List

读多写少使用`CopyOnWriteArrayList`；写多读少使用`ConcurrentLinkedQueue`，但由于其是无界的，需要进行容量限制，避免无限膨胀，导致内存溢出。

# Map

`Map`接口的两个实现是`ConcurrentHashMap`和`ConcurrentSkipListMap`；从应用角度来看，主要区别在于`ConcurrentHashMap`的`key`是无序的，而`ConcurrentSkipListMap`的`key`是有序的，且两者的`key`与`value`均不能为空，否则会抛出`NullPointerException`运行时异常。

## ConcurrentHashMap

`ConcurrentHashMap`是线程安全的`HashMap`，用于替代`Hashtable`。

**特性**

`ConcurrentHashMap`实现了`ConcurrentMap`接口，而`ConcurrentMap`接口扩展了`Map`接口。

`ConcurrentHashMap`的实现包含了`HashMap`所有的基本特性，如数据结构、读写策略等。

`ConcurrentHashMap`没有实现对`Map`加锁以提供独占访问。因此无法通过在客户端加锁的方式来创建新的原子操作。但是，一些常见的复合操作，如“若没有则添加”、“若相等则替换”等都以实现为原子操作，并且是围绕着`ConcurrentMap`的扩展来实现的。

**原理**

+ JDK7

  + 数据结构：数组+单链表

  + 并发机制：分段锁机制细化锁粒度，降低阻塞，提高并发性

  + 实现：分段锁，是将内部进行分段（Segment），里面是`HashEntry`数组，和`HashMap`类似，哈希相同的条目也是以链表形式存放。`HashEntry`内部使用`volatile`的`value`字段来保证可见性，也利用了不可变对象的机制，以改进利用`Unsafe`提供的底层能力，比如`volatile access`，去直接完成部分操作，以优化性能。

    <img src="Java编程自学之路19-并发容器/image-20210721224900435.png" alt="分段锁机制" style="zoom:80%;" />

+ JDK8

  + 数据结构：数组+单链表+红黑树
  + 并发机制：取消分段锁，基于CAS+`synchronized`实现。
  + 实现：
    + 当数据出现哈希冲突时，数据会存入数据指定桶的单链表，当链表长度达到8，则将其转换为红黑树结构，以改进性能。
    + 取消`segments`字段，直接采用`transient volatile HashEntry<K,V>[] table`保存数据，采用`table`数组元素作为锁，从而实现对每一行数据进行加锁，进一步减少并发冲突的概率。
    + 使用CAS + `synchronized`操作，在特定场景进行无锁并发操作。使用`Unsafe`、`LongAdder`之类底层手段，进行极端情况的优化。

# List

## CopyOnWriteArrayList

`CopyOnWriteArrayList`是线程安全的`ArrayList`。`CopyOnWrite`字面意思为写的时候会将共享变量新复制一份出来。复制的好处在于读操作是无锁的。

`CopyOnWriteArrayList`仅适用于写操作非常少的场景，而且能够容忍读写的短暂不一致，如果读写比例均衡或者有大量写操作的话，使用`CopyOnWriteArrayList`性能会非常糟糕。

**原理**

`CopyOnWriteArrayList`内部维护了一个数组，成员变量`array`就执行这个内部数组，所有的读操作都是基于`array`进行的，

+ `lock`：执行写时复制操作，需要使用可重入锁加锁
+ `array`：对象数组，用于存放元素
+ 读操作：读操作不同步，他们在内部数组的快照上工作，多个迭代器可同时遍历而不会相互阻塞；
+ 写操作：所有的写操作都是同步的，他们在备份数组上工作，写操作完成后，后备队列将被替换为复制的队列，并释放锁定。支持数组变得易变，所以数组的调用是原子操作。
  + 添加操作：先将原容器复制一份，然后在新副本上执行写操作，之后再切换引用，此过程加锁。
  + 删除操作：与添加操作类似，将除要删除之外的元素拷贝到新副本中，然后切换引用，将容器引用指向新副本，此过程同样加锁。

> `CopyOnWriteArrayList`读性能差不多是写性能的一百倍。

# Set

`Set`接口的两个实现是`CopyOnWriteArraySet`和`ConcurrentSkipListSet`，使用场景参考`CopyOnWriteArrayList`和`ConcurrentSkipListMap`，它们原理是一样的。

# Queue

Java并发包里面的`Queue`类并发容器是最复杂的，可以从以下两个维度分类：

+ 阻塞与非阻塞
+ 单端与双端

## BlockingQueue

`BlockingQueue`：顾名思义，是一个阻塞对了，`BlockingQueue`基本都是基于锁实现的，当对垒已满时，入队操作阻塞；当队列已空时，出队操作阻塞。

`BlockingQueue`对插入操作、移除操作、获取元素提供了四种不同方法用于不同的场景使用：

+ 抛出异常
+ 返回特殊值（`null`或`true/false`，取决于具体的操作）
+ 阻塞等待此操作，直到操作成功
+ 阻塞等待此操作，知道成功或超时

总结如下：

| 操作类型 | 异常      | 特殊值   | 阻塞           | 超时               |
| -------- | --------- | -------- | -------------- | ------------------ |
| Insert   | add(e)    | offer(e) | put(e)         | offer(e,time,unit) |
| Remove   | remove()  | poll()   | take           | poll(time,unit)    |
| Examine  | element() | peek()   | not applicable | not applicable     |

> BlockingQueue不接受`null`值元素

JDK提供了以下阻塞队列：

+ `ArrayBlockingQueue`：一个由数组结构组成的有界阻塞队列。
+ `LinkedBlockingQueue`：一个由链表结构组成的有界阻塞队列。
+ `PriorityBlockingQueue`：一个支持优先级排序的吴杰阻塞队列。
+ `SynchronousQueue`：一个不存储元素的阻塞队列。
+ `DelayQueue`：一个使用优先级队列实现的无界阻塞队列。
+ `LinkedTransferQueue`：一个由链表结构组成的无界阻塞队列。

## PriorityBlockingQueue

**要点**

+ `PriorityBlockingQueue`可以视为`PriorityQueue`的线程安全版本。
+ `PriorityBlockingQueue`实现了`BlockingQueue`，也是一个阻塞队列。
+ `PriorityBlockingQueue`实现了`Serializable`，支持序列化。
+ `PriorityBlockingQueue`不接受`null`值元素。
+ `PriorityBlockingQueue`的插入操作`put`方法不会`block`，因为它是无界序列。

**原理**

+ `queue`是一个`Object`数组，用于保存`PriorityBlockingQueue`的元素。
+ 可重入锁`lock`则用于在执行插入、删除操作时，保证这个方法在当前线程释放锁之前，其他线程不能访问。

> `PriorityBlockingQueue`容量索然有初始化大小，但是不限制大小，如果当前容量已满，则插入新元素时自动扩容。

## ArrayBlockingQueue

`ArrayBlockingQueue`是由数组结构组成的有界阻塞队列。

**要点**

+ `ArrayBlockingQueue`实现`BlockingQueue`，也是一个阻塞队列。
+ `ArrayBlockingQueue`实现了`Serializable`，支持序列化。
+ `ArrayBlockingQueue`是基于数组实现的有界阻塞队列。所以初始化时必须指定容量。

**原理**

`ArrayBlockingQueue`内部以`final`的数组保存数据，数组的大小决定了队列的边界。

`ArrayBlockingQueue`实现并发同步，原理为读操作与写操作都需要获取到AQS独占锁才能进行操作。队列构造时可以指定以下三个参数：

+ 队列容量：限制队列中最多允许的元素个数
+ 锁类型：可指定为公平锁或非公平锁。非公平锁吞吐量高，公平锁保证每次都是等待醉酒的线程获取到锁。
+ 初始化：指定一个集合来初始化，将此集合中的元素在构造方法期间就先添加到队列中。

## LinkedBlockingQueue

`LinkedBlockingQueue`是由链表结构组成的有界阻塞队列。容易被误解为无边界，但其实其行为和内部代码都是基于有界的逻辑实现的，如果创建队列时没有指定容量，那么其容量就自动被设置为`Integer.MAX_VALUE`，约等于无界队列。

**要点**

+ `LinkedBlockingQueue`实现了`BlockingQueue`，也是一个阻塞队列。
+ `LinkedBlockingQueue`实现了`Serializable`，支持序列化。
+ `LinkedBlockingQueue`基于单链表实现的阻塞队列，可以当做无界队列也可以当做有界队列来使用。
+ `LinkedBlockingQueue`中元素按照插入顺序保存(FIFO)。

## SynchronousQueue

`SynchronousQueue`是不存储元素的阻塞队列。每个删除操作都要等待插入操作，反之每个插入操作也都要等待删除操作。队列容量为0.

`SynchronousQueue`类，在线程池的实现类`ScheduledThreadPoolExecutor`中得到了应用。

`SynchronousQueue`的队列其实是虚的，数据必须从某个写线程交给某个读线程，而不是写到某个队列中等待被消费。

`SynchronousQueue`不能被迭代，因为没有元素可以拿来迭代。

`SynchronousQueue`不允许传递`null`值。

## ConcurrentLinkedDeque

`Deque`的侧重点是支持对队列头尾都进行插入和删除，所以提供了特定的方法，如：

+ 尾部插入时需要的`addLast(e)`、`offerLast(e)`
+ 尾部删除所需要的`removeLast()`、`poolLast()`

# Queue并发应用

`Queue`被广发使用在生产者-消费者场景，在并发场景中，利用`BlockingQueue`的阻塞机制，可以减少很多并发协调工作。

+ 队列边界：
  + `ArrayBlockingQueue`有明确容量限制；
  + `LinkedBlockingQueue`取决于是否在创建时指定；
  + `SynchronousQueue`不能缓存任何元素；
+ 空间利用
  + `ArrayBlockingQueue`要求初始内存较大，且需要连续的内存空间，但整体相对紧凑；
  + `LinkedBlockingQueue`整体内存空间要求相对较大；
+ 性能
  + `ArrayBlockingQueue`实现简单，性能稳定；
  + `SynchronousQueue`在元素较小的场景是性能非常优异；


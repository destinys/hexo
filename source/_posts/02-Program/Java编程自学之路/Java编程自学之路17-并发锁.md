---
title: Java编程自学之路：并发锁
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# 并发锁简介

确保线程安全最常见的做法是利用锁机制（`Lock`、`synchronized`）来对共享数据做互斥同步，这样在同一个时刻，只有一个线程可以执行某个方法或者代码块，那么操作必然是原子性的，线程安全的。

## 可重入锁

可重入锁，顾名思义，指的是线程可以重复获取同一把锁。即同一个线程在外层方法获取 了锁，在进入内层方法会自动获取锁。

可重入锁可在一定程度 上避免死锁。

+ `ReentrantLock`、`ReentrantReadWriteLock`是可重入锁。
+ `synchronized`也是一个可重入锁。

## 公平锁与非公平锁

+ 公平锁：公平锁是指多线程按照申请锁的顺序来获取锁。
+ 非公平锁：非公平锁是指多线程不按照申请锁的顺序来获取锁。这就可能出现优先级反转或者饥饿现象。

公平锁为 了保证线程申请顺序，势必要付出一定的性能代价，因此其吞吐量一般低于非公平锁。

公平锁与非公平锁在Java中的典型实现：

+ `synchronized`只支持非公平锁。
+ `ReentrantLock`、`ReentrantReadWriteLock`，默认是非公平锁，但支持公平锁。

## 独享锁与共享锁

独享锁与共享锁是一种广义上的说法，从实际用途上来看，也常被称为互斥锁与读写锁。。

+ 独享锁：独享锁是指锁一次只能被一个线程所持有。
+ 共享锁：共享锁是指锁可以被多个线程锁持有。

独享锁与共享锁在Java中的典型实现：

+ `synchronized`、`ReentrantLock`只支持独享锁。
+ `ReentrantReadWriteLock`其写锁是独享锁，其读锁是共享锁。读锁是共享锁使得并发读是非常高效的，读写、写读、写写的过程是互斥的。

## 悲观锁与乐观锁

乐观锁与悲观锁不是指具体的什么类型的锁，而是并发同步的策略。

+ 悲观锁：悲观锁对于并发采取悲观的态度，悲观锁认为：不加锁的并发操作一定会出问题。悲观锁适合写操作频繁的场景。
+ 乐观锁：乐观锁对于并发采取乐观的态度，乐观锁认为：不加锁的并发操作也没什么问题；对于同一个数据的并发操作，是不会发生修改操作的。在更新数据时，会采用不断尝试更新的方式更新数据，乐观锁适合读多写少的场景。

悲观锁与乐观锁在Java中的典型实现：

+ 悲观锁在Java中的应用是通过`synchronized`和`Lock`显示加锁来进行互斥同步，这是一种阻塞同步。
+ 乐观锁在Java中的应用就是采用`CAS`机制。（`CAS`操作通过`Unsafe`类提供，但这个类不直接暴露为API，所以都是间接使用，如各种原子类）

## 偏向锁、轻量级锁及重量级锁

所谓轻量级锁与重量级锁，指的是锁控制粒度的粗细。显然，控制粒度越细，阻塞开销越小，并发性也就越高。

JDK6以前，重量级锁一般指的是`synchronized`，而轻量级锁指的是`volatile`。

JDK6以后，针对`synchronized`做了大量优化，引入无锁状态、偏向锁、轻量级锁和重量级锁。锁可以单向的从偏向锁升级到轻量级锁，再升级至重量级锁。

+ 偏向锁：偏向锁是指一段同步代码一直被一个线程所访问，那么该线程就会升级为轻量级锁。降低获取锁的代价。
+ 轻量级锁：是指当锁是偏向锁的时候，被另一个线程锁访问，那么该线程会自动获取锁，其他线程会通过自选的形式尝试获取锁，不会阻塞，提高性能。
+ 重量级锁：是指当锁为轻量级锁的时候，另一个线程虽然是自旋，但自旋不会一直持续下去，当自旋一定次数的时候，还没有获取到锁，就会进入阻塞，该锁膨胀为重量级锁。重量级锁会让其他申请的线程进入阻塞，性能降低。

## 分段锁

分段锁其实是一种锁的设计，并不是具体的一种锁。所谓分段锁，就是把锁的独享分成多段，每段独立控制，使得锁的粒度更细，减少阻塞开销，从而提高并发性。

`Hashtable`使用`synchronized`稀释方法来保证线程安全性，面对线程的访问，`Hashtable`就会锁住整个对象，所有的其他线程只能等待，这种阻塞方式的吞吐量很低。

JDK7以前的`ConcurrentHashMap`就是分段锁的典型按理。`ConcurrentHashMap`维护了一个`Segment`数组，一般称为分段桶。

当有线程访问`ConcurrentHashMap`的数据时，`ConcurrentHashMap`会先根据`hashCode`计算出数据在哪个桶，然后锁住该桶。

## 显式锁与内置锁

JDK5之前，协调对共享对象的访问时可以使用的机制只有`synchronized`和`volatile`。这两个都属于内置锁，即锁的申请和释放都是由JVM控制。

JDK5之后，增加了新的机制：`ReentrantLock`、`ReentrantReadWriteLock`，这类锁的申请和释放都可以由程序控制，所以常被称为显式锁。

显式锁与内置锁的差异：

+ 主动获取锁和释放锁
  + `synchronized`不能主动获取锁和释放锁。获取锁和释放锁都是JVM控制。
  + `ReentrantLock`可以主动获取锁和释放锁。（忘记释放锁可能产生死锁）
+ 响应中断
  + `synchronized`不能响应中断。
  + `ReentrantLock`可以响应中断。
+ 超时机制
  + `synchronized`没有超时机制。
  + `ReentrantLock`有超时机制；设置超时后，超时自动释放锁，避免一直等待。
+ 支持公平锁
  + `synchronized`只支持非公平锁。
  + `ReentrantLock`支持公平锁和非公平锁。
+ 是否支持共享
  + `synchronized`修饰的方法或代码块，只能被一个线程访问（独享）。如果这个线程被阻塞，其他线程也只能等待。
  + `ReentrantLock`可以基于`Condition`灵活控制同步条件。
+ 是否支持读写分离
  + `synchronized`不支持读写锁分离。
  + `ReentrantReadWriteLock`支持读写锁，从而使阻塞读写的操作分开，有效提高并发性。

# Lock和Condition

## 为何引入Lock和Condition

并发编程领域，有量大核心问题：互斥与同步。

+ 互斥：同一时刻只允许一个线程访问共享资源。
+ 同步：线程间如何通信、协作。

这两大问题，管程都是能够解决的。JDK并发包通过Lock和Condition两个接口来实现管程，其中Lock用于解决互斥问题，Condition用于解决同步问题。

`synchronized`是管程的一种实现，但使用不当可能会出现死锁。

`synchronized`无法通过破坏不可抢占条件来避免死锁，原因是`synchronized`申请资源的时候，如果申请不到，线程直接进入阻塞状态，无法操作也无法释放已占有资源。

与`synchronized`不同的是，`Lock`提供了一组无条件、可轮询、定时的以及可中断的锁操作，所有获取锁、释放锁的操作都是显示的操作。

## Lock接口

`Lock`接口定义如下：

```java
public interface Lock {
  void lock();
  void lockInterruptibly() throws InterruptedException;
  boolean tryLock();
  boolean tryLock(long time, timeUnit unit) throws InterruptedException;
  void unlock();
  Condition newCondition();
}
```

+ `lock()`：获取锁；
+ `unlock()`：释放锁；
+ `tryLock()`：尝试获取锁；
+ `tryLock(long time TimeUnit unit)`：和`tryLock()`类似，区别在于限定时间，如果达到限定时间未获取到锁，则视为失败；
+ `lockInterruptibly()`：锁未被另一个线程持有，且线程没有被中断的情况下，才能获取锁；
+ `newCondition()`：返回一个绑定到`Lock`对象上的`Condition`实例；

## Condition

`Condition`实现了管程模型里面的条件变量。

在单线程中，一段代码的可执行可能依赖于某个状态，如果不满足状态条件，代码就不会被执行（典型场景为`if...else…`）。在并发环境中，当一个线程判断某个状态条件时，其状态可能是由于其他线程的操作而改变，这时就需要一定的协调机制来确保在同一时刻，数据只能被一个线程锁修改，且修改的数据状态被所有线程锁感知。

在JDK5之前，主要利用`Object`类的`wait`、`notify`及`notifyAll`配合`synchronized`来进行线程间通信。

JDK5之后引入`Lock`，使用`Lock`的线程彼此间通过`Condition`通信。

**Condition特性**

`Condition`接口定义如下：

```java
public interface Condition {
  void await() throws InterruptedException;
  void awiatUninterruptibly();
  long awaitNanos(long nanosTimeout) throws InterruptedException;
  boolean await(long time TimeUnit unit) throws InterruptedException;
  boolean awaitUntil(Date deadline) throws InterruptedException;
  void signal();
  void signalAll();
}
```

+ 每个锁（`Lock`）上可以存在多个`Condition`，这意味着锁的状态条件可以有多个。
+ 支持公平的或非公平的队列操作。
+ 支持可中断的条件等待。
+ 支持可定时的等待。

# ReentrantLock

`ReentrantLock`类是`Lock`接口的具体实现，与内置锁`synchronized`相同的是，它是一个可重入锁。

## ReentrantLock特性

`ReentrantLock`特性如下：

+ 支持互斥性、内存可见性和可重入性。
+ 支持公平锁和非公平锁（默认）两种模式。
+ 实现了`Lock`接口，支持了`synchronized`锁不具备的灵活性。
  + `synchronized`无法中断一个重在等待获取锁的线程
  + `synchronized`无法在请求获取一个锁时无休止地等待

## ReentrantLock使用

### 构造方法

+ `ReentrantLock()`：默认构造方法，初始化一个非公平锁（NonfairSync）；
+ `ReentrantLock(boolean)`：初始化一个公平锁(FairSync)；

### lock和unlock方法

+ `lock()`：无条件获取锁。如果当前线程无法获取锁，则当前线程进入休眠状态不可用，直至当前线程获取到锁。如果该锁没有被另一个线程持有，则获取该锁并立即返回，并将锁的持有计数设置为1。
+ `unlock()`：用于释放锁。

> 获取锁操作`lock()`必须在`try catch`块中进行，并且释放锁操作`unlock()`放在`finally`块中进行，以保证锁一定被释放，防止死锁发生。

### trylock方法

无与条件获取锁相比，`tryLock`有更完善的容错机制。

+ `tryLock()`：可轮询获取锁。如果成功，则返回`true`；如果失败，则返回`false`。也就是说，这个方法无论成败都会立即返回，获取不到锁时会一直等待。
+ `tryLock(long,TimeUnit)`：可定时获取锁。与`tryLock`类似，区别仅在于这个方法在获取不到锁时会等待一定时间，在时间期限之内如果还获取不到锁，就返回`false`。如果一开始就拿到锁或者在等待期间内拿到了锁，则返回`true`。

### lockInterruptibly方法

+ `lockInterruptibly()`：可中断获取锁。可中断获取锁可以在获得锁的同时保持对中断的响应。可中断获取锁比其他获取锁的方式更复杂一些，需要两个`try catch`。

> 当一个线程获取到了锁之后，是不会被`interrupt()`方法中断的。单独调用`interrupt()`方法不能中断正在运行状态中的线程，只能中断阻塞状态中的线程。因此当通过`lockInterruptibly()`方法获取某个锁时，如果未获取到锁，只有在等待的状态下，才可以响应中断。

### newCondition方法

`newCondition()`：返回一个绑定到`Lock`对象上的`Condition`实例。

# ReentrantReadWriteLock

`ReadWriteLock`适用于读多写少的场景。

`ReentrantReadWriteLock`类是`ReadWriteLock`接口的具体实现，它是一个可重入的写锁。

`ReentrantReadWriteLock`维护了一对读写锁，将读写锁分开，有利于提高并发效率。

读写锁，并不是Java语言特有的，而是一个广为使用的通用技术，所有的读写锁都遵守以下基本原则：

+ 允许多个线程同时读共享变量；
+ 只允许一个线程写共享变量；
+ 如果一个写线程正在执行写操作，此时禁止读线程读共享变量；

读写锁与互斥锁的一个重要区别就是读写锁允许多个线程同时读共享变量，而互斥锁是不允许的，这是读写锁在读多写少场景下性能优于互斥锁的关键。但读写锁的写操作是互斥的，当一个线程在写共享变量的时候，是不允许其他线程执行写操作和读操作的。

## ReentrantReadWriteLock特性

+ 适合读多写少场景，如果写多读少，则性能反而较`ReentrantLock`差一些。
+ 读写锁分离，有利于提高并发效率。锁策略为：允许多个读操作并发执行，但每次只允许一个写操作。
+ 读写锁都提供可重入的加锁语义。
+ 支持公平锁与非公平锁（默认）模式。

# StampedLock

`ReadWriteLock`支持读锁与写锁。而`StampedLock`支持三种模式，分别是写锁、悲观读锁和乐观读。其中，写锁、悲观读锁的语义和`ReadWriteLock`的写锁、读锁的语义非常类似，允许多个线程同时获取悲观读锁。但是只允许一个线程获取写锁，写锁与悲观读锁是互斥的。不同的是：`StampedLock`里的写锁和悲观读锁加锁成功之后，都会返回一个`stamp`；然后解锁的时候，需要传入这个`stamp`。

> 乐观读操作是无锁的，所以相较于写锁，乐观读的性能会更好一些。

`StampedLock`的性能之所以比`ReadWriteLock`好，其关键是`StampedLock`支持乐观读。

+ `ReadWriteLock`支持多个线程同时读，但是当多个线程同时读的时候，所有的写操作会被阻塞；
+ `StampedLock`提供乐观读，允许一个线程获取写锁，也就是说不是所有的写操作都被阻塞；

对于读多写少的场景`StampedLock`性能很好，简单的应用场景基本上可以替代`ReadWriteLock`，但是`StampedLock`的功能仅仅是`ReadWriteLock`的子集，在使用的时候，需要注意以下几点：

+ `StampedLock`不支持重入；
+ `StampedLock`悲观读锁、写锁都不支持条件变量；
+ 如果线程`StampedLock`的`readLock()`或者`writeLock()`上时，此时调用该阻塞线程的`interrupt()`方法，会导致CPU飙升。使用`StampedLock`一定不要调用中断操作，如果需要支持中断功能，一定要使用可中断的悲观读锁`readLockInterruptibly()`和写锁`writeLockInterruptibly()`；

# AQS

`AbstractQueuedSynchronizer`简称AQS，是队列同步器，顾名思义，其主要作用是处理同步。它是并发锁和很多同步工具类的实现基石。

## AQS要点

AQS提供了对独享锁与共享锁的支持。

在`java.lang.concurrent.locks`包中的相关锁都是基于AQS来实现。这些锁都没有直接继承AQS,而是定义了一个`Sync`类去继承AQS。因为锁面向的是使用用户，而同步器面向的则是线程控制，在锁的实现中聚合同步器而不是直接继承AQS，可以很好的做到隔离二者过关注的事情。

## AQS应用

AQS提供了对独占锁与共享锁的支持。

### 独占锁API

获取、释放速战所的主要API如下：

+ `acquire`：获取独占锁；
+ `acquireInterruptibly`：获取可中断的独占锁；
+ `tryAcquireNanos`：尝试在指定时间内获取可中断的独占锁，在以下情况下返回：
  + 超时时间内，成功获取锁；
  + 当前线程超时时间内被中断；
  + 超时时间结束，仍未获取锁返回`false`；
+ `release`：释放独占锁；

### 共享锁API

+ `acquireShared`：获取共享锁；
+ `acquireSharedInterruptibly`：获取可中断的共享锁；
+ `tryAcquireSharedNanos`：尝试在指定时间内获取可中断的共享锁；
+ `release`：释放共享锁；

## AQS原理

+ AQS使用一个整形的`volatile`变量来维护同步状态，状态的意义由子类赋予；
+ AQS维护一个FIFO的双链表，用来存储获取锁失败的线程；

# 死锁

## 什么是死锁

死锁是一种特定的程序状态，在实体之间，由于循环依赖导致彼此一直处于等待之中，没有任何个体可以继续前进。死锁不仅仅是在线程之间会发生，存在资源独占的进程之间同样也可能出现死锁。通常来说，我们大多聚焦在多线程场景中的死锁，指两个或多个线程之间，由于互相持有对方需要的锁，而永久处于阻塞的状态。

## 如何定位死锁

定位死锁最常见的方式就是利用`jstack`等工具获取线程栈，然后定位互相之间的依赖关系，进而找到死锁。如果是比较明显的死锁，往往`jstack`等就能直接定位，类似`JConsole`甚至可以在图形化界面进行优先的死锁检测。

如果是开发自己管理的工具，需要更加程序化的方式扫描服务进程、定位死锁，可以考虑使用Java提供的标准管理API，`ThreadMXBean`，其直接就提供了`findDeadlockedThreads()`方法用于定位。

## 如何避免死锁

基本上死锁的发生是因为：

+ 互斥：类似Java中`Monitor`都是独占的；
+ 长期保持互斥，在使用结束前，不会释放，也不能被其他线程抢占；
+ 循环依赖，多个个体之间虚线了锁的循环依赖，彼此依赖上一环释放锁；

由此可知，避免死锁的思路为：

+ 避免一个线程同时获取多个锁；
+ 避免一线程在锁内同时占用多个资源，尽量保证每个锁只占用一个资源；
+ 尝试使用定时锁`Lock.tryLock(timeout)`，避免锁一直不能释放；
+ 对于数据库锁，加锁和解锁必须在一个数据库链接里，否则会出现解锁失败情况；




---
title: Java编程自学之路：并发工具类
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# CountDownLatch

字面意思为递减计数锁，用于控制一个线程等待多个线程。

`CountDownLatch`维护一个计数器`count`，表示需要等待的事件数量。`countDown`方法递减计数器，表示有一个时间已经发生，调用`await`方法的线程会一直阻塞直到计数器为零，或者等待中的线程中断或者等待超时。

`CountDownLatch`是基于AQS实现的。

```java
public CountDownLatch(int count) {}；
public void await() throws InterruptedException {};
public boolean await(long timeout, TimeUnit unit) throws InterruptedException {};
public void countDown() {};
```

说明：

+ `count`：初始化时传入的统计值；
+ `await()`：调用`await()`方法的线程会被挂起，它会等待知道`count`值为0才继续执行；
+ `await(long timeout, TimeUnit unit)`：与`await()`类似，只不过等待一定的时间后`count`值未归零也会继续执行；
+ `countDown()`：将统计值减1；

# CyclicBarrier

字面意思为循环珊栏，`CyclicBarrier`可以让一组线程等待至某个状态之后再全部执行。之所以被叫做循环珊栏，是因为当所有等待线程被释放以后，`CyclicBarrier`可以被重用。

`CyclicBarrier`维护一个计数器`count`，每次执行`await`方法之后，`count`加1，知道计数器的值与设置的值相等，所有等待的线程才会继续执行。

`CyclicBarrier`是基于`ReentrantLock`和`Condition`实现的。

`CyclicBarrier`应用场景：并行迭代算法场景；

```java
public CyclicBarrier(int parties) {};
public CyclicBarrier(int parties, Runnable barrierAction) {};
public int await() throws InterruptedException, BrokenBarrierException {};
public int await(long timeout, TimeUnit unit) throws InterrputedException,BrokenBarrierException,TimeoutException {};
public void reset() {};
```

# Semaphore

字面意思为信号量，`Semaphore`用来控制某段代码的并发数。

`Semaphore`管理着一组虚拟的许可（`permit`），`permit`的初始数量可通过构造方法来指定。每次执行`acquire`方法可以获取一个`permit`，如果没有就等待；而`release`方法可以释放一个`permit`。

`Semaphore`应用场景：

+ 用于实现资源池，如数据库连接池。
+ 用于将任何一种容器编程有界阻塞容器。

# 总结

`CountDownLatch`和`Cyclicbarrier`都能够实现线程间的等待，只不过他们侧重点不同：

+ `CountDownLatch`一般用于某个线程等待若干个其他线程执行完任务后，该线程方可执行；不可重用；
+ `CyclicBarrier`一般用于一组线程互相等待至某个状态，然后这一组线程再同时执行；可重用；

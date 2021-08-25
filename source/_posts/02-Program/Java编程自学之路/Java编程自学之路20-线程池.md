---
title: Java编程自学之路：线程池
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# 线程池简介

## 什么是线程池

线程池是一种多线程处理形式，处理过程中将任务添加到队列，然后在创建县城后自动启动这些任务。

### 为什么使用线程池

如果并发请求数量较多 ，但每个线程执行的时间很短时，就会出现频繁的创建和销毁线程，大大降低系统的效率，可能创建与销毁线程的时间、资源开销要大于实际工作的所需。使用线程池的好处：

+ 降低资源消耗：通过重复利用已创建的线程降低线程创建和销毁造成的损耗。
+ 提高响应速度：当任务到达时，任务可以不需要等到线程创建就能立即执行。
+ 提高线程可管理性：线程是稀缺资源，如果无限制创建，不会消耗系统资源，还会降低系统的稳定性，使用线程池可以进行统一的分配、调优和监控。

# Executor框架

`Executor`框架是一个根据一组执行策略调用、调度、执行和控制的异步任务框架，目的是提供一种将“任务提交”和“任务运行”分离开来的机制。

## 核心API

+ `Executor`：运行任务的简单接口。
+ `ExecutorService`：扩展了`Executor`接口，扩展能力为：
  + 支持有返回值的线程；
  + 支持管理线程的生命周期；
+ `ScheduledExecutorService`：扩展了`ExecutorService`接口。
  + 扩展能力：支持定期执行任务。
+ `AbstractExecutorService`：`ExecutorService`接口的默认实现。
+ `ThreadPoolExecutor`：`Executor`框架最核心的类，它继承`AbstractExecutorService`类。
+ `ScheduledThreadPoolExecutor`：`ScheduledExecutorService`接口的实现，一个可定时调度任务的线程池。
+ `Executors`：可通过调用`Executors`的静态工厂方法来创建线程池并返回一个`ExecutorService`对象。

## Executor

`Executor`接口只定义了一个`execute`方法，用于接收一个`Runnable`对象。

## ExecutorService

`ExecutorService`接口继承了`Executor`接口，它提供了`invokeAll`、`invokeAny`、`shutdown`、`submit`等方法。其主要的扩展为：

+ 支持有返回值的线程：`submit`、`invokeAll`、`invokeAny`方法都支持传入`Callable`对象。
+ 支持管理线程生命周期：`shutdown`、`shutdownNow`、`isShutdown`等方法。

## ScheduledExecutorService

`ScheduledExecutorService`接口扩展了`ExecutorService`接口。

它除了支持前面两个接口能力以外，还支持定时调度线程。

+ `shedule`方法可以在指定的延时后执行一个`Runnable`或者`Callable`任务。
+ `scheduleAtFixedRate`方法和`scheduleWithFixedDelay`方法可以按照指定时间间隔，定期执行任务。

# ThreadPoolExecutor

`java.util.concurrent.ThreadPoolExecutor`类是`Executor`框架中最核心的类。

## 参数说明

+ `ctl`：用于控制线程池的运行状态和线程池中的有效线程数量。

  + 线程池的运行状态（`runState`）
  + 线程池内有效线程数量（`workerCount`）
  + `ctl`使用`Integer`保存，高3位保存`runState`，低29位保存`workerCount`。`COUNT_BITS`就是29，`CAPACITY`就是1左移19位减1，这个常量表示`workerCount`的上限值，大约5亿。

+ 运行状态：

  + `RUNNING`：运行状态，接口新任务，并且也能处理阻塞队列中的任务。
  + `SHUTDOWN`：关闭状态，不接受新任务，但可以处理阻塞队列中的任务。
    + 在线程池处于`RUNNING`状态时，调用`shutdown`方法会使线程池进入到该状态。
    + `finalize`方法在执行过程中也会调用`shutdown`方法进入该状态。
  + `STOP`：停止状态，不接受新任务也不处理对垒中的任务。会中断正在处理任务的线程。在线程池处于`RUNNING`或`SHUTDOWN`状态时，调用`shutdownNow`方法会使线程池进入到该状态。
  + `TIDYING`：整理状态，如果所有的 任务都已经终止了，`workerCount`为0，线程池进入该状态后会调用`terminated`方法进入`TERMINATED`状态。
  + `TERMINATED`：已终止状态，在`terminated`方法执行完后进入该状态。默认`terminated`方法中什么也没有做。进入`TERMINATED`的条件如下:
    + 线程池不是`RUNNING`状态。
    + 线程池状态不是`TIDYING`或`TERMINATED`状态。
    + 线程池状态为`SHUTDOWN`且`workerCount`为空。
    + `workerCount`为0。
    + 设置`TIDYING`状态成功。

  <img src="Java编程自学之路20-线程池/image-20210722002858083.png" alt="线程池状态" style="zoom:80%;" />

## 构造方法

`ThreadPoolExecutor`有四个构造方法，前三个都是基于第四个实现。第四个构造方法如下：

```java
public  ThreadPoolExecutor( int corePoolSize, 
                           int maximunPoolSize,
                           long keepAliveTime, 
                           TimeUnit unit, 
                           BlockingQueue<Runnable> workQueue, 
                           ThreadFactory threadFactory, 
                           RejectedExecutionHandler handler) 
{}
```

参数说明：

+ `corePoolSize`：核心线程数量，当有新任务通过`execute`方法提交时，线程池会执行以下判断：
  + 运行线程数小于`corePoolSize`，则创建新线程来处理任务，即使线程池中的其他线程是空闲状态。
  + 如果线程池中线程数量大于等于`corePoolSize`且小于`maximumPoolSize`，则只有当`workQueue`满时才创建新的线程去处理任务。
  + 如果设置的`corePoolSize`和`maximumPoolSize`相同，则创建的线程池的大小是固定的。任务提交时，如果`workQueue`未满，则将请求放入`workQueue`中，等待有空闲的线程去从`workQueue`中取任务并处理。
  + 如果运行的线程数量大于等于`maximumPoolSize`，这时如果`workQueue`已经满了，则使用`handler`所指定的策略来处理任务。
  + 任务提交判断的顺序为：`corePoolSize`=> `workQueue`=> `maximumPoolSize`。
+ `maximumPoolSize`：最大线程数。
  + 如果队列满，且已创建线程数小于最大线程数，则线程池会再创建新的线程执行任务。
  + 如果使用吴杰的任务队列，则该参数无效。
+ `keepAliveTime`：线程保持活动的时间。
  + 线程池中的线程数量大于`corePoolSize`的时候，如果没有新的任务提交，核心线程外的线程不会立即销毁，而是会等待，知道等待的时间超过了`keepAliveTime`。
+ `unit`：`keepAliveTime`的时间单位。
  + `DAYS`：天
  + `HOURS`：小时
  + `MINUTES`：分钟
  + `MILLISECONDS`：毫秒
  + `MICROSECONDS`：微妙
  + `NANOSECONDS`：纳秒
+ `workQueue`：等待执行的任务队列，用于保存等待执行的任务的阻塞队列。可选队列如下：
  + `ArrayBlockingQueue`：有界阻塞队列
    + 基于数组的FIFO队列
    + 创建时需指定大小
  + `LinkedBlockingQueue`：无界阻塞对列
    + 基于俩表的FIFO队列
    + 默认大小为`Integer.MAX_VALUE`
    + 吞吐量高于`ArrayBlockingQueue`
    + 最大线程数量为`corePoolSize`，`maximumPoolSize`参数无效；等待任务队列是无界队列。
    + `Executors.newFixedThreadPool`使用了此队列。
  + `SynchronousQueue`：不会保存提交的任务，而是将直接新建一个线程来执行新来的任务。
    + 每个插入操作必须等到另一个线程调用移除操作，否则插入操作一直处于阻塞状态。
    + 吞吐量高于`LinkedBlockingQueue`
    + `Executors.newCachedThreadPool`使用了此队列。
  + `threadFactory`：线程工厂，可以通过线程工厂给每个创建出来的线程设置更有意义的名字。
  + `handler`：饱和策略，他是`RejectedExecutionHandler`类型的变量，当队列和线程池都满了，说明线程池处于饱和状态，那么必须采取一种策略处理提交的新任务。线程池支持以下策略：
    + `AbortPolicy`：丢弃任务并抛出异常，默认策略。
    + `DiscardPolicy`：丢弃任务，但不抛出异常。
    + `DiscardOldestPolicy`：丢弃队列最前面的任务，然后重新尝试执行任务。
    + `CallerRunsPolicy`：直接调用`run`方法并且阻塞执行。
    + 以上策略都不能满足需求，也可以通过`RejectedExecutionHandler`接口来定制处理策略。如记录日志或持久化不能处理的任务。

## Execute方法

默认情况下，创建线程池之后，线程池中是没有线程的，需要提交任务之后才会创建线程。

提交任务可以使用`execute`方法，它是`ThreadPoolExecutor`的核心方法，通过这个方法可以向线程池提交一个任务，交由线程池去执行。

`execute`方法工作流程如下：

1. 如果`workerCount < corePoolSize`，则创建并启动一个线程来执行新提交的任务；
2. 如果`workerCount >= corePoolSize`，且线程池内的阻塞队列未满，则将任务添加到该阻塞队列中；
3. 如果`workerCount >= corePoolSize && workerCount < maximumPoolSize`，且线程池内的阻塞队列已满，则创建并启动一个线程来执行新提交的任务；
4. 如果`workerCount >= maximumPoolSize`，并且线程池内的阻塞队列已满，则根据拒绝策略来处理该任务，默认的处理方式是直接抛异常。

<img src="Java编程自学之路20-线程池/image-20210722010120451.png" alt="execute工作流程" style="zoom:80%;" />

## 其他方法

在`ThreadPoolExecutor`类中还有一些重要的方法：

+ `submit`：类似`execute`，但是针对的是有返回值的线程。
+ `shutdown`：不会立即终止线程池，而是要等所有任务缓存队列中的任务都执行完成后才终止，但再也不接受新任务。
  + 将线程池切换到`SHUTDOWN`状态。
  + 调用`interruptIdleWorkers`方法请求中断所有空闲的`worker`。
  + 取出阻塞对垒中没有被执行的任务并返回。
+ `isShutdown`：调用`shutdown`或`shutdownNow`方法后，`isShutdown`方法就会返回`true`。
+ `isTerminaed`：当所有的任务都已关闭后，才表示线程池关闭成功，这时调用`isTerminaed`方法会返回`true`。
+ `setCorePoolSize`：设置核心线程数大小。
+ `setMaximumPoolSize`：设置最大线程数大小。
+ `getTaskCount`：线程池已经执行的和未执行的任务总数。
+ `getCompletedTaskCount`：线程池已完成的任务数量，该值小于等于`taskCount`。
+ `getLargestPoolSize`：线程池曾经创建过的最大线程数量。通过这个数据可以知道线程池是否满过，也就是达到了`maximumPoolSize`。
+ `getPoolSize`：线程池当前的线程数量。
+ `getActiveCount`：当前线程池中正在执行任务的线程数量。

# Executors

JDK的`Executors`类中提供了集中具有代表性的线程池，这些线程池都是基于`ThreadPoolExecutor`的定制化实现。

在实际使用线程池的场景中，我们一般使用JDK中提供的具有代表性的线程池实例。

## newSingleThreadExecutor

创建一个单线程的线程池。

只会创建唯一的工作线程来执行任务，保证所有任务按照指定顺序（FIFO、FILO、优先级）执行。如果这个唯一的线程因为异常结束，那么会有一个新的线程来替代它。

单线程最大的特点是：可保证顺序地执行各个任务。

## newFixedThreadPool

创建一个固定大小的线程池。

每次提交一个任务就会新创建一个工作线程，如果工作线程数量达到下次呢恒驰最大线程数，则将提交的任务存储到阻塞队列中。

`FixedThreadPool`是一个典型且优秀的线程池，它具有线程池提高程序效率和节省创建线程时所耗的开销的有点。但是，在线程池空闲时，即线程池中没有可运行任务时，它不会释放工作线程，还会占用一定的系统资源。

## newCachedThreadPool

创建一个可缓存的线程池。

+ 如果线程池大小超过处理任务所需要的线程数，就会回收部分空闲线程。
+ 如果长时间没有往线程池中提交任务，则工作线程自动终止。终止后，如果再提交新的任务，则线程池重新创建一个工作线程。
+ 此线程池不会对大小做限制，线程池大小完全依赖操作系统（或者说JVM）能够创建的最大线程大小。因此，使用`CachedThreadPool`时，一定要注意控制任务的数量，否则容易导致系统瘫痪。

## newScheduleThreadPool

创建一个大小无线的线程池，此线程池支持定时以及周期性执行任务的需求。

## newWorkStealingPool

JDK8新引入。

其内部会构建`ForkJoinPool`，利用`Work-Stealing`算法，并行地处理任务，不保证处理顺序。

# 线程池最佳实践

## 计算线程数量

一般多线程执行的任务类型可以分为CPU密集型和IO密集型，根据不同的任务类型，我们计算线程数的方法也不一样。

+ CPU密集型任务：这种任务消耗的主要是CPU资源，可以将线程数设置为N（CPU核心数） + 1，比CPU核心数多出来的一个线程是为了防止线程偶发的缺页中断，或者其他原因导致的任务暂停而带来的影响。一旦任务暂定，CPU就会处于空闲状态，而在这种情况下多出来的一个线程就可以充分利用CPU的空闲时间。
+ IO密集型任务：这种任务运行起来，系统会用大部分的时间来处理IO交互，而线程在处理IO的时间段内不会占用CPU来处理，这时就可以将CPU交出来给其它线程使用。因此在IO密集型任务的应用中，我们可以多配置一些线程，具体计算方法为 2N，

## 使用有界阻塞队列

不建议使用`Executors`的重要原因是：`Executors`提供的很多方法默认使用的都是无界的`LinkedBlockingQueue`，高负载情境下，无界队列很容易导致OOM，而OOM会导致所有请求都无法处理，这是致命问题。所以强烈建议使用有界队列。

## 重要任务应该自定义拒绝策略

使用有界队列，当任务过多时，线程池会出发执行拒绝策略，线程池默认的拒绝策略会`throw RejectedExecutionException`这个运行时异常，对于运行时异常编译器不强制`catch`它，所以开发人员很容易忽略。因此默认拒绝策略要慎重使用。如果线程池处理的任务非常重要，建议自定义自己的拒绝策略。并且在实际工作中，自定义的拒绝策略往往和降级策略配合使用。


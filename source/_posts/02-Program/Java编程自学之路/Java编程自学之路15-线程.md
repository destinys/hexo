---
title: Java编程自学之路：线程
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# 线程简介

## 什么是进程

简言之，进程可视为一个正在运行的程序。它是系统运行程序的基本单位，因此进程是动态的。进程是具有一定独立功能的程序关于某个数据集合上的一次运行活动。进程是操作系统进行资源分配的基本单位。

## 什么是线程

线程是操作系统进行调度的基本单位。线程也叫轻量级进程，在一个进程里可以创建多个线程，这些线程都拥有各自的计数器、堆栈和局部变量等属性，并且能够访问共享的内存变量。

# 创建线程

创建线程有以下三种方式：

+ 继承`Thread`类
+ 实现`Runnable`接口
+ 实现`Callable`接口

## Thread

通过继承`Thread`类创建线程的步骤：

1. 定义`Thread`类的子类，并覆写该类的`run`方法。`run`方法的方法体就代表了线程要完成的任务，因此把`run`方法称为执行体。
2. 创建`Thread`子类的实例，即创建了线程对象。
3. 调用线程对象的`start`方法来启动该线程。

```java
public class ThreadDemo01 {
  
  static class MyThread extends Thread {
    private int num = 3;
    MyThread(String name) {
      super(name);
    }
    
   @Override
    public void run() {
      while (num > 0) {
        System.out.println("Print " + num +" time");
        num--;
      }
    }
  }
  
  public static void main(String[] args) {
    MyThread t1 = new MyThread("Thread A");
    MyThread t2 = new MyThread("Thread B");
    t1.start();
    t2.start();
  }
}
```

## Runnable

实现`Runnable`接口优于继承`Thread`类，因为：

1. Java不支持多重继承，所有的类都只允许继承一个父类，可以实现多个接口。如果继承了`Thread`类就无法继承其他类，这不利于扩展。
2. 类可能只要求可执行就行，继承整个`Thread`类开销过大。

通过实现`Runnable`接口创建线程步骤：

1. 定义`Runnable`接口的实现类，并覆写该接口的`run`方法。该`run`方法的方法体同样是该线程的线程执行体。
2. 创建`Runnable`实现类的实例，并以此实例作为`Thread`的`target`来创建`Thread`对象，该`Thread`对象才是真正的线程对象。
3. 调用线程对象的`start`方法来启动该线程。

```java
public class RunnableDemo01 {
  public static void main(String[] args) {
    MyThread t1 = new MyThread("Thread A");
    MyThread t2 = new MyThread("Thread B");
    
    t1.start();
    t2.start();
  }
  
  static class MyThread implements Runnable {
    private int num = 3;
    
    @Override 
    public void run() {
      System.out.println("Print " + num + " times!");
      num--;
    }
  }
}
```

## Callable、Future、FutureTask

继承`Thread`类和实现`Runnable`接口这两种创建线程的方式都是没有返回值的。所以，线程执行结束后，无法看到执行结果。

为了解决这个问题，JDK5后，提供了`Callable`接口和`Future`接口，通过它们，可以在线程执行结束后，返回执行结果。

### Callable

`Callable`接口只声明了一个方法，这个方法叫做`call()`。`Callable`接口一般配合`ExecutorService`类来完成调用。

### Future

`Future`就是对于具体的`Callable`任务的执行结果进行取消、查询是否完成、获取结果。必要时可以通过`get`方法获取执行结果，该方法会阻塞直到任务返回结果。

### FutureTask

`FutureTask`类实现了`RunnableFuture`接口，`RunnableFuture`继承了`Runnable`接口和`Future`接口。

所以，`FutureTask`既可以作为`Runnable`被线程执行，又可以作为`Future`得到`Callable`的返回值。事实上，`FutureTask`是`Future`接口的一个唯一实现类。

### 代码示例

通过`Callable`接口创建线程的步骤：

1. 创建`Callable`接口的实现类，并实现`call`方法。该`call`方法将作为线程执行体，并且有返回值。
2. 创建`Callable`实现类的实例，使用`FutureTask`类来包装`Callable`对象，该`FutureTask`对象封装了该`Callable`对象的`call`方法的返回值。
3. 使用`FutureTask`对象作为`Thread`对象的`target`创建并启动新线程。
4. 调用`FutureTask`对象的`get`方法来获得线程执行结束后的返回值。

```java
public class CallableDemo01 {
  publci static void main(String[] args) {
    Callable<Long> call01 = new MyThread();
    FutureTask<Long> ft = new FutureTask<>(call01);
    
    new Thread(ft, "Callable Thread").start();
    
    try{
      System.out.println("Task cost : " + ft.get()/1000000 + " ms !");
    } catch (InterruptedException | ExecutionException e ) {
      e.printStackTrace();
    }
  }
  
  static class MyThread implements Callable<Long> {
    private int num = 3;
    
    @Override
    public Long call() {
      long begin = System.nanoTime();
      while(num > 0) {
        System.out.println(Thread.currentThread().getName() + " print " + num + " times! ");
        num--;
      }
      
      long end = System.nanoTime();
      return (end - begin);
    }
  }
}
```

# 线程基本使用

线程（`Thread`）常用方法：

| 方法名          | 说明                                                         |
| --------------- | ------------------------------------------------------------ |
| run()           | 线程的执行实体                                               |
| start()         | 线程的启动方法                                               |
| currentThread() | 返回对当前正在执行的线程对象的引用                           |
| setName()       | 设置线程名称                                                 |
| getName()       | 获取线程名称                                                 |
| setPriority()   | 设置线程优先级，范围为[1,10]；默认为5                        |
| getPriority()   | 获取线程优先级                                               |
| setDaemon()     | 设置线程为守护线程                                           |
| isDaemon()      | 判断线程是否为守护线程                                       |
| isAlive()       | 判断线程是否启动                                             |
| interrupt()     | 终端一个线程的运行状态                                       |
| interrupted()   | 测试当前线程是否已被中断。该方法也可以清楚线程的中断状态     |
| join()          | 可以使一个线程强制运行，线程强制运行期间，其他线程无法运行，必须等待此线程运行完成之后才可以继续执行 |
| Thread.sleep()  | 静态方法，将当前正在执行的线程休眠                           |
| Thread.yield(0) | 静态方法，将正在执行的线程暂停，让其他线程执行               |

## 线程休眠

使用`Thread.sleep`方法可以使当前正在执行的线程进入休眠状态。该方法接收一个整数值，单位为毫秒。

## 线程礼让

`Thread.yield`方法的调用声明了当前线程已经完成了生命周期中最重要的部分，可以切换给其他线程来执行。该方法是针对线程调度器的一个建议，而且也只有建议具有相同优先级的其他线程可以运行。

## 线程终止

安全地终止线程有两种方法：

+ 定义`volatile`标志位，在`run`方法中使用标志位控制线程终止。
+ 使用`interrupt`方法和`Thread.interrupted`方法配合使用来控制线程终止。

## 守护线程

**什么是守护线程？**

+ 守护线程是在后台执行并且不会组织JVM终止的线程。当所有非守护线程结束时，程序也就终止，同时会杀死所有守护线程。
+ 与守护线程对应的，叫做用户线程，也就是非守护线程。

**为什么需要守护线程？**

守护线程的优先级比较低，用于为系统中的其它对象和线程提供服务。典型的应用就是垃圾回收器。

**如何使用守护线程？**

+ 使用`isDaemon`方法判断线程是否为守护线程。
+ 可以使用`setDaemon`方法设置线程为守护线程。
  + 正在运行的用户线程无法设置为守护线程，所以`setDaemon`必须在`thread.start`方法之前设置，否则会抛出`illegalThreadStateException`异常。
  + 一个守护线程创建的子线程依然是守护线程。

# 线程通信

当多个线程可以一起工作去解决某个问题时，如果某些部分必须在其它部分之前完成，那么就需要对线程进行协调。

## wait/notify/notifyAll

+ `wait`：自动释放当前线程占有的对象锁，并请求操作系统挂起当前线程，让线程从`Running`状态转入`Waiting`状态，等待`notify/notifyAll`来唤醒。如果没有释放锁，那么其它线程就无法进入对象的同步方法或者同步控制块中，那么就无法执行`notify`或`notifyAll`来环形挂起的线程，造成死锁。
+ `notify`：唤醒一个正在`Waiting`状态的线程，并让它拿到对象锁，具体环形哪一个线程由JVM控制。
+ `notifyAll`：唤醒所有正在`Waiting`状态的线程，唤醒的线程可能会产生锁竞争。

> 基本知识点：
>
> 1. 每一个Java对象都有一个与之对应的监视器（`Monitor`）
> 2. 每一个监视器里面都有一个**对象锁**、一个**等待队列**、一个**同步队列**
> 3. `wait`、`notify`、`notifyAll`属于`Obejct`类中的方法；
> 4. `wait`、`notify`、`notifyAll`只能用在`synchronized`方法或者`synchronized`代码块中，否则会抛出`IllegalMonitorStateException`

生产者、消费者模型示例：

```java
import java.util.PriorityQueue;

/**
 * @Author : Semon
 * @Date : Created in 2021/7/16 10:36
 * @ Description: Thread demo
 * @ Modified by :
 * @ Version: v1.0
 **/
public class ProducerAndConsumerDemo {
    private static final int QUEUE_SIZE = 10;
    private static final PriorityQueue<Integer> queue = new PriorityQueue<>(QUEUE_SIZE);

    public static void main(String[] args) {
        new Producer("Producer_A").start();
        new Producer("Producer_B").start();
        new Consumer("Consumenr_A").start();
        new Consumer("Consumer_B").start();
    }


    static class Consumer extends Thread {
        Consumer(String name) {
            super(name);
        }

        @Override
        public void run() {
            while (true) {
                synchronized (queue) {
                    while (queue.size() == 0) {
                        try{
                            System.out.println("Queue is empty,wait for data");
                            queue.wait();
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                            queue.notifyAll();
                        }
                    }
                    queue.poll();  //move head element
                    queue.notifyAll();


                try {
                    Thread.sleep(500);
                } catch (InterruptedException e ) {
                    e.printStackTrace();
                }
                System.out.println(Thread.currentThread().getName() + "get an element from queue, the queue has " + queue.size() + " element currently.");
                }
            }
        }
    }

    static class Producer extends Thread {
        Producer(String name) {
            super(name);
        }

        @Override
        public void run() {
            synchronized (queue) {
                while (queue.size() == QUEUE_SIZE ) {
                    try {
                        System.out.println("the queue capacity is full, pls wait a minute");
                        queue.wait();
                    } catch (InterruptedException e ) {
                        e.printStackTrace();
                        queue.notifyAll();
                    }
                }

                queue.offer(1);
                queue.notifyAll();
                try {
                    Thread.sleep(500);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println(Thread.currentThread().getName() + "insert an element to the queue. current " +
                        "capacity is " + queue.size());
            }
        }
    }
}

```

## join

在线程操作中，可以使用`join`方法让一个线程强制运行，线程强制运行期间，其他线程无法运行，必须等待此线程完成之后才尅继续执行。

```java
public class ThreadJoinDemo {
  public static void main(String[] args) {
    MyThread mt = new MyThread();
    Thread t = new Thread(mt,"mythread");
    t.start();
    for(int i=0; i <20; i++) {
      if (i>10) {
        try{
          t.join();
        } catch (InterruptedException e) {
          e.printStackTrace();
        }
      }
      System.out.println("Main Thread run ---" + i);  
    }
  }
  
  static class MyThread implements Runnable {
    @Override 
    public void run() {
      for (int i=0; i< 20; i++) {
        System.out.println(Thread.currentThread.getName() + " run, i = " + i " times.")
      }
    }
  }
}
```

## 管道

管道输入/输出流与普通的文件输入/输出流或者网络输入/输出流不同之处在于，它主要用于线程间的数据传输，传输媒介为内存。管道输入/输出流主要包括如下4种具体实现：

+ `PipedOutputStream`
+ `PipedInputStream`
+ `PipedReader`
+ `PipedWriter`

```java
public class PipedDemo {
  public static void main(String[] args) throws Exception {
    PipedWriter out = new PipedWriter();
    PipedReader in = new PipedReader();
    out.connect(in);
    
    Thread printThread = new Thread(new Print(in), "PrintThread");
    printThread.start();
    int receive = 0;
    
    try{
      while ( (receive = System.in.read()) ! = -1 ) {
        out.write(receive);
      }
    } finally {
      out.close();
    }
  }
  
  static class Print implements Runnable {
    private PipedReader in ;
    Print(PipedReader in ) {
      this.in = in;
    }
    
    public void run() {
      int receive = 0;
      try {
        while ((receive = in.read()) != -1 ) {
          System.out.print( (char) receive);
        } 
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
  }
}
```

# 线程生命周期

<img src="Java编程自学之路15-线程/image-20210716141154264.png" alt="线程状态机转换" style="zoom:100%;" />

`java.lang.Thread.State`中定义了6种不同的线程状态，在给定的某一时刻，线程必定处于其中某一个状态。

以下为各状态说明：

+ `New`：新建，尚未调用`start`方法的线程处于此状态。该状态意味着，创建的线程尚未启动。
+ `Runnable`：就绪，已经调用了`start`方法的线程处于此状态。该状态意味着，线程已经在JVM中运行，但在操作系统层面，它可能处于运行状态，也可能处于等待资源调度。
+ `Blocked`：阻塞，线程处于被阻塞状态。此状态意味着，线程在等待`synchronized`的隐式锁（`Monitor lock`）。
+ `Waiting`：等待。此状态意味着，线程无限期等待，知道被其他线程显式的唤醒。阻塞与等待的区别在于，阻塞是被动的，获取到`synchronized`隐式锁即可转换为就绪状态；而等待是主动的，通过调用`Object.wait`等方法进入，只能等待其他线程进行唤醒。
+ `Timed waiting`：定时等待。此状态意味着，无需等待其它线程显式唤醒，在一定时间之后会被系统自动唤醒。
+ `Terminated`：终止，线程执行完`run`方法，或因异常退出了`run`方法。此状态意味着，线程结束了生命周期。

# 线程常见问题

## yield方法

+ `yield`方法会让线程从`Running`状态转入`Runnable`状态。
+ 调用了`yield`方法后，只有与当前线程相同或更高优先级的`Runnable`状态线程才会获得执行机会。

## sleep方法

+ `sleep`方法会让线程从`Running`状态转入`waiting`状态。
+ `sleep`方法需要指定等待时间，超过等待时间后，JVM会自动将线程从`waiting`状态转入`Runnable`状态。
+ 调用了`sleep`方法后，任何线程都可能得到执行机会。
+ `sleep`方法不会释放“锁标记”，即如果存在`synchronized`同步代码块，其他线程仍然无法访问共享数据。

## join方法

+ `join`方法会让线程从`Running`状态转入`Waiting`状态。
+ 当调用了`join`方法后，当前线程必须等待调用`join`方法的线程结束后才能继续执行。

## 线程优先级

在Java中，即便对线程设置了优先级，也无法保证高优先级的线程一定比低优先级的线程先执行。

线程优先级依赖于操作系统的支持，然而，不同的操作系统支持的线程优先级并不相同，不能很好的与Java中的线程优先级一一对应。




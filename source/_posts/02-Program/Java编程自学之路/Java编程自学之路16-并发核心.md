---
title: Java编程自学之路：并发核心
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# J.U.C简介

Java的`java.util.concurrent`包（简称`J.U.C`）提供了大量并发工具类，是Java并发能力的主要体现。从功能上，大致可以分为：

+ 原子类：`AtomicInteger`、`AtomicIntegerArray`、`AtomicReference`、`AtomicStampedReference`等
+ 锁：`ReentrantLock`、`ReentrantReadWriteLock`等
+ 并发容器：`ConcurrentHashMap`、`CopyOnWriteArrayList`、`CopyOnWriteArraySet`等
+ 阻塞队列：`ArrayBlockingQueue`、`LinkedBlockingQueue`等
+ 非阻塞队列：`ConcurrentLinkedQueue`、`LinkedTransferQueue`等
+ `Executor`框架：`ThreadPoolExecutor`、`Executors`等

`J.U.C`包中的工具类是基于`synchronized`、`volatile`、`CAS`、`ThreadLocal`这样的并发核心机制打造的。

## synchronized

`synchronized`是Java的关键字，是利用锁的机制来实现互斥同步。

`synchronized`可以保证同一时刻，只有一个线程可以执行某个方法或代码块。

`synchronized`是JVM的内置特性，所有版本JDK均提供支持。

### 应用

+ 同步实例方法：对于普通同步方法，锁为当前实例对象；
+ 同步静态方法：对于静态同步方法，锁为当前类的`Class`对象；
+ 同步代码块：对于同步代码块，锁是`synchronized`后小括号中显式指定的对象；

```java
class Account {
  private int balance;
  private static int seq = 0;
  
  //同步实例方法，本例因为涉及多个Account对象，所以需要使用对象公用锁
  void transfer(Account target, int amt) {
    synchronized(Account.class) {
      if (this.balance > amt) {
        this.balance -= amt;
    		target.balance += amt;
      }
    }
  }
  
  //同步静态方法，不需要指明锁，默认为当前类的Class对象
  public synchronized static void increase() {
    seq++;
  }
  
  //同步代码块，需要显式执行同步锁，该锁对象可以是对象实例或Class实例
  public void increase2() {
    synchronized (Account.class) {
      seq++;
    }
  }
}
```

### 原理

`synchronized`代码块是由一对`monitorenter`和`monitorexit`指令实现的，`Monitor`对象是同步的基本实现单元。在JDK6之前，`Monitor`的实现完全依靠操作系统内部的互斥锁，因为需要进行用户态到内核态的切换，所以同步操作是一个无差别的重量级操作。

`synchronized`明确指定了对象参数，则锁为该对象的引用；如果没有明确指定，则根据`synchronized`修饰的方法类型来判断，静态方法锁为该类的`Class`对象；实例方法锁为该对象实例。

`synchronized`同步块对同一线程来说是可重入的，不会导致锁死问题。

`synchronized`同步块是互斥的，即已进入同步代码块的线程执行完成前，会阻塞其他视图进入的线程。

**同步代码块**

`synchronized`在修饰同步代码块时，是由`monitorenter`和`monitorexit`指令来实现的。进入`monitorenter`指令后，线程将持有`Monitor`对象，退出`monitorenter`指令后，线程释放`Monitor`对象。

**同步方法**

`synchronized`修饰同步方法时，会设置一个`ACC_SYNCHRONIZED`标志。当方法调用时，调用指令将会检查该方法是否被设置`ACC_SYNCHRONIZED`访问标志；如果设置了该标志，执行线程将先持有`Monitor`对象，然后在执行方法。在该方法运行期间，其他线程将无法获取到`Monitor`对象，当方法执行完成后，再释放`Monitor`对象。

**Monitor**

每个对象实例都会有一个`Monitor`，`Monitor`可以和对象一起创建、销毁。`Monitor`是由`ObjectMonitor`实现，而`ObjectMonitor`是由C++的`ObjectMonitor.hpp`文件实现。

当多个线程同时访问一段同步代码时，多个线程会先被存放在`EntryList`集合中，处于`block`状态的线程，都会被加入该列表。接下来当线程获取到对象的`Monitor`时，`Monitor`是依靠底层操作系统的`Mutex Lock`来实现互斥的，线程申请`Mutex`成功，则持有该`Mutex`，其他线程将无法获取到该`Mutex`。如果线程调用`wait()`方法，就会释放当前持有的`Mutex`，并且该线程会进入`WaitSet`集合中，等待下一次被唤醒。如果当前线程顺利执行完毕，也将释放`Mutex`。

### 优化

> JDK6以，`synchronized`做了大量的优化，其性能已经与`Lock`，`ReadWriteLock`基本持平。

**Java对象头**

在JDK6的JVM中，对象实例在堆内存中被分为了三个部分：对象头、实例数据和对齐填充。其中Java对象头由`Mark Word`、指向类的指针以及数组长度三部分组成。

`Mark Word`记录了对象和锁有关的信息。`Mark Word`在64位JVM中的长度是64bit，64位JVM的存储结构如下：

<img src="./Java编程自学之路16-并发核心/image-20210719115231932.png" alt="Java对象头结构" style="zoom:80%;" />

锁升级功能主要依赖于`Mark Word`中的锁标志位和是否偏向锁标志位，`synchronized`同步锁就是从偏向锁开始的，锁着竞争越来越激烈，偏向锁升级到轻量级锁，最终升级到重量级锁。

JDK6引入了偏向锁和轻量级锁，从而让`synchronized`拥有的四个状态：

+ 无锁状态(unlocked)
+ 偏向锁状态(biasble)
+ 轻量级锁状态(lightweight locked)
+ 重量级锁状态(inflated)

当JVM检测到不同的竞争状况时，会自动切换到适合的锁实现。

当没有竞争出现时，默认使用偏向锁。JVM利用CAS操作(compare and swap)，在对象头上的`Mark Word`部分设置线程ID，以表示这个对象偏向于当前线程，随意并不涉及真正的互斥锁。这样做的假设是基于在很多应用场景中，大部分对象生命周期中最多会被一个线程锁定，使用偏向锁可以降低无竞争开销。

如果有另外的线程视图锁定有个已经被偏向过的对象，JVM就需要撤销偏向锁，并切换到轻量级锁实现。轻量级锁依赖CAS操作`Mark Word`来试图获取锁，如果重试成功，就使用普通的轻量级锁；否则，进一步升级为重量级锁。

**偏向锁**

偏向锁的思想是偏向于第一个获取锁对象的线程，这个线程在之后获取该锁就不在需要进行同步操作，甚至连CAS操作也不再需要。

**轻量级锁**

轻量级锁是相对于传统的重量级锁而言，它使用CAS操作来避免重量级锁使用互斥量的开销。对于绝大部分的锁，在整个同步周期内都是不存在竞争的，因此也就不需要使用互斥量进行同步，可以先采用CAS操作进行同步，如果CAS失败了再改用互斥量进行同步。

当尝试获取一个锁对象时，如果锁对象标记为`0|01`，说明锁对象的锁为未锁定状态(unlocked)；此时虚拟机在 当前线程的虚拟机栈中创建`Lock Record`，然后使用CAS操作将对象的`Mark Word`更新为`Lock Redord`指针；如果CAS操作成功了，那么线程就获取了该对象上的锁，并且对象的`Mark Word`的锁标记变更为`00`，表示该对象处于轻量级锁状态。

**锁消除|锁粗化**

出了锁升级优化，Java还使用了编译器对锁进行优化。

+ 锁消除

  锁消除是指对于被检测出不可能存在竞争的共享数据的锁进行消除。

  JIT编译器在动态编译同步块的时候，借助了一种被称为逃逸分析的技术，来判断同步块使用的锁对象是否只能够被一个线程访问，而没有被发布到其他线程。确认结果为肯定，则JIT编译器在编译这个同步块的时候就不会生成`synchronized`锁表示的锁的申请与释放机器码，即消除了锁的使用。在JDK7之后的版本，该操作自动实现。

+ 锁粗化

  锁粗化与锁消除类似，就是在JIT编译器动态编译时，如果发现几个相邻的同步块使用的是同一个锁实例，那么JIT编译器会把几个同步块合并为一个大的同步块，从而避免一个线程频繁申请/释放锁带来性能开销。

  如果一系列的连续操作都对同一个对象反复加锁与解锁，频繁的加锁操作会导致额外的性能损耗。

**自旋锁**

互斥同步进入阻塞状态的开销都很大，因尽量避免。在许多应用中，共享数据的锁定状态只会持续很短的一段时间。自旋锁的思想是让一个线程在请求一个共享数据的锁时执行忙循环（自旋）一段时间，如果这段时间内能获取到锁，则可以避免进入阻塞状态。

自旋锁虽然能避免进行阻塞状态从而减少开销，但他需要进行忙循环操作占用CPU时间，它只适用于共享数据的锁定状态很短的场景。

JDK6引入了自适应的自旋锁，自适应意味着自旋的次数不在固定，而是由前一次在同一个锁上的自旋次数及锁的拥有者的状态来决定。

## volatile

`volatile`是轻量级的`synchronized`，它在多处理器开发中保证了共享变量的“可见性”。

被`volatile`修饰的变量，具备以下特性：

+ 线程可见性：保证了不同线程对这个变量进行操作时的可见性，即一个修改了某个共享变量，另外一个线程能读取到这个修改的值
+ 禁止指令重编排
+ 不保证原子性

线程安全需要具备：可见性、原子性、顺序性。`volatile`不保证原子性，所以决定了它不能彻底地保证线程安全。

### 应用

如果`volatile`变量修饰符使用恰当的话，它比`synchronized`的使用和执行成本要低，因为它不会引起线程上下文切换和调度。但是`volatile`无法替代`synchronized`，因为`volatile`无法保证操作的原子性。

通常来说，`volatile`必须具备以下两个条件：

+ 对变量的写操作不依赖于当前值
+ 该变量没有包含在具有其他变量的表达式中

### 原理

使用`volatile`关键字时，编译后的代码会多出一个`lock`前缀指令。`lock`前缀指令实际上相当于一个内存屏障，内存屏障会提供3个功能：

+ 确保指令重排序时不会将其后指令排到内存屏障之前，也不会将前面的指令排到内存屏障的后面；即在执行到内存屏障这句指令时，在它前面的操作已经全部完成；
+ 强制将对缓存的修改操作立即写入主存；
+ 写操作会导致其他CPU中对应的缓存行无效；

## CAS

互斥同步是最常见的并发正确性保障手段。

互斥同步最主要的问题是线程阻塞和唤醒所带来的性能问题，因此互斥同步也内称为阻塞同步。互斥同步属于一种悲观并发策略，总是认为只要不做正确的同步措施，就肯定会出问题。无论共享数据是否真的会出现竞争，它都要进行加锁、用户态核心态切换、维护锁计数器和检查是否有被阻塞的线程需要唤醒等操作。

随着硬件指令集发展，我们可以使用基于冲突检测的乐观并发策略：先进行操作，如果没有其他线程争用共享数据，则操作成功；否则采用补偿措施)(不断重试，直至成功为止)。乐观并发策略的许多实现都不需要将线程阻塞，因此这种同步操作称之为非阻塞同步。

为什么乐观并发策略需要硬件指令集发展才能进行？因为乐观并发策略需要操作和冲突检测这两个步骤具备原子性，而这点需要由硬件来完成，而硬件支持的原子性操作最典型的按理为：CAS.

CAS—`compare and swap`，字面意思为比较并交换。CAS有3个操作数，分别为内存值M，期望值E以及更新值U。当且仅当内存值M与期望值E相同时，将内存值M修改为U，否则什么都不做。

### 应用

CAS适用于线程冲突较少的情况。

CAS典型应用场景：

+ 原子类
+ 自旋锁

### 原理

Java主要利用`Unsafe`这个类提供的CAS操作。`Unsafe`的CAS依赖的是JVM针对不同的操作系统实现的硬件指令`Atomic::cmpxchg`。`Atomic::cmpxchg`的实现使用了汇编的CAS操作，并使用CPU提供的`lock`信号保证其原子性。

### 缺陷

任何事务都是有利有弊，CAS也存在以下问题：

+ ABA问题
+ 循环时间长开销大
+ 只能保证一个共享变量原子性

#### ABA问题

如果一个变量初次读取的时候值为A，当该值变更为B后再次更新为A，那么CAS操作会误认为它从来没有发生过改变。

J.U.C包提供了一个带有标记的原子类引用`AtomicStampedReference`来解决这个问题，他可以通过控制变量值的版本来保证CAS的正确性。大部分情况下ABA问题不会影响程序并发的正确性，如果需要解决ABA问题，则改用传统的互斥同步可能会比原子类更高效。

#### 循环时间长开销大

自旋CAS如果长时间不成功，会给CPU带来非常大的执行开销。

如果JVM能支持处理器提供的`pause`指令那么效率会有一定的提成，`pause`指令有两个作用：

+ 延迟流水线执行指令(de-pipeline)。使CPU不会消耗过多的执行资源，延迟的时间取决于具体实现的版本，在一些处理器上延迟时间是零。
+ 避免在退出循环的时候因内存顺序冲突(memory order violation)而引起CPU流水线被清空(CPU pipeline flush),从而提高CPU的执行效率。

#### 只能保证一个共享变量原子性

当一个共享变量执行操作时，我们可以使用循环CAS的方式来保证原子操作，但是对多个共享变量操作时，循环CAS就无法保证操作的原子性，这个时候就可以用锁。

或者通过取巧的办法，将多个共享变量合并成一个共享变量来操作。从JDK5开始提供了`AtomicReference`类来保证引用对象之间的原子性，你可以把多个变量放在一个对象里来进行CAS操作。

## ThreadLocal

`ThreadLocal`是一个存储线程本地副本的工具类。

要保证线程安全，不一定非要进行同步。同步只是保证共享数据争用时的正确性，如果一个方法本来就不涉及共享数据，那么自然无须同步。

> Java中的无同步方案有：
>
> + 可重入代码：也叫纯代码。如果一个方法，它的返回结果是可以预测的，即只要输入了相同的数据，就会返回相同的结果，那么就满足可重入性，当然也是线程安全的。
> + 线程本地存储：使用`ThreadLocal`为共享变量在每个线程中都创建了一个本地副本，这个副本只能被当前线程访问，其他线程无法访问，那么自然是线程安全的。

### 应用

`ThreadLocal`常用于防止对可变的单例变量或全局变量进行共享。典型应用场景有：管理数据库了解、Session。

```java
public  class ThreadLocal<T> {
  public T get() {}
  public void set(T value) {}
  public void remove() {}
  public static <S> ThreadLoacl<S> withInitial(Supplier<? extends S> supplier) {}
}
```

> + `get`：用于获取`ThreadLocal`在当前线程找那个保存的副本；
> + `set`：用于设置当前线程中变量的副本；
> + `remove`：用于删除当前线程中变量的副本。如果此线程局部变量随后被当前线程读取，则其值将通过调用其`initialValue`方法重新初始化，除非其值由中间线程中的当前线程设置。这可能会导致当前线程中多次调用`initialValue`方法；
> + `initialValue`：为`ThreadLocal`设置默认的`get`初始值，需要重写`initialValue`方法；

### 原理

**存储结构**

`Thread`类中维护着一个`ThreadLocal.ThreadLocalMap`类型的成员`threadLocals`。这个成员就是用来存储当前线程独占的变量副本。

`ThreadLocalMap`是`ThreadLocal`的内部类，它维护者一个`Entry`数组，`Entry`继承了`WeakReference`，所以是弱引用，`Entry`用于保存键值对，其中：

+ `key`是`ThreadLocal`对象；
+ `value`是传递进来的对象（变量副本）；

**如何解决`Hash`冲突**

`ThreadLocalMap`虽然是类似`Map`结构的数据结构，但它并没有实现`Map`接口。它不支持`Map`接口中的`next`方法，这意味着`ThreadLocalMap`中解决Hash冲突的方式并非拉链表方式。

实际上，`ThreadLocalMap`采用线性探测的方式来解决Hash冲突。所谓线程探测，就是根据初始`key`的`hashcode`值确定元素在`table`数组中的位置，如果发现这个位置上已经被其他的`key`值占用，则利用固定的算法寻找一定步长的下个位置，依次判断，直至找到能够存放的位置。

**内存泄露问题**

`ThreadLocalMap`的`Entry`继承了`WeakReference`，所以它的`key（ThreadLocal对象）`是弱引用，而`value`是强引用。

+ 如果`ThreadLocal`对象没有外部强引用来引用它，那么`ThreadLocal`对象会在下次GC时被回收。
+ 若`Entry`中的`key`已经被回收，但是`value`由于是强引用不会被垃圾回收器回收。如果创建`ThreadLocal`的线程一直持续运行，那么`value`一直得不到回收，产生内存泄露。

> 避免内存泄露的方式为：使用`ThreadLocal`的`set`方法后，显示的调用`remove`方法

### 场景

`ThreadLocal`适用于变量在线程间间隔，而在方法或类间共享的场景。

> 线程池会重用固定的几个线程，一旦线程重用，那么很可能首次从`ThreadLocal`中获取的值是之前其他用户请求遗留的值。这时候，`ThreadLocal`中的用户信息就是其他用户的信息。所以没有显示开启多线程也可能会存在线程安全问题。使用`ThreadLocal`工具来存放数据时，切记要显示地清空设置的数据。

## InheritableThreadLocal

`InheritableThreadLocal`类是`ThreadLocal`类的子类。

`ThreadLocal`中每个线程拥有它自己独占的数据。与`ThreadLocal`不同的是，`InheritableThreadLocal`允许一个线程以及该线程创建的所有子线程都可以访问它保存的数据。




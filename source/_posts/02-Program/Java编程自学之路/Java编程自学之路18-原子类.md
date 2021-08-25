---
title: Java编程自学之路：原子类
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# 原子变量类简介

## 为什么需要原子变量类

保证线程安全是Java并发变成必须要解决的重要问题。Java从原子性、可见性、有序性这三大特性入手，确保多线程的数据一致性。

+ 确保线程安全最常见的做法是利用锁机制来对共享数据做互斥同步，这样在同一个时刻，只有一个线程可以执行某个方法或者代码块，那么操作必然是原子性的，线程安全的。互斥同步最主要的问题是线程阻塞和唤醒所带来的性能问题。
+ `volatile`是轻量级锁，它保证了共享变量在多线程中的可见性，但无法保证原子性。所以，它只能在一些特定场景下使用。
+ 为了兼顾原子性以及锁带来的性能问题，Java引入了CAS来实现非阻塞同步（也叫乐观锁），并基于CAS，提供了一套原子工具类。

## 原子变量类的作用

原子变量类比锁的粒度更细，更轻量级，并且对于在多处理器系统上实现高性能的并发代码来说是非常关键的。原子变量将发生竞争的范围缩小到单个变量上。

原子变量类相当于一种繁华的`volatile`变量，能够支持原子的、有条件的读/改/写操作。

原子类在内部使用CAS指令来实现同步，这些指令通常比锁更快。

原子变量类可分为4组：

+ 基本类型
  + `AtomicBoolean`：布尔类型原子类
  + `AtomicInteger`：整形原子类
  + `AtomicLong`：长整形原子类
+ 引用类型
  + `AtomReference`：引用类型原子类
  + `AtomicMarkableReference`：带有标记位的引用类型原子类
  + `AtomicStampedReference`：带有版本号的引用类型原子类
+ 数组类型
  + `AtomicIntegerArray`：整形数组原子类
  + `AtomicLongArray`：长整形数组原子类
  + `AtomicReferenceArray`：引用类型数组原子类
+ 属性更新器类型
  + `AtomicIntegerFieldUpdater`：整形字段的原子更新器
  + `AtomicLongFieldUpdater`：长整形字段的原子更新器
  + `AtomicReferenceFieldUpdater`：引用类型字段的原子更新器

# 原子变量类使用

## 基本类型

这一类型的原子类是针对Java基本类型进行操作。基本类型的原子变量类都支持CAS技术，此外，`AtomicInteger`、`AtomicLong`还支持算术运算。

> 虽然Java只提供了`AtomicBoolean`、`AtomicInteger`、`AtomicLong`,但是可以模拟其它基本类型的原子变量。模式方式为将`short`或`byte`等类型与`int`类型进行转换或者使用`Float.floatToIntBits`、`Double.doubleToLongBits`来转换浮点数。

以`AtomicInteger`为例，常用方法为：

```java
public final int get();  //获取当前值
public final int getAndSet(int newValue); //获取当前值并设置新值
public final int getAndIncrement(); //获取当前值并自增
public final int getAndDecrement(); //获取当前值并自减
public final int getAndAdd(int delta); //获取当前值并加上预期值
boolean compareAndSet(int expect, int update); //如果update等于expect，将update设置为输入值
public final void lazySet(int newValue); //最终设置为newValue， 设置后其他线程在短时间内仍然只能获取到旧值
```

## 引用类型

引用类型对应Java引用数据类型的处理 ，并可以在一定程度上规避ABA问题。

```java
public class AtomicReferenceDemo01 {
  private static int ticket = 10;
  public static void main(String[] args) {
    threadSafeDemo();
  }
  
  private static void threadSafeDemo() {
    SpinLock lock = new SpinLock();
    ExecutorService es = Executors.newFixedThreadPool(3);
    
    for (int i=0; i<5; i++) {
      es.execute(new MyThread(lock));
    }
    
    es.shutdown();
  }
  
  
  static class SpinLock {
    private AtomicReference<Thread> af = new AtomicReference<>();
    
    public void lock() {
      Thread curr = Thread.currentThread();
      while (!af.compareAndSet(curr, null));
    }
  }
  
  static class MyThread implements Runnable {
    private SpinLock lock;
    
    public MyThread(SpinLock lock) {
      this.lock = lock;
    }
    
    @Override
    public void run() {
      while( ticket > 0) {
        lock.lock();
        if(ticket > 0) {
          System.out.println(Thread.currentThread().getName() + " sell out " + ticket + " tickets");
          ticket--;
        }
        lock.unlock();
      }
    }
  }
}
```

## 数组类型

数组类型的原子类为数组元素提供了`volatile`类型的访问语义。

> `volatile`类型的数组仅在数组上具备`volatile`语义，但针对数组中的元素不具备`volatile`语义。

```java
public class AtomicIntegerArrayDemo {
  private static AtomicIntegerArray atarr = new AtomicIntegerArray(10);
  
  public static void main(final String[] args) throws InterruptedException {
    System.out.println("Init Values: ");
    
    for (int i=0;i<atarr.length();i++) {
      atarr.set(i,i);
      System.out.println(atarr.get(i) + " ");
    }
    
    System.out.println();
    
    Thread t1 = new Thread(new Increment());
    Thread t2 = new Thread(new Compare());
    
    t1.start();
    t2.start();
    
    t1.join();
    t2.join();
    
    System.out.println("Final Values: ");
    
    for (int i=0;i<atarr.length();i++) {
      System.out.println(atarr.get(i));
    }
    System.out.println();
  }
  
  static class Increment implement Runnable {
    @Override 
    public void run() {
      for (int i=0; i<atarr.length();i++) {
        int value = atarr.incrementAndGet(i);
        System.out.println(Thread.currentThread().getName() + " , index= " + i + " value = " + value);
      }
    }
  }
  
  static class Compare implements Runnable {
    @Override
    public void run() {
      for (int i=0;i<atarr.length();i++) {
        boolean swapped = atarr.compareAndSet(i,2,3);
        if(swapped) {
          System.out.println(Thread.currentThread().getName() + " swapped, index = " + i + " , value = 3 ");
        }
      }
    }
  }
}
```

## 属性更新类型

更新器类支持基于反射机制的更新字段值的原子操作。使用时有一定的限制：

+ 属性更新类型原子类都是抽象类，每次使用必须使用静态方法`newUpdater`创建一个更新器，并且需要设置想要更新的类和属性。
+ 字段必须使用`volatile`修饰；
+ 不能作用于静态变量；
+ 不能作用于常量；

```java
public class AtomicReferenceFieldUpdaterDemo {

    static User user = new User("name");

    static AtomicReferenceFieldUpdater<User, String> updater = AtomicReferenceFieldUpdater.newUpdater(User.class,
            String.class,"name");

    public static void  main(String[] args) {
        ExecutorService es = Executors.newFixedThreadPool(3);
        for(int i=0;i<5;i++) {
            es.execute(new MyThread());
        }
        es.shutdown();
    }

    static class MyThread implements Runnable {
        @Override
        public void run() {
            if (updater.compareAndSet(user,"begin","end")) {
                try {
                    TimeUnit.SECONDS.sleep(1);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println(Thread.currentThread().getName() + " already modify name = " + user.getName());
            } else {
                System.out.println(Thread.currentThread().getName() + " had modified by other Thread.");
            }
        }
    }


    static class User {
        volatile String name;

        public User(String name) {
            this.name = name;
        }

        public String getName() {
            return name;
        }

        public User setName(String name) {
            this.name=name;
            return  this;
        }
    }
}

```

## 原子化的累加器

`DoubleAccumulator`、`DoubleAdder`、`LongAccumulator`、`LongAdder`四个类仅用来执行累加操作，相比原子化的数据类型，速度更快，但是不支持`compareAndSet()`方法。如果仅需要累加功能，使用原子化的累加器性能会更好，代价是消耗更多内存资源。


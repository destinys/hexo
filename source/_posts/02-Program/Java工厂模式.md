---
title: Java工厂模式浅析
categories: Program
tags: java
date: 2021-06-22
author: Semon
---

# Java工厂模式浅析

## 传统工厂类

传统工厂类最大的弊端：使用关键字`new`，导致每新增一个类都要修改工厂类；

```java
package org.demo
interface  IFruit {
  public void eat();
}

class Apple implements IFruit  {
  @override
  public void eat() {
    System.out.println("[Apple] 吃苹果");
  }
}

class Factory  {
  private Factory() {}
  public static IFruit getInstance(String className) {
    if ("apple".equals(className))  {
      return new Apple();
    }
    return null;
  }
}

public class TestDemo  {
  public static void main(String[] args) throws Exception  {
    IFruit fruit = Factory.getInstance("apple");
    fruit.eat();
  }
}
```

## 反射工厂类

通过反射对工厂模式进行改进，起最大特征在于可以方便动态进行子类的扩充操作，但存在性能问题；

```java
package org.demo
  
interface IFruit {
  public void eat();
}

class Apple implements IFruit  {
  @override
  public void eat() {
    System.out.println("[Apple] 吃苹果");
  }
}

class Cherry implements IFruit {
  @override
  public void eat() {
    System.out.println("[Cherry] 吃樱桃");
  }
}

class Factory {
  private Factory() {}
  
  public static IFruit getInstance(String className) {
    IFruit fruit = null;
    try {
      fruit = (IFruit) Class.forName(className).newInstance();
    } catch (Exception e) {
      e.printStackTrace();
    }
    return fruit;
  }
}

public class TestDemo1 {
  public static void main (String[] args) throws Exception {
    IFruit fruit1 = Factory.getInstance("org.demo.Apple");
    IFruit fruit2 = Factory.getInstance("org.demo.Cherry");
    fruit1.eat();
    fruit2.eat();
  }
}
```

## 泛型反射工厂类

通过泛型避免重复创建工厂类，使代码应用于实际开发；

```java
package org.demo
  
interface IFruit {
  public void eat() {}
}

interface IAnimal {
  public void howl() {}
}

class Apple implements IFruit {
  @override
  public void eat() {
    System.out.println("[Apple] 吃苹果");
  }
}

class Dog implements IAnimal {
  @override
  public void howl() {
    System.out.println("[Dog] 汪汪叫")
  }
}

class Factory {
  private Factory() {}
  
  public static <T> T getInstance(String className) {
    T t = null;
    try {
      t = (T) Class.forName(className).newInstance();
    } catch (Exception e) {
      e.printStackTrace();
    }
    return t;
  }
}

public class TestDemo2 {
  public static void main(String[] args) throws Exception {
    IFruit fruit = Factory.getInstance("org.demo.Apple");
    IAnimal animal = Factory.getInstance("org.demo.Dog");
    
    fruit.eat();
    animal.howl();
  }
}
```


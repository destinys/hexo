---
title: Java编程自学之路：枚举
categories: Program
tags: java
date: 2021-08-02
author: Semon
---

# 简介

`enum`的全称为`enumeration`，是JDK5引入的新特性；

在Java中，被`enum`关键字修饰的类型就是枚举类型，形式如下：

```java
enum ColorEm {RED,GREEN,BLUE}
```

+ 枚举好处：可以将常量组织起来，统一进行管理；
+ 应用场景：错误码、状态机；

# 枚举解析

## 枚举定义

`java.lang.Enum`类声明：

```java
public  abstract class Enum<E extends Enum<E>>  implements Comparable<E>,Serializable {
  
  private final String name;
  
  public final String name() { return name;}
  public final int ordinal() {...};
  public final boolean equals(Object other) { return this == other;};
  public final class<E> getDeclaringClass() {...};
  public final int compareTo() {...};
}
```



在`enum`中，提供了一些基本方法：

+ `name()`：返回实例名；
+ `ordinal()`：返回实例声明时的次序，从0开始；
+ `equals()`：判断是否为同一个对象；
+ `getDeclaringClass()`：返回实例所属的`enum`类型；
+ `compareTo()`：对象比较；

> `enum`支持通过`==`来进行实例比较；

## 枚举特性

枚举的本质是`java.lang.Enum`的子类，是一种受限制的类，并且不能别其他类继承；

定义的枚举值，默认会被`public static final`修饰，本质上是静态常量；

### 基本特性

如果枚举没有定义方法，也可以在最后一个实例后添加逗号、分号或什么都不加；

如果枚举中没有定义方法，枚举值默认为从0开始的数值；

### 枚举方法

枚举中可以添加普通方法、静态方法、抽象方法、构造方法；

枚举不支持使用`=`进行赋值，但可通过定义方法来实现对枚举赋值；

枚举如果定义方法，那么必须在枚举的最后一个实例添加分号作为结尾，否则编译器会报错；

# 枚举应用

## 组织常量

在JDK5之前，在Java中定义常量的方式为`public static final Type var`；有了枚举之后，可以将有关联关系的常量组织起来，使代码更加易读、安全，并且可以使用枚举提供的方法；

## switch状态机

Java经常使用`switch`来编写状态机，在JDK7之后，`switch`已经支持`int`、`char`、`String`及`enum`类型的参数。这几种类型参数比较起来，使用枚举的`switch`代码更具有可读性；

# 枚举工具类

Java提供了两个方便操作的工具类：`EnumSet`及`EnumMap`；

## EnumSet

`EnumSet`是枚举类型的高性能`Set`实现；它要求放入它的枚举常量必须属于同一枚举类型；

主要方法：

+ `noneOf`：创建一个具有指定元素类型的空`EnumSet`；

+ `allOf`：创建一个指定元素类型并包括所有枚举类型的`EnumSet`；
+ `range`：创建一个包含枚举值中指定范围元素的`EnumSet`；
+ `complementOf`：初始集合包括指定集合的补集；
+ `of`：创建一个包括阐述中所有元素的`EnumSet`；
+ `copyOf`：创建一个包含参数容器中的所有元素的`EnumSet`；

## EnumMap

`EnumMap`是专门为枚举类型量身定做的`Map`实现，虽然使用其他的`Map`实现也能完成枚举类型实例到值的映射，但是使用`EnumMap`会更加高效：它只能接收同一枚举类型的实例作为键值，并且由于枚举类型实例的数量相对固定并且有限，所以`EnumMap`使用属组来存放与枚举类型对应的值，这使得`EnumMap`效率非常高；

主要方法：

+ `size`:返回键值对数量；
+ `containsValue`：判断是否存在指定的`value`；
+ `containsKey`：判断是否存在指定的`key`；
+ `get`：根据指定的`key`获取对应`value`；
+ `put`：根据指定的`key`取出`value`；
+ `remove`：删除指定的键值对；
+ `putAll`：批量去除所有的键值对；
+ `keySet`：获取所有`key`的集合；
+ `values`：返回所有`value`；


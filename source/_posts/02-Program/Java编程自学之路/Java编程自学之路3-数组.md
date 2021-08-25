---
title: Java编程自学之路：数组
categories: Program
tags: java
date: 2021-07-30
author: Semon
---

# 简介

几乎所有程序设计语言都支持数组。数组对于每一门编程语言来说都是非常重要的数据结构；

数组代表一系列引用类型或基本类型，所有相同的类型封装到一起，采用一个统一的标识名称；

> Java中，数组是一种引用类型；
>
> Java中，数组是用来存储相同类型的元素（包括基本类型和引用类型）；
>
> Java中，数组是一种效率最高的存储和随机访问对象引用的方式；

# 数组操作

## 数组创建

Java使用`new`关键字来创建数组；创建数组有两种方式：

+ 指定维度创建
  + 维度支持以下类型：
    + 整形、字符型；
    + 整形变量、字符型变量；
    + 计算结果为整形或字符型的表达式；
  + 为数组开辟指定大小的数组维度；
  + 为每个维度元素赋予初始值；若元素类型为引用类型，则初始值为`null`；
+ 不指定维度创建
  + 通过具体元素创建并初始化数组，数组大小与元素个数相同；

> 创建数组的维度数值过大，可能会导致编译报错或栈溢出；

```java
public class ArrayDemo01 {
  public static void main(String[] args) {
    int len = 3;
    
    int[] arr1 = new int['a']; // 字符型
    int[] arr2 = new int[len];  //整形变量
    int[] arr3 = new int[len + 2]; // 整形表达式
    int[] arr4 = new int['a' + 2]; //字符型表达式
  }
}
```

## 数组使用

Java中，可通过方括号`[]`指定下标来访问数组元素，下标位置从0开始；

Java中，数组类型是一种引用类型。因此，它可以作为引用，被Java函数作为参数或返回值来使用；

```java
public class ArrayDemo02 {
  
  //数组作为参数
  prviate static void func1(int[] arr) {
    for(int i=0; i<arr.length;i++) {
      //通过下标访问数组
      System.out.println(arr[i]);
    }
  }
  
  //返回数组引用
  public static static int[] func2() {
    return new int[] {1,3,5,7,9};
  }
  
  public static void Main(String[] args) {
    int[] arr1 = new int[] {2,4,6,8,10};
    func1(arr1);
    int[] arr2 = func2();
     
    System.out.println(Arrays.toString(arr2));
  }
}
```

## 多维数组

多维数组可以看成是数组的数组，比如二维数组就是一个特殊的一维数组，其中每一个元素都是一个一维数组类型的引用；Java语言本身是可以支持N维数组，但正常人类的理解能力，一般最多能够理解三维数组；

```java
public class MultiArrayDemo {
  public stativ void main(String[] args) {
    Integer[][] mulArray = {
      {1,2,3},
      {2,4,6},
    };
    
    System.out.println("mulArray: " + Arrays.deepToString(mulArray));
  }
}
```

## Arrays类

Java中提供了一个很有用的数组工具类：`Arrays`；

它提供的主要方法有：

+ `sort`：排序
+ `equals`：比较
+ `fill`：填充
+ `hash`：哈希
+ `asList`：数组转列表
+ `toString`：数组转字符串
+ `binarySearch`：二分查找

> Java中不允许直接创建泛型数组，如果需要使用泛型，建议使用容器；
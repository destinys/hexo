---
title: Java编程自学之路：JUnit测试
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# 简介

JUnit是一个Java编程语言的单元测试框架；JUnit在测试驱动的开发方面有很重要的作用，起源于JUnit的一个统称为xUnit的单元测试框架；

JUnit功能包括：

1. 用于测试预期结果的断言；
2. 用于共享通用测试数据的测试装置；

**好处：**

1. `JUnit`是 一个测试框架，开发人员可以在开发软件时用来编写测试用例；可以为程序员编写的每个函数编写并运行测试用例；因此，可以确保程序员编写的每行代码都会收到测试；
2. 每次对代码进行变更时，都可以通过一次为该函数编写所有`JUnit`测试用例来确保该函数运行良好且没有破坏任何较旧的功能；因此，编写一个测试用例后，可以重复使用该测试用例，以确保每次修改代码时，都能够按照预期运行；
3. 使用`JUnit`，可以轻松创建并为整个软件管理丰富的单元测试用例套件；
4. 团队中的任何新成员都可以轻松理解使用`JUnit`编写和管理的测试用例，有助于编写更多的测试用例以提升开发软件的健壮性；
5. `JUnit`已成为使用Java编程语言进行测试的标准，并且几乎受所有IDE的支持；

# JUnit断言

什么是断言呢？简而言之就是判断；

`JUnit`所有的断言都包含在`Assert`类中；

这个类提供了很多有用的断言方法来编写测试用例。只有失败的断言才会被记录。`Assert`类中的一些有用的方法如下：

+ `void assertEquals(boolean expected, boolean actual)`:检查两个变量或者等式是否平衡;
+ `void assertTrue(boolean expected,boolean actual)`：检查条件为真；
+ `void assertFalse(boolean condition)`：检查条件为假；
+ `void assertNotNull(Object obj)`：检查对象不为空；
+ `void assertNull(Object obj)`：检查对象为空；
+ `void assertSame(boolean condition)`：检查两个相关对象是否指向同一个对象；
+ `void assertNotSame(boolean condition)`：检查两个相关对象是否不指向同一个对象；
+ `void assertArrayEquals(Object[] expectedArray,Object[] resultArray)`：检查两个数组是否相等；

# JUnit注解

+ `@Test`：创建一个待测试方法的测试案例；
+ `@Ignore`：定义需要忽略的测试方法或测试类；`JUnit`会统计忽略的用例数；
+ `@BeforeClass`：定义在所有测试用例前运行；一般用于多个有关联的用例时，可以将前期准备的公用部分提取出来封装在一个方法里，例如创建数据库链接、读取文件等；该方法必须是`public static void`修饰，即公开、静态、无返回；该方法仅运行一次；
+ `@AfterClass`：与`@BeforeClass`相对应，在测试类所有用例运行之后，运行一次，用于处理一些测试后续数据，如清理数据、恢复线程等；该方法必须是`public static void`修饰，该方法同样只运行一次；
+ `@Before`：与`@BeforeClass`类似，区别在于其修饰的方法在每个用例运行前都会运行一次；主要用于一些独立于用例之间的准备工作；该方法必须是`public void`修饰，且不能为`static`；
+ `@After`：与`@Before`对应；在用例运行之后运行；
+ `RunWith`：定义测试类的测试运行器，决定用什么方式偏好去运行这些测试集/类/方法；如不指定，则使用默认运行期；常见运行器有：
  + `@RunWith(Parameterized.class)`：参数运行器，配合`@Patameters`使用`JUnit`的参数化功能；
  + `@RunWith(Suite.class) @SuiteClass(ATest.class,BTest.class,CTest.class)`：测试集运行器配合使用测试集功能；
  + `@RunWith(JUnit4.class)`：`JUnit4`的默认运行器；
+ `@Parameters`：用于使用参数化功能；
+ `@Test(timeout=1000)`：限时测试，用于应对逻辑复杂、嵌套循环比较深的程序，对测试设置一个执行时间，超时系统自动终止，以毫秒为单位；

# JUnit参数化测试

## 方案一

`Junit4`引入了一个新的功能：参数化测试；参数化测试允许开发人员使用不同的值反复运行同一个测试；测试步骤如下：

+ `@RunWith(Parameterized.class)`来修饰测试类；
+ 创建一个由`@Parameters`注释的公用静态方法，返回一个对象的集合（数组）来作为测试数据集合；
+ 创建一个公共的构造函数，它接受和一行测试数据相等同的东西；
+ 为每一列测试数据创建一个实例变量；
+ 用实例变量作为测试数据的来源创建测试用例；

# 方案二

`JUnit5`引入`JUnitParamsRunner`执行器，相较`JUnit4`的参数化测试更为简便，具体使用步骤为：

+ `@RunWith(JUnitParamsRunner)来修饰测试类`；
+ 在待测试方法上添加注释`@Parameters({"arg11,arg12,arg13","arg21,arg22,arg23"})`，多组参数使用大括号限定，逗号分隔；同一组参数位于同一组双引号内，使用逗号分隔；
+ 测试方法定义形参按顺序与注解中参数对应即可；

> `JUnit4`可以通过引入`JUnitParams`包来使用该功能

# 常见错误

1. `java.lang.NoClassDefFoundError: org/hamcrest/SelfDescribing`

   该报错是因为`JUnit`版本升级后，默认不在包含`hamcrest-core`包导致，降低`JUnit`版本至4.10或添加`hamcrest-core`即可；

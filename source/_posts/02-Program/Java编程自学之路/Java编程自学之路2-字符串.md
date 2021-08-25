---
title: Java编程自学之路：字符串
categories: Program
tags: java
date: 2021-07-30
author: Semon
---

# 简介

`String`类型可能是Java中应用最频繁的引用类型，但它的性能问题却容易被忽略。高效的使用字符串，可以提升系统的整体性能。

# String的不可变性

`String`类定义：

```java
public final class String implements java.io.Serializable, Comparable<String>, CharSequence {
  private final char value[];
}
```

代码说明：

+ `String`类被`final`修饰，表示该类不可被继承；
+ `String`的数据存储于数组中，数组被`final`修饰，表示`String`对象不可被修改；

为什么Java要这么设计？

1. 保证`String`对象的安全性，避免`String`对象被篡改；
2. 保证对象的哈希值不会频繁变更，可以缓存`hashcode`,使用更加便利、更加安全等；
3. 可以实现字符串常量池；

## 字符串创建

字符串创建有以下两种方式：

+ 通过字符串常量创建
+ 通过对象初始化创建

**字符串常量创建**

通过常量创建字符串对象时，JVM首先会检查对象是否在字符串常量池中；如果在，则返回该对象引用，否则在常量池中创建新的字符串并返回；这种方式可以减少同一个值的字符串对象的重复创建，节约内存；

**对象初始化创建**

通过对象初始化创建字符串对象，编译类文件时，常量字符串将会放入到常量结构中，在类的加载过程中，常量字符串将会在常量池中创建；JVM调用`String`的构造函数，在堆内存中创建一个`String`对象变量，并引用常量池中的常量字符串；

> 一旦一个`String`对象在内存中创建出来，就无法再更改；`String`类的所有方法都没有改变原来的字符串引用的常量池中的值，而是生成了一个新的对象，并返回新的对象的引用值；
>
> 如果需要一个可变的字符串，应该使用`StringBuffer`或`StringBuilder`，否则会浪费大量的时间在垃圾回收上，因为针对字符串的每次修改都将创建一个新的对象；

## 字符串池

在Java中，为了减少相同字符串的重复创建，达到节省内存的目的，会单独开辟一块内存，用于保存字符串常量，这个内存区域被叫做字符串常量池；

当通过“字面量”创建字符串对象时，JVM会现在字符串常量池中查找是否已存在相同内容的字符串对象引用，如果存在则直接返回该对象引用，否则创建新的字符串对象，并将该对象放入字符串常量池，并返回该引用，这种机制称为**字符串驻留或池化**

；

> `intern()`方法：判断常量池中是否已存在当前字符串对象，如果存在则返回当前字符串引用；如不存在，则将此字符串对象放入常量池后，再返回其引用；

### 字符串常量池位置

JDK7以前，字符串常量池放在永久代；

JDK7中，将字符串常量池从永久代移出，暂时放到了堆内存中；

JDK7以后，使用元空间替代了永久代，字符串常量池再次从堆内存移动到了元空间（元空间位于本地内存，不在JVM汇总）；

## 字符串操作

字符串拼接是我们在Java代码中的高频操作，但`String`是Java中的一个不可变类，所以一旦实例化就无法被修改；所谓的字符串拼接，是重新生成了一个新的字符串；

### 字符串拼接

#### 使用`+`拼接字符串

在java中，拼接字符串最简单的方式就是直接使用符号`+`来拼接；

`+`在这里其实是Java提供的一个语法糖；这里不是运算符重载，Java不支持运算符重载；

> + `+`拼接字符串的原理为：将`String`转换为`StringBuilder`，然后调用其`append`方法进行处理；
>
> + 运算符重载：在计算机程序设计中，运算符重载是多态的一种；运算符重载，就是对已有的运算符重新进行定义，并赋予其另一种功能，以适应不同的数据类型；
>
> + 语法糖：指计算机语言中添加的某种语法，这种语法对语言的功能没有影响，但是更方便程序员使用，语法糖让程序更加简洁，易读；

#### concat

原理为创建一个新的字符数组，再把两个字符串复制到新的字符数组中，并使用这个新的字符数组创建一个新的`String`对象并返回；

#### StringBuffer

`StringBuffer`类可以用来定义一个字符串变量对象，该对象可以进行扩充和修改；

其原理为：封装一个字符数组，通过`append`方法进行字符串拼接，线程安全；

#### StringBuilder

`StringBuilder`用法与`StringBuffer`类似，原理与`StringBuffer`基本一致，唯一区别为`StringBuilder`线程不安全；

#### StringUtils.join

除了JDK内置字符串拼接方法外，还可以使用开源类库中提供的字符串拼接方法，如`apache.commons`提供的`StringUtils`类，其中`join`方法可以拼接字符串；该方法其实是通过`StringBuilder`实现；

#### 字符串拼接总结

以上五种字符串拼接效率排序为：

`StringBuilder` < `StringBuffer` < `concat` < `+` < `StringUtils.join`

使用场景推荐：

+ 非循环体内：推荐使用`+`
+ 并发场景：使用`StringBuffer`
+ 循环体内：`StringBuilder`

### 字符串剪裁

`String`类对象包括三个成员变量：`char[] value`,`int offset`、`int count`；它们分别用来存储字符串的实际内容，数组的第一个位置索引以及字符串包含的字符个数；

字符串剪裁最常用的方法为`substring()`方法；

JDK6下`substring()`实现原理为：

1. 创建一个新的字符串对象；
2. 字符串对象中的数组指向原字符串对象中的字符数组；
3. 根据`substring()`方法参数计算出剪裁后字符串对象的`count`及`offset`；

> 在JDK6中，如果字符串很大，使用`substring`进行切割时，可能会导致性能问题；切割后的一个小字符串会导致整个大字符串无法释放；

JDK7下`substring()`实现原理：

JDK7通过创建一个新的字符串对象，从而避免对老字符串的引用，解决内存泄露问题；

```java
public String(char value[], int offset, int count) {
    //check boundary
    this.value = Arrays.copyOfRange(value, offset, offset + count);
}

public String substring(int beginIndex, int endIndex) {
    //check boundary
    int subLen = endIndex - beginIndex;
    return new String(value, beginIndex, subLen);
}
```

### 字符串转换

#### Integer与String互换

1. **通过自动转换实现整数转换为字符串**

“小”数据类型+“大”数据类型返回“大”数据类型，本质是使用`StringBuilder.append(i).toString()`进行转化；

```java 
Integer i = 10;
String s1 = '' + i;
//等价于 String s1 = (new StringBuilder()).append(i).toString()
```

2. **调用字符串类静态方法实现整数转换为字符串**

```java
String s2 = String.ValueOf(i);
```

3. **调用整数类的静态方法实现整数转换为字符串**

```java
String s3 = Integer.toString(i);
```

4. **调用整数类的静态方法实现字符串转换为整数**

```java
int i2 = Integer.valueOf(i);
```

### 字符串长度限制

字符串长度受常量池及运行期参数限制；

#### 常量池限制

在将java文件编译成class文件的过程中，必须遵守一定的格式规范；

`CONSTANT_String_info` 用于表示`java.lang.String`类型的常量,格式为：

```java
CONSTANT_String_info {
  u1 tag;
  u2 string_index
}

CONSTANT_utf8_info {
  u1 tag;
  u2 length; 
  u1 bytes[length];
}
```

说明：

+ `string_index`：必须是对常量池有效的索引，结构为`CONSTANT_utf8_info`；
+ `length`：两字节无符号数，最大长度小于65535（2^16 -1）,即字符串常量最大长度小于65535；

#### 运行期限制

字符串长度运行期限制为`Integer.MAX_VALUE`，大小约为4G；
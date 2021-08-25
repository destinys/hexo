---
title: Java编程自学之路：JDK8新特性
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# 接口默认方法

JDK8开始支持通过`default`关键字将非抽象方法实现添加到接口。这个功能也被称为虚拟扩展方法。

```java
interface Formula{
  double calculate(int a);
  
  default doubel sqrt(int a) {
    return Math.sqrt(a);
  }
}


public class Jdk8NewDemo01 implements Formula {
  @Override
  double calculate(int a) {
    return a / 2.0;
  }
  
  public static void main(String[] args) {
    int a = 10;
    Jdk8NewDemo01 demo01 = new Jdk8NewDemo01();
    System.out.println(demo01.calculate(a));
    
    //接口默认方法，不需要重写即可直接使用
    System.out.println(demo01.sqrt(a));
  }
}
```

# Lambda表达式

Lambda表达式又称闭包或匿名函数，主要优点在于简化代码、并行操作集合等。

## Lambda语法

lambda基本语法：

```java
（Type1 param1, Type2 param2,...,TypeN paramN） -> {
  statment1;
  statment2;
  ...
    return statmentM;
}
```

Lambda表达式特性：

+ 可选类型声明：无需声明参数类型，编译器即可自动识别
+ 可选的参数圆括号：仅有一个参数时圆括号可以省略
+ 可选的大括号：主体只包含一个语句时可省略大括号
+ 可选的返回关键字：主体只包含一个表达式返回值并省略大括号时，编译器会自动return返回值；有大括号时，需要显式指定表达式return一个结果；

> 从程序的严谨性触发，尽量指明函数的参数类型，避免出错。

## Lambda示例

```java
// demo1

//before java8
new Thread(new Runnable() {
  @Override
  public void run() {
    System.out.println("Before Java 8, too much code for too little to do!")
  }).start();
  
  
//java8
new Thread() -> System.out.println("In Java 8, Lambda expression rocks !!").start();
  

//demo2

// before java8
JButton button = new JButton("Show");
button.addActionListener(new ActionListener() {
 @Override
  public void actionPerformed(ActionEvent e) {
    System.out.println("Event handling without lambda expression !")
  }
});
  
//java8
JButton button = new JButton("Show");
button.addActionListener( e -> System.out.println("Lambda expression!"));
  

//demo3

// before java 8
List li = Arrays.asList("Lambdas","Method","Stream", "Date");
for (String e: li) {
  System.out.println(e);
}
  
// java 8
List li = Arrays.asList("Lambdas","Method","Stream", "Date");
li.forEach(n -> System.out.println(n));
  

//demo4
  
//before java 8
List tax = Arrays.asList(100,200,300,400);
for (Integer cost:tax) {
  double price = cost + 0.12 * cost;
  System.out.println(price);
}
  
//java8
List tax = Arrays.asList(100,200,300,400);
tax.stream().map(cost -> cost + cost * 0.12).forEach(System.out::println);
```

# 函数式接口

函数式接口就是一个有且仅有一个抽象方法，但是可以有很多个非抽象方法或静态方法的接口。

函数式接口可以被隐式转换为lambda表达式，让代码更简洁。

JDK8包含了许多内置的函数式接口，这些接口可以通过`@FunctionalInterfaceannotation`注解扩展为支持Lambda。

## Predicate

`Predicate`是只有一个参数的布尔型函数。该接口包含各种默认方法，用于将谓词组合成复杂的逻辑术语（与、或、非）

+ 抽象方法：`boolean test(T t)`传入一个参数，返回一个布尔型。

## Function

`Function`接口一个参数并产生一个结果。可以使用默认方法将多个函数链接在一起。

+ 抽象方法：`R apply(T t)`传入一个参数，返回想要的结果。

## Supplier

`Supplier`产生一个泛型结果，与`Function`不同，`Supplier`不接受参数。

+ 抽象方法：`T get()` 返回一个自定义数据。

## Consumer

`Consumer`表示要在一个输入参数上执行的操作。

+ 抽象方法：`void accept(T t)` 接收一个参数进行消费，但无需返回结果。

```java
public class FunctionalInterfaceDemo {
  
  //输入一个指定类型的参数，基于此参数进行计算，但并不返回结果
  public static void demoConsumer() {
    Consumer<List<String>> counter = list -> {
      int num = list.size();
    };
    String[] words = {"tom","and","jerry"};
    counter.accept(Arrays.asList(words));
  }
  
  
  //输入一个指定类型的参数，返回另外一个指定类型的结果
  public static void demoFunction() {
    Function<Integer, Integer> square = i-> i*i;
    
    int root = 3;
    int result = square.apply(root);
  }
  
  //不需要提供参数，每次总是返回同一个常量
  public static void demoSupplier() {
    Supplier<String> constValue = () -> "hello world";
  }
  
  //输入一个指定类型为T的参数，基于它执行某种断言逻辑，给出一个true/false结论
  public static void demoPredicate() {
    Predicate<String> flag = type -> type.equalsIgnoreCase("dog");
    
    String animal = "dog";
    boolean isDog = flag.test(animal);
  }
}
```

## Optional

`Optional`不是功能性接口，而是防止`NullPointerException`的好工具。

`Optional`是一个简单的容器，其值可以是null或非null。

```java
Optional<String> option = Optional.of("apple");

option..isPresent();  //true
option.get();		//"apple"
option.orElse("pear"); //"pear"
option.ofPresent( (s) -> System.out.println(s.charAt(0))) //"a"
```

# Streams

JDK8中的`Stream`是对集合对象功能的增强，它专注于对集合对象进行各种非常便利】高效的聚合操作，或者大批量数据操作。`Stream API`借助于同样新出现的Lambda表达式，极大的提高了编程效率和程序可读性。同时它提供串行和并行两种模型进行汇聚操作，并发模式能够充分利用多核处理器的优势，使用`fork/join`并行方式来拆分任务和加速处理过程。通常编写并行代码很难而且容易出错，但使用`Stream API`无需编写一行多线程代码，就可以很方便的写出高性能的并发程序。所以说，JDK8中首次出现的`java.util.Stream`是一个函数式语言 + 多核时代综合影响的产物。

## 什么是流

`Stream`不是集合元素，它不是数据结构并不保存数据，它是有关算法和计算的，它更像一个高级版本的`Iterator`。原始版本的`Iterator`，用户只能显式地一个一个遍历元素并对其执行某些操作；高级版本的`Stream`，用户只需要给出需要对其包含的元素执行什么操作，`Stream`会隐式地在内部进行遍历，做出相应的数据转换。

`Stream`就如同一个迭代器，单向，不可往复，数据只能遍历一次；而和迭代器又不通，`Stream`可以并行化操作，迭代器只能命令式地、串行化操作。顾名思义，当使用串行方式去遍历时，每个`item`读完后再读下一个`item`。而是用并行去遍历时，数据会被拆分成多个段，每一段在不同的线程中处理，然后一起输出。`Stream`的并行操作依赖于JDK7引入的`Fork/Join`框架来拆分任务和加速处理过程。

`Stream`的另外一大特点就是，数据源本身可以是无限的。

## 流的构成

当我们使用一个流时，通常包括三个步骤：

1. 获取一个数据源；
2. 数据转换；
3. 执行操作获取想要的结果；

> 针对流的每次转换，原有的Stream对象不改变，返回一个新的Stream兑现个，这就允许对其操作可以像链条一样排列，编程一个管道。

流数据源类型：

+ 从`Collection`和数组创建
  + `Collection.stream()`
  + `Collection.parallelStream()`
  + `Arrays.stream(T array)`
  + `Arrays.Stream.of(T array)`
+ 从`BufferedReader`创建
  + `java.io.BufferedReader.lines()`

+ 静态工厂
  + `java.util.stream.IntStream.range()`
  + `java.nio.file.File.walk()`
+ 用户构建
  + `java.util.Spliterator`
  + 其它
    + `Random.ints()`
    + `BitSet.stream()`
    + `Pattern.splitAsStream(java.lang.CharSequence)`
    + `JarFile.stream()`

流的操作类型：

+ `Intermediate`：一个流可以后面跟随零个或多个`intermediate`操作。其目的主要是打开流，做出某种程度的数据映射/过滤，并返回一个新的流，交给下一个操作使用。这类操作都是惰性化的(lazy)。
+ `Terminal`：一个流只能有一个`terminal`操作，当这个操作执行后，流就无法再被操作。所以这必定是流的最后一个操作。`terminal`操作的执行，擦灰真正开始流的遍历，并生成一个结果，或者`side effect`。
+ `short-circuiting`：
  + 对于一个`intermediate`操作，如果它接受一个无限大的`Stream`，但返回一个有限的新的`Stream`；
  + 对于一个`terminal`操作，如果它接受一个无限大的`Stream`，但能在有限的时间结算出结果。

## 流的操作

常见的流的操作可以归类如下：

### Intermediate类

```java
map(mapToInt,flatMap)、filter、distinct、sorted、peek、limit、skip、parallel、sequential、unordered
```

### Terminal

```java
forEach、forEachOrdered、toArray、reduce、collect、min、max、count、anyMatch、allMatch、noneMatch、findFirst、findAny、iterator
```

### Short-circuiting

```java
anyMatch、allMatch、noneMatch、findFirst、findAny、limit
```

## 代码示例

```java
String[] strArray = new String[] {"a", "b", "c"};
stream = Stream.of(strArray);

stream.filter(e-> e.length() =1 ).peek(e -> System.out.println("Filtered value: " + e)).map(String::toUpperCase).collect(Collectors.toList());
```

# Date API

JDK8在`java.time`包下新增了一个全新的日期和时间`API`。新的日期`API`与`Joda-Time`库相似，但不一样。以下示例涵盖了此新`API`的最重要部分。

## Clock

`Clock`提供对当前日期和时间的访问。`Clock`知道一个时区，可以使用它来代替`System.currentTimeMillis()`获取从**Unix EPOCH**开始的以毫秒为单位的当前时间。时间线上的某一时刻也由类`Instant`表示。`Instants`可以用来创建遗留的`java.util.Date`对象。

## TimeZone

时区由`ZoneId`来表示，他们可以很容易地通过静态工厂方法访问。时区定义了某一时刻和当地日期、时间之间转换的重要偏移量。

## LocalTime

`LocalTime`代表没有时区的时间，例如晚上10点或`17:30:00`。

## LocalDate

`LocalDate`表示不同的日期，它是不可变的，与`LocalTime`完全类似。

## LocalDateTime

`LocalDateTime`表示日期时间，它将日期和时间组合成一个实例。`LocalDateTime`是不可变的。

## 代码示例

```java
Clock clock = Clock.systemDefaultZone()
long millis = colck.millis();

Instant instant = clock.instant();
Date legacyDate = Date.from(instant);  //legacy java.util.Date


System.out.println(ZoneId.getAvailableZoneIds());
ZoneId zone1 = ZoneId.of("Europe/Berlin");
ZoneId zone2 = ZoneId.of("Brazil/East");
System.out.println(zone1.getRules());


LocalTime now1 = LocalTime.now(zone1);
LocalTime now2 = LocalTime.now(zone2)

System.out.println(now1.isBefore(now2));

long hoursBeteween = ChronoUnit.HOURS.between(now1,now2);
long minutesBetween = ChronoUnit.MINUTES.between(now1,now2);

System.out.println(hoursBetween);

LocalTime late = LocalTime.of(23,59,59);
System.out.println(late);

DateTimeFormatter formater = DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT).withLocale(Locale.GERMAN);

LocalTime leetTime = LocalTime.parse("13:37",formater);
System.out.println(leettime);

LocalDate today = LocalDate.now();
LocalDate tomorrow = today.plus(1, ChronoUnit.DAYS);

LocalDate inDay = LocalDate.of(2014,Month.JULY,5);
DayOfWeek dayOfWeek = inDay.getDayOfWeek();

DateTimeFormatter formater =DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM).withLocale(Locale.GERMAN);

LocalDate xmas = LocalDate.parse("24.12.2021",formater);

LocalDateTime now_full = LocalDateTime.of(2021,Month.DECEMBER, 31, 23,59,59);

long munuteOfDay = now_full.getLong(ChronoField.MONUTE_OF_DAY);


DateTimeFormatter formater = DateTimeFormatter.ofPattern("MMM dd,yyyy - HH:mm");

LocalDateTime parsed = LocalDateTime.parse("Nov 05, 2021 - 22:24", formater);
String str = formater.format(parsed);
System.out.println(str);
```

> DateTimeFormatter是不可变且线程安全的。


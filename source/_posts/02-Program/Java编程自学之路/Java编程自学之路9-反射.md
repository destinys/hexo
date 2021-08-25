---
title: Java编程自学之路：反射
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# Java反射

## 反射简介

反射（`Reflection`）是Java程序开发语言的特征之一，它允许运行中的Java程序获取自身的信息，并且可以操作类或对象的内部属性；

通过反射机制，可以在运行时访问Java对象的属性、方法等；

## 应用场景

反射的应用场景主要有：

1. 开发通用框架：反射最重要的用于就是开发各种通用框架，很多商用框架都是配置化的，为了保证框架的通用性，他们可能需要根据配置文件加载不同的对象或类，调用不同的方法，这就需要通过反射–运行时动态加载来实现；
2. 动态代理：在切面编程（`AOP`）中，需要拦截特定的方法，通常，会选择动态代理方式来实现；
3. 注解：注解本身仅起到标记作用，实际需要利用反射机制，根据注解标记去调用对应的注解解释器，执行行为；
4. 可扩展性：应用程序可以通过使用完全限定名创建可扩展对象实例来使用外部用户定义类，比如数据库驱动类；

## 反射缺点

任何事务都是有双面性的，反射实现了一系列功能的同事，也引入了一些缺点：

1. 性能开销：由于反射涉及动态解析，因此无法执行某些Java虚拟机优化；因此，反射操作的性能相对较差，在性能敏感性应用中因避免频繁调用；
2. 破坏封装性：反射调用方法时可以忽略权限检查，因此可能破坏封装性而导致安全问题；
3. 内部曝光：由于反射允许代码执行非反射代码中的非法操作，如访问私有字段或方法；这可能导致代码功能失常并可能破坏代码可移植性；反射代码打破了抽象，可能会随着平台的升级而改变行为；

# 反射机制

## 类加载流程

类加载完成过程如下：

1. 编译阶段：Java编译器对`.java`文件编译完成，在磁盘中生成`.class`文件；`.class`文件是二进制文件，内容是只有JVM能够识别的机器码；
2. 加载阶段：JVM的类加载器读取字节码文件，取出二进制数据，加载到内存中，解析`.class`文件内的信息；类加载器会根据类的全限定名来获取此类的二进制字节流；将字节流所代表的的静态存储结构转化为方法区的运行时数据结构，在内存中生成代表这个类的`java.lang.Class`对象；
3. 执行阶段：加载结束后，JVM开始进行链接阶段（包括验证、准备、初始化）；经过这一系列操作，类的变量会被初始化；
4. 底层调用：将JVM的调用提交至操作系统进行计算；

## Class对象

想使用反射，首先需要获得待操作的类所对应的`Class`对象；在Java中，无论生成某个类的多少个对象，这些对象都会对应于同一个`Class`对象。这个`Class`对象是由JVM生成的，通过它能够获悉整个类的结构；所以，`java.lang.Class`可以是为所有反射API的入口；

反射的本质就是：在运行时，把Java类中的各种成分映射成一个个的Java对象；

> JVM自动创建类的`Class`对象后，存储在JVM的方法区中；且一个类有且只有一个`Class`对象；

## 方法反射调用

方法的反射调用，也就是`Method.invoke`方法；

`Method.invoke`方法源码：

```java
public final class Method extends Executable {
  public Object invoke(Object obj, Object ... args) throws ... {
    MethodAccessor ma = methodAccessor;
    if(ma == null) {
      ma = acquireMethodAccessor();
    }
    return ma.invoke(obj,args);
  }
}
```

说明：

+ `NativeMethodAccessorImpl`：本地方法来实现反射调用；
+ `DelegationMethodAccessorImpl`：委派模式来实现反射调用；

`Method.invoke`方法调用实际上是委派给`MethodAccessor`接口来处理；每个`Method`实例的第一次反射调用都会生成一个委派实现，它所委派的具体实现便是一个本地实现（`NativeMethodAccessorImpl`）；

Java的反射机制还设立了另一种动态生成字节码的实现，直接使用`invoke`指令来调用目标方法；通过委派实现，能够在本地实现与动态实现中切换；动态实现不需要经过Java到C++再到Java，效率比本地实现高20倍，但生成字节码很耗时，仅调用一次的话，反而是本地实现要快3到4倍；（在16次调用时，动态调用性能追上本地调用）

## 反射调用开销

方法的反射调用会带来不少性能开销，主要原因为：

+ 变长参数方法导致的`Object`数组；
+ 基本类型的自动装箱、拆箱；
+ 方法内联；

`Class.forName()`会调用本地方法，`Class.getMethod()`则会遍历该类的共有方法，如果没有匹配到，它还将遍历父类的公有方法，可想而知，这两个操作都非常费时；

# 反射使用

## java.lang.reflect包

Java中的`java.lang.reflect`包提供了反射功能，包中的类都没有`public`构造方法；

`java.lang.reflect`包的核心接口和类如下：

+ `Member`接口：反映关于单个成员（字段或方法）或构造函数的标识信息；
+ `Field`类：提供一个类的域信息以及访问类的域的接口；
+ `Method`类：提供一个类的方法的信息以及访问类的方法的接口；
+ `Constructor`类：提供一个类的构造函数的信息以及访问类的狗仔函数的接口；
+ `Array`类：提供动态生成和访问JAVA数组的方法；
+ `Modifier`类：提供了static方法和常量，对类和成员访问修饰符进行解码；
+ `Proxy`类：提供动态地生成代理类和类实例的静态方法；

## 获取Class对象

获取`Class`对象的三种方法：

1. `Class.forName()`静态方法：使用类的完全限定名来反射对象的类；常用应用场景为：在JDBC开发中常用此方法加载数据库驱动；
2. 类名 + `.class`
3. `Object`的`getClass`方法：`Object`类中有`getClass`方法，因为所有类都继承`Object`类；从而调用`Object`类来获取`Class`对象；

代码示例：

```java
public class ReflectClassDemo {
  
  public static void main(String[] args) throws ClassNotFoundException {
    //m1  jdbc驱动
    Class c1 = Class.forName("org.mysql.jdbc.Driver");
    // double 数组
    Class c2 = Class.forName("[D"); 
    System.out.println(c2.getCanonicalName());   // double[]
    
    //m2
    Class c3 = java.io.PrintStream.class;
    Class c4 = int[] [] [].class;
    System.out.println(c4.getCanonicalName())   // int[][][]
    
    //m3
    Set<String> set = new HashSet<>();
    Class c5 = set.getClass();
    System.out.println(c5.getCanonicalName());  // java.util.HashSet
  }
}
```

## 判断类实例

判断是否为某个类的实例方式：

+ `instanceof`关键字；
+ `Class`对象`isinstance`方法（`Native`方法）；

示例代码：

```java
public class InstanceOfDemo {
  public static void main(String[] args) {
    
    ArrayList arr = new ArrayList();
    
    if (arr instanceof List) {
      System.out.println("ArrayList is  List");
    }
    
    if (List.class.isInstance(arr)) {
      System.out.println("ArrayList is  List");
    }
  }
}
```

## 创建实例

通过反射来创建实例对象有以下方式：

+ 用`Class`对象的`newInstance`方法；
+ 用`Constructor`对象的`newInstance`方法；

示例代码：

```java
public class ReflectNewInstanceDemo {
  public static void main(String[] args) throws Exception {
    
    //m1
    Class<?> c1 = StringBuilder.class;
    StringBuilder sb = (StringBuilder) c1.newInstance();
    sb.append("hello");
    
    //m2
    //获取String对应class对象
    Class<?> c2 = String.class;
    //获取String类带一个String参数的构造器
    Constructor con = c2.getConstructor(String.class);
    //使用构造器构造对象
    String str = (String) con.newInstance("world");
  }
}
```

## 创建数组实例

数组在Java中是比较特殊的一种类型，它可以赋值给一个对象引用；Java中，可以通过`Array.newInstance`来创建数组实例；

示例代码：

```java
public class ReflectArrayDemo {
  public static void main(String[] args) throws ClassNotFoundException {
    Class<?> cls = Class.forName("java.lang.String");
    Object arr = Array.newInstance(cls,20);
    Array.set(arr,0,"Scala");
    Array.set(arr,1,"java");
    System.out.println(Array.get(arr,1));
  }
}
```

### d

`Class`对象提供以下方法获取对象的成员：

+ `getFiled`：根据名称获取共有的类成员；
+ `getDeclaredField`：根据名称获取以声明的类成员，但不能获取起父类成员；
+ `getFields`：获取所有共有的类成员；
+ `getDeclaredFields`：获取所有已声明的类成员；

```java
public class ReflectFieldDemo {
  class FieldDemo<T> {
    public boolean b = false;
    public String name = "Alice";
    public List<Integer> list;
    public T val;
  }
  
  public static void main(String[] args) throws NoSuchFieldException {
    Field f1 = FieldDemo.class.getField("b");
    System.out.println("Type: %s%n" ,f1.getType());
    
    Field f2 = FieldDemo.class.getField("val");
    System.out.println("type: %s%n", f2.getType());
  }
}
```

### Method

`Class`对象提供以下方法获取对象的方法：

+ `getMethod`：返回类或接口的特定方法。其中第一个参数为方法名称，后面的参数为方法参数对应的`Class`对象；
+ `getDeclaredMethod`：返回类或接口的特定声明方法。其中第一个参数为方法名称，后面的参数为方法参数对应`Class`对象；
+ `getMethods`：返回类或接口的所有公有方法，包括起父类的公有方法；
+ `getDeclaredMethods`：返回类或接口声明的所有方法，但不包括继承的方法；

获取一个`Method`对象后，可以用`invoke`方法来调用这个方法。

```java
public class ReflectMethodDemo {
  public static void main(String[] args) throws Exception {
    Method[] m1 = System.class.getMethods();
    for (Method m: m1) {
      System.out.println(m);
      System.out.println(m.invoke(null));
    }
  }
}
```

### Constructor

`Class`对象提供以下方法获取对象的构造方法：

+ `getConstructor`：返回类的特定公有构造方法，参数为方法参数对应的`Class`对象;
+ `getDeclaredConstructor`：返回类的特定构造方法，参数为方法参数对应的`Class`对象；
+ `getConstructors`：返回类的所有共有构造方法；
+ `getDeclaredConstructors`：返回类的所有构造方法；

获取一个`Constructor`对象后，可以使用`newInstance`方法来创建类实例；

```java
public class ReflectConstructorDemo{
  public static void main(String[] args) throws Exception {
    Constructor constructor = String.class.getConstructor(String.class);
    String str = (String) constructor.newInstance("helloworld");
    System.out.println(str);
   }
}
```

### 绕开访问限制

反射可以通过`setAccessible(true)`来绕开Java的访问限制，直接访问私有成员、私有方法；

## 代理

### 静态代理

静态代理其实就是指设计模式中的代理模式；代理模式为其它对象提供一种代理以控制对这个对象的访问；

```java
//定义抽象类
public class Subject {
  public abstract void Request();
}

//实现抽象类
class RealSubject extends Subject {
  @Override
  public Request() {
    System.out.println("real Subject");
  }
}

//定义代理类，用来保存一个引用使代理可以访问实体，并提供一个与Subject的接口相同的接口，这样代理就可以用来替代实体
class Proxy extends Subject {
  
  private RealSubject real;
  
  @Override 
  public void Request() {
    if (null ==  real) {
      real = new RealSubject();
    }
    real.Request();
  }
}
```

+ 优点：能够访问正常实体无法访问的资源，增强现有的接口业务功能；
+ 缺点：真实实体与代理的功能本质上是相同的，代理只起到了中介作用，但代理的存在会导致系统结构比较臃肿，增加维护难度；

### 动态代理

为了解决静态代理的问题，所以有了动态代理的概念；

动态代理是一种方便运行是动态构建代理、动态处理代理方法调用的机制，很多场景都是利用类似机制实现的，比如包装RPC调用、面向切面编程等；

实现动态代理的方式很多，比如JDK自身提供的动态代理，主要就是利用了反射机制；高性能的字节码操作机制，类似ASM、cglib、javassist等；

Java动态代理基于经典代理模式，引入了一个`InvocationHandler`，`InvocationHandler`负责统一管理所有的方法调用；

动态代理步骤：

1. 获取真实实体上所有接口列表；
2. 确认要生成的代理类的类名，默认为：`com.sun.proxy.$ProxyXXX`；
3. 根据需要实现的接口信息，在代码中动态创建该`Proxy`类的字节码；
4. 将对应的字节码转换为对应的`class`对象；
5. 创建`InvocationHandler`实例`handler`，用来实现`proxy`所欲方法调用；
6. `Proxy`的`class`对象以创建的`handler`对象为参数，实例化一个`proxy`对象；

JDK动态代理的实现是基于实现接口的方式，使得`Proxy`与真实实体具有相同的功能；

#### InvocationHandler接口

每一个动态代理类都必须要实现`InvocationHandler`接口，并且每个代理类的实例都关联到了一个`handler`。当我们通过代理对象调用一个方法的时候，这个方法的调用就会被转发为由`InvocationHandler`接口的`invoke`方法来进行调用；

接口定义：

```java
public interface InvocationHandler {
  public Object invoke(Object proxy, Method method, Object[] args) throws Throwable;
}
```

说明：

+ `proxy`：代理的真实对象；
+ `method`：要调用真实对象的某个方法的`Method`对象；
+ `args`：调用真实对象的某个方法时接受的参数；

#### Proxy类

`Proxy`类的作用是用来动态创建一个代理对象的类，它提供了许多方法，但使用最多的就是`newProxyInstance`方法；

方法定义：

```java
public static Object newProxyInstance(ClassLoader loader, Class<?>[] interfaces, InvocationHandler handler) throws IllegalArgumentException
```

说明：

+ `loader`：一个`ClassLoader`对象，定义了生成代理对象进行加载的`ClassLoader`；
+ `interface`：一个`Class<?>`对象的数组，表示的是将要提供给代理的对象提供的一组接口，代理对象宣称实现这组接口，代理对象即可调用这组接口的方法；
+ `handler`：一个`InvocationHandler`对象，表示的是当动态代理对象调用方法时，会关联到哪一个`InvocationHandler`对象上；

### JDK动态代理

```java
//定义接口
public  interface Subject  {
  void hello(String str);
  
  String bye();
}

//定义一个类并实现接口
public class RealSubject implements Subject {
  @Override
  public void hello(String str) {
    System.out.println("Hello " + str);
  }
  
  @Override
  String bye() {
    System.out.println("Goodbye");
    return "Over";
  }
}

//动态代理
public class InvocationHandlerDemo implements InvocationHandler {
  //要代理的对象
  private Object subject;
  
  //自定义构造方法
  public InvocationHandlerDemo(Object obj) {
    this.subject  = obj;
  }
  
  @Override
  public Object invoke(Object obj, Method method, Object[] args) throws Throwable {
    //代理真实实体前，添加一些自定义操作
    System.out.println("Before Method");
    
    Object obj = method.invoke(subject,args);
    
    //代理真实实体后，添加一些自定义操作
    System.out.println("After Method");
    
    return obj;
  } 
}

//调用测试
public class ClientDemo{
  public static void main(String[] args) {
    //要代理的实体
    Subject realSubject = new RealSubject();
    
    //绑定代理实体
    InvocationHandler handler = new InvocationHandlerDemo(realSubject);
    /*
    通过Proxy的newProxyInstance方法来创建代理对象，
    参数1：handler.getClass().getClassLoader()，使用handler类的ClassLoader对象来加载我们的代理对象；
    参数2：realSubject.getClass().getInterfaces()，这里为代理对象提供的接口是针对实体所实现的接口，表示我要dialing的是该真实实体，这样就可以调用这组接口中的方法了；
    参数3：handler，将代理对象关联到InvocationHandler对象上
    */
    Subject  subject = (Subject) Proxy.newProxyInstance(handler.getClass().getClassLoader(), realSubject.getClass().getInterfaces(), handler);
    
    System.out.println(subject.getClass().getName());
    subject.hello("World");
    String result = subject.bye();
  }
}
```

> JDK动态代理特点：
>
> 优点：相对于静态代理模式，不需要硬编码接口，代码复用率高；
>
> 缺点：强制要求代理类实现InvocationHandler接口；

### CGLIB动态代理

CGLIB提供了与JDK动态代理不同的方案；很多框架，例如`Spring AOP`中，就使用了CGLIB动态代理；

CGLIB底层,其实是借助了ASM这个强大的Java字节码框架去进行字节码增强操作；

CGLIB动态代理步骤：

+ 生成代理类的二进制字节码文件；
+ 加载二进制字节码，生成`Class`对象；
+ 通过反射获得实例构造，并创建代理类实例；

CGLIB动态代理特点：

+ 优点：使用字节码增强，比JDK动态代理方式性能更高；可以在运行时对类或者是接口进行增强操作，且委托类无需实现接口；
+ 缺点：不能对`final`类及`final`方法进行代理；

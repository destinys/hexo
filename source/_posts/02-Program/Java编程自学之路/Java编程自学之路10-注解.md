---
title: Java编程自学之路：注解
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# 注解简介

## 注解的形式

Java中，注解是以`@`字符开始的修饰符；

注解可以包含命名或未命名的属性，并且这些属性有值；如果只有一个名为`value`的值，那么名称可以省略；

如果注解没有属性，则称为**标记注解**；比如`@Override`；

代码示例：

```java
@Author(
	name = "semon"   //带属性的注解
  date = "2020-07-13"
)
class ClassDemo extends SuperDemo{ 

  @Override  //标记注解
	void SubMethod1() { ... }
  
  @SuppressWarnings("unchecked")  // 属性名为value  值为unchecked
  void SubMethod2() { ... }

}
```

## 什么是注解

从本质上来说，注解是一种标签，其实质上可以视为一种特殊的注释，区别在于注解通过代码进行解析实现特定功能。注解的解析一般有两种形式：

+ 编译器扫描：编译器在对javadiamante编译字节码的过程中会检测到某个类或者方法被一些注解修饰，这是会对于这些注解进行某些处理，但仅适用于JDK内置的注解类；
+ 运行期反射：编译器利用反射技术，识别自定义注解以及它携带的信息，然后进行相应的处理；

## 解的作用

+ 编译器信息：编译器可以使用注解来检测错误或抑制告警；
+ 编译部署处理：程序可以在编译或部署期间处理注解信息生成代码、XML文件等；
+ 运行处理：程序可以在运行时检查注解并处理；

## 注解的代价

凡事有得必有失，享受注解带来便利的同时，也需要付出一定的代价：

+ 注解是一种侵入式编程，增加了程序耦合度；
+ 自定义注解通过反射技术实现，违背了面向对象的封装性；
+ 通过注解实现功能，产生问题时更加难以进行定位；

## 注解应用访问

注解可以应用于类、字段、方法和其他程序元素的声明；

JDK8开始，注解的应用范围进一步扩大：

+ 类实例初始化
+ 类型转换
+ 实现接口声明
+ 抛出异常声明

```java
//类实例化
new @Interned Demo01() { ... };

//类型转换
str2 = (@NonNull String) str1;

//实现接口声明
class DemoList<T> implements @Readonly List<@Readonly T> { ... };

//抛出异常
void DemoException() throws @Critical IOException {}
```

# 内置注解

JDK中内置了以下注解：

+ @Override：声明被修饰的方法覆写了父类方法；
+ @Deprecated：声明该类或方法已废弃、过时，不建议使用；
+ @SuppressWarnnings：声明对该类、方法、成员编译时产生的特定警告；常见参数值如下：
  + deprecation：使用了过时方法或类时的警告；
  + unchecked：指定了未检查的转换时警告；
  + fallthrough：当Switch程序块分支没有break时的警告；
  + path：在类路径、源文件路径中有不存在的路径时的警告；
  + serial：在可序列化的类上缺少SerialVersionUID定义时的警告；
  + finally：任何finally子句不能正常完成的警告；
  + all：所有警告；
+ @SafeVarargs：JDK7引入，压制变长参数中的泛型类型检查，使用范围为：
  + 构造方法
  + static或final修饰的方法
+ @FunctionalInterface：JDK8移入，声明被修饰的接口是函数式接口；函数式接口就是有且仅有一个抽象方法的接口（可以有多个非抽象方法），可以被隐式转换为lambda表达式。

代码示例：

```java
public Class AnnotateDemo01 {
  
  @FunctionalInterface
  public interface Work(
  void printWork(String msg); 
  )
  
  static Class Person {
    public String getName() {
      return "Name";
    }
    
    @Deprecated
    public String OldMethod() {
      return "Deprecated";
    }
    
    @SafeVarargs
    static void SafeVarsDemo(List<String> ... stringLists) {
      System.out.println("demo");
    }
  }
  
  static class Man extends Person {
    @Override
    public String getName() {
      return "man";
    }
  }
  
  @SuppressWarnings({"deprecation","unchecked"})
  public static void main(String[] args) {
    
  }
}
```



# 元注解

JDK中虽然内置了部分注解，但这远远不能满足开发过程中遇到的千变万化的需求，所以我们需要用到自定义注解，这就需要用到元注解。

元注解的作用就是定义其他的注解，Java提供了以下元注解类型：

+ @Retention
+ @Target
+ @Documented
+ @Inherited(JDK8)
+ @Repeatable(JDK8)

## @Retention

该注解声明注释的保留级别。通过一个`RetentionPolicy`指定注释保留级别：

+ SOURCE：仅在源文件有效，编译器忽略；
+ CLASS：在class文件中有效，JVM忽略；
+ RUNTIME：运行时有效

## @Documented

表示任何级别的注解都应用于Javadoc中（默认情况下，注释不包含在Javadoc中）；

## @Target

指定注解可以修饰的元素类型，通过`ElementType`指定应用范围：

+ ANNOTATION_TYPE：标记的注解可应用于注解类型；
+ CONSTRUCTOR：标记的注解可用于构造方法；
+ FIELD：标记的注解可用于字段或属性；
+ METHOD：标记的注解可用于方法；
+ PACKAGE：标记的注解可用于包声明；
+ PARAMETER：标记的注解可用于参数列表；
+ TYPE：标记的注解可用于类的任何元素；
+ LOCAL_VARIABLE：标记的注解可用于局部变量；

## @Inherited

表示注解类型可以被继承。如果类型声明中存在`@Inherited`元注解，则注解所修饰类的子类都将会继承此注解。

## @Repeatable

表示注解可以重复使用。

# 自定义注解

使用`@interface`自定义注解时，自动继承了`java.lang.annotation.Annotation`接口，由编译程序自动完成其他细节。在定义注解时，不能继承其他的注解或接口。`@interface`用来声明一个注解，其中的每个方法实际上是声明了一个配置参数。方法的名称就是参数的名称，返回值类型就是参数的类型（返回值类型只能是基本类型、Class、String以及enum）。可以通过`default`来声明参数的默认值。

## 注解定义

注解语法格式如下：

```java
public @interface 注解名 { 定义体 }
```

## 注解属性

注解属性的语法格式如下：

```JAVA
[访问级别修饰符]  [数据类型]  名称() default 默认值;
```

定义注解属性有以下要点：

+ 定义属性时，属性名后面需要加`()`；
+ 注解属性只能使用`public`或默认访问级别修饰；
+ 注解属性数据类型有以下限制要求：
  + 基本数据类型（byte、char、short、int、long、float、double、boolean）
  + String类型
  + Class类型
  + enum类型
  + Annotation类型
  + 以上类型的数组
+ 注解属性需要有确定的值，建议指定默认值。注解属性只能通过指定默认值或使用注解时指定属性值。注解属性如果是引用类型时不可以为null。
+ 注解中只有一个属性值，最好将其命名为value，因为当属性名为value时，在使用注解时，可以直接指定value的值而不指定属性名称。

## 注解处理器

如果没有用来读取注解的方法和工作，那么注解就等同于注释。使用注解的过程中，很重要的一部分就是创建与使用注解处理器。JDK5扩展了反射机制的API,以帮助程序员快速的构造自定义注解处理器。

`java.lang.annotation.Annotation`是一个接口，程序可以通过反射来获取制定程序元素的注解对象，然后通过注解对象来获取注解里面的元数据。

除此之外，Java中支持注解处理器接口，`java.lang.reflect.AnnotatedElement`，该接口代表程序中可以接受注解的程序元素，该接口主要有如下几个实现类：

+ Class：类定义
+ Constructor：构造器定义
+ Field：类成员变量定义
+ Method：类方法定义
+ Package：类的包定义

`AnnotatedElement`接口是所有程序元素的父接口，所以程序通过反射获取了某个类的`AnnotatedElement`对象之后，程序就可以调用该对象的如下四个方法来访问注解信息：

+ getAnnotation：返回该程序元素上存在的、指定的类型的注解，如果该类注解不存在，则返回null
+ getAnnotations：返回该程序元素上的所有注解
+ isAnnotationPresent：判断该程序元素上是否包含指定类型的注解，存在返回True，否则返回False
+ getDeclaredAnnotations：返回直接存在于此元素上的所有注释（忽略继承的注释）；

代码示例：

```java
//声明自定义注解DEMO

public class FindFiles {

	//声明一个可作用域字段或属性的注解
	@Target(ElementType.FIELD)
	//该注解运行时有效
	@Retention(RetentionPolicy.RUNTIME)
	//使用Javadoc
	@Documented
	//可以被继承
	@Inherited
	public @interface AnnotationColumn {
  	public String name() default "fieldName";
  	public String setFuncName() default "setField";
  	public String getFuncName() default "getField";
  	public boolean defaultDBValue() default false;
	}

	@Target(ElementType.METHOD)
	@Retention(RetentionPolicy.RUNTIME)
	@Repeatable(FileTypes.class)
	public @interface FileType {
 	 String value();
	};

	@Target(ElementType.METHOD)
	@Retention(RetentionPolicy.RUNTIME)
	public @interface FileTypes {
  	FileType[]  value();
	}
	
  
  @FileType(".java")
  @FileType(".js")
  @FileType(".css")
  @FileType(".html")
  public void work() {
    try {
      FileType[] fileTypes = this.getClass().getMethod("work").getAnnotationByType(FileType.class);
      System.out.println("Find content from these file of types:");
      for(FileType f : fileTypes) {
        System.out.println(f.value());
      }
      System.out.println("processing...");
    } catch (NoSuchMethodException | SecurityException e) {
      e.printStackTrace();
    }
  }
  
  public static void main(String[] args) {
    new FindFiles().work();
  }
}


// demo2
public class RepeatableDemo {

    @Target({ElementType.TYPE})
    @Retention(RetentionPolicy.RUNTIME)
    @Documented
    @Repeatable(Roles.class)
    @interface Role{
        String value() default "";
    }


    @Target(ElementType.TYPE)
    @Retention(RetentionPolicy.RUNTIME)
    @Documented
    @interface Roles {
        Role[] value();
    }


    //只有一个属性且名称为value时，可直接赋值，属性名-value省略
    @Role("admin")
    @Role("dev")
    @Role("ops")
    class User {
        private String name;

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }
    }

    public static void main(String[] args) {
        if (User.class.isAnnotationPresent(Roles.class)) {
            Roles roles = User.class.getAnnotation(Roles.class);
            System.out.println("User role is : ");
            for (Role r : roles.value()) {
                System.out.println(r.value());
            }
        }
    }
}
```




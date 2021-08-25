---
title: Java编程自学之路：容器
categories: Program
tags: java
date: 2021-07-30
author: Semon
---

# 简介

## 数组与容器

Java中最常用的存储结构就是数组与容器，二者的区别为：

+ 存储大小是否固定：
  + 数组创建后长度固定；
  + 容器创建后可自动扩容；
+ 存储元素类型：
  + 数组即可存储基本类型，也可存储引用类型；
  + 元素只能存储引用类型，基本类型需通过包装类转换后才能存入容器；

## 容器框架

Java容器框架主要分为`Collection`和`Map`两种；其中，`Collection`又可细分为`List`、`Set`和`Queue`；

+ `Collection`：一个独立元素的序列，这些元素需要服从一条或多条规则；
  + `List`：按照插入书序保存元素；
  + `Set`：不能保存重复元素；
  + `Queue`：按照排序规则来确定对象产生的顺序（默认与插入顺序一致）；
+ `Map`：一组成对的`K-V`对象，允许使用键来查找值；

## 容器基本机制

Java容器具有一定的共性，他们全部或部分依赖以下技术：

+ 泛型
+ `Iterator`和`Iterable`
+ `Comparator`和`Comparable`
+ `Cloneable`
+ `fail-fast`

### 泛型

JDK5开始引入泛型技术；

Java容器通过泛型技术来保证其内部数据的类型安全；

什么是类型安全呢？

举例来说：如果有一个`List<Object>`容器，Java编译器在编译时不对原始类型进行类型安全检查，但会对带参数的类型进行检查，通过使用`Object`作为类型，可以告知编译器该方法可以接受任何类型的对象，如`Integer`、`String`等；

### Iterator和Iterable

`Iterator`与`Iterable`的目的在于支持遍历访问容器内部元素；

`Collection`接口扩展了`Iterable`接口；

迭代可以简单理解为遍历，是一个标准化遍历各类容器里面的所有对象的接口。它是一种经典的设计模式 — 迭代器模式（`Iterator`）；

> 迭代器模式：提供一种方法顺序访问一个聚合对象中各个元素，而又无需暴露该对象的内部表示；

### Comparator和Comparable

`Comparable`是排序接口；

类实现了`Comparable`接口，该类实例便可以进行比较及排序；

实现了`Comparable`接口类对象的容器可通过`Collection.sort`或`Arrays.sort`进行自动排序；

`Comparator`是比较接口；

对于不支持排序的类,可通过创建该类的比较器来支持排序,比较器需实现`Comparator`接口；

> Java容器中，有些容器默认支持排序，如`TreeMap`、`TreeSet`等，可以通过传入`Comparator`来定义内部元素的排序规则；

### Cloneable

Java中一个类要实现克隆功能，则必须实现`Cloneable`接口，否则调用`clone()`方法时会报`CloneNotSupportedException`异常；

Java中所有类都继承自`java.lang.Object`类，`java.lang.Object`类中有一个方法`clone()`，该方法返回`Object`对象的一个浅拷贝；

> 浅拷贝基本类型返回其属性；浅拷贝引用类型返回其引用地址；

### fail-fast

`fail-fast`是Java容器的一种错误检测机制；当多个线程对容器进行结构上的更改操作时，可能会触发`fail-fast`机制；

容器在迭代操作中改变元素个数（添加、删除元素）都可能会导致`fail-fast`，抛出`java.util.ConcurrentModificationException`异常；

**fail-fast解决方案：**

+ 遍历过程中对涉及改变容器个数的地方全部添加`synchronized`或者直接`Collections.synchronizedXXX`容器，但会因此造成同步锁阻塞遍历操作，影响吞吐量；
+ 使用并发容器，如：`CopyOnWriteArrayList`等；

## List

`List`是一个接口，继承于`Collection`，代表着有序的队列；

`AbstractList`是一个抽象类，继承于`AbstractCollection`，并实现了`List`接口中除`size()`、`get()`之外的所有函数；

`AbstractSequentialList`是一个抽象类，继承于`AbstractList`，实现了链表根据索引操作链表的全部函数；

### 常用实现类

`List`的常用实现类有：`ArrayList`、`LinkedList`、`Vector`和`Stack`：

+ `ArrayList`：
  + 基于动态数组实现，存在容量限制，但支持自动扩容；
  + 随机访问速度快，但随机插入、删除元素慢；
  + 线程不安全；
+ `LinkedList`：
  + 基于双链表实现，不存在容量限制；
  + 随机插入、删除快，但随机访问慢
  + 线程不安全
+ `Vector`：
  + 与`ArrayList`类似，主要方法都是`synchronized`方法；
  + 线程安全
+ `Stack`：
  + 继承于`Vector`类，是同步容器；
  + 线程安全

> `Vector`和`Stack`因效率问题，已基本被废弃，使用对应的并发容器替代；



### ArrayList

`ArrayList`从数据结构来看，可以视为支持动态扩容的线性表；

`ArrayList`是一个数组队列，相当于动态数组；`ArrayList`默认初始化容量大小为10；

`ArrayList`容量达到阈值后，会自动进行扩容，每次自动扩容为当前容量的1.5倍；因此尽量在初始化时指定合适的初始化容量大小，减少自动扩容产生的性能开销；

`ArrayList`定义：

```java
public class ArrayList<E> extends AbstractList<E> implements List<E>,RandomAccess,Cloneable,Serializable { 
	//默认初始化容量
	private static final int DEFAULT_CAPACITY = 10;
	//对象数组
	transient Object[] elementData;
	//数组长度
	private int size;
  
}
```

说明：

+ 实现了`List`接口，并继承`AbstractList`,支持所有的`List`操作；
+ 实现了`RandomAccess`接口，支持随机访问；
+ 实现了`Cloneable`接口，支持深拷贝；
+ 实现了`Serializable`接口，支持序列化，能够通过序列化方式传输；
+ 线程不安全；
+ 数据结构：
  + `size`：内部动态数组的实际大小；
  + `eleemtnData`：保存添加到`ArrayList`中元素的对象数组；
+ 构造方法：
  + 默认构造方法，无参数，创建一个默认大小空数组；
  + 创建`ArrayList`对象时，传入数组初始大小参数；
  + 创建`ArrayList`对象时，传入一个集合进行初始化；
+ 操作元素：
  + 访问元素：直接通过下标访问，时间复杂度为O(1);
  + 添加元素：调用`add()`方法添加
    + 添加到任意位置：会导致该位置后的所有元素都需要重新排列；
    + 添加到数组末尾：在没有扩容的前提下，不会有元素复制排序过程；
  + 删除元素：调用`remove()`方法移除
    + 与添加元素到任意位置类似，每次删除操作，都会触发数组重拍；删除元素位置越靠前，数组重排开销越大；具体实现为通过`System.arrayCopy()`循环向前复制移动；
+ 序列化：`ArrayList`具有动态扩容特性，数组保存的元素不一定都会使用，但实现了序列化接口默认会将数组所有元素进行序列化。为提升性能，`ArrayList`定制了其序列化方式，具体逻辑为：
  + 存储元素的`Object`数组使用`transient`修饰，使得它可以被Java序列化忽略；
  + 重写`writeObject()`和`readObject()`来控制序列化数组中有元素填充的部分内容；

### LinkedList

`LinkedList`从数据结构角度来看，可以视为双链表；

`LinkedList`基于双链表实现，因此顺序访问会非常高效，但随机访问效率较低；

`LinkedList`定义：

```java
public class LinkedList<E> extends AbstractSequentialList<E>  implements List<E>, Cloneable,Serializable {
  transient int size = 0;
	transient Node<E> first;
	transient Node<E> last;

	private static class Node<E> {
 	 	E item;
 	 	Node<E> next;
 	 	Node<E> prev;
	}
}
```

说明：

+ 实现了`List`接口，并继承了`AbstractSequentialList`，支持所有`List`操作；
+ 实现了`Deque`接口，可以被当做队列或双向队列操作，也可以用来实现栈；
+ 实现了`Cloneable`接口，支持深拷贝；
+ 实现了`Serializable`接口，支持序列化；
+ 线程不安全；
+ 数据结构：
  + `size`：表示双链表中节点个数，初始为0；
  + `first`：表示双链表的头结点；
  + `last`：表示双链表的尾结点；
  + `Node`：`LinkedList`的内部类，表示链表中的元素实例，包含3个元素：
    + `prev`：指向当前节点的上一个节点；
    + `next`：指向当前节点的下一个节点；
    + `item`：当前节点包含的值；
+ 操作元素：
  + 访问元素：通过`get()`方法按照`index`获取元素；
  + 添加元素：调用`add()`方法添加元素
    + 新增数据包装为`Node`；
    + 如果向头部添加元素，则将头指针指向新的`Node`，之前的`first`对象`prev`指向新的`Node`；
    + 如果想维护添加元素，则将尾指针指向新的`Node`，之前的`last`对象`next`指向新的`Node`；
  + 删除元素：调用`remove()`方法删除元素
    + 遍历找到要删除的元素节点，调用`unlink`方法删除节点；
    + `unlink`删除节点：
      + 如果当前节点有前驱节点，则让前驱节点指向当前节点的下个节点，否则让双链表头指针指向下一个节点；
      + 如果当前节点有后继节点，则让后继节点指向当前节点的上个节点，否则让双链表的尾指针指向上一个节点；
  + 序列化：`LinkedList`也定制化了自身的序列化方式；具体实现为：
    + 将`size`、`first`、`last`修饰为`transient`，使得它们Java序列化所忽略；
    + 重写`writeObject()`和`readObject()`来控制序列化，只处理双链表中能被头结点链式引用的节点元素；

### List常见问题

**Arrays.asList转换不支持基本类型数组**

通常使用`Arrays.asList`来将数据转换为列表，但在对基本类型数组进行转换时，`Arrays`工具类会将整个数组当做一个类型为泛型`T`的对象进行转换，正确的转换方式为：

+ 将基础类型数组转换为包装类数组后，在进行转换；
+ JDK8可以使用`Arrays.stream`方法来进行转换；

```java
//M1
Integer[] arr2 = {1,2,3};
List list2 = Arrays.asList(arr2);

// M2
int[] arr1 = {1,2,3};
List list1 = Arrays.stream(arr1).boxed().collect(Collectors.toList());
```

**Arrays.asList转换列表不支持增删操作**

`Arrays.asList`返回的`List`并不是我们期望的`java.util.ArrayList`，而是`Arrays`的内部类`ArrayList`，该内部类继承自`AbstractList`，但并没有覆写`add()`和`remove()`方法。所以通过`Arrays.asList`转换得到的`List`不支持增删操作；

**Arrays.asList转换列表受原始数组变更影响**

`Arrays.asList`转换得到的`List`实际上复用了原始的数组，当原始数组元素发生改变时，`List`元素也会同步变更；如果希望切断两者之间的联系，可以使用转换后的结果来`new`一个新的列表；

```java
String[] str = {"a", "b", "c"};

//lt1受str元素变更影响
List lt1 = Arrays.asList(str);
//lt2不受str元素变更影响
List lt2 = new Arrays.asList(str);
```

**List.subList返回队列与原队列共享内存**

`List.subList`直接引用了原始的`List`，也可以认为是共享“存储”，而且对原始`List`进行结构性修改会导致`SubList`出现异常；解决方案如下：

+ 利用`List.subList`返回的结果重新`new ArrayList`，在构造方法中传入`SubList`来构建一个独立的`ArrayList`；
+ JDK8使用`Stream`的`skip`和`limit`API来跳过流中的元素，以及显示流中的元素个数，同样可以达到`SubList`切换的目的；

```java
//m1
List<Integer> subList = new ArrayList<>(list.subList(1,4));
//m2
List<Integer> subList2 = list.stream().skip(1).limit(3).collect(Collectors.toList());
```

## Map

`Map`提供了一个通用的元素存储方法。`Map`容器用于存储元素值对(`K-V`)，其中每个键映射到一个值；

### 常用接口/抽象类

#### Map接口

`Map`接口定义：

```java
public interface Map<K,V> {}
```

`Map`接口提供3种容器视图，允许以键集、值集以及键-值集的方式访问数据；

`Map`接口的实现类应提供2个标准的构造方法：

+ 无参构造方法，用于创建空`Map`；
+ 单个`Map`类型参数的构造方法，用于创建一个与参数具有相同键值映射关系的新`Map`；

实际上，单参构造方法允许复制任意`Map`，生成一个所需类的`Map`；JDK不强制执行此建议，但JDK中所有通用`Map`实现都遵循它；

#### `Map.Entry`接口

`Map.Entry`接口一般用于通过迭代器访问`Map`；

`Map.Entry`是`Map`接口内部的一个接口，`Map.Entry`代表了键值对实体，`Map`通过`entrySet()`获取`Map.Entry`集合，从而通过该集合实现对键值对的操作；

#### AbstractMap抽象类

`AbstractMap`定义如下：

```java
public abstract class AbstractMap<K,V> implements Map<K,V> {}
```

+ 实现不可修改的`Map`，扩展此类并提供`entrySet()`方法的实现，该方法返回`Map`的映射关系`Set`视图；此`Set`不支持`add()`和`remove()`方法；
+ 实现可修改的`Map`，程序员需自行实现`put()`方法；`entrySet().iterator()`放回的迭代器也必须另外实现`remove()`方法；

`AbstractMap`提供了`Map`接口的核心实现，可最大限度减少实现`Map`接口所需工作；

#### SortedMap接口

`SortedMap`定义如下：

```java
 public interface SortedMap<K,V> extends Map<K,V> {}
```

+ 构造方法：
  + 无参构造方法：创建一个空的有序`Map`，按照自然排序进行排序；
  + 带有`Comparator`类型参数的构造方法，创建一个空的有序`Map`，根据指定比较器进行排序；
  + 带有`Map`类型参数的构造方法，创建一个新的有序`Map`，其键值映射关系与参数相同，按照键的自然排序；
  + 带有`SortedMap`类型参数的构造方法，创建一个新的有序`Map`，其键值映射关系和排序方法与输入的有序`Map`相同；

#### NavigableMap接口

`NavigableMap`定义如下：

```java
public interface NavigableMap<K,V> extends SortedMap<K,V> {}
```

`NavigableMap`提供了获取键、键值对、建集、键值对集的相关方法：

+ 获取键值对：
  + `lowerEntry`、`floorEntry`、`ceilingEntry`、`higherEntry`，分别返回小于、小于等于、大于等于或大于给定键的建关联`Map.Entry`对象；
+ 移除键值对：
  + `pollFirstEntry`、`pollLastEntry`，移除最小、最大映射关系；
+ 获取键：
  + `lowerKey`、`floorKey`、`ceilingKey`和`higherKey`，分别返回小于、小于等于、大于等于、大于给定键的键；
+ 获取键的集合：
  + `NavigableKeySet`、`descendingKeySet`分别获取正序/倒序的键集；

#### Dictionary抽象类

`Dictionary`定义如下：

```java
public abstract class Dictionary<K,V> {}
```

`Dictionary`是JDK1.0定义的操作键值对的抽象类，包括了操作键值对的基本方法；

### HashMap

`HashMap`是最常用的`Map`接口实现类；

`HashMap`以散列方式存储键值对；

`HashMap`允许使用空值和空键，其中元素不保序，元素顺序可能会随着时间的推移变化；

`HashMap`是线程不安全的；

`HashMap`有两个影响其性能的参数：初始容量和负载因子；

+ 初始容量：指散列表创建时的初始大小；
+ 负载因子：指散列表在其容量自动扩容之前被允许的最大饱和量；当哈希表中的`entry`数量超过负载因子与当前容量的乘积时，散列表会被重新映射，一般散列表是存储桶数量的两倍；

`HashMap`定义如下：

```java
public class HashMap<K,V> extends AbstractMap<K,V> implements Map<K,V>, Cloneable, Serializable {
  //该表在初次使用时初始化，分配长度总是2的幂
  transient Node<K,V>[] table;
  //保存缓存的entrySet()
  transient Set<Map.Entry<K,V>> entrySet;
 	//map中的键值对数量
  transient int size;
  //HashMap结构修改次数
  transient int modCount;
  //下一个调整大小的值
  int threshold;
  //散列表的加载因子,默认为0.75
  final float loadFactor;
  
  public HashMap();
  public HashMap(int initCapacity); //以initCapacity初始化容量,默认加载因子0.75
  public HashMap(int initCapacity, float loadFactor); //以initCapacity初始化容量,loadFactor为加载因子
  public HashMap(Map<? extends K, ? extends V> map); //以一个已有map内容、默认负载因子0.75
}
```

说明：

+ 数据结构：

  + `table`：`HashMap`使用一个`Node<K,V>[]`类型的数组`table`来存储元素；
  + `size`：初始容量，默认为16，容量不足时自动扩容，扩容结果为2次幂（即扩展为原来的2倍）；
  + `factor`：负载因子，默认为0.75，自动扩容之前允许的最大饱和度；

+ 操作元素：

  + 获取元素：调用`get()`方法，通过键查找值；
  + 添加元素：调用`put()`方法，通过键更新值或插入键；

+ `hash()`方法：

  `HashMap`计算桶下表`index`的公式为：：`(n-1) & key.hashCode() ^ (h>>>16)；`其中n为table的长度，默认为16。

  <img src="Java编程自学之路4-容器/image-20210731011455070.png" alt="hash算法" style="zoom:90%;" />

+ `resize()方法`:

  当散列表容量达到阈值后，自动将`bucket`扩充为原来的2倍，然后重新计算`index`，然后将节点重新放回`bucket`中；扩容后的元素，要么保留在原位置，要么在原位置移动2次幂的位置；

  元素在重新计算`hash`后，因为N变为原来的2倍，那么N-1的`mask`范围在高位多1位，因此新的`index`会发生如下变化：

  <img src="Java编程自学之路4-容器/image-20210731012002642.png" alt="扩容后hash计算" style="zoom:90%;" />

  因此，在扩充`HashMap`的时候，不需要重新计算`hash`，只需要看原来的`hash`值新增`bit`是1还是0即可；若为0，则下标不变；若为1则下边变更为“原索引+原容量大小”；如下图所示：

  <img src="Java编程自学之路4-容器/image-20210731012259711.png" alt="扩容后键值分布" style="zoom:80%;" />

### LinkedHashMap

`LinkedHashMap`通过维护一个保存所有条目`(Entry)`的双向链表，保证了元素迭代的顺序（插入顺序）；

`LinkedHashMap`允许`key`和`value`为`null`；

`LinkedHashMap`允许插入重复数据，若`key`相同则覆盖，`value`允许重复；

`LinkedHashMap`默认按照元素插入顺序进行存储；

`LinkedHashMap`是线程不安全的；

`LinkedHashMap`定义如下：

```java
public class LinkedHashMap<K,V> extends HashMap<K,V> implements Map<K,V> {
  transient LinkedHashMap.Entry<K,V>  head;
  transient LinkedHashMap.Entry<K,V>  tail;
  
  //排序算法， true -- access method   false -- insert
  final boolean accessOrder;
}
```

说明：

+ 通过维护一对`LinkedHashMap.Entry<K,V>`类型的头尾指针，以双链表形式，保存所有数据；
  + 继承`HashMap`的`put`方法，但并未实现`put`方法；

### TreeMap

`TreeMap`基于红黑树实现；

`TreeMap`是有序的，排序规则为：根据`map`中`key`的自然语义顺序或提供的比较器(`Comparator`)定义的比较顺序；

`TreeMap`不允许出现重复的`key`，且不允许`key`为`null`；

`TreeMap`是线程不安全的；

### WeakHashMap

`WeakHashMap`是一个散列表，存储内容为键值对，且键值都可以为`null`；

`WeakHashMap`是不同步的；可以使用`Collections.synchronizedMap`方法来构造同步的`WeakHashMap`；

`WeakHashMap`的键是弱键，当某个键不再被其它对象引用，会被从`WeakHashMap`中自动移除；原理为通过`WeakReference`和`ReferenceQueue`实现。

`WeakHashMap`的`key`是弱键，即`WeakReference`类型的，`ReferenceQueue`是一个队列，它是会被GC回收的弱键，实现步骤为：

+ 创建`WeakHashMap`，将键值添加到`WeakHashMap`中，
  + `WeakHashMap`通过`table`保存`Entry`；每个`Entry`实际上是一个单向链表，即`Entry`是键值对链表；
+ 当弱键不在被其它对象引用，并被GC回收时，该弱键也会同时添加到`ReferenceQueue`队列中；
+ 当下次操作`WeakHashMap`时，会先同步`table`和`queue`；`table`中保存了全部的键值对，而`queue`中保存被GC回收的键值对；同步它们，即删除`table`中被GC回收的键值对；

`WeakHashMap`定义如下：

```java
public class WeakHashMap<K,V> extends AbstractMap<K,V> implements Map<K,V> {}
```

## Set

`Set`注重独一无二性质，不能存储重复元素；

### 常用接口/抽象类

#### Set接口

`Set`继承了`Collection`接口；实质上就是一个`Collection`；

#### SortedSet接口

`SortedSet`中的内容是排序的唯一值，排序的方法是通过`Comparator`完成的；

`SortedSet`接口扩展了一些新方法：

+ `comparator`：返回一个`Comparator`
+ `subSet`：返回指定区间的子集
+ `headSet`：返回小于指定元素的子集
+ `tailSet`：返回大于指定元素的子集
+ `first`：返回第一个元素
+ `last`：返回最后一个元素

#### NavigableSet接口

`NavigableSet`继承了`SortedSet`，它丰富了一系列查找方法：

+ `lower`：返回小于指定值的元素中最接近的元素
+ `higher`：返回大于指定值的元素中最接近的元素
+ `floor`：返回小于或等于指定值的元素中最接近的元素
+ `ceiling`：返回大于或等于指定元素中最接近的元素
+ `pollFirst`：检索并移除第一个(最小的)元素
+ `pollLast`：检索并移除最后一个(最大的)元素
+ `descendingSet`：返回反序排列的`Set`
+ `descendingIterator`：返回反序排列的`Set`的迭代器

#### AbstractSet抽象类

`AbstractSet`类提供`Set`接口的核心实现，已最大限度减少实现`Set`接口所需的工作；

### HashSet

`HashSet`类依赖于`HashMap`，它实际上是通过`HashMap`实现的。`HashSet`中的元素是无序的、散列的；

`HashSet`通过继承`AbstractSet`实现了`Set`接口中的骨干方法；

`HashSet`实现了`Cloneable`，支持拷贝；

`HashSet`实现了`Serializable`，支持序列化；

`HashSet`中存储的元素是无序的；

`HashSet`允许`null`值的元素；

`HashSet`线程不安全；

`HashSet`定义如下：

```java
public class HashSet<E> extends AbstractSet<E> implements Set<E>, Cloneable, Serializable {

  private transient HashMap<E,Object> map;
 
  private static final Object PRESENT = new Object();
}
```

说明：

+ 维护了一个`HashMap`对象，围绕该对象实现了`add()`、`remove()`、`Iterator()`、`clear()`、`size()`方法；
+ 通过定义`readObject()`和`writeObject()`方法确定其序列化机制；
+ 定义`PRESENT`用于关联`map`中当前操作元素；

### TreeSet

`TreeSet`类依赖于`TreeMap`，实际上是通过`TreeMap`实现的。`TreeSet`中的元素是有序的，它是按自然排序或者用户指定比较器排序的`Set`；

`TreeSet`通过继承`AbstractSet`实现了`NavigableSet`接口中的骨干方法；

`TreeSet`实现了`Cloneable`，支持克隆；

`TreeSet`实现了`Serializable`，支持序列化；

`TreeSet`存储的元素是有序的；排序规则是自然顺序或比较器`Comparator`中提供的顺序规则；

`TreeSet`不允许`null`值元素；

`TreeSet`线程不安全；

`TreeSet`定义如下：

```java
public class TreeSet<E> extends AbstractSet<E> implements NavigableSet<E>,Cloneable,Serializable {
  private transient NavigableSet<E, Object> m;
  
  private static final Object PRESENT = new Object();
}
```

说明：

+ 维护了一个`NavigableSet`对象（实质上是一个`TreeMap`），围绕该对象实现了`add()`、`remove()`、`iterator()`、`clear()`、`size()`方法；
+ 定义`PRESENT`用于关联`map`中当前元素；
+ `TreeSet`中的元素都被当成了`TreeMap`的`key`来存储，而`value`为`PRESENT`;

### LinkedHashSet

`LinkedHashSet`是按插入顺序排序的`Set`；

`LinkedHashSet`通过继承`HashSet`实现了`Set`接口中的骨干方法；

`LinkedHashSet`实现了`Clonebale`，支持克隆；

`LinkedHashSet`实现了`Serializable`，支持序列化；

`LinkedHashSet`中存储的元素是按照插入顺序保存的；

`LinkedHashSet`线程不安全；

`LinkedHashSet`定义如下：

```java
public class LinkedHashSet<E> extends HashSet<E> implements Set<E>, Cloneable, Serializable {
  
  public LinkedHashSet(int initialCapacity, float loadFactor) {
    super(initialCapacity,loadFactor,true);
  }
  
  public LinkedHashSet(int initialCapacity) {
    super(initialCapacity,.75f,true);
  }
  
  public LinkedHashSet() {
    super(16,.75f,true);
  }
}
```

### EnumSet

`EnumSet`继承了`AbstractSet`，实现了`Set`接口中的骨干方法；

`EnumSet`实现了`Cloneable`，支持克隆；

`EnumSet`实现了`Serializable`，支持序列化；

`EnumSet`通过`<E extends Enum<E>>`限定了存储元素必须为枚举型；

`EnumSet`没有构造方法，只能通过类中的`static`方法来创建`EnumSet`对象；

`EnumSet`是有序的，以枚举值在`EnumSet`类中的定义顺序来决定集合元素的顺序；

`EnumSet`线程不安全；

`EnumSet`定义如下：

```java
public static class EnumSet<E extends Enum<E>> extends AbstractSet<E> implements Cloneable, Serializable {}
```

## Queue

`Queue`是一种先进先出的数据结构；

### 常用接口/抽象类

#### Queue接口

`Queue`继承于`Collection`接口；除了支持集合的基本操作外，还提供了额外的插入、提取和检查操作；

#### AbstractQueue抽象类

`AbstractQueue`类提供`Queue`接口的核心实现，以最大限度地减少实现`Queue`接口所需的工作；

`AbstractQueue`定义如下：

```java
public abstract class AbstractQueue<E> extends AbstractCollection<E>  implements Queue<E> {}
```

#### Deque接口

`Deque`是`double ended queue`的缩写，即双端队列；`Deque`继承了`Queue`接口，并扩展支持在队列两端插入和删除元素；

支持特定方法：

+ 尾部插入：`addLast(e)`、`offerLast(e)`
+ 尾部删除：`removeLast()`、`pollLast(e)`

> `Deque`支持有容量限制，也支持没有固定大小限制；

### ArrayDeque

`ArrayDeque`是`deque`的顺序表实现；

`ArrayDeque`用一个动态数组实现了栈和队列所需的所有操作；

### PriorityQueue

`PriorityQueue`是一个优先级队列，是不同于先进先出队列的另一种队列；默认按照自然顺序排列，也就是数字默认小的在队列头，字符串按字典序列排序；

`PriorityQueue`实现`Serializable`，支持序列化；

`PriorityQueue`类是无界优先级队列；

`PriorityQueue`元素按自然顺序或`Comparator`提供的顺序排序；

`PriorityQueue`不接受`null`值元素；

`PriorityQueue`线程不安全；

`PriorityQueue`定义如下：

```java
public class PriorityQueue<E> extends AbstractQueue<E> implements Serializable {}
```


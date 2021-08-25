---
title: Java编程自学之路：IO模型
categories: Program
tags: java
date: 2021-08-03
author: Semon
---

# UNIX I/O模型

UNIX I/O模型有5种：

+ 同步阻塞I/O
+ 同步非阻塞I/O
+ I/O多路复用
+ 信号驱动I/O
+ 异步I/O

## 同步阻塞I/O

用户线程发起读取调用后阻塞，让出CPU。内存等待数据到来后，将数据拷贝到内核空间，接着拷贝到用户空间后，唤醒阻塞的用户线程。

## 同步非阻塞I/O

用户线程不断发起读取调用，数据拷贝到内核空间前，每次都返回失败，直到数据到达内核空间，这次调用后，等待数据从内核空间拷贝到用户空间时，线程仍然是阻塞的，等到数据到达用户空间再把用户线程唤醒。

## I/O多路复用

用户线程将读取数据操作拆分为两步，线程先发起查询调用，目的是确认内核数据是否准备好；等内核将数据准备好之后，用户线程再发起读取调用，在等待数据从内核空间拷贝到用户空间的过程，线程是阻塞的；因为一次查询调用可核查多个数据通道的状态，所以叫多路复用；

## 信号驱动I/O

首先开启`Socket`的信号驱动I/O功能，并安装一个信号处理函数，进程继续运行并不阻塞。当数据准备好时，进程会收到一个SIGIO信号，可以在信号处理函数中调用I/O操作函数处理数据。信号驱动式I/O模型的优点是我们在数据报到达期间进程不会阻塞，我们只要等待信号处理函数的通知即可。

## 异步I/O

用户线程发起读取调用的同时注册一个回调函数，读取调用后立即返回，等内核将数据准备好后，再调用指定的回调函数完成处理。并且在这个过程中，用户线程一直没有阻塞。

# Java I/O模型

## BIO

> BIO（blocking IO）即阻塞IO。指的主要是传统的`java.io`包，它基于流模型实现。

### BIO简介

`java.io`包提供了我们最熟知的一些IO功能，比如`File`抽象、输入输出流等。交互方式为同步、阻塞的方式；也就是说，在读取输入流或者出入输出流时，在读、写动作完成之前，线程会一直阻塞，它们之间的调用是可靠的线性顺序。

很多时候，`java.net`下面提供的部分网络API，比如`Socket`、`ServerSocket`、`HttpURLConnection`等也归类到同步阻塞IO类库,因为网络通信同样是IO行为。

BIO的优点是代码比较简单、直观；缺点是IO效率和扩展性存在局限性，容易称为应用性能的瓶颈。

### BIO性能缺陷

采用BIO的服务端，通常由一个独立的`Acceptor`线程负责监听客户端链接。服务端一般在`while(true)`循环中调用`accept()`方法等待客户端的链接请求，一旦接收到一个链接请求，就可以建立`Socket`，并基于这个`Socket`进行读写操作。此时，不能再接收其他客户端链接请求，只能等待当前链接的操作执行完成。

如果要让BIO通信模型能够同时处理多个客户端请求，就必须使用多线程，但会造成不必要的线程开销。不过可以通过线程池机制改善，线程池还可以让线程的创建和回收成本相对较低。

虽然线程池能够略微优化性能，但是会消耗宝贵的线程资源，并且在百万级并发场景下也撑不住。并发访问量增加可能会导致线程数急剧膨胀，进而引发线程堆栈溢出、创建新线程失败等问题，最终导致进程宕机或僵死，无法对外提供服务。

## NIO

> NIO（non-blocking IO），即非阻塞IO。指的是Java 1.4中引入的`java.nio`包。

为了解决BIO的性能问题，Java 1.4中引入了`java.nio`包。NIO优化了内存复制以及阻塞导致的严重性能问题。

`java.nio`包提供了`Channel`、`Selector`、`Buffer`等新的抽象，可以构建多路复用的、同步非阻塞IO程序，同时提供了更接近操作系统底层的高性能数据操作方式。

### 使用缓冲区优化读写流

NIO与传统I/O不同，它是基于块（`Block`）的，它以块为基本单位处理数据。在NIO中，最为重要的两个组件是缓冲区（`Buffer`）和通道（`Channel`）。

`Buffer`是一块连续的内存块，是NIO读写数据的缓冲。`Buffer`可以将文件一次性读入内存再做后续处理，而传统的方式是边读文件边处理数据。`Channel`表示缓冲数据的源头或者目的地，它用于读取缓冲或者写入数据，是访问缓冲的接口。

### 使用DirectBuffer减少内存复制

NIO还提供了一个可以直接访问物理内存的类`DirectBuffer`。普通的`Buffer`分配的是JVM堆内存，而`DirectBuffer`包装类被回收时，会通过Java引用机制来释放该内存块。

### 优化I/O，避免阻塞

传统I/O的数据读写是在用户空间和内核空间来回复制，而内核空间的数据是通过操作系统层面的I/O接口从磁盘读取或写入。

NIO的`Channel`有自己的处理器，可以完成内核空间和磁盘之间的I/O操作。在NIO中，我们读取和写入数据都要通过`Channel`，由于`Channel`是双向的，所以读、写可以同时进行。

## AIO

> AIO（Asynchronous IO）即异步非阻塞IO，指的是Java 7中，对NIO有了进一步的改进，也称为NIO2，引入了异步非阻塞IO方式。

在Java7中，NIO有了进一步的改进，也就是NIO2，引入了异步非阻塞IO方式，也有很多人叫它AIO（`Asynchronous IO`）。异步IO操作基于事件和回调机制，可以简单理解为，可以简单理解为，应用操作直接返回，而不会阻塞在那里，当后台处理完成，操作系统会通知响应线程进行后续工作。

## 传统IO流

流从概念上来说是一个连续的数据流。当程序需要读数据的时候就需要使用输入流读取数据，当需要向外写数据的时候就需要输出流。

BIO中操作的流主要有两大类，字节流和字符流，两类根据流的方向都可以分为输入流和输出流。

+ 字节流
  + 输入字节流：`InputStream`
  + 输出字节流：`OutputStream`
+ 字符流
  + 输入字符流：`Reader`
  + 输出字符流：`Writer`

### 字节流

字节流主要操作字节数据或二进制对象。

字节流有两个核心抽象类：`InputStream`和`OutputStream`。所有的字节流对象都继承自这两个抽象类。

**文件字节流**

`FileOutputStream`和`FileInputStream`提供了读写字节到文件的能力。

文件流操作一般步骤：

+ 使用`File`类绑定一个文件；
+ 把`File`对象绑定到流对象上；
+ 进行读或写操作；
+ 关闭流；

`FileOutputStream`及`FileInputStream`示例：

```java
public class FileStreamDemo {
  private static final  String FILEPATH="demo.txt";
  
  public static void main(String[] args ) throws Exception {
    writeStream(FILEPATH);
    readStream(FILEPATH);
  }
  
  public static void writeStream(String filepath) throws IOException {
    
    File f = new File(filepath);
    
    OutputStream out = new FileOutputStream(f);
    //OutputStream out = new FileOutputStream(f,true);
    //添加参数true，表示对原文件进行内容追加；否则为覆写
    
    String str = "hello world!";
    byte[] bys = str.getBytes();
    out.write(bys);
    out.close();
  }
  
  public static void readStream(String filepath) throws IOException {
    File f = new File(filepath);
    
    InputStream in = new FileInputStream(f);
    
    byte[] bys = new byte[(int) f.length()];
    int len = in.read(bys);
    System.out.println("read data length : " + len);
    in.close();
    System.out.println("read data content is : " + new String(bys));
  }
}
```

**内存字节流**

`ByteArrayInputStream`和`ByteArrayOutputStream`是用来完成内存的输入和输出功能。

内存操作一般在生成一些临时信息时才使用，如果临时信息保存在文件中，还需要在有效期后删除文件，比较麻烦。

内存字节流示例：

```java
public class ByteArrayStreamDemo {
  
  public static void main(String[] args) {
    String str = "hello world!";
    ByteArrayInputStream bis = new ByteArrayInputStream(str.getBytes());
    ByteArrayOutputStream bos = new ByteArrayOutputStream();
    
    //wait for read data from memory
    int tmp =0;
    while ((tmp = bis.read()) != -1) {
      char c = (char) tmp;  //read number to char
      bos.write(Character.toLowerCase(c)); //modify char to lower
    }
    
    String newStr = bos.toString();
    try {
      bis.close();
      bos.close();
    } catch (IOException e) {
      e.printStackTrace();
    }
    
    System.out.println(newStr);
  }
}
```

**管道流**

管道流的主要作用是可以进行两个线程间通信。

如果要先进性管道通信，则必须把`PipedOutputStream`链接在`PipedInputStream`上。

管道流示例：

```java
public class PipedStreamDemo {
  public static void Main(String[] args) {
    Send s = new Send();
    Receive r = new Receive();
    
    try{
      s.getPos().connect(r.getPis());
    } catch (IOException e) {
      e.printStackTrace();
    }
    
    new Thread(s).start();
    new Thread(r).start();
  }
  
  static class Send implements Runnable {
    private PipedOutputStream pos = null;
    
    Send() {
      pos = new PipedOutputStream();
    }
    @Override
    public void run() {
      String str = "hello world!";
      try {
        pos.write(str.getBytes());
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
    
    PipedOutputStream getPos() {
      return pos;
    }
  }
  
  
  static class Receive implements Runnable {
    
    private PipedInputStream pis = null;
    
    Reveive() {
      pis = new PipedInputStream();
    }
    
    @Override
    public void run() {
      byte[] b = new byte[1024];
      int len = 0;
      try {
        len = pis.read(b);
      } catch (IOException e) {
        e.printStackTrace();
      }
      
      System.out.println("receive data is :" + new String(b,0,len));
    }
    
    
    PipedInputStream getPis() {
      return pis;
    }
  }
  
}
```

**对象字节流**

`ObjectInputStream`和`ObjectOutputStream`是对象输入输出流，一般用于对象序列化。

**数据操作流**

数据操作流提供了格式化读入和输出数据的方法，分别为`DataInputStream`和`DataOutputStream`。

数据操作流示例：

```java
public class DataStreamDemo {
  public static final String FILEPATH = "demo.txt";
  
  public static void main(String[] args) throws IOException {
    readStream(filepath);
    writeStream(filepath);
  }
  
  private static void writeStream(String filepath) throws IOException {
    File f = new File(filepath);
    
    DataOutputStream dos = new DataOutputStream(new FileOutputStream(f));
    
    String[] ns = {"apple","pear","lemon"};
    float[] prices = {12.3f,30.3f,50.5f};
    int[] nums  = {3,2,1};
    for(int i=0;i<ns.length;i++) {
      dos.writeChars(ns.[i]);
      dos.writeChar('\t');
      dos.writeFloat(prices[i]);
      dos.writeChar('\t');
      dos.writeInt(nums[i]);
      dos.writeChar('\n');
    }
    
    dos.close();
  }
  
  
  private static void readStream(String filepath) throws IOException {
    File f = new File(filepath);
    DataInputStream dis = new DataInputStream(new FileInputStream(f));
    
    String name = null;
    float price = 0.0f;
    int num = 0;
    char[] tmp = null;
    int len = 0;
    cahr c = 0;
     try {
       while(true) {
         tmp = new char[200];
         len = 0;
         while ((c = disreadChar()) != '\t') {
           tmp[len] = 0;
           len++;
         }
         name = new String(tmp,0,len);
         price = dis.ReadFloat();
         dis.readChar();
         num = dis.readInt();
         dis.readChar();
         System.out.printf("name: %s; price: %5.2f; num: %d\n", name,price,num)
       }
     } catch (EOFException e) {
       e.printStackTrace();
     }
    catch (IOException e) {
      e.printStackTrace();
    }
    
    dis.close();
  }
}
```

**合并流**

合并流的主要功能是将多个`InputStream`合并为一个`InputStream`。合并流的功能由`SequenceInputStream`完成。

```java
public class SequenceInputStreamDemo {
  
  public static void main(String[] args) throws Exception {
    InputStream is1 = new FileInputStream("demo1.txt");
    InputStream is2 = new FileInputStream("demo1.txt");
    SequenceInputStream sis = new SequenceInputStream(is1,is2);
    
    int tmp = 0;
    
    OutputStream os = new FileOutputStream("demo3.txt");
    while ((tmp = sis.read()) != -1) {
      os.write(tmp);
    }
    
    sis.close();
    is1.close();
    is2.close();
    os.close();
  }
}
```

### 字符流

字符流主要操作字符，一个字符等于两个字节。

字符流有两个核心类：`Reader`类和`Writer`类。所有的字符流类都继承自这两个抽象类。

**文件字符流**

文件字符流`FileReader`和`FileWriter`可以向文件读写文本数据。

文件字符流示例：

```java
public class FileReaderWriterDemo {
  
  private static final String FILEPATH = "demo.txt";
  
  public static void main(String[] args) throws IOException {
    
    writeStream(FILEPATH);
    System.out.println("content is :" + new String(readStream(FILEPATH)));
  }
  
  
  public static void writeStream(String filepath) throws IOException {
    
    File f = new File(filepath);
    
    Writer out = new FileWriter(f);
    
    String str = "hello world!";
    out.write(str);
    
    out.flush();
    out.close();
  }
  
  
  public void readStream(String filepath) throws IOException {
    
    File f = new File(filepath);
    
    Reader in = new FileReader(f);
    
    int tmp = 0;
    int len = 0;
    char[] c = new char[1024];
    while((tmp = in.read())!= -1) {
      c[len] = (char) tmp;
      len++;
    }
    System.out.println("file char nums is : " + len);
    
    in.close();
    return c;
  }
}
```

**字节流转字符流**

我们可以在程序中通过`InputStream`和`Reader`从数据源中读取数据，然后也可以在程序中将数据通过`OutputStream`和`Writer`输出到目标媒介中。

使用`InputStreamReader`可以将输入字节流转化为输入字符流；使用`OutputStreamWriter`可以将输出字节流转化为输出字符流。

字节流转字符流示例：

```java
public class StreamToCharacterDemo {
  public static void main(String[] args) throws IOException {
    
  }
  
  public stream2Writer(String filepath) {
    File f = new File("demo.txt");
    Writer out = new OutputStreamWriter(new FileOutputStream(f));
    out.write("hello world!");
    out.close();
  }
  
  public stream2Reader(String filepath) {
    File f =new File("demo1.txt");
    Reader in = new InputStreamReader(new FileInputStream(f));
    char[] c = new cahr[1024];
    int len = in.read(c);
    in.close();
    System.out.println(new String(c,0,len));
  }
}
```

### 字符流vs字节流

**相同点：**

字节流与字符流都有`read()`、`write()`、`flush()`、`close()`方法。这决定了他们的操作方式相似。

**不同点：**

+ 数据类型：
  + 字节流的数据是字节（二进制数据）。主要核心类是`InputStream`类和`OutputStream`类；
  + 字符流的数据是字符，一个字符等于两个字节。主要核心类是`Reader`和`Writer`类；
+ 缓冲区：
  + 字节流在操作时本身不会用到缓冲区，是文件直接操作的；
  + 字符流在操作时是使用了缓冲区，通过缓冲区再操作文件；

**使用场景：**

+ 纯文本：能同时支持字符流和字节流；
+ 媒体类文件：图片、影音文件等只能以字节流进行读写；

# Java NIO模型

## NIO简介

NIO是一种同步非阻塞的I/O模型，在Java1.4中引入的NIO框架，对应的`java.nio`包，提供了`Channel`、`Selector`、`Buffer`等抽象。

NIO中的N可以理解为Non-blocking，不单纯是New。它支持面向缓冲的，基于通道的I/O操作方法。NIO提供了与传统BIO模型中的`Socket`和`ServerSocket`相对应的`SocketChannel`和`ServerSocketChannel`两种不同的套接字通道实现，两种通道都支持阻塞和非阻塞两种模式。阻塞模式使用就像传统中的支持一样，比较简单，但是性能和可靠性较差；非阻塞模式正好相关，对于低负载、低并发的应用程序，可以使用同步阻塞I/O来提升开发速率和更好的维护性；对于高负载、高并发的网络用用，使用NIO的非阻塞模式来来发。

### NIO与BIO区别

**Non-blocking IO（非阻塞）**

BIO是阻塞的，NIO是非阻塞的。

BIO的各种流是阻塞的。这意味着，当一个线程调用`read()`或`write()`时，该线程被阻塞，知道一些数据被读取，或者数据完全写入。在此期间，该线程不能再干其他任何事。

NIO使我们可以进行非阻塞IO操作。比如说，单线程中从通道读取数据到`buffer`，同时可以继续做别的事情吗，当数据读取到`buffer`中后，线程再继续处理数据。写数据类似。另外，非阻塞写也是如此。一个线程请求写入一些数据到某通道，但不需要等待它完全写入，这个线程同事可以去做别的事情。

**Buffer**

BIO面向流（Stream oriented），而NIO面向缓冲区（buffer oriented）。

`Buffer`是一个对象，它包含一些要写入或者读出的数据。在NIO类库中加入`Buffer`对象，提现了NIO与BIO的一个重要区别。在面向流的BIO中可以将数据直接写入或者将数据直接读到Stream对象中。虽然Stream中也有`Buffer`开头的扩展类，但只是流的包装类，还是从流读到缓冲区，而NIO确实直接读取到`Buffer`中进行操作。

在NIO库中，所有数据都是用缓冲区处理的。在读取数据时，它是直接读缓冲区中的数据；在写入数据时，写入到缓冲区中。任何访问NIO中的数据，都是通过缓冲区操作。

最常用的缓冲区是`ByteBuffer`，一个`ByteBuffer`提供了一组用于操作`byte`数组。除了`ByteBuffer`，还有其他的一些缓冲区，事实上，每一种Java基本类型（除`Boolean`外）都对应一种缓冲区。

**Channel**

NIO通过`Channel`进行读写。

通道是双向的，可读也可写，而流的读写是单向的。无论读写，通道只能与`Buffer`交互。因为`Buffer`，通道可以异步地读写。

**Selector**

NIO有选择器，而IO没有。

选择器用于使用单个线程处理多个通道。因此，它需要较少的线程来处理这些通道。线程之间的切换对于操作系统来说是昂贵的。因此，为了提高 系统效率，选择器是有用的。

### NIO基本流程

通常来说NIO中的所有IO都是从`Channel`开始的：

+ 从通道读取数据：创建一个缓冲区，然后请求通道读取数据；
+ 从通道写入数据：创建一个缓冲区，填充数据并要求通道写入数据；

### NIO核心组件

NIO包含以下几个核心组件：

+ Channel
+ Buffer
+ Selector

## Channel

通道是对BIO中的流的模拟，可以通过它读写数据。

`Channel`，类似在`Linux`之类的操作系统上看到的文件描述符，是NIO中被用来支持批量式IO操作的一种抽象。

`File`或者`Socket`，通常被认为是比较高层次的抽象，而`Channel`则是更加操作系统底层的一种抽象，这也使得NIO得以充分利用现代操作系统底层机制，获得特定场景的性能优化，例如DMA（`Direct Momory Access`）等。不同层次的抽象是相互关联的，我们可以通过`Socket`获取`Channel`，反之亦然。

通道与流的不同之处在于：

+ 流是单向的：一个流只能单纯的负责读或者写；
+ 通道是双向的：一个通道可以同时用于读写；

通道包括以下类型：

+ `FileChannel`：从文件中读写数据；
+ `DatagramChannel`：通过UDP读写网络中的数据；
+ `SocketChannel`：通过TCP读写网络中数据；
+ `ServerSocketChannel`：可以监听新增的TCP连接，对每一个新进来的连接都会创建一个`SocketChannel`；

## Buffer

NIO与传统I/O不同，它是基于块（`Block`）的，它以块为基本单位处理数据。`Buffer`是一块连续的内存块，是NIO读写数据的缓冲。`Buffer`可以将文件一次性读入内存再做后续处理，而传统的方式是边读文件边处理数据。

向`Channel`读写的数据都必须先置于缓冲区。也就是说，不会直接对通道进行读写数据，而是要先经过缓冲区。缓冲区实质上是一个数组，但它不仅仅是一个数组。缓冲区提供了对数据的结构化访问，而且还可以跟踪系统的读写进程。

BIO和NIO已经很好地继承了，`java.io.*`已经以NIO为基础重新实现了，所以现在它可以利用NIO的一些特性。例如，`java.io.*`包中的一些包含以块的形式读写数据的方法，这使得即使在面向流的系统中，处理速度也会更快。

缓冲区包含以下类型：

+ `ByteBuffer`
+ `CharBuffer`
+ `ShortBuffer`
+ `IntBuffer`
+ `LongBuffer`
+ `FloatBuffer`
+ `DoubleBuffer`

### 缓冲区状态容量

+ `capacity`：最大容量；
+ `position`：当前已读写的字节数；
+ `limit`：还可以读写的字节数；
+ `mark`：记录上一次`position`的位置，默认为0，算是一个便利性的考虑，往往不是必须的。

缓冲区状态变量的变更过程：

1. 新建一个大小为8个字节的缓冲区，此时`position`为0，而`limit`=`capacity`=8。`capacity`变量不会改变；
2. 从输入通道中读取5个字节数据写入到缓冲区中，此时`position`=5，而`limit`保持不变；
3. 在将缓冲区的数据写到输出通道之前，需要先调用`flip()`方法，这个方法将`limit`设置为当前`position`，并将`position`设置为0；
4. 从缓冲区中取4个字节到输出缓冲中，此时`position`设为4；
5. 最后需要调用`clear()`方法来清空缓冲区，此时`position`和`limit`都被设置为最初位置；

NIO快速复制文件示例：

```java
public static void fastCopy(String src,String dest) throws IOException {
  
  //获取源文件输入字节流
  FileInputStream fin = new FileInputStream(src);
  
  //获取输入字节流的文件通道
  FileChannel fci = fin.getChannel();
  
  //获取目标文件的输出字节流
  FileOutputStream fout = new FileOutputStream(dist);
  
  //获取输出字节流通道
  FileChannel  fco = fout.getChannel();
  
  //为缓冲区分配内存
  ByteBuffer bb = ByteBuffer.allocateDirect(1024);
  
  while(true) {
    int r = fci.read(bb);
    
    if (r == -1) {
      break;
    }
    
    bb.flip();
    
    fco.write(bb);
    
    bb.clear();
  }
}
```

### DirectBuffer

NIO还提供了一个可以直接访问物理内存的类`DirectBuffer`。普通的`Buffer`分配的是JVM堆内存，而`DirectBuffer`是直接分配物理内存。

数据要输出到外部设备，必须先从用户空间复制到内核空间，再复制到输出设备，而`DirectBuffer`则是直接将步骤简化为从内核空间复制到外部设备，减少了数据拷贝。

`DirectBuffer`申请的是非JVM的物理内存，所以创建和销毁的代驾都很高。`DirectBuffer`申请的内存并不是直接由JVM负责垃圾回收，但在`DirectBuffer`包装类被回收时，会通过Java引用机制来释放该内存块。

## Selector

NIO常常被叫做非阻塞IO，主要是因为NIO在网络通信中的非阻塞特性被广泛使用。

`Selector`是Java NIO编程的基础。用于检查一个或多个NIO的`Channel`状态是否处于可读、可写。

NIO实现了IO多路复用中的Reactor模型：

+ 一个线程使用一个选择器通过轮询的方式去监听多个通道上的事件（`read`、`accept`），如果某个通道上发生监听事件，这个通道就处于就绪状态，然后进行IO操作；
+ 通过配置监听的通道为非阻塞，那么当通道上的IO事件还未到达时，就不会进入阻塞状态一直等待，而是继续轮询其他通道，找到IO事件已经到达的通道执行；
+ 因为创建和切换线程的开销很大，因此使用一个线程来处理多个事件而不是一个线程处理一个事件具有更好的性能。

> 只有`SocketChannel`才能配置为阻塞，而`FileChannel`不行；
>
> 目前操作系统的IO多路复用机制都使用了`epoll`，相比传统的`select`机制，`epoll`没有最大连接句柄1024的限制，所以`Selector`在理论上可以轮询成千上万的客户端。

**创建选择器**

```java
Selector selector = Selector.open();
```

**注册选择器**

```java
ServerSocketChannel ssc = ServerSocketChannel.open();
ssc.configureBlocking(false);
ssc.register(selector,SelectionKey.OP_ACCEPT);
```

通道必须配置为非阻塞模式，否则使用选择器就没有任何意义了，因为如果通道在某个事件上被阻塞，那么服务器就不能响应其它事件，必须等待这个事件处理完毕才能去处理其它事件，显然这和选择器的作用背道而驰。

在将通道注册到选择器上时，还需要指定要注册的具体事件，主要有以下几类：

+ `SelectionKey.OP_CONNECT`；
+ `SelectionKey.OP_ACCEPT`；
+ `SelectionKey.OP_READ`；
+ `SelectionKey.OP_WRITE`；

**监听事件**

```java
int num = selector.select();
```

使用`select()`来监听到达的事件，它会一直阻塞知道有至少一个事件到达。

**获取事件**

```java
Set<SelectionKey> keys = selector.selectedKeys();
Iterator<SelectionKey> keyIterator = keys.iterator();
while(keyIterator.hasNext()) {
  SelectionKey key =keyIterator.next();
  if(key.isAcceptable()) {
    //...
  } else if (key.isReadable()) {
    //...
  }
  keyIterator.remove();
}
```

**事件循环**

因为一次`select()`调用不能处理完所有的事件，并且服务器端有可能需要一直监听事件，因此服务器端处理事件的代码一般会放在一个死循环内。

```java
while(true) {
  int num = selector.select();
  Set<SelectionKey> keys = selector.selectedKeys();
  Iterator<SelectionKey> keyIterator = keys.itertor();
  while(keyIterator.hasNext()) {
    SelectionKey key = keyIterator.next();
    if(key.isAcceptable()) {
      //...
    } else if (key.isReadable()) {
      //...
    }
    keyIterator.remove();
  }
}
```

套接字NIO示例

```java
public class NIOServer {
  
  public static void main(String[] args) throws IOException {
    Selector selector = Selector.open();
    
    ServerSocketChannel ssc = ServerSocketChannel.open();
    ssc.configureBlocking(false);
    ssc.register(selector,SelectionKey.OP_ACCEPT);
    ServerSocket ss =ss.socket();
    InetSocketAddress addr = new InetSocketAddress("127.0.0.1",8888);
    ss.bind(addr);
    
    while(true) {
      selector.select();
      Set<SelectionKey> keys = selector.selectedKeys();
      Iterator<SelectionKeys> keyIterator = keys.iterator();
      
      while(keyIterator.hasNext()) {
        SelectionKey key = keyInterator.next();
        if(key,isAcceptable()) {
          ServerSocketChannel ssc1 = (ServerSocketChannel) key.channel();
          SocketChannel ss1 = ss1.accpet();
          ss1.configureBlocking(false);
          
          ss1.register(selector,SelectionKey.OP_READ)
        } else if (key.isReadable()) {
          SocketChannnel ss2 = (SocketChannel) key.channel();
          System.out.println(readDataFromSocketChannel(ss2));
          ss2.close();
        }
        
        keyIterator.remove();
      }
      
    }
  }
  
  private static String readDataFromSocketChannel(SocketChannel ss) throws IOException {
    ByteBuffer bb = ByteBuffer.allocate(1024);
    StringBuilder data = new StringBuilder();
    
    while(true) {
      bb.clear();
      
      int n = ss.read(bb);
      if (n ==-1) {
        break;
      }
      
      bb.flip();
      int limit = bb.limit();
      char[] dest = new char[limit];
      
      for (int i=0;i<limit;i++) {
        dest[i] = (char) bb.get(i);
      }
      data.append(dest);
      bb.clear();
    }
    return data.toString();
  }
}


public class NIOClient{
  public static void main(String[]  args) throws IOException {
    Socket socket = new Socket("127.0.0.1",8888);
    OutputStream out = socket.getOutputStream();
    String s = "hello world!";
    out.write(s.getBytes());
    out.close();
  }
}
```

**内存映射文件**

内存映射文件IO是一种读和写文件数据的方法，它可以比常规的基于流或者基于通道的IO快得多。

向内存映射文件写入可能是危险的，只是改变数组的单个元素这样的简单操作，就可能还会直接修改磁盘上的文件。修改数据与将数据保存到磁盘是没有分开的。

## NIO vs BIO

BIO与NIO最重要的区别是数据打包和传输的方式：BIO以流的方式处理数据，而NIO以块的方式处理数据。

+ 面向流的BIO一次处理一个字节数据：一个输入流产生一个字节数据，一个输出流消费一个字节数据。以流式数据创建过滤器非常容器，链接几个过滤器，以便每个过滤器只负责复杂处理机制的一部分。不利的一面是，面向流的IO通常效率非常低；
+ 面向块的NIO一次处理一个数据块，按块处理数据比按流处理数据要快得多。但是面向块的NIO缺少一些面向流的BIO所具有的的优雅性和简单性；

# Java序列化

## Java序列化简介

<img src="Java编程自学之路23-IO模型/image-20210727000402678.png" alt="Java序列化" style="zoom:80%;" />

+ 序列化（`Serialize`）：序列化是将对象转换为字节流的过程；
+ 反序列化（`Deserialize`）：反序列化是将字节流转换为对象；
+ 序列化用途：
  + 序列化可以将对象的字节序列持久化—保存在内存、文件、数据库中；
  + 在网络上传送对象的字节序列；
  + RMI（远程方法调用）；

> 使用Java对象序列化，在保存对象时，会将其状态保存为一组字节；在未来，再将这些字节组装成对象。必须注意的是，对象序列化保存的是对象的“状态”，即它的成员变量。对象序列化不会关注类中的静态变量。

## Java序列化与反序列化

Java通过对象输入输出流来实现序列化和反序列化：

+ `java.io.ObjectOutputStream`类的`writeObject()`方法可以实现序列化；
+ `java.io.ObjectInputStream`类的`readObject()`方法用于实现反序列化；

示例：

```java
public class SerializeDemo01 {
  enum Sex{
    MALE,
    FEMALE
  }
  
  static class Person implements Serializable {
    private static final long SerialVersion = 1L;
   	private String name = null;
    private Integer age = null;
    private Sex sex;
    
    public Person() {}
    
    public Person(String name,Integer age, Sex sex) {
      this.name = name;
      this.age = age;
      this.sex = sex;
    }
    
    @Overide
    public String toString() {
      return "Person { name =" + name + '\'' + ", age = " + age " , sex = " + sex;
     }
  }
  
  private static void serialize(String filename) throws IOException {
    File f = new File(filename);
    OutputStream out = new FileOutputStream(f);
    ObjectOutputStream oos = new ObjectOutoutStream(out);
    oos.writeObject(new Person("jack",30,Sex.MALE));
    oos.close();
    out.close();
  }
  
  
  private static void deserialize(String filename) throws IOException,ClassNotFoundException {
    File f = new File(filename);
    InputStream in = new FileInputStream(f);
    ObjectInputStream ois = new ObjectOutputStream(in);
    Object obj = ois.readObject();
    ois.close();
    in.close();
    System.out.println(obj);
  }
  
  
  public static void main(String[] args) throws IOException,ClassNotFoundException {
    final String filename = "demo.txt";
    serialize(filename);
    deserialize(filename);
  }
  
}
```

## Serializable接口

被系列化的类必须是属于`Enum`、`Array`和`Serializable`类型中的任意一种，否则将抛出`NotSerializableException`异常。这是因为：在序列化操作过程中会对类型进行检查，如果不满足序列化类型要求，就会抛出异常。

### serialVersionUID

`serialVersionUID`是Java为每个序列化类产生的版本标识。它用来保证在反序列化时，发送方发送的和接收方接收的是可兼容的对象。如果接收方接受的类的`serialVersionUID`与发送方发送的`serialVersionUID`不一致，会抛出`InvalidClassException`。

如果可序列化类没有显示声明`serialVersionUID`，则序列化运行时将基于该类的各个方面计算该类的默认`serialVersionUID`值。但处于良好的编程习惯，建议在每个序列化的类中显示指定`serialVersionUID`的值。因为不同的JDK可能会生成不同的`serialVersionUID`默认值，从而导致在反序列化时抛出`InvalidClassException`。

`serialVersionUID`字段必须指定为`static final long`类型。

### 默认序列化机制

如果让某个类实现`Serializable`接口，而没有其它任何处理的话，那么就会使用默认序列化机制。

使用默认系列化机制，在序列化对象时，不仅会序列化当前对象本身，还会对其父类的字段以及该对象引用的其它对象也进行序列化，并且递归序列化引用的对象。

### transient

在实际应用中，可能希望序列化过程忽略某些敏感信息，或者简化序列化过程，降低序列化开销。

将不希望序列化的字段声明为`transient`，默认序列化机制将忽略该字段内容，且序列化后无法访问该字段；

## Externalizable接口

`Externalizable`是JDK提供的另外一个序列化接口。

可序列化类实现`Externalizable`接口之后，基于`Serializable`接口的默认序列化机制就会失效。

+ `Externalizable`继承于`Serializable`，并增加了两个方法：`writeExternal()`与`readExternal()`。这两个方法在序列化和反序列化过程中会被自动调用，以便执行执行一些特殊操作。当使用该接口时，序列化的细节需要由程序员去完成。如未重写方法，则不会进行任何序列化与反序列化操作。
+ 使用`Externalizable`进行序列化，当读取对象时，会调用被序列化类的无参构造方法区创建一个新的对象；然后再将被保存对象的字段和值分别填充到新的对象中。所以实现`Externalizable`接口必须提供一个无参构造方法，且访问权限为`public`。

### Externalizable替代方案

通过`Externalizable`接口控制序列化与反序列化细节的替代方案为：实现`Serializable`并添加`writeObject(ObjectOutputStream out)`与`readObject(ObjectInputStream in) `方法，序列化与反序列化时会自动回调这两个方法。

### readResolve方法

为了在单例模式中仍然保持序列的特性，尅使用`readResolve()`方法，在该方法中直接返回类的实例。

## Java序列化问题

Java的序列化能保证对象状态的持久保存，但是遇到一些对象结构复杂的情况还是难以处理，例如如下场景：

+ 父类是`Serializable`，则所有子类都可以序列化；
+ 子类是`Serializable`，而父类不是，此时子类可以正确序列化，父类的属性不会被序列化，且不报错（父类属性丢失）；
+ 如果序列化的属性是对象，则对象也必须是Serializable`，否则会报错；
+ 反序列化时，如果对象的属性有修改或删减，则修改的部分属性会丢失，但不会报错；
+ 反序列化时，如果`serialVersionUID`被修改，则反序列化会失败；

## Java序列化缺陷

+ 不支持跨语言：Java序列化目前只适用于基于Java语言实现的框架，其他语言大部分都没有使用Java的序列化框架，也没有实现Java徐泪花这套协议。因此，如果两个基于不同语言编写的应用程序相互通信，则无法实现两个应用服务之间传输对象的序列化与反序列化；
+ 容易被攻击：对象是通过`ObjectInputStream`上调用`readObject()`方法进行反序列化的，它可以将类路径上几乎所有实现了`Serializable`接口的对象都实例化。这意味着，在反序列化字节流的过程中，该方法可以执行任意类型的代码，这是非常危险的。对于需要长时间进行反序列化的对象，不需要执行任何代码，都可以发起一次攻击。攻击者可以创建循环对象链，然后将序列化后的对象传输到程序中反序列化，这种情况会导致`hashCode`方法被调用次数诚指数级爆发增长，从而引发栈溢出异常；
+ 序列化后流过大：Java序列化中使用`ObjectOutputStream`来实现对象二进制编码，编码后数组很大，非常影响存储和传输效率；
+ 序列化性能太差：Java序列化性能耗时比较长；序列化的速度也是体现序列化性能的重要指标，如果序列化的速度慢，就会影响网络通信的效率，从而增加系统的响应时间；
+ 序列化编程限制：
  + Java官方的序列化需要实现`Serializable`接口；
  + Java官方的序列化需要关注`serialVersionUID`属性；

## 序列化技术选型

因为Java序列化存在的缺陷问题，我们建议使用第三方序列化工具来替代，根据不同使用场景来进行选型：

1. 性能敏感，开发体验要求不高：`thrift`、`protobuf`；
2. 开发体验敏感，性能有要求：`hessian`；
3. 序列化后数据有良好可读性：`jackson`、`gson`、`fastjson`；（可转为`json`、`xml`格式文件）

# Java IO工具类

## File

`File`类是`java.io`包中唯一对文件本身进行操作的类。它可以对文件、目录进行增删查操作。

### createNewFile

可以使用`createNewFile()`方法创建一个新文件。

> `Windows`系统使用反斜杠（`\`）表示目录的分隔符；
>
> `Linux`系统使用正斜杠（`/`）表示目录的分隔符；

良好的开发习惯是使用`File.separator`静态常量，可以根据所在操作系统选取对应的分隔符。

### mkdir

`mkdir()`可以用来创建文件夹，但是如果需要创建目录的父目录不存在，则无法创建成功。如果需要递归创建目录，可使用`mkdirs()`方法。

### delete

`delete()`用来删除文件或目录。当删除目标为目录且目录不为空时，直接调用`delete()`方法会失败。

删除非空目录方案是通过递归来实现。

### list和listFiles

`File`中给出了两种列出文件夹内容的方法：

+ `list()`：列出全部名称，返回一个字符串数组；
+ `listFiles()`：列出完整的路径，返回一个`File`对象数组；

## RandomAccessFile

`RandomAccessFile`类是随机读取类，它是一个完全独立的类。

它适用于由大小已知的记录组成的文件，所以我们可以用`seek()`将记录从一处转移到另一处，然后读取或者修改记录。

文件中记录的大小不一定都相同，只要能够确定哪些记录有多大以及他们在文件中的位置即可。

### RandomAccessFile写操作

当使用`rw`方式声明`RandomAccessFile`对象时，如果要写入的文件不存在，则系统自动创建。

### RandomAccessFile读操作

读取是直接使用`r`模式即可，以只读方式打开文件。

读取时所有字符串只能按照`byte`数组方式读取出来，而且长度必须和写入时的固定大小相匹配。

## System

`System`类中提供了大量的静态方法，可以获取系统相关的信息或系统级操作，其中提供了3个常用于IO的静态成员：

+ `System.out`：一个`PrintStream`流。`System.out`一般会把你写到其中的数据输出到控制台上；`System.out`通常仅用在类似命令行工具的控制台程序上。`System.out`也经常用于打印程序的调试信息；
+ `System.err`：一个`PrintStream`流。`System.err`与`System.out`的运行方式类似，但它更多的是用于打印错误文本。一些IDE会将错误信息以红色文本通过`System.err`输出到控制台上；
+ `System.in`：一个典型的连接控制台程序和键盘输入的`InputStream`流。通常当数据通过命令行参数或者配置文件传递给命令行Java程序的时候；

## Scanner

`Scanner`可以获取用户的输入，并对数据进行校验。

# Java网络编程

网络编程是指编写运行在多个设备的程序，这些设备通过网络连接起来。

`java.net`包中提供了低层次的网络通信细节。程序员可以直接使用这些类和接口，来专注于解决问题，而不用关注通信细节。

`java.net`包中提供了两种常见的网络协议的支持：

+ TCP：`TCP`是传输控制协议的缩写，它保障了两个应用程序之间的可靠通信。通常用于互联网协议，也称`TCP/IP`；
+ UDP：`UDP`是用户数据包协议的缩写，一个无连接的协议。提供了应用程序之间要发送的数据的数据包；

## Socket与ServerSocket

`Socket`（套接字）使用TCP提供了两台计算机之间的通信机制。客户端程序创建一个套接字，并尝试连接服务端套接字。

Java通过`Socket`和`ServerSocket`实现对TCP的支持。Java中的`Socket`通信可以简单理解为：`java.net.Socket`代表客户端，`java.net.ServerSocket`代表服务端，二者可以建立连接，然后通信。

`Socket`通信基本流程：

+ 服务器实例化一个`ServerSocket`对象，绑定服务器一个端口；
+ 服务器调用 `ServerSocket`的 `accept()`方法，该方法一直等待，直到客户端链接到服务器的绑定端口（也叫监听端口）；
+ 客户端实例化一个`Socket`对象，指定服务器名称和端口号来请求链接；
+ `Socket`类的构造函数视图将客户端链接到指定的服务器和端口号，如果通信被建立，则在客户端创建一个`Socket`对象能够与服务器进行通信；
+ 在服务端，`accept()`方法返回服务器上一个新的`Socket`引用，该引用链接到客户端的`Socket`；

链接建立后，可以通过使用IO流进行通信。每一个`Socket`都有一个输出流和一个输入流。客户端的输出流链接到服务器端的输入流，而客户端的输入流链接到服务器端的输出流。

TCP是一个双向的通信协议，因此数据可以通过两个数据流在同一时间发送，以下是一些类提供的一套完整的有用的方法来实现`sockets`。

### ServerSocket

服务器程序通过使用`java.net.ServerSocket`类以获取一个端口，并且监听客户端链接此端口的请求。

**ServerSocket构造方法**

+ `ServerSocket()`：创建非绑定服务器套接字；
+ `ServerSocket(int port) `：创建绑定到特定端口的服务器套接字；
+ `ServerSocket(int port, int backlog) `：利用指定的`backlog`创建服务器套接字并将其绑定到指定的本地端口号；
+ `ServerSocket(int port,int backlog, InetAddress addr)`：使用指定的端口，监听`backlog`和要绑定的本地IP地址创建服务器；

**ServerSocket常用方法**

创建非绑定服务器套接字，如果`ServerSocket`构造方法没有抛出异常，就意味着你的应用程序已经成功绑定到指定的端口，并且侦听客户端请求。

+ `int getLocalPort()`：返回此套接字在其上侦听的端口；
+ `Socket accept()`：监听并接受到此套接字的连接；
+ `void setSoTimeout(int timeout)`：通过指定超时值启用/禁用SO_TIMEOUT，以毫秒为单位；
+ `void bind(SocketAddress host,int backlog)`：将`ServerSocket`绑定到特定地址（IP和端口）；

### Socket

`java.net.Socket`类代表客户端和服务器都用来互相沟通的套接字。

**Socket构造方法**

+ `Socket()`：通过系统默认类型的`SocketImpl`创建未连接套接字；
+ `Socket(String host, int port)`：创建一个流套接字并将其链接到指定主机上的指定端口；
+ `Socket(InetAddress host,int port)`：创建一个流套接字并将其链接到指定IP地址的指定端口；
+ `Socket(String host,int port,InetAddress localAddress int localPort)`：创建一个套接字并将其链接到指定远程主机上的指定远程端口；
+ `Socket(InetAddress host,int port,InetAddress localAddress ,int localPort)`：创建一个套接字并将其链接到指定远程地址上的指定远程端口；

当`Socket`构造方法返回，并没有简单的实例化一个`Socket`对象，它实际上会尝试链接到指定的服务器端口。

**Socket常用方法**

实际上，客户端与服务端都有一个`Socket`对象，所以无论客户端耗时服务端都能够调用这些方法。

+ `void connect(SocketAddress host,int timeout)`：将此套接字链接到服务器，并指定一个超时值；
+ `InetAddress getInetAddress()`：返回套接字链接的地址；
+ `int getPort()`：返回套接字链接的远程端口；
+ `int getLocalPort()`：返回套接字绑定的本地端口；
+ `SocketAddress getRemoteSocketAddress()`：返回套接字链接的端点的地址，如果未连接则返回`null`；
+ `InputStream getInputStream()`：返回套接字的输入流；
+ `OutputStream getOutputStream()`：返回套接字的输出流；
+ `void close()`：关闭套接字；

## DatagramSocket与DatagramPacket

Java通过`DatagramSocket`和`DatagramPacket`实现对UDP协议的支持。

+ `DatagramSocket`：通信类；
+ `DatagramPacket`：数据包类；

```java
public class UDPServer {
  public static void main(String[] args) throws Exception {
    String str = "hello world";
    //服务端绑定端口3000
    DatagramSocket ds = new DatagramSocket(3000);
    //将发送信息使用buf保存
    DatagramPacket dp = new DatagramPacket(str.getBytes(),str.length(),InetAddress.getByName("localhost"),9000);
    
   	System.out.println("send msg!");
    ds.send(dp);
    ds.close();
  }
}


public class UDPClient {
  public static void main(String[] args) throws Exception {
    byte[] buf = new byte[1024];
    DatagramSocket ds = new DatagramSocket(9000);
    DatagramPacket dp = new DatagramPacket(buf,1024);
    ds.receive(dp);
    String str = new String(dp.getData(),0,dp.getLength()) + " from " + dp.getAddress().getHostAddress() + " : " + dp.getPort();
    System.out.println(str);
  }
}
```

## InetAddress

`InetAddress`类表示互联网协议（IP）地址；

`InetAddress`没有公有的构造函数，只能通过静态方法来创建实例；

```java
InetAddress.getByName(String host);
InetAddress.getByAddress(byte[] address);
```

## URL

可以直接从URL中读取字节流数据。

```java
public static void main(String[] args) throws IOException {
  URL url  = new URL("https://www.baidu.com");
  InputStream is = url.openStream();
  InputStreamReader isr = new InputStreamReader(is,"utf-8");
  BufferReader br = new BufferReader(isr);
  
  String line;
  while((line = br.readLine()) != null) {
    System.out.println(line);
  }
  
  br.close();
}
```


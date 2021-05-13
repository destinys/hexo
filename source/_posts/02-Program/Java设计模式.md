---
title: Java设计模式
categories: Program
tags: java
date: 2020-05-06
author: Semon
---
# Java 设计模式
## 单例模式
为了节省内存资源、保证数据内容的一致性，对某些类要求只能创建一个实例，这就是所谓的单例模式

单例模式有 3 个特点：
单例类只有一个实例对象；
该单例对象必须由单例类自行创建；
单例类对外提供一个访问该单例的全局访问点；

单例模式有饿汉式与懒汉式两种类型：
+ 饿汉式：该模式的特点是类一旦加载就创建一个单例，保证在调用 getInstance 方法之前单例已经存在了。饿汉式单例在类创建的同时就已经创建好一个静态的对象供系统使用，以后不再改变，所以是线程安全的，可以直接用于多线程而不会出现问题。

    ```java
    public class HungrySingleton
    {
        private static final HungrySingleton instance=new HungrySingleton();
        private HungrySingleton(){}
        public static HungrySingleton getInstance()
        {
            return instance;
        }
    }
    ```
    
+ 懒汉式：该模式的特点是类加载时没有生成单例，只有当第一次调用 getlnstance 方法时才去创建这个单例。懒汉式用于多线程建议使用静态内部类方式保证线程安全。

    ```java
    public class SingletonLazy {
        private SingletonLazy() {
        }
        private static class SingletonHolder{
            private static SingletonLazy instance = new SingletonLazy();
        }
        public static SingletonLazy getInstance(){
            return SingletonHolder.instance;
        }
    }
    ```
    
    

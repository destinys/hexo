---
title: Mybatis学习入门
categories: Program
tags: mybatis
author: semon
date: 2021-06-03
---

# Mybatis学习入门

## 什么是Mybatis

Mybatis是支持定制化SQL、存储过程以及高级映射的优秀的持久层框架。Mybatis避免了几乎所有的JDBC代码和手动设置参数。Mybatis可以对配置和原生Map使用简单的XML或者注解，将接口和Java的POJOs（Plain Old Java Objects）映射成数据库中的记录。

## Mybatis如何配置依赖

1. 直接将mybatis-x.x.x.jar添加到classpath中；
2. 通过依赖工具配置：

```groovy
implementation group: 'org.mybatis', name: 'mybatis', version: '3.5.7'
```

### Mybatis功能架构

Mybatis的功能架构一般分为三层：

1. API接口层：提供外部使用的接口API，开发人员通过API来操纵数据库完成具体的数据处理；
2. 数据处理层：负责具体的SQL查找、SQL解析、SQL执行和执行结果映射处理等。主要目的是根据调用请求完成一次数据库操作；
3. 基础支撑层：负责最基础的功能支撑，包括连接管理、事务处理、配置加载及缓存处理，将通用的东西抽象为最基础的组件，为数据处理层提供基础支撑；

## Mybatis优缺点

### 优点

+ 易学：框架本身很小且简单，没有任何第三方依赖，易于学习，易于使用，通过文档和源码，可以完全的掌握设计思路和实现；
+ 灵活：Mybatis不会对应用程序或者数据库的现有设计产生任何影响。通过xml保存sql，便于统一管理和优化；
+ 解耦：通过提供DAL层，将业务逻辑与数据访问逻辑分离，使系统设计更清晰，易维护，易单元测试，提高可维护性；
+ 映射：支持对象与数据库的orm字段关系映射；
+ 标签：提供xml标签，支持编写动态sql；

## 缺点

+ 编写SQL语句工作量大，尤其字段多、关联表多时；
+ SQL强依赖数据库，可移植性差；
+ 框架简陋，虽然简化了数据绑定代码，但整个底层数据库查询代码需要自行开发，工作量大；
+ 二级缓存机制不佳；

## Mybatis注解

注解可以实现SQL与实体映射，`SQL`查询出来的结果集，可以通过`@Result`注解将数据库字段与实体属性关联起来，并将查询结果集进行命名供后续其它`SQL`引用，如以下示例中，`offsets`即为映射结果集名称，`value`即为定义实体集映射关系；

`@Select`为定义select语句注解，`#{id}`为`SQL`语句中传入参数，`@Param("id")`定义方法传入参数与`SQL`参数的映射关系，同时可进行参数进行重命名；`SQL`引用中直接使用对象属性进行查询；

```java
@Results(id ="offsets", value = {
            @Result(property = "id", column = "id"),
            @Result(property = "groupId", column = "group_id"),
            @Result(property = "topicName",column = "topic_name"),
            @Result(property = "partitionId",column = "partition_id"),
            @Result(property = "offsetValue",column = "offset_value"),
            @Result(property = "createDate",column = "create_date"),
            @Result(property = "updateDate",column = "update_date")
    })
    @Select("select * from kafka_offset where id = #{id}")
    OffsetEntity queryById(@Param("id") int id);

@Select("select * from kafka_offset where group_id = #{offsetEntity.groupId} and topic_name = #{offsetEntity.topicName} and " +
            "partition_id = " +
            "#{offsetEntity.partitionId}")
@ResultMap(value = "offsets")
OffsetEntity queryByEntity(@Param("offsetEntity") OffsetEntity offsetEntity);
```


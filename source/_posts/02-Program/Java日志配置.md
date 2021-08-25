---
title: Java日志配置
categories: Program
tags: java
author: semon
date: 2021-04-27
---

# Java日志配置
## 常用日志类
+ logger：Jdk内置，基本不用于生产环境
+ log4j：apache提供，已于2015年停止更新，历史遗留项目仍在使用，最后版本为1.2.17
+ log4j2：apache提供，log4j升级版本，性能较log4j提升10倍(官方说明)
+ logback：log4j作者出走后重新开发，性能相对log4j有很大提升

### log4j2
log4j2使用基本与log4j一致，通过xml配置文件来定义
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!--日志级别以及优先级排序: OFF > FATAL > ERROR > WARN > INFO > DEBUG > TRACE > ALL -->
<!--Configuration后面的status，这个用于设置log4j2自身内部的信息输出，可以不设置，当设置成trace时，你会看到log4j2内部各种详细输出-->
<!--monitorInterval：Log4j能够自动检测修改配置 文件和重新配置本身，设置间隔秒数-->
<configuration status="ERROR" monitorInterval="30">
    <!--定义全局变量-->
    <properties>
    <property name = "highlight_pattern" >[%d{HH:mm:ss:SSS}]  %highlight{%-5level}{ERROR=Bright RED, WARN=Bright Yellow, INFO=Bright Green, DEBUG=Bright Cyan, TRACE=Bright White} %style{[%t]}{bright,magenta} %style{%c{1.}.%M(%L)}{cyan}: %msg%n
    </property>
    </properties>

    <!--
        定义全局Filter，需要定制过滤条件时,尽量使用全局Filter，因为全局Filter会作用到每条日志，无论打印日志级别，全局Filter过滤逻辑应尽可能简单，避免影响业务
        当只有一个Filter时，外面Filters标签可省略
    -->
    <Filters>
        <!--
            LevelRangeFilter中minLevel与maxLevel定义参数不能颠倒，否则会导致无日志输出
            minLevel与maxLevel可以简单理解为定义的intLevel与打印日志数量正相关，即打印日志越多，intLevel值越大
            onMatch：匹配定义级别及以上范围
            onMismatch：匹配定义级别以下范围
            ACCEPT:接受匹配范围内日志
            DENY:拒绝匹配范围内日志
            NEUTRAL:中立，不对匹配范围内日志操作，转交下游判断
			实际测试情况：全局filter配置会导致root及logger配置的日志级别失效
        -->
        <LevelRangeFilter minLevel="error" maxLevel="info" onMatch="ACCEPT" onMismatch="NEUTRAL"></LevelRangeFilter>
    </Filters>

    <!--先定义所有的appender-->
    <appenders>

        <!--控制台 SYSTEM_OUT 日志输出格式配置-->
        <console name="Console_out" target="SYSTEM_OUT">
            <!--输出日志的格式-->
            <PatternLayout pattern="${highlight_pattern}" />
            <!-- appender 级别Filter 针对该输出源有效 -->
            <ThresholdFilter level="DEBUG" onMatch="ACCEPT" onMismatch="DENY" />
        </console>

        <!-- 控制台 SYSTEM_ERR 日志输出在控制台显示为红色 -->
        <console name="Console_err" target="SYSTEM_ERR" >
            <PatternLayout pattern="${highlight_pattern}" />
        </console>

        <!--文件输出 文件会打印出所有信息，这个log每次运行程序会自动清空，由append属性决定，这个也挺有用的，适合临时测试用-->
        <File name="log" fileName="logs/test.log" append="false">
            <PatternLayout pattern="${highlight_pattern}" />
        </File>


        <!-- 这个会打印出所有的info及以下级别的信息，每次大小超过size，则这size大小的日志会自动存入按年份-月份建立的文件夹下面并进行压缩，作为存档-->
        <RollingFile name="RollingFileInfo" fileName="logs/info.log"
                     filePattern="logs/$${date:yyyy-MM}/info-%d{yyyy-MM-dd}-%i.log">
            <!--控制台只输出level及以上级别的信息（onMatch），其他的直接拒绝（onMismatch）-->
            <ThresholdFilter level="error" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout pattern= "${highlight_pattern}" />
            <Policies>
                <TimeBasedTriggeringPolicy  />
                <SizeBasedTriggeringPolicy size="100 MB"/>
            </Policies>

            <!-- DefaultRolloverStrategy属性如不设置，则默认为最多同一文件夹下7个文件，这里设置了20 -->
            <DefaultRolloverStrategy max="20"/>
        </RollingFile>


        <RollingFile name="RollingFileError" fileName="${sys:user.home}/logs/error.log"
                     filePattern="logs/$${date:yyyy-MM}/error-%d{yyyy-MM-dd}-%i.log">
            <ThresholdFilter level="ERROR" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout pattern= "${highlight_pattern}" />
            <Policies>
                <!--
                    interval:指定日志按照时间滚动的频率，默认为1，滚动的时间单位由filePattern中最小时间单位决定，如本配置中最小时间单位为D，故日志滚动周期为每天一次
                    modulate：指定是否对滚动时间进行调制，即是否以当天0点为起始点开始计算下次滚动时间
                    size：指定触发文件滚动大小，支持KB，MB，GB等
                -->
                <TimeBasedTriggeringPolicy interval="1" modulate="true"/>
                <SizeBasedTriggeringPolicy size="100 MB"/>
            </Policies>
        </RollingFile>
    </appenders>


    <Loggers>
        <!-- 配置日志的根节点 -->
        <!-- 定义logger，只有定义了logger并引入了appender，appender才会生效 -->
        <root level="INFO">
            <!--logger级别Filter，仅当前Logger有效-->
            <MapFilter onMatch="ACCEPT" operator="or">
                    <KeyValuePair key="eventId" value="login"/>
                    <KeyValuePair key="eventId" value="logout" />
            </MapFilter>
            <appender-ref ref="Console_out" />
        </root>

        <!-- 指定自定义appender时，logger中name属性应配置为完成包路径（不含类名）
            additivity默认为true，日志信息继承至root logger中，即符合自定义appender的日志会被打印两次
            如果appender中已指定level，则logger中指定的无效
        -->
        <logger name="org.demo"  additivity="false">
            <appender-ref ref="RollingFileInfo">
                    <!--append-ref Filter，仅当前引用有效-->
                    <BurstFilter level="INFO" rate="100" maxBurst="1000"/>
            </appender-ref>
        </logger>
      <!--配置异步日志-->
      <AsyncRoot level="debug">
        <AppenderRef ref="log"  level="info" />
        <AppenderRef ref="RollingFileInfo" level="debug" />
      </AsyncRoot>


        <!-- 第三方日志系统 -->
        <logger name="org.springframework.core" level="info" />
        <logger name="org.springframework.beans" level="info" />
        <logger name="org.springframework.context" level="info" />
        <logger name="org.springframework.web" level="info" />
        <logger name="org.jboss.netty" level="warn" />
        <logger name="org.apache.http" level="warn" />

    </Loggers>
</configuration>
```

#### PatternLayout参数说明

| 参数名                | 说明                             |
| --------------------- | -------------------------------- |
| charset               | 指定日志字符集                   |
| pattern               | 指定日志输出格式                 |
| alwaysWriteExceptions | 输出异常，默认为true             |
| header                | 可选项，包含在每个日志文件的顶部 |
| footer                | 可选项，包含在每个日志文件的底部 |

#### Pattern Layouts属性说明

Pattern Layouts是一个灵活的布局，
 是最常用的日志格式配置。
 该类的目标是格式化一个日志事件并返回结果，
 结果的格式取决于转换模式。
 转换模式与c语言中printf函数的转换模式密切相关。
 转换模式由称为转换说明符的文字文本和格式控制表达式组成。
 注意，任何文字文本，包括特殊字符，都可能包含在转换模式中。
 特殊字符包括\t、\n、\r、\f，使用\输出一个反斜杠。
 每个转换说明符以百分号(%)开头，
 后面是可选的格式修饰符和必填的转换字符。
 格式修饰符控制字段宽度、填充、左对齐和右对齐等内容。
 转换字符指定数据的类型，例如日期、线程名、日志级别、日志名称等等。

| 数据类型     | 参数                | 样例                                                         | 备注                                                         |
| ------------ | ------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 日期         | %d{HH:mm:ss:SSS}    | 20:03:22:625                                                 |                                                              |
| 线程名       | %t                  | main                                                         |                                                              |
| 日志级别     | %-5level            | INFO                                                         |                                                              |
| 日志名称     | %c{1.}   {}定义精度 | c.z.h.HikariDataSource                                       | {1.} 表示最右侧完成显示，其他位仅打印一个字母;  {-2}表示仅打印最右侧两级名称 |
| Java类名     | %C                  | DaoHikariUtils                                               | 慎用，影响性能                                               |
| 方法名       | %M                  | <init>                                                       |                                                              |
| 错误行号     | %L                  | 80                                                           |                                                              |
| 错误信息     | %m                  | HikariPool-1 - Starting...                                   |                                                              |
| 完整错误位置 | %l                  | org.apache.logging.log4j.Log4j2Test.logAll(Log4j2Test.java:18) |                                                              |
| 换行         | %n                  |                                                              |                                                              |
| 特殊符号-&   | &amp   &#38         | &                                                            | 特殊符号需要使用实体名称或编号打印                           |
| 特殊符号-<   | &lt    &#60         | <                                                            | 特殊符号需要使用实体名称或编号打印                           |
| 特殊符号->   | &gt   &#62          | >                                                            | 特殊符号需要使用实体名称或编号打印                           |
| 特殊符号-“   | &quot  &#34         | “                                                            | 特殊符号需要使用实体名称或编号打印                           |
| 特殊符号-‘   | &apos  &#39         | ‘                                                            | 特殊符号需要使用实体名称或编号打印                           |

```bash
# 样例PatternLayout及日志对应
[%d{HH:mm:ss.SSS}]  %-5level  %t %c{1.} %M.(%L) : %m %n 

[20:03:22:625 ]  INFO  [main] c.z.h.HikariDataSource.<init>(80): HikariPool-1 - Starting...
```

#### Filters说明

##### 介绍

对输出日志进行过滤。过滤器将返回ACCEPT, DENY 或者NEUTRAL其中一个， 以确定日志如何输出。
过滤器可以配置在4个地方：
1、上下文范围的过滤器直接在configuration中配置（如果配置中存在 properties，则filter必须位于properties下方）。
2、日志记录器过滤器是在指定的Logger中配置。
3、Appender过滤器用于确定特定的Appender是否应该处理事件的格式和输出。
4、Appender引用过滤器用于确定日志记录器是否应该将事件路由到Appender。

##### BurstFilter

BurstFilter提供了一种机制，通过在达到最大限制后静默地丢弃事件来控制处理logevent的速度。
配置参数：

| 参数名     | 类型    | 描述                                                         |
| ---------- | ------- | ------------------------------------------------------------ |
| level      | String  | 要筛选的消息级别。如果超过maxBurst，则将过滤掉此级别或以下的任何内容。默认值是WARN，这意味着任何高于WARN的消息都将被记录，无论Burst的大小如何。 |
| rate       | float   | 每秒可以执行的事件平均数量。                                 |
| maxBurst   | integer | 最大的处理事件，默认是rate的10倍。                           |
| onMatch    | String  | 过滤器匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是NEUTRAL。 |
| onMismatch | String  | 当过滤器不匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是DENY。 |

示例：

```xml
<BurstFilter level="INFO" rate="16" maxBurst="100"/>
```

##### CompositeFilter

复合过滤器提供了一种指定多个过滤器的方法。他以Filters元素加入到配置中，元素里面可以配置多个过滤器。该元素不支持添加参数。
示例：

```xml
<Filters>
	<MarkerFilter marker="EVENT" onMatch="ACCEPT" onMismatch="NEUTRAL"/>
	<DynamicThresholdFilter key="loginId" defaultThreshold="ERROR"
							onMatch="ACCEPT" onMismatch="NEUTRAL">
	  <KeyValuePair key="User1" value="DEBUG"/>
	</DynamicThresholdFilter>
</Filters>
```

##### DynamicThresholdFilter

可以通过明确的属性对不同的日志级别进行拦截。例如，可以通过ThreadContext对指定用户输出不同的日志级别。如果日志事件不包含指定的ThreadContext项，那么默认使用NEUTRAL。

配置参数：

| 参数名           | 类型           | 描述                                                         |
| ---------------- | -------------- | ------------------------------------------------------------ |
| key              | String         | 去ThreadContext中比较的key                                   |
| defaultThreshold | String         | 需要被过滤的消息等级。当指定的key不在ThreadContext中时，使用该配置。 |
| keyValuePair     | KeyValuePair[] | 可以定义多个KeyValuePair属性。通过该属性可以对指定用户设置日志级别。KeyValuePair的key为ThreadContext中获取的value值，KeyValuePair的value为日志的级别，如<KeyValuePair key="User1" value="DEBUG"/> |
| onMatch          | String         | 过滤器匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是NEUTRAL。 |
| onMismatch       | String         | 当过滤器不匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是DENY。 |

示例：

```xml
<DynamicThresholdFilter key="loginId" defaultThreshold="ERROR"
                          onMatch="ACCEPT" onMismatch="NEUTRAL">
    <KeyValuePair key="User1" value="DEBUG"/>
</DynamicThresholdFilter>
```

##### MapFilter

MapFilter允许对MapMessage中的数据元素进行过滤。
配置参数：

| 参数名       | 类型           | 描述                                                         |
| ------------ | -------------- | ------------------------------------------------------------ |
| operator     | String         | 如果配置为or，那么只要有一个匹配就可以了。否则所有的key/value都要匹配。 |
| keyValuePair | KeyValuePair[] | 可以定义一个或多个KeyValuePair元素，这些元素定义映射中的键和要匹配的值。如果同一个key被多次指定，那么对该key的检查将自动成为“or”，因为映射只能包含一个值。 |
| onMatch      | String         | 过滤器匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是NEUTRAL。 |
| onMismatch   | String         | 当过滤器不匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是DENY。 |

示例1：

```xml
<MapFilter onMatch="ACCEPT" onMismatch="NEUTRAL" operator="or">
    <KeyValuePair key="eventId" value="Login"/>
    <KeyValuePair key="eventId" value="Logout"/>
</MapFilter>
```

##### MarkerFilter

MarkerFilter将配置的标记值与LogEvent中包含的标记进行比较。当标记名称与日志事件的标记匹配，或者与其任一父标记匹配时，则将进行匹配。
配置参数：

| 参数名     | 类型   | 描述                                                         |
| ---------- | ------ | ------------------------------------------------------------ |
| marker     | String | 要比较的标记名称。                                           |
| onMatch    | String | 过滤器匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是NEUTRAL。 |
| onMismatch | String | 当过滤器不匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是DENY。 |

示例：

```xml
<RollingFile name="RollingFile" fileName="logs/app.log"
			 filePattern="logs/app-%d{MM-dd-yyyy}.log.gz">
  <MarkerFilter marker="FLOW" onMatch="ACCEPT" onMismatch="DENY"/>
  <PatternLayout>
	<pattern>%d %p %c{1.} [%t] %m%n</pattern>
  </PatternLayout>
  <TimeBasedTriggeringPolicy />
</RollingFile>
```

##### RegexFilter

RegexFilter将格式化或未格式化的消息与正则表达式进行比较。
配置参数：

| 参数名     | 类型    | 描述                                                         |
| ---------- | ------- | ------------------------------------------------------------ |
| regex      | String  | 正则表达式                                                   |
| useRawMsg  | boolean | 如果为true，将使用未格式化的消息，否则将使用格式化的消息。默认值为false。 |
| onMatch    | String  | 过滤器匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是NEUTRAL。 |
| onMismatch | String  | 当过滤器不匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是DENY。 |

示例：

```xml
<RollingFile name="RollingFile" fileName="logs/app.log"
			 filePattern="logs/app-%d{MM-dd-yyyy}.log.gz">
  <RegexFilter regex=".* test .*" onMatch="ACCEPT" onMismatch="DENY"/>
  <PatternLayout>
	<pattern>%d %p %c{1.} [%t] %m%n</pattern>
  </PatternLayout>
  <TimeBasedTriggeringPolicy />
</RollingFile>
```

##### ScriptFilter

ScriptFilter执行一个返回true或false的脚本。
配置参数：

| 参数名     | 类型                            | 描述                                                         |
| ---------- | ------------------------------- | ------------------------------------------------------------ |
| script     | Script, ScriptFile or ScriptRef | 指定需要执行的脚本                                           |
| onMatch    | String                          | 过滤器匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是NEUTRAL。 |
| onMismatch | String                          | 当过滤器不匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是DENY。 |

Script参数：

| 参数名        | 类型           | 描述                                                         |
| ------------- | -------------- | ------------------------------------------------------------ |
| configuration | Configuration  | 拥有此ScriptFilter的配置。                                   |
| level         | Level          | 事件关联的日志级别。仅在配置为全局过滤器时显示。             |
| loggerName    | String         | 日志记录器的名称。仅在配置为全局过滤器时显示。               |
| logEvent      | LogEvent       | 正在处理的日志事件。全局过滤器配置不存在时使用。             |
| marker        | Marker         | 如果有日志调用，则将标记传递给日志调用。仅在配置为全局过滤器时显示。 |
| message       | Message        | 与日志调用关联的消息。仅在配置为全局过滤器时显示。           |
| parameters    | Object[]       | 传递给日志调用的参数。仅在配置为全局过滤器时显示。有些消息将参数作为消息的一部分。 |
| throwable     | Throwable      | 如果有日志调用，则将Throwable传递给日志调用。仅在配置为全局过滤器时显示。 |
| substitutor   | StrSubstitutor | 用于替换查找变量。                                           |

示例：

```xml
<Scripts>
	<ScriptFile name="filter.js" language="JavaScript" path="src/test/resources/scripts/filter.js" charset="UTF-8" />
	<ScriptFile name="filter.groovy" language="groovy" path="src/test/resources/scripts/filter.groovy" charset="UTF-8" />
</Scripts>

<Logger name="TestJavaScriptFilter" level="trace" additivity="false">
  <AppenderRef ref="List">
	<ScriptFilter onMatch="ACCEPT" onMisMatch="DENY">
	  <ScriptRef ref="filter.js" />
	</ScriptFilter>
  </AppenderRef>
</Logger>
```

##### StructuredDataFilter

StructuredDataFilter是一个MapFilter，它还允许过滤事件id、类型和消息。
示例：

```xml
<StructuredDataFilter onMatch="ACCEPT" onMismatch="NEUTRAL" operator="or">
<KeyValuePair key="id" value="Login"/>
<KeyValuePair key="id" value="Logout"/>
</StructuredDataFilter>
```

##### ThreadContextMapFilter (or ContextMapFilter)

ThreadContextMapFilter或ContextMapFilter允许对当前上下文中的数据元素进行过滤。默认情况下，这是ThreadContext映射。
示例：

```xml
<ContextMapFilter onMatch="ACCEPT" onMismatch="NEUTRAL" operator="or">
    <KeyValuePair key="User1" value="DEBUG"/>
    <KeyValuePair key="User2" value="WARN"/>
</ContextMapFilter>
```

示例2：

```xml
<Root level="error">
  <AppenderRef ref="RollingFile"/>
  <ContextMapFilter onMatch="ACCEPT" onMismatch="NEUTRAL" operator="or">
	<KeyValuePair key="foo" value="bar"/>
	<KeyValuePair key="User2" value="WARN"/>
  </ContextMapFilter>
</Root>
```

##### ThresholdFilter

如果配置的level与日志记录器中一样或者高于日志级别，那么使用onMatch的配置，否则使用onMismatch的配置。例如，如果ThresholdFilter配置的日志级别为ERROR，日志记录器配置了DEBUG，那么onMismatch将被返回。因为ERROR比DEBUG更加明确。
配置参数：

| 参数名     | 类型   | 描述                                                         |
| ---------- | ------ | ------------------------------------------------------------ |
| level      | String | 要匹配的有效级别名称                                         |
| onMatch    | String | 过滤器匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是NEUTRAL。 |
| onMismatch | String | 当过滤器不匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是DENY。 |

示例：

```xml
<ThresholdFilter level="TRACE" onMatch="ACCEPT" onMismatch="DENY"/>
```

##### TimeFilter

时间过滤器可用于将过滤限制在一天的特定部分
配置参数：

| 参数名     | 类型   | 描述                                                         |
| ---------- | ------ | ------------------------------------------------------------ |
| start      | String | 开始时间，格式为：HH🇲🇲ss。                                   |
| end        | String | 结束时间，格式为：HH🇲🇲ss。如果结束时间小于开始时间，那么将没有日志输出。 |
| timezone   | String | 比较时使用的时区。                                           |
| onMatch    | String | 过滤器匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是NEUTRAL。 |
| onMismatch | String | 当过滤器不匹配时要采取的操作。可以是ACCEPT、DENY、NEUTRAL，默认是DENY。 |

示例：

```xml
<TimeFilter start="05:00:00" end="05:30:00" onMatch="ACCEPT" onMismatch="DENY"/>
```

#### 异步日志

异步Logger通过使用LMAX Disruptor环形队列和单独的处理线程，避免了锁的竞争，从而实现更高的吞吐量。队列大小默认4096；

##### 全局异步

1. 在代码中添加环境变量

```java
System.setProperty("log4j2.contextSelector, "org.apache.logging.log4j.core.async.AsyncLoggerContextSelector");
```

2. 启动进程时添加参数

```bash
java -Dog4j2.contextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector
```

#### 混合异步

在一个应用中同时使用同步与异步日志；如审计日志，推荐使用同步日志；

通过在配置文件中使用AsyncRoot/AsyncLogger替代Root/Logger；

> 1. 不要同时在appender和logger中使用Async标记；
> 2. 不要在开启了全局异步的情况下使用Async标记；
> 3. 禁用immediateFlush功能；（设置为false）

#### 配置文件加载顺序

##### 默认路径

系统选择配置文件的优先级(从先到后)如下：

1. classpath下的名为log4j2-test.json 或者log4j2-test.jsn的文件.

2. classpath下的名为log4j2-test.xml的文件.

3. classpath下名为log4j2.json 或者log4j2.jsn的文件.

4. classpath下名为log4j2.xml的文件.

##### 自定义路径

```bash
 java  -Dlog4j.configurationFile=/opt/wks/log4j2.xml -jar  demo.jar
```



### logback

logback有三个核心模块logback-access、logback-core及logback-classic；其中logback-classic是log4j的升级版；可通过xml文件进行配置；

```xml
<?xml version="1.0" encoding="UTF-8" ?>

<!--
scan=true ：自动加载xml配置文件，每隔scanPeriod进行一次扫描
debug=true ：是否打印logback内部日志
-->
<configuration scan="true" scanPeriod="3 seconds" DEBUG="true">

    <!--statusListener：监听logback内部信息-->
    <statusListener class="ch.qos.logback.core.status.OnConsoleStatusListener" />

    <!--name="stdout" 指定appender名称-->
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <!--指定日志格式-->
            <pattern>%d{HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n
            </pattern>
        </encoder>
    </appender>

    <appender name="FILE" class="ch.qos.logback.core.FileAppender">
        <file>file.log</file>
        <append>true</append>
        <encoder>
            <pattern>%-4relative [%thread] %-5level %logger{35} - %msg%n
            </pattern>
        </encoder>
    </appender>

    <appender name="ROLLINGFILE"
              class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>mylog.txt</file>
        <rollingPolicy
                class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <!-- rollover daily -->
            <fileNamePattern>mylog-%d{yyyy-MM-dd}.%i.log.zip</fileNamePattern>
            <!-- 每个日志文件大小不超过100MB，在日志文件总大小不超过20GB的情况下保存60天，超出则清楚部分日志 -->
            <maxFileSize>100MB</maxFileSize>
            <maxHistory>60</maxHistory>
            <totalSizeCap>20GB</totalSizeCap>
        </rollingPolicy>
        <encoder>
            <pattern>%d{HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n
            </pattern>
        </encoder>
    </appender>
    <!--appender-ref 指定启用附加器-->
    <root level="INFO">
        <appender-ref ref="STDOUT" />
    </root>

</configuration>
```

### log4j

log4j主要通过log4j.properties配置文件进行定义

```bash
#跟日志
#info：配置日志输出级别
#console：日志附加器，配置日志输出方式，可同时配置多个附加器名称，如不配置，则不生效
log4j.rootLogger=info,console

#附加器可自定义名称，如log4j.appender.xxx中，xxx即为附加器名称，默认控制台为console、文件为file、滚动为rollfile
#控制台附加器
log4j.appender.console = org.apache.log4j.ConsoleAppender
#Target可配置System.out及System.error，error显示文字为红色
log4j.appender.console.Target = System.out
#layout可分为：
# HTMLLayrout--网页表格形式布局
# SimpleLayout--简单布局，包含日志信息级别及日志信息字符串
# PatternLayout--匹配器布局
log4j.appender.console.layout = org.apache.log4j.PatternLayout
# ConversionPattern结合PatternLayout使用，配置PatternLayout布局格式
log4j.appender.console.layout.ConversionPattern = [%-5p][%d{yyyy-MM-dd HH:mm:ss}] %m%n

#文件附加器
log4j.appender.file = org.apache.log4j.ConsoleAppender
log4j.appender.file.Target = /Users/semon/IdeaProjects/helloworld/jakartaee/log4j.log
log4j.appender.file.layout = org.apache.log4j.PatternLayout
log4j.appender.file.layout.ConversionPattern = [%-5p][%d{yyyy-MM-dd HH:mm:ss}] %m%n

#滚动附加器
log4j.appender.rollfile = org.apache.log4j.ConsoleAppender
log4j.appender.rollfile.Target = System.out
log4j.appender.rollfile.layout = org.apache.log4j.PatternLayout
log4j.appender.rollfile.MaxFileSize= 10kb
log4j.appender.rollfile.layout.ConversionPattern = [%-5p][%d{yyyy-MM-dd HH:mm:ss}] %m%n
```

## sl4j规范

代表Simple Logging Facade for Java。它提供了Java中所有日志框架的简单抽象。因此，它使用户能够使用单个依赖项处理任何日志框架；
+ 使用SLF4J框架，可以在部署时迁移到所需的日志记录框架。
+ Slf4J提供了对所有流行的日志框架的绑定，例如log4j，JUL，Simple logging和NOP。因此可以在部署时切换到任何这些流行的框架。
+ 无论使用哪种绑定，SLF4J都支持参数化日志记录消息。
+ 由于SLF4J将应用程序和日志记录框架分离，因此可以轻松编写独立于日志记录框架的应用程序。而无需担心用于编写应用程序的日志记录框架。
+ SLF4J提供了一个简单的Java工具，称为迁移器。使用此工具，可以迁移现有项目，这些项目使用日志框架(如Jakarta Commons Logging(JCL)或log4j或Java.util.logging(JUL))到SLF4J。

sl4j使用demo：

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class Test01 {

	public static void main(String[] args) {
		 // 创建记录日志的对象
		 //当需要更换日志实现jar时，仅需调整具体日志实现jar包及配置文件，代码不需要做变更
        Logger log = LoggerFactory.getLogger(Test01.class);

        log.debug("debug信息");
        log.info("info信息");
        log.warn("warn信息");
        log.error("error信息");
	}

}
```
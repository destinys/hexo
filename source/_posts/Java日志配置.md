---
title: Java日志配置
categories: Tech
tags: Java
author: Semon
---
# Java日志配置
## 常用日志类
+ logger：Jdk内置，基本不用于生产环境
+ log4j：apache提供，已于2015年停止更新，历史遗留项目仍在使用，最后版本为1.2.17
+ log4j2：apache提供，log4j升级版本，性能较log4j提升10倍(官方说明)
+ logback：log4j作者出走后重新开发，性能相对log4j有很大提升


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

### log4j2
log4j2使用基本与log4j一致，通过xml配置文件来定义
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- status="TRACE"这个用于设置log4j2自身内部的信息输出，可以不设置，当设置成trace时，你会看到log4j2内部各种详细输出。OFF则关闭log4j2自己的日志输出 -->
<configuration status="OFF">
    <appenders>
        <Console name="Console" target="SYSTEM_OUT">
            <!--过滤器：控制台只输出level及以上级别的信息（onMatch），其他的直接拒绝（onMismatch）-->
            <ThresholdFilter level="trace" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout pattern="%d{HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n" />
        </Console>
        <!--append默认为false，每次清空日志文件  filename指定相对路径为项目根目录-->
        <File name="log" fileName="log/test.log" append="true">
            <PatternLayout pattern="%d{HH:mm:ss.SSS} %-5level %class{36} %L %M - %msg%xEx%n"/>
        </File>
        <!--指定日志滚动大小阈值为50M，超过大小文件进行压缩 -->
        <RollingFile name="RollingFile" fileName="logs/app.log"
                     filePattern="log/$${date:yyyy-MM}/app-%d{MM-dd-yyyy}-%i.log.gz">
            <PatternLayout pattern="%d{yyyy-MM-dd 'at' HH:mm:ss z} %-5level %class{36} %L %M - %msg%xEx%n"/>
            <SizeBasedTriggeringPolicy size="50MB"/>
        </RollingFile>
    </appenders>
    <loggers>
        <!-- 定义日志输出级别，默认为trace -->
        <root level="trace">
            <!-- 定义启用的日志附加器 -->
            <appender-ref ref="log" />
            <appender-ref ref="Console" />
        </root>
        <!-- 指定特定类的日志配置 -->
        <!-- additivity开启的话，由于这个logger也是满足root的，所以会被打印两遍。 不过root logger 的level是error，为什么Bar里面的trace信息也被打印两遍呢 -->
        <logger name="com.zzstxx.log4j2.HelloWorld2" level="warn"
                additivity="false">
            <appender-ref ref="Console" />
        </logger>
        <!-- 设置指定包目录下的输出级别 -->
        <!-- <logger name="com.zzstxx.log4j2" level="warn"
            additivity="false">
            <appender-ref ref="Console" />
        </logger>s -->
    </loggers>
</configuration>
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
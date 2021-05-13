---
title: Apache Knox简介及部署
categories: Hadoop
tags: knox
author: semon
date: 2021-05-13
---



# Apache Knox 介绍

Apache Knox Gateway是用于与Apache Hadoop部署的RESTAPI和UI交互的应用程序网关。Knox Gateway为与Apache Hadoop集群的所有REST和HTTP交互提供一个单一的访问点。KNOX提供三组面向用户的服务：

+ 代理服务：Apache Knox项目的主要目标是通过代理HTTP资源提供对Apache Hadoop的访问。
+ 认证服务：认证USTAPI访问以及UIS的WebSSO流进行身份验证。LDAP/AD，基于头的PROAUTH、Kerberos、SAML、Oauth都是可选项；
+ 客户服务：可以通过DSL编写脚本或直接将Knox Shell类作为SDK来完成客户端开发；

简单的说，Apache Knox Gateway是一款用于保护Hadoop生态体系安全的代理网关系统，为Hadoop集群提供唯一的代理入口。Knox以类似反向单例的形式挡在用户前面，隐藏部署细节，接管所有用户的HTTP请求，以此来保护集群的安全。

Knox网管本质上是一款基于Jetty实现的高性能反向代理服务器，通过内置的过滤器链来处理URL请求，支持使用LDAP进行用户身份认证。Knox网管在架构设计上具有良好的可扩展性，这种扩展性主要通过Service和Provider这两个扩展性框架来实现。Server扩展性框架还提供了一种网关新增的HTTP或RESTful服务端点的途径。例如WebHDFS就是以新建的Service 的形式加入Knox网管的；而Provider扩展性框架则是用来定义并实现相应Service所提供的功能，例如端点的用户认证或WebHDFS的文件上传等功能。

Knox的官方文档地址为https://knox.apache.org/books/knox-1-4-0/user-guide.html



# Apache Knox 配置

Knox的配置文件位于`$KNOX_HOME/conf`目录下，主要包含以下配置文件：

+ gateway-site.xml：用于配置knox服务访问相关属性；
+ krb5JAASLogin.conf：配置keytab路径及对应principal；
+ users.ldif：配置ldap相关层级，一般不做修改；
+ topologies：配置代理服务拓扑；

knox已预置了部分服务的路由配置信息，主要位于`$KNOX_HOME/data/services`下面

+ service.xml：配置预置服务role及转发规则；需自定义服务，可在此参考预置配置文件进行配置；

> knox服务最终的URL地址生成规则为：协议 + 主机名 + 端口 + knox根目录 + topology + 服务
>
> 协议：一般为http
>
> 主机名：FQDN
>
> 端口：gateway-site.xml配置文件gateway.port参数配置
>
> knox根目录：gateway-site.xml配置文件gateway.path参数配置
>
> topology：由$KNOX_HOME/conf/topology/下文件名决定，例如配置文件名为demo.xml，则topology值则为demo
>
> 服务：为$KNOX_HOME/data/services/xxx/versions/service.xml中role对应name值
>
> 按照以下样例说明配置文件，最终的代理访问地址为：http://hostname:8443/gateway/demo/yarn



## 样例配置说明

### conf/gateway-site.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!--
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->
<configuration>
    <property>
        <name>gateway.backlog</name>
        <value>128</value>
        <description>配置挂起队列最大长度</description>
    </property>

    <property>
        <name>gateway.port</name>
        <value>8443</value>
        <description>配置knox服务端口</description>
    </property>

    <property>
        <name>gateway.path</name>
        <value>gateway</value>
        <description>配置knox服务根目录</description>
    </property>

    <property>
        <name>gateway.gateway.conf.dir</name>
        <value>deployments</value>
        <description>The directory within GATEWAY_HOME that contains gateway topology files and deployments.</description>
    </property>

    <property>
        <name>gateway.hadoop.kerberos.secured</name>
        <value>true</value>
        <description>配置是否启用Kerberos</description>
    </property>

    <property>
        <name>java.security.krb5.conf</name>
        <value>/data/disk2/knox/krb5.conf</value>
        <description>配置集群Kerberos配置文件路径</description>
    </property>

    <property>
        <name>java.security.auth.login.config</name>
        <value>/data/disk2/knox/conf/krb5JAASLogin.conf</value>
        <description>配置keytab相关信息文件路径</description>
    </property>

    <property>
        <name>sun.security.krb5.debug</name>
        <value>false</value>
        <description>配置是否启用Kerberos debug模式</description>
    </property>

    <!-- @since 0.10 Websocket configs -->
    <property>
        <name>gateway.websocket.feature.enabled</name>
        <value>false</value>
        <description>Enable/Disable websocket feature.</description>
    </property>

    <property>
        <name>gateway.scope.cookies.feature.enabled</name>
        <value>true</value>
    </property>

    <property>
        <name>ssl.enabled</name>
        <value>false</value>
    </property>
</configuration>
```



### krb5JAASLogin.conf

```bash
com.sun.security.jgss.initiate {
    com.sun.security.auth.module.Krb5LoginModule required
    renewTGT=true    
    doNotPrompt=true  
    useKeyTab=true
    keyTab="/data/disk2/knox/conf/yarn.keytab"  #配置keytab文件绝对路径
    principal="nm/bigdata006.deppon.com.cn@BIGDATA.DEPPON.COM.CN"  # 配置keytab文件对应principal
    isInitiator=true
    storeKey=true
    useTicketCache=true
    client=true;
};
```



### topologies

该目录保存具体应用配置文件，配置文件名会作为最终knox应用路径的一部分；

以下为一个简单demo供参考；

文件名：demo.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<topology>
  <!-->gateway部分一般保持不变，不做修改<-->
  <gateway>
    <provider>
      <role>webappsec</role>
      <name>WebAppSec</name>
      <enabled>true</enabled>
      <param>
        <name>cors.enabled</name>
        <value>true</value>
      </param>
    </provider>
    <provider>
      <role>identity-assertion</role>
      <name>Default</name>
      <enabled>true</enabled>
    </provider>
    <provider>
      <role>ha</role>
      <name>HaProvider</name>
      <enabled>true</enabled>
      <param>
        <name>WEBHDFS</name>
    <value>maxFailoverAttempts=3;failoverSleep=1000;maxRetryAttempts=300;retrySleep=1000;enabled=true</value>
      </param>
      <param>
        <name>YARNUI</name>
        <value>maxFailoverAttempts=3;failoverSleep=1000;maxRetryAttempts=300;retrySleep=1000;enabled=true
                </value>
      </param>
    </provider>
  </gateway>
  
  
  <!-->role属性值knox已提供常用服务预置，详细参考$KNOX_HOME/data/services/xxx/versions/service.xml文件中role,多个服务可添加多个service配置<-->
  <service>
    <role>NAMENODE</role>
    <url>hdfs://bigdata015.deppon.com.cn:8020/</url>
    <url>hdfs://bigdata016.deppon.com.cn:8020/</url>
  </service>
  <service>
    <role>HDFSUI</role>
    <url>http://bigdata015.deppon.com.cn:50070/</url>
    <url>http://bigdata016.deppon.com.cn:50070/</url>
  </service>
  <service>
    <role>YARNUI</role>
    <url>http://bigdata015.deppon.com.cn:8088/</url>
    <url>http://bigdata016.deppon.com.cn:8088/</url>
  </service>
  <service>
    <role>JOBHISTORYUI</role>
    <url>http://bigdata016.deppon.com.cn:19888/</url>
  </service>
  <service>
    <role>AMBARIUI</role>
    <url>http://bigdata015.deppon.com.cn:8080/</url>
  </service>
</topology>

```





# Knox启动

```bash
$KNONX_HOME/bin/knoxcli.sh create-master [--force]

$KNONX_HOME/bin/gateway.sh start
```



> 说明：
>
> 当knox启动kerberos时，0.8-1.2之间版本会存在认证问题导致转发失败；
---
title: ELK套件介绍及部署
categories: Hadoop
tags: elk
author: semon
date: 2021-04-27
---

EKL是三个开源软件的缩写，分别表示Elasticsearch、Logstash及Kibana，他们都是开源软件，后来新增了Filebeat，它是一个轻量级的日志手机处理工具，Filebeat占用资源少，适合在各个服务器上手机日志后传输给Logstash；

Filebeat用于采集服务器上指定日志文件，并将采集结果发送至output中；有点在于资源消耗非常小，单个采集进程仅占用10多M内存资源；

Elasticsearch是开源分布式搜索引擎，提供搜集、分析、存储数据三大功能；它的特点是：分布式、零配置、自动发现，索引自动分片、索引副本、restful风格API、多数据源、自动搜索负载等；

Logstash主要用于日志搜集、分析、过滤，支持大量的数据获取方式；一般为C/S架构，client端部署在需要搜集日志的主机上，server段负责接收各个client收集的日志并进行过滤、修改等操作，并将结果推送至elasticsearch；

Kibana用于为Logstash和elasticsearch提供可视化界面，帮助汇总、分析和搜索重要数据日志；

# Filebeat

Filebeat由orospector和harvesters组成：

harvesters负责读取单个文件内容并发送至output中，harvesters读取文件为逐行读取；每个文件都将启动一个harvesters，这意味着每个harvesters运行时都会保持文件的打开状态直至harvesters关闭后才会释放文件句柄；

Prospector负责管理Harvsters，并且找到所有需要进行读取的数据源，且prospector会为每个找到的文件保持状态信息，避免因移动或重命名导致重复采集；

## 软件包下载

```bash
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.4.0-linux-x86_64.tar.gz
```

## 部署

```BASH
cd $FILEBEAT_HOME
tar -zxvf filebeat-7.4.0-linux-x86_64.tar.gz 

# 配置filebeat  vi filebeat.yml
filebeat.inputs:
# 定义input类型，常用类型为log和stdin
# - 表示一个input
- type: log  
  # enable选项配置是否启用该input
	enable: true 
	#指定监控目录及模糊匹配文件
	paths:
	- /var/logs/*.log
	# 排除日志文件中符合规则的记录行
	exclude_lines: ['^ABC']  # 排除以ABC开头的记录行
	exclude_files: ['.gz$']  # 排除以.gz结尾的文件
	
	# 在输出数据中新增一个额外字段信息
	# 默认情况下，会在输出信息的fields子目录下以指定的新增fields建立子目录，例如fields.level
  # 这个得意思就是会在es中多添加一个字段，格式为 "filelds":{"level":"debug"}
	fields:
		level: debug
		review: 1
	
	# 如果该选项设置为true，则新增fields成为顶级目录，而不是将其放在fields目录下。
  # 自定义的field会覆盖filebeat默认的field
  # 如果设置为true，则在es中新增的字段格式为："level":"debug"
	fields_under_root: false
	
	# 可以指定Filebeat忽略指定时间段以外修改的日志内容，比如2h（两个小时）或者5m(5分钟)。
	ignore_older: 2h
  
  # 指定超时(指定时间段内文件内容未进行更新)关闭文件handle，默认1h
  colse_older: 1h
  
  # 指定es输出的document类型，默认为log
  document_type: log
  
  # 指定filebeat检测文件变更的频率，0s为尽可能快的进行检测，默认为10s
  scan_frequency: 10s
  
  # 指定harvester 监控文件使用的buffer大小
  harvester_buffer_size: 16384
  
  # 配置单行记录最大值,超出最大值部分会被截断
  max_bytes: 10485760
  
  # 配置一条日志占用多行情况,比如java 报错信息调用栈等
  multiline:
  	pattern: ^\[   # 配置多行日志开始行的匹配模式
  	negate: false  # 配置是否否定多行合并，需与match参数结合使用
  	match: before  # 配置匹配模式后，多行日志合并方式，当negate为true时，before表示匹配行是结尾，与前面不匹配的行进行合并，after表示匹配行是开头，与后面不匹配的行进行合并；当negate为false时，before表示匹配行是开头，与后面不匹配的行进行合并，after表示匹配行是结尾，与前面不匹配的行进行合并
  	max_lines: 500 # 配置最大合并行数
  	timeout: 5s    # 配置多行日志合并超时时间，即到达超时时间后，即认为当前事件(行)已合并完成
  	
  # 配置文件读取位置，为true则从当前文件结尾开始监控文件新增内容
  tail_files: false
  
  # 配置检测到文件结尾(EOF)后再次检测等待时长，默认1s
  backoff: 1s
  
  # 配置检测到文件结尾(EOF)后再次检测等待最大时长，该参数与backoff冲突时，以本参数为准，默认10s
  max_backoff: 10s
  
  # 定义backoff更新频率，即连续backoff指定次数无更新后，backoff将重置为max_backoff，直至检测到更新，再次重置回原backoff
  backoff_factor: 2
  
  # 文件名发生变更时，关闭harvester，建议在windows启用
  force_close_files: false
  
  
# 引入moudle配置
filebeat.config.moudles:
	path: ${path.config}/moudles.d/*.yml
	
	#是否允许重新加载
	reload.enabled: false
  

# 定义输出类型
output：
	elasticsearch:
		hosts:["localhost:9200"]
		protocol: "https"
		username: "es"
		password: "passwd"
		index: "filebeat-%{[beat.version]}-%{+yyyy.MM.dd}"

	logstash:
		hosts: ["localhost:5044"]
		# 默认不启用ssl
		# 配置https证书目录
		ssl.certificate_authorities: ["/etc/pki/root/ca.pem"]
		# 配置客户端证书
		ssl.certificate: "/etc/pki/client/cert.pem"
		# 配置客户端key
		ssl.key: "/etc/pki/client/cert.key"


processors:
	
	# 配置主机元数据采集
	- add_host_metadata: -
	
	# 配置云主机元数据采集
	- add_cloud_metadata: -
	
	# 配置k8s元数据采集
	- add_kubernetes_metadata: -
	
	# 配置docker元数据采集
	- add_docker_metadata: -
	
	# 配置执行进程相关数据
	- add_process_metadata: -
	

logging.level: debug
logging.selectors: ["*"]

# general

# 设置filebeat名称，默认为主机名
name:	demo

# 添加额外标签
tags: ["tagsA","demo"]

```



# ES部署

## 软件包下载

```bash
# es软件包
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.4.0-linux-x86_64.tar.gz
```



## 系统环境调整

```bash
# 预置JDK及NODE.js至环境变量

#添加es用户并修改句柄数限制 vi  /etc/security/limits.conf
useradd elasticsearch

elasticsearch	soft	nproc	65536
elasticsearch	hard	nproc	65536
elasticsearch	soft	nofile	1048576
elasticsearch	hard	nofile	1048576

# 修改虚拟内存大小 vi /etc/sysctl.conf
vm.max_map_count=262144

/sbin/sysctl -p
```



## 部署

规划ES目录及配置文件修改

```bash
cd $ES_HOME
mkdir data logs

# 修改配置文件 config/elasticsearch.yaml

cluster.name: my-application   # 配置Elasticsearch的集群名称，默认是elasticsearch，Elasticsearch会自动发现在同一网段下的es集群，如果在同一个网段下有多个集群，可以利用这个属性来区分不同的集群。
node.name: node-1  #集群的节点名称，Elasticsearch启动的时候会自动创建节点名称，但是你也可以进行配置。
path.data: /usr/local/elastic/data  # 设置索引数据的存储路径，默认是Elasticsearch根目录下的data文件夹，可以设置多个存储路径，用逗号隔开，是的数据在文件级别跨域位置，这样在创建时就有更多的自由路径，如：path.data: /path/to/data1,/path/to/data2
path.logs: /usr/local/elastic/logs  #设置日志文件的存储路径，默认是Elasticsearch根目录下的logs文件夹 
network.host: 192.168.1.20 # 设置绑定的IP地址，可以是ipv4或者ipv5，默认使用0.0.0.0地址，并为http传输开启9200、9300端口，为节点到节点的通信开启9300-9400端口，也可以自行设置IP地址。
http.port: 9200 # 设置对外服务的Http端口，默认是9200
discovery.zen.ping.unicast.hosts: ["192.168.1.11"]  #设置集群中master节点的初始化列表，可以通过这些节点来自动发现新加入集群的节点(主要用于不同网段机器连接)。
discovery.zen.minimum_master_nodes: 1  #设置这个参数来保证集群中的节点可以知道其它N个有master资格的节点，默认为1，当集群多余三个节点时，可以设置大一点的值(2-4)
gateway.recover_after_nodes: 3 # 设置集群中启动N个节点启动时进行数据恢复，默认是1
node.rack: r1 # 每个节点都可以定义一些与之关联的通用属性，用于后期集群进行碎片分配时的过滤。
bootstrap.mlockall: true # 设置为true来锁住内存，因为当JVM开始swapping的时候Elasticsearch的效率会降低，所以要保证他不被swap，可以吧ES_MIN_MEN和ES_MAX_MEN两个环境变量设置为同一个值，并且保证机器有足够的内存分配给Elasticsearch，同时也要允许Elasticsearch的进程可以锁住内存，Linux下可以通过`ulimit -l unlimited`命令


# 修改JVM相关参数   config/jvm.options
-Xms2g
-Xmx2g

#启动服务
bin/elasticsearch -d  #-d：后台启动
```





## 插件安装



### elasticsearch-head

```bash
wget https://github.com/mobz/elasticsearch-head/archive/master.zip

unzip master.zip -d $ES_HOME/modules/

cd $ES_HOME/modules/elasticsearch-head-master

npm install -g grunt --registry=https://registry.npm.taobao.org

npm install


# 修改head插件配置
## vi  elasticsearch-head-master/Gruntfile.js connect节点配置信息，添加hostname属性
connect: {
	    server: {
	        options: {
	            port: 9100,
	            hostname: '0.0.0.0',
	            base: '.',
	            keepalive: true
	        }
	    }
	}


##  elasticsearch-head-master/_site/app.js 
## this.base_uri = this.config.base_uri || this.prefs.get("app-base_uri") || "http://localhost:9200"; 修改localhost为当前节点主机名或IP
this.base_uri = this.config.base_uri || this.prefs.get("app-base_uri") || "http://demo06.bigdata.163.com:9200";



## 启动head插件
elasticsearch-head-master/node_modules/grunt/bin/grunt server &
```



### ik分词插件

```bash
# 分词插件版本需与es版本保持一致
wget https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v7.4.0/elasticsearch-analysis-ik-7.4.0.zip


# 停止es服务
jps |grep Elasticsearch|awk {'print $1'}|xargs kill

# 安装IK分词插件
$ES_HOME/bin/elasticsearch-plugin install file:///root/elasticsearch-analysis-ik-7.4.0.zip

# 查看已安装插件
$ES_HOME/bin/elasticsearch-plugin list


# 创建一个自定义扩展词文件
touch $ES_HOME/config/analysis-ik/my_extra.dic
# 创建一个停用词文件
touch $ES_HOME/config/analysis-ik/my_stopword.dic

```

```xml
<!-- 编辑ik分词器配置文件 vim $ES_HOME/config/analysis-ik/IKAnalyzer.cfg.xml -->

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
        <comment>IK Analyzer 扩展配置</comment>
        <!--用户可以在这里配置自己的扩展字典 -->
        <entry key="ext_dict">my_extra.dic</entry>
         <!--用户可以在这里配置自己的扩展停止词字典-->
        <entry key="ext_stopwords">my_stopword.dic</entry>
  
  			<!--用户可以在这里配置远程扩展字典 -->
  		  <entry key="remote_ext_dict">http://192.168.1.14/ik/my_extra.dic</entry>
        <!--用户可以在这里配置远程扩展停止词字典-->
        <entry key="remote_ext_stopwords">http://192.168.1.14/ik/my_stopword.dic</entry>
</properties>
```





# Kibana

## 软件包下载

```bash
wget https://artifacts.elastic.co/downloads/kibana/kibana-7.4.0-linux-x86_64.tar.gz
```

## 部署

```BASH
tar -zxvf kibana-7.4.0-linux-x86_64.tar.gz C $KINIBA_HOME/

# 创建目录
cd  $KINABA_HOME
mkdir data logs


# 修改配置文件 vi config/kibana.yml

#可通过 http://192.168.46.132:5601 在浏览器访问
server.name: "MyKibana"
server.host: "192.168.100.200"
server.port: 5601
#指定elasticsearch节点
elasticsearch.url: "http://192.168.46.132:9200"
pid.file: /var/run/kibana.pid
# 日志目录
logging.dest: /opt/data/logs/kibana/kibana.log
# 间隔多少毫秒，最小是100ms，默认是5000ms即5秒
ops.interval: 5000
```



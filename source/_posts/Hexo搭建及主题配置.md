---
title: Hexo静态博客搭建
categories: Blog
tags: hexo
date: 2020-01-01
author: Semon
---



# Hexo搭建

## Git安装

```bash
# 安装zlib-devel依赖包
yum install -y zlib-devel curl-devel

# 下载源码包
wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.26.0.tar.gz

# 解压并编译安装
tar -zxvf git-2.26.0.tar.gz -C  /opt/semon
mv /opt/wangsong03/git-2.26.0 /opt/semon/git-2.26.0-source
cd /opt/wangsong03/git-2.26.0-source
./configure --prefix=/opt/semon/git-2.26.0
make & make install

# 添加git至环境变量
echo 'export GIT_HOME=/opt/semon/git-2.26.0'>>/etc/profile
echo 'export PATH=$GIT_HOME/bin:$GIT_HOME/libexec/git-core:$PATH'>>/etc/profile
source /etc/profile
```



## NodeJs安装

```BASH
# 部署node.js
tar -zxvf node-v10.16.0-linux-x64.tar.gz -C /opt/semon

# 添加node至环境变量 vi /etc/profile
export NODE_HOME=/etc/profile/node-v10.16.0-linux-x64

export PATH=$NODE_HOME/bin:$PATH
```



## Hexo安装

```bash
# 修改NPM源地址
npm config set registry https://registry.npm.taobao.org

# 更新NPM并替换为国内镜像源
npm install -g cnpm --registry=https://registry.npm.taobao.org

# 安装hexo-cli
npm install -g hexo-cli



# 初始化博客文件夹 blog
hexo init blog
cd blog

# 创建标签--生成index.md添加type: tags 以及layout: tags
hexo new page tags

# 创建分类--生成index.md添加type: categories 以及layout: categories
hexo new page categories



# 新建友情链接-- --生成index.md添加type: friends 以及layout: friends
hexo new page friends
## source下新建_data文件夹，创建friends.json文件
[{
    "avatar": "http://image.luokangyuan.com/1_qq_27922023.jpg",
    "name": "码酱",
    "introduction": "我不是大佬，只是在追寻大佬的脚步",
    "url": "http://luokangyuan.com/",
    "title": "前去学习"
}, {
    "avatar": "http://image.luokangyuan.com/4027734.jpeg",
    "name": "闪烁之狐",
    "introduction": "编程界大佬，技术牛，人还特别好，不懂的都可以请教大佬",
    "url": "https://blinkfox.github.io/",
    "title": "前去学习"
}, {
    "avatar": "http://image.luokangyuan.com/avatar.jpg",
    "name": "ja_rome",
    "introduction": "平凡的脚步也可以走出伟大的行程",
    "url": "https://me.csdn.net/jlh912008548",
    "title": "前去学习"
},{
    "avatar": "http://static.blinkfox.com/2019/11/23/avatar3.jpeg",
    "name": "Jark's Blog",
    "introduction": "Flink框架研发大佬",
    "url": "http://wuchong.me/",
    "title": "前去学习"
}
]


# 生成静态页面
hexo g

# 启动服务
hexo s
```



## GitHub配置

```bash
# 配置远程仓库
## 用于向仓库提交时表明提交人身份
git config --global user.name "destinys"
git config --global user.email "4304517@qq.com"

#添加公钥至git并测试
ssh -T git@github.com

# 初始化本地git
git init

# 添加远程仓库
git remote add origin git@github.com:destinys/blog.git

# 查看远程仓库及别名
git remote -v

# 强制远程覆盖本地
git fetch --all
git reset --hard origin/master
git pull origin master

# 强制本地覆盖远程

```



> 常见错误：
>
> Q1：ssh: connect to host github.com port 22: Operation timed out
>
> A1：添加以下内容至~/.ssh/config中即可
>
> Host github.com  
> User git  
> Hostname ssh.github.com 
> PreferredAuthentications publickey  
> IdentityFile ~/.ssh/id_rsa 
> Port 443



## 博客配置

### 主题配置

hexo当前较为热门的主题为next、hexo-theme-matery等；

```bash
# 主题下载
cd blog
git clone https://github.com/blinkfox/hexo-theme-matery.git ./themes/
git clone https://github.com/theme-next/hexo-theme-next.git ./themes/

# 添加搜索插件
npm install hexo-generator-search --save

## _config.yml 添加配置
search:
  path: search.xml
  field: post
  format:html
  limit:1000
### 跳转至主题配置文件
local_search:
	enable: true
	trigger: auto
	top_n_per_article: 1
	unescape:	false
	preload: false

## 需添加hexo clean 后在重新生成和部署，否则关键字不会变红
hexo clean && hexo g -d

# 添加快速部署插件
npm install hexo-deployer-git --save
  
# 添加中文转拼音插件
npm i hexo-permalink-pinyin --save

## _config.yml 添加配置
permalink_pinyin:
  enable: true
  separator: '-' # default: '-'

# 字数统计插件
npm i --save hexo-wordcount

## _config.yml 添加配置
postInfo:
  date: true
  update: false
  wordCount: false # set true.
  totalCount: false # set true.
  min2read: false # set true.
  readCount: false # set true.

#添加表情支持插件
npm install hexo-filter-github-emojis --save
## _config.yml 添加配置
githubEmojis:
  enable: true
  className: github-emoji
  inject: true
  styles:
  customEmojis:
  


# 配置当前主题
## vi blog/_config.yaml
# 添加algolia搜索
npm install hexo-algolia --save

# 注册algolia
## 登陆官网地址：https://www.algolia.com/
## 创建index，然后点击左侧API Keys，跳转后点击上方 ALL API Keys(要自己新建一个)，点击右上角New API Key跳转页面中，仅修改最下方ACL属性即可，其他保持默认，ACL添加所有项；

algolia:
  applicationID: 'your applicationID'
  apiKey: 'your apiKey'
  adminApiKey: 'your adminApiKey'
  indexName: 'your indexName'
  chunkSize: 5000
  
# 上传数据至algolia
export HEXO_ALGOLIA_INDEXING_KEY=your apiKey
hexo algolia

# 切换至主题目录下的配置文件themes/xxx/_config.yml
algolia_search:
  enable: true
  hits:
    per_page: 10
  labels:
    input_placeholder: Search for Posts
    hits_empty: "我们没有找到任何搜索结果: ${query}"
    hits_stats: "找到${hits}条结果（用时${time} ms）"

```


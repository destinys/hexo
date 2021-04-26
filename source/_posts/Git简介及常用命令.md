---
title: Git简介及使用
categories: Dev
tags: git
date: 2021-03-15
author: Semon
top: true
---



# Git介绍

Git是什么？

Git是目前世界上最先进的分布式版本控制系统，没有之一！

很多人都知道，Linus在1991年创建了开源的Linux，从此，Linux系统不断发展，目前已经成为最大的服务器系统软件；

在2002年以前，Linux系统的开发方式是由全世界各地的志愿者将源码文件通过diff的方式发送给linus，然后由linus本人通过手工方式进行代码合并，到了2002年，Linux系统已经发展了10年，代码库之大让linus很难继续通过手工方式进行管理；于是linus选择了一个商业化版本控制系统BitKeeper，BitKeeper软件的公司BitMover处于人道主义精神，授权linux社区免费使用这个版本系统

2005年由于Samba的Andrew视图破解BitKeeper协议被BitMover公司发现，要收回Linux社区的免费使用权；

linus在此情况下花费两周时间自己用c语言编写了一个分布式版本控制系统，这就是Git！一个月之内，Linux系统的源码纳入了Git管理。

Git迅速成为最流行的分布式版本控制系统，尤其是2008年，GitHub网站上线，他为开源项目免费提供Git存储，无数开源项目开始迁移至GitHub，包括jQuery、PHP、Ruby等；

下图为git架构及常用操作：

![image-20200426113305606](./Git简介及常用命令/image-20200426113305606.png)

{% asset_img Git.assets/image-20200426113305606.png This is an test image %}

专有名词解释：

+ Workspace：工作区，即本地文件系统初始化后目录，初始化命令为`git init`；
+ Index：暂存区，工作区变更后提交的中转站，提交命令为`git add`；
+ Repository：仓库区，也叫本地仓库，实现本地代码版本控制，提交命令为`git commit`；
+ Remote：远程库，一般位于公网或办公网服务器上，实现多人协作，提交命令为`git push`；
+ Branch：版本分支，用于在当前版本的基础上进行feature功能开发；



## git初始化

git初始化`git init`会在当前目录下生成一个隐藏目录`.git`及一个隐藏文件`.gitignore`；

+ `.gitignore`：配置当前工作区中不纳入git管理的文件及文件夹列表，文件名支持模糊匹配；
+ `.git`：用于保存暂存区及仓库区相关信息；



## git常用配置

```bash
# 查看当前git配置
git config --list

# 添加git配置
git config -e

# 添加git全局配置
git config -e --global

# 查看git全局参数
git config --global --list

# 查看git本地参数
git config --local --list

# 查看git系统参数
git config --system --list

# 查看git所有参数：全局+本地+系统
git config --list

# 配置git显示相关颜色
git config --global color.ui true

# 查看当前配置远程仓库
git remote -v

# 关联远程仓库
## origin 为自定义远程仓库别名  如需使用公钥进行数据同步，仓库链接需使用ssh协议
git remote add origin git@github.com:destinys/blog.git
## 删除远程仓库别名
git remote rm origin

# 本地分支关联成成分支
git branch -u origin/remote_branch local_branch
git branch --set-upstream-to <local_branch> origin/<remote_branch>

# 在本地创建与远程分支对应的分支
git checkout -b local_branch origin/<remote_branch>

```



## git远程仓库管理

```bash
# 拉取远程仓库
## clone是一个从无到有的操作，不需要本地必须是一个git仓库，clone会将远程仓库完整的克隆到本地，包括仓库的版本变化
## 语法：git clone <远程仓库> [本地目录] 本地目录省略则拉取至当前目录
git clone origin  local_dir

## pull是拉取远程仓库更新并与本地分支进行合并  pull = fetch + merge 
## 语法： git pull <远程仓库> [远程分支]:[本地分支]，如果省略远程分支与本地分支参数，则默认拉取远程master分支并与本地当前分支合并
git pull origin  master:master

## fetch是拉取远程仓库指定分支至本地仓库指定分支
## 语法：git fetch <远程仓库> <远程分支>:[指定分支]，如果省略指定分支，如果省略指定分支，则默认拉取远程分支至本地master分支
git fetch origin master
```



## git本地仓库管理

```bash
# 工作区提交至暂存区
## 语法：git add [-f] <文件名1 文件名2| 文件夹名 |.> git提交支持指定文件或使用"."进行通配提交所有变更 参数-f用于强制提交被.gitignore忽略的文件
git add .

# 暂存区提交至本地仓库
## 语法： git commit -m "remark" 将当前暂存区变更提交至本地仓库，并进行备注
git commit -m "bug fix"

# 版本回退
# 语法：git reset --hard HEAD^  HEAD^表示上一个版本,HEAD^^表示上上一个版本，HEAD~100表示上100个版本
git reset --hard HEAD^

# 仓库与工作区对比
# 语法：git diff HEAD -- <文件名> 对比工作区与本地仓库的指定文件
git diff HEAD -- readme.txt

# 撤销工作区修改
## git checkout --<文件名> 撤销工作区文件的修改，回到与本地库或暂存区一致
git checkout --readme.txt

# 撤销暂存区修改
## git reset HEAD <文件名> 撤销暂存区修改
git reset HEAD readme.txt

# 删除本地库文件
## 语法：git rm <文件名> && git commit -m "remark" 
git rm -r --cached readme.txt
git commit -m "remove file"
```



## git分支管理

git仓库初始化后，默认会在仓库中创建出master分支；

```bash
# 创建本地分支
## 语法：git branch  <分支名称>
git branch dev

# 切换本地分支 
## 语法：git checkout/switch <分支名称>   新版本建议使用swith进行分支切换
git checkout dev

# 创建并切换至分支
## 语法：git checkout -b <分支名称>
## 语法：git switch -c <分支名称>
git checkout -b dev

# 查看所有分支 当前分支以*标识
## git branch [-ravv]：查看本地分支，参数r查看远程所有分支；参数a查看本地+远程所有分支；vv查看本地分支对应的远程分支
git branch

# 删除本地分支
## 语法：git branch -d|D <分支dev>：删除分支dev，参数D为强制删除dev
git branch -d dev

# 分支重命名
## 语法：git branch -m oldname newname：将分支名称从oldname重命名为newname
git branch -m dev ops


# 分支合并
## 语法：git merge <分支dev> [--no-ff]：将分支dev合并至当前分支 no-ff，禁用fast forward模式
git merge dev

## 语法：git rebase <分支名>：指定所有分支变更为以<分支名>为基础分支
git rebase master

## 语法：git merge --abort <分支dev>：分支合并，存在冲突则重建合并前状态
git merge --abort dev

# 分支冲突查看
## 语法：git status （需在执行分支合并命令后执行，根据提示的冲突文件，手工进行处理后在提交）
git status

# 查看分支合并情况
## 语法：git log [--graph] [--pretty=oneline] [--abbrev-commit]： graph图形化显示 pretty定义显示格式 abbrev-commit 仅显示sha1前几个字符
git log --graph --pretty=oneline --abbrev-commit

# 删除分支
## git branch -d|D <分支名>：D强制删除没有提交的分支
git branch -d dev

# 工作区暂存
## 语法：git stash：将当前工作区中修改但尚未提交至暂存区的内容存储起来
git stash

## 语法：git stash list：查看暂存工作区列表
git stash list

## 语法：git stash pop：恢复暂存工作区并删除暂存
git stash pop

## 语法：git stash apply stash@{0}：指定要恢复的暂存内容，stash@{0}为通过git stash list查看结果的序号
git stash apply stash@{0}

## 语法：git stash drop stash@{0}：删除指定的暂存内容
git stash drop stash@{0}

## git cherry-pick <sha1-id>：将指定commit合并至当前分支
git cherry-pick 4ch05e1
```

> HEAD：指向当前分支最新提交节点
>
> 分支名：指向各自分支最后提交节点
>
> 快进模式：又名Fast-forward，当被合并分支与当前分支存在继承关系，进行合并时，git会直接将当前分支移动到被合并分支最新节点，并将HEAD指向当前分支；
>
> 普通模式：当被合并分支与当前分支不存在继承关系时，git会使用两个分支最近的共同父节点及两个分支的最新节点进行合并生成一个新的节点，并将当前分支指向新节点，HEAD指向当前分支；
>
> 变基合并：又名rebase，当存在多个分支依赖的基础分支不同时，可通过rebase将所有分支变更为依赖相同的基础分支，然后在进行普通分支合并，使项目提交时间线条理清晰；



## git标签管理

git在进行版本提交前，可以对本地将要提交的版本打标签进行标记，相比于每次提交自动生成的sha1编码，自定义的标签明显更直观易懂；

```bash
# 对当前提交进行标记
## 语法：git tag <tag_name> [commit_id] tag_name由用户自定定义，一般使用直观易理解的短语，如需对历史已提交版本进行标签，则指定对应提交版本的commit_id
git tag v1.0 

# 查看当前分支所有标签
## 语法：git tag
git tag

# 创建带说明的标签
## 语法：git tag -a <tag_name> -m "description" [commit_id]
git tag -a v1.0 -m "demo" 1094adb

# 查看标签说明
## 语法：git show <tag_name>
git show v1.0

# 删除标签
## 语法：git tag -d <tag_name>
git tag -d v1.0

# 推送标签至远程仓库
## 语法：git push <origin> <tag_name>
git push origin v1.0

# 推送所有未推送标签至远程仓库
## 语法：git push <origin> --tags
git push origin --tags

# 删除远程仓库便签
## 语法：git tag -d <tag_name> && git push <origin> :refs/tags/<tag_name>
git tag -d v1.0
git push origin :refs/tags/v1.0
```


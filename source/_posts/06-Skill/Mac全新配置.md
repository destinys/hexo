---
title: Mac初始化
categories: Skill
tags: mac
date: 2021-08-20
author: semon
---

# 系统安装

| 快捷键                       | 功能说明                                                     |
| ---------------------------- | ------------------------------------------------------------ |
| command + R                  | 安装Mac上当前安装的macOS                                     |
| option + command + R         | 安装与当前Mac兼容的最新版本macOS                             |
| shift + option + command + R | 安装Mac出厂时的macOS或与出厂最接近且官方仍提供验证的macOS版本 |

如果不需要保留已有数据，可以进入磁盘工具，选择抹掉所有数据；

磁盘格式化一般选择APFS格式，方案选择GUID分区图

# 常用软件

## 软件管理

HomeBrew是一款Mac OS平台下的软件包管理工具，拥有安装、卸载、更新、查看、搜索等很多实用的功能。简单的一条指令，就可以实现包管理，而不用你关心各种依赖和文件路径的情况，十分方便快捷。

### HomeBrew安装

```bash
# 安装CLT for Xcode
xcode-select --install

# 设置环境变量
if [[ "$(uname -s)" == "Linux" ]]; then BREW_TYPE="linuxbrew"; else BREW_TYPE="homebrew"; fi
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/${BREW_TYPE}-core.git"

# 从清华镜像源下载安装脚本并安装 Homebrew / Linuxbrew
git clone --depth=1 https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/install.git brew-install
# 安装brew
/bin/bash brew-install/install.sh
# 删除安装脚本
rm -rf brew-install

# 替换brew程序本身的源
git -C "$(brew --repo)" remote set-url origin  https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git

# 替换仓库上游源
# 使用下面的几行命令自动设置
BREW_TAPS="$(brew tap)"
for tap in core cask{,-fonts,-drivers,-versions} command-not-found; do
    if echo "$BREW_TAPS" | grep -qE "^homebrew/${tap}\$"; then
        # 将已有 tap 的上游设置为本镜像并设置 auto update
        # 注：原 auto update 只针对托管在 GitHub 上的上游有效
        git -C "$(brew --repo homebrew/${tap})" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-${tap}.git
        git -C "$(brew --repo homebrew/${tap})" config homebrew.forceautoupdate true
    else   # 在 tap 缺失时自动安装（如不需要请删除此行和下面一行）
        brew tap --force-auto-update homebrew/${tap} https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-${tap}.git
    fi
done

# 重新设置 git 仓库 HEAD
brew update-reset


# 还原仓库上游
# brew 程序本身，Homebrew / Linuxbrew 相同
git -C "$(brew --repo)" remote set-url origin https://github.com/Homebrew/brew.git

# 以下针对 macOS 系统上的 Homebrew
BREW_TAPS="$(brew tap)"
for tap in core cask{,-fonts,-drivers,-versions} command-not-found; do
    if echo "$BREW_TAPS" | grep -qE "^homebrew/${tap}\$"; then
        git -C "$(brew --repo homebrew/${tap})" remote set-url origin https://github.com/Homebrew/homebrew-${tap}.git
    fi
done

# 重新设置 git 仓库 HEAD
brew update-reset
```

### HomeBrew基本用法

| 操作                 | 命令                |
| -------------------- | ------------------- |
| 更新HomeBrew         | brew update         |
| 更新所有已安装软件包 | brew upgrade        |
| 更新指定软件包       | brew upgrade 软件名 |
| 查找软件包           | brew search 软件名  |
| 安装软件包           | brew install 软件名 |
| 卸载软件包           | brew remove 软件名  |
| 列出已安装软件包     | brew list           |
| 查看安装软件包信息   | brew info 软件名    |
| 列出软件包依赖关系   | brew deps 软件名    |
| 列出可更新软件包列表 | brew outdated       |

## 终端软件

推荐`iTerm2 + Oh-My-ZSH`

### 软件安装

iTerm2：登陆官网下载dmg安装包安装即可；

### 插件安装

```bash
# 插件安装
$ sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# 主题安装 可使用自带ys和 agnoster

# 添加插件
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_HOME/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions



plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# 自定义PROMPTING
PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"
PROMPT+=' %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)'
export PROMPT="%{$fg[blue]%}%n@%m%{$reset_color%} %{$fg[green]%}%c %{$reset_color%}$ "



# 字体安装（Powerline Fonts）
git clone https://github.com/powerline/fonts.git
cd fonts
./install.sh
cd ..
rm -rf fonts

# vim 主题
git clone  https://github.com/gosukiwi/vim-atom-dark.git
mkdir -p ~/.vim/colors
cp vim-atom-dark-256.vim ~/.vim/colors/

## 启用主题
vi ~/.vimrc
syntax enable
set background=dark
colorscheme vim-atom-dark-256


## 可用提示符
添加左侧提示符
PROMPT=''
添加右侧提示符

RPROMPT=''

%n - username
%m - short name of the current host
%M - name of curent host
%# - a `%` or a `#`, depending on whether the shell is running as root or not
%~ - relative path
%/ or %d - absolute path
%c or %C - Trailing component of the current working directory.
%t - time 12hr am/pm format
%T - time 24hr format
%w - day and date (day-dd)
%D - Date (default: yy-mm-dd)
%D{%f} - day of the month
%l or %y - The line  (tty)  the user is logged in on, without `/dev/' prefix.

`%F{237}` 256 color number

`%F{red}` 8 color name (black, red, green, yellow, blue, magenta, cyan, white)

`$FG[237]` (notice the `$` sign instead of `%`) 256 color number

`$fg[red]` (notice the `$` and lower case `fg`) 8 color name (black, red, green, yellow, blue, magenta, cyan, white)

`%{$fg_bold[blue]%}` bold variants

`%F` is Foreground color, `$f` for resetting foreground color
 `%K` is bacKground color, `%k` for resetting background-color
 `$reset_color` is a Zsh variable that resets the color of the output
 You can use Unicode for symbols
 `%E` Clear to end of the line.
 `%U` `(%u)` to Start (stop) underline mode.
```



## SDK

+ python3

+ jdk8
+ node.js

## 效率工具

+ AIfred：全局搜索工具

+ TinyCal：小历，农历日历

+ 文件对比：Meld
+ 文本编辑：Typora、Vs Code、
+ 解压软件：The UnArchiver
+ 系统助手：macOS Assistant
+ 日程：滴答清单
+ 网盘：OneDrive，Adrive
+ 远程桌面：Jump Desktop
+ 播放器：INNA
+ 下载工具：
+ 输入法：搜狗

## 开发工具

+ 虚拟机：Parallels Desktop
+ IDE：idea
+ 数据库：Dbeaver
+ FTP工具：Forklift
+ 反编译：JD GUI
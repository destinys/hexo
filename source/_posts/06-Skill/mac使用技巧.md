---
title: Mac使用小技巧
categories: Skill
tags: mac
date: 2021-05-17
author: semon
---

# Mac系统使用小技巧

## 命令行分卷压缩

```bash
# -b 指定单个分卷大小  -a 指定分卷序号位数  demo.zip为文件通配前缀
# 压缩后生成文件需手动修改后缀为demo.zip.001格式才能解压
zip - demo.txt |split  -b  20mb -a 3 - demo.zip
```


---
title: Python编程入门
categories: Program
tags: python
author: semon
date: 2021-05-12
---

# Python编程入门

## python模块

### 模块导入

### `__all__` 变量

该变量的值是一个列表，存储的是当前模块中一些成员（变量、函数或者类）的名称。通过在模块文件中设置`__all__` 变量，当其它文件以“from 模块名 import *”的形式导入该模块时，该文件中只能使用 `__all__`  列表中指定的成员，未指定的成员是无法导入的。


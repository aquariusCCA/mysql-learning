> ✏️**MySQL 图形化管理工具极大地方便了数据库的操作与管理，常用的图形化管理工具有：MySQL Workbench、phpMyAdmin、Navicat Preminum、MySQLDumper、SQLyog、dbeaver、MySQL ODBC Connector。**

# 5 MySQL 图形化管理工具

## 关键字

- `MySQL Workbench`：MySQL 官方图形化管理工具
- `Navicat`：常见的 MySQL 图形化管理与开发工具
- `SQLyog`：轻量且常见的 MySQL 图形化管理工具
- `DBeaver`：支持多种数据库的通用管理工具
- `GUI`：图形用户界面，适合可视化管理数据库
- `ER模型`：Workbench 支持的数据建模功能
- `正向工程` `逆向工程`：数据库设计与还原常见操作
- `caching_sha2_password`：MySQL 8 常见认证插件
- `mysql_native_password`：旧版本常见认证方式
- `ALTER USER`：修改用户认证方式与密码
- `FLUSH PRIVILEGES`：刷新权限使修改生效

## 工具1. MySQL Workbench

MySQL 官方提供的图形化管理工具`MySQL Workbench`完全支持`MySQL 5.0`以上的版本。

`MySQL Workbench`分为社区版和商业版，社区版完全免费，而商业版则是按年收费。

`MySQL Workbench` 为数据库管理员、程序开发者和系统规划师提供可视化设计、模型建立、以及数据库管理功能。它包含了用于创建复杂的数据建模 ER 模型，正向和逆向数据库工程，也可以用于执行通常需要花费大量时间的、难以变更和管理的文档任务。

下载地址：[http://dev.mysql.com/downloads/workbench/。](http://dev.mysql.com/downloads/workbench/%E3%80%82)

### 使用：

首先，我们点击 Windows 左下角的「开始」按钮，如果你是 Win10 系统，可以直接看到所有程序。接着，找到「MySQL」，点开，找到「`MySQL Workbench 8.0 CE`」。点击打开 `Workbench`，如下图所示：

![image-20211007153522427.png](./images/image-20211007153522427.png)

左下角有个本地连接，点击，录入 Root 的密码，登录本地 MySQL 数据库服务器，如下图所示：

![image-20211014195108502.png](./images/image-20211014195108502.png)

![image-20211014195129219.png](./images/image-20211014195129219.png)

### 界面介绍

![image-20211014195142849.png](./images/image-20211014195142849.png)

- 上方是菜单。左上方是导航栏，这里我们可以看到 MySQL 数据库服务器里面的数据 库，包括数据表、视图、存储过程和函数；左下方是信息栏，可以显示上方选中的数据 库、数据表等对象的信息。
- 中间上方是工作区，你可以在这里写 SQL 语句，点击上方菜单栏左边的第三个运行按 钮，就可以执行工作区的 SQL 语句了。
- 中间下方是输出区，用来显示 SQL 语句的运行情况，包括什么时间开始运行的、运行的 内容、运行的输出，以及所花费的时长等信息。

好了，下面我们就用 Workbench 实际创建一个数据库，并且导入一个 Excel 数据文件， 来生成一个数据表。数据表是存储数据的载体，有了数据表以后，我们就能对数据进行操作了。

## 工具2. Navicat

Navicat MySQL 是一个强大的 MySQL 数据库服务器管理和开发工具。它可以与任何 `3.21` 或以上版本的 MySQL 一起工作，支持触发器、存储过程、函数、事件、视图、管理用户等，对于新手来说易学易用。

其精心设计的图形用户界面（GUI）可以让用户用一种安全简便的方式来快速方便地创建、组织、访问和共享信息。Navicat 支持中文，有免费版本提供。

下载地址：[http://www.navicat.com/。](http://www.navicat.com/%E3%80%82)

![1557378069584.png](./images/1557378069584.png)

![image-20210913180359685.png](./images/image-20210913180359685.png)

## 工具3. SQLyog

SQLyog 是业界著名的 Webyog 公司出品的一款简洁高效、功能强大的图形化 MySQL 数据库管理工具。

这款工具是使用C++语言开发的。该工具可以方便地创建数据库、表、视图和索引等，还可以方便地进行插入、更新和删除等操作，同时可以方便地进行数据库、数据表的备份和还原。该工具不仅可以通过SQL文件进行大量文件的导入和导出，还可以导入和导出XML、HTML和CSV等多种格式的数据。

下载地址：[http://www.webyog.com/，读者也可以搜索中文版的下载地址。](http://www.webyog.com/%EF%BC%8C%E8%AF%BB%E8%80%85%E4%B9%9F%E5%8F%AF%E4%BB%A5%E6%90%9C%E7%B4%A2%E4%B8%AD%E6%96%87%E7%89%88%E7%9A%84%E4%B8%8B%E8%BD%BD%E5%9C%B0%E5%9D%80%E3%80%82)

![image-20211014213018979.png](./images/image-20211014213018979.png)

![image-20211014213036470.png](./images/image-20211014213036470.png)

## 工具4：DBeaver

DBeaver 是一个通用的数据库管理工具和 SQL 客户端，支持所有流行的数据库：MySQL、PostgreSQL、SQLite、Oracle、DB2、SQL Server、 Sybase、MS Access、Teradata、 Firebird、Apache Hive、Phoenix、Presto 等。

DBeaver 比大多数的 SQL 管理工具要轻量，而且支持中文界面。

DBeaver 社区版作为一个免费开源的产品，和其他类似的软件相比，在功能和易用性上都毫不逊色。

唯一需要注意是 DBeaver 是用 Java 编程语言开发的，所以需要拥有 JDK（Java Development ToolKit）环境。如果电脑上没有 JDK，在选择安装 DBeaver组件时，勾选「Include Java」即可。

下载地址：[https://dbeaver.io/download/](https://dbeaver.io/download/)

![image-20211014195237457.png](./images/image-20211014195237457.png)

![image-20211014195251371.png](./images/image-20211014195251371.png)

![image-20211014195300510.png](./images/image-20211014195300510.png)

![image-20211014195309805.png](./images/image-20211014195309805.png)

## 常见连接问题

有些图形界面工具，特别是旧版本的图形界面工具，在连接 MySQL8 时出现「`Authentication plugin 'caching_sha2_password' cannot be loaded`」错误。

![image-20211019215249254.png](./images/image-20211019215249254.png)

出现这个原因是 `MySQL8` 之前的版本中加密规则是 `mysql_native_password`，而在 `MySQL8` 之后，加密规则是 `caching_sha2_password`。

解决问题方法有两种，第一种是升级图形界面工具版本，第二种是把 MySQL8 用户登录密码加密规则还原成 `mysql_native_password`。

第二种解决方案如下，用命令行登录 MySQL 数据库之后，执行如下命令修改用户密码加密规则并更新用户密码，这里修改用户名为 「`root@localhost`」的用户密码规则为「`mysql_native_password`」，密码值为「`123456`」，如图所示。

```sql
#使用mysql数据库
USE mysql;

#修改'root'@'localhost'用户的密码规则和密码
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'abc123';

#刷新权限
FLUSH PRIVILEGES;
```

![image-20211019215408965.png](./images/image-20211019215408965.png)

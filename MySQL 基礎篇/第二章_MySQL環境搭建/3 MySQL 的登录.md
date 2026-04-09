# 3 MySQL 的登录

> 所属章节：[第二章_MySQL環境搭建](./README.md)

## 本节导读

这一节主要介绍在 MySQL 安装完成后，如何确认服务已经启动，以及如何通过图形界面或命令行登录并退出 MySQL。

如果你每次都会忘记登录命令格式，这篇就是后续最常回来的参考页；复习时可以优先看服务名、命令格式和常见报错说明。

如果你还没有完成安装和环境变量设置，可以先回看 [2 MySQL 的下载、安装、配置](./2%20MySQL%20的下载、安装、配置.md)；如果登录时遇到命令无法识别或权限问题，也可以继续查 [7 常见问题的解决（课外内容）](./7%20常见问题的解决(课外内容).md)。

## 关键字

- `MySQL服务`：登录前需先确认服务已启动
- `services.msc`：Windows 服务管理入口
- `MySQL80`：Windows 下常见的 MySQL 服务名
- `net start`：启动 MySQL 服务
- `net stop`：停止 MySQL 服务
- `mysql -h -P -u -p`：命令行登录 MySQL 的基本格式
- `localhost` `127.0.0.1`：本机连接常用主机地址
- `3306`：MySQL 默认端口
- `root`：默认常见管理员账户
- `mysql -V` `mysql --version`：查看客户端版本
- `select version()`：登录后查看服务端版本
- `exit` `quit`：退出 MySQL 登录

## 3.1 服务的启动与停止

MySQL 安装完毕之后，需要启动服务器进程，不然客户端无法连接数据库。

在前面的配置过程中，已经将 MySQL 安装为 Windows 服务，并且勾选当 Windows 启动、停止时，MySQL 也自动启动、停止。

## 方式1：使用图形界面工具

- 步骤1：打开 windows 服务
    - 方式1：计算机（点击鼠标右键）→ 管理（点击）→ 服务和应用程序（点击）→ 服务（点击）
    - 方式2：控制面板（点击）→ 系统和安全（点击）→ 管理工具（点击）→ 服务（点击）
    - 方式3：任务栏（点击鼠标右键）→ 启动任务管理器（点击）→ 服务（点击）
    - 方式4：单击【开始】菜单，在搜索框中输入「`services.msc`」，按 Enter 键确认

- 步骤2：找到 `MySQL80`（点击鼠标右键）→ 启动或停止（点击）
    
    ![image-20211014183908375.png](./images/image-20211014183908375.png)
    

## 方式2：使用命令行工具

```bash
# 启动 MySQL 服务命令：
net start MySQL服务名

# 停止 MySQL 服务命令：
net stop MySQL服务名
```

![image-20211014184037414.png](./images/image-20211014184037414.png)

> **✏️说明：**
> 1. start 和 stop 后面的服务名应与之前配置时指定的服务名一致。
> 2. 如果当你输入命令后，提示 **拒绝服务**，请以`系统管理员身份`打开命令提示符界面重新尝试。

---

## 3.2 自带客户端的登录与退出

当 MySQL 服务启动完成后，便可以通过客户端来登录 MySQL 数据库。注意：确认服务是开启的。

## 登录方式1：MySQL 自带客户端

开始菜单 → 所有程序 → MySQL → MySQL 8.0 Command Line Client

![image-20211014184425147.png](./images/image-20211014184425147.png)

**✏️说明：仅限于 root 用户**

## 登录方式2：windows 命令行

![image-20211014185035137.png](./images/image-20211014185035137.png)

- 格式：
    
    ```bash
    mysql -h 主机名 -P 端口号 -u 用户名 -p密码
    ```
    
- 举例：
    
    ```bash
    mysql -h localhost -P 3306 -u root -pabc123  # 这里我设置的root用户的密码是abc123
    ```
    

### 注意：

1. `-p` 与密码之间不能有空格，其他参数名与参数值之间可以有空格也可以没有空格。如：
    
    ```bash
    mysql -hlocalhost -P3306 -uroot -pabc123
    ```
    
2. 密码建议在下一行输入，保证安全
    
    ```bash
    mysql -h localhost -P 3306 -u root -p
    Enter password:****
    ```
    
3. 客户端和服务器在同一台机器上，所以输入 `localhost` 或者 `IP` 地址 `127.0.0.1`。同时，因为是连接本机：`-hlocalhost` 就可以省略，如果端口号没有修改：`-P3306` 也可以省略
    
    简写成：
    
    ```bash
    mysql -u root -p
    Enter password:****
    ```
    
4. 连接成功后，有关于 MySQL Server 服务版本的信息，还有第几次连接的 id 标识。
5. 可以在命令行通过以下方式获取 MySQL Server 服务版本的信息：
    
    ```bash
    mysql -V
    ```
    
    ```
    mysql --version
    
    ```
    
    或**登录**后，通过以下方式查看当前版本信息：
    
    ```bash
    select version();
    ```

## 退出登录

```bash
exit
# 或
quit
```

## 延伸阅读

- [2 MySQL 的下载、安装、配置](./2%20MySQL%20的下载、安装、配置.md)
- [4 MySQL 演示使用](./4%20MySQL%20演示使用.md)
- [7 常见问题的解决（课外内容）](./7%20常见问题的解决(课外内容).md)

---

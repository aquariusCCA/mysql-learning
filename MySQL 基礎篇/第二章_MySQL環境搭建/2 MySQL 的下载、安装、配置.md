# 2 MySQL 的下载、安装、配置

> 所属章节：MySQL 基礎篇 / 第二章_MySQL環境搭建
> 建议回查情境：需要重新下载安装包、忘记 MySQL 8.0 的安装与初始化配置步骤、命令行无法直接使用 `mysql`、安装失败需要排查依赖或残留服务时
> 上一节：[1 MySQL 的卸载](./1%20MySQL%20的卸载.md)
> 下一节：[3 MySQL 的登录](./3%20MySQL%20的登录.md)

## 本节导读

这一节主要整理 MySQL 在 Windows 下的下载、安装、初始化配置、环境变量设置，以及安装失败时最常见的排查方向。

这篇内容偏操作型。第一次安装时，建议按“版本选择 -> 下载安装包 -> 安装 -> 初始化配置 -> 配置环境变量 -> 常见问题”的顺序阅读；如果只是回查某一步，直接根据下面的 `快速定位` 跳到对应小节即可。

如果你已经卸载过旧版本，建议先确认 [1 MySQL 的卸载](./1%20MySQL%20的卸载.md) 里的残留目录和服务是否已经清理干净；安装完成后，可以继续阅读 [3 MySQL 的登录](./3%20MySQL%20的登录.md)。

## 你会在这篇学到什么

- MySQL 常见版本之间的区别，以及课程为什么使用 `8.0.26`。
- Windows 下更适合下载哪一种 MySQL 安装包。
- 如何通过 MSI 安装程序安装 `MySQL 8.0`。
- 初始化配置时端口号、授权方式、`root` 密码和 Windows 服务名分别代表什么。
- 为什么要把 MySQL 的 `bin` 目录加入 `Path` 环境变量。
- 安装失败时，应优先检查哪些依赖、残留目录和残留服务。

## 快速定位

- `2.1 MySQL 的 4 大版本`：先分清常见版本与课程所用版本
- `2.2 软件的下载`：确认官网入口、Windows 安装包类型与下载建议
- `2.3 MySQL 8.0 的安装`：按安装器完成程序安装
- `2.4 配置 MySQL 8.0`：完成初始化配置、服务名和 `root` 密码设置
- `2.5 配置 MySQL 8.0 环境变量`：解决命令行不能直接使用 `mysql`
- `2.6 MySQL 5.7 版本的安装、配置`：对照 8.0 和 5.7 的差异
- `2.7 安装失败问题`：安装失败、重装失败、残留服务的处理方式

## 关键字

- `MySQL Community Server`：社区版，开源免费
- `MySQL Enterprise Edition`：企业版，付费并提供官方支持
- `MySQL Cluster`：MySQL 集群版本
- `MySQL Workbench`：MySQL 官方图形化管理工具
- `MSI 安装程序`：Windows 下推荐的安装方式
- `mysql-installer-web-community`：联网安装包
- `mysql-installer-community`：离线安装包
- `Custom`：安装时可自定义组件和目录
- `3306`：MySQL 默认端口
- `root`：MySQL 默认常见管理员账户
- `SHA256`：MySQL 8 默认较新的密码加密方式
- `MySQL80`：Windows 下常见的 MySQL 服务名
- `Path`：配置后可直接在命令行使用 `mysql`
- `my.ini`：MySQL 主要配置文件
- `.NET Framework`：Windows 安装 MySQL 时常见依赖
- `Visual C++ 2015-2019`：Windows 安装 MySQL 时常见运行库依赖
- `sc delete`：删除残留 MySQL 服务

## 建议阅读顺序

- 第一次安装时，先看 `2.1` 和 `2.2`，确认版本与安装包，再按 `2.3`、`2.4`、`2.5` 完成安装与配置。
- 如果你只是想解决“命令无法识别”的问题，可以直接看 `2.5 配置 MySQL 8.0 环境变量`。
- 如果已经安装失败或卸载重装失败，优先跳到 `2.7 安装失败问题`，结合 [1 MySQL 的卸载](./1%20MySQL%20的卸载.md) 一起排查。

## 2.1 MySQL 的 4 大版本

- **MySQL Community Server**：社区版本，开源免费，自由下载，但不提供官方技术支持，适用于大多数普通用户。
- **MySQL Enterprise Edition**：企业版本，需要付费，不能直接在线下载，可试用 30 天。它提供更多功能和更完整的技术支持，更适合对数据库功能和可靠性要求较高的企业客户。
- **MySQL Cluster**：集群版，开源免费，用于架设集群服务器，可将多个 MySQL Server 组织成一个集群环境，需要在社区版或企业版基础上使用。
- **MySQL Cluster CGE**：高级集群版，需要付费。

按原教材时间点，文中提到的最新版本是 `8.0.27`，发布时间为 `2021 年 10 月`；而 `8.0.0` 早在 `2016-09-12` 就已发布。本课程实际使用的是 `8.0.26`。

此外，官方还提供了 `MySQL Workbench` 这款专为 MySQL 设计的图形界面管理工具。

`MySQL Workbench` 也分为两个版本：

1. `社区版`：MySQL Workbench OSS
2. `商用版`：MySQL Workbench SE

## 2.2 软件的下载

### 2.2.1 下载地址

官网：[https://www.mysql.com](https://www.mysql.com/)

### 2.2.2 打开官网，点击 Downloads

先进入官网首页，再点击 `DOWNLOADS`，然后选择 `MySQL Community (GPL) Downloads`。

![MySQL 官网下载入口](./images/image-20210817185920150.png)

### 2.2.3 点击 MySQL Community Server

![MySQL Community Server 下载页](./images/image-20210817185955123.png)

### 2.2.4 在 General Availability (GA) Releases 中选择适合的版本

Windows 平台下常见的安装文件有两类：

- `MSI 安装文件`：带安装向导，适合大多数初学者。
- `ZIP 压缩包`：免安装版，需要自己处理初始化和启动，通常不作为初学阶段首选。

一般建议优先使用二进制分发版，也就是 `MSI 安装程序`。这种方式自带图形化安装向导，安装流程更直观，也更适合跟着课程同步操作。

> ✏️ Windows 系统下推荐下载 `MSI 安装程序`，点击 `Go to Download Page` 即可进入下载页。
>
> ![进入下载页](./images/image-20210727192819147.png)
> ![选择下载版本](./images/image-20211014163001964.png)

### 2.2.5 Windows 下两种安装程序的区别

Windows 下的 `MySQL 8.0` 安装程序通常有两种：

- `mysql-installer-web-community-8.0.26.0.msi`
  - 安装程序体积约 `2.4 MB`
  - 安装过程中需要联网下载组件
- `mysql-installer-community-8.0.26.0.msi`
  - 安装程序体积约 `450.7 MB`
  - 安装过程中可以直接离线安装
  - **更推荐**

如果你的网络环境不稳定，或者希望安装过程中少受网络影响，优先下载离线版会更稳妥。

### 2.2.6 如果要下载 MySQL 5.7

如果你需要安装 `MySQL 5.7`，则需要进入 `Archives`，再选择 `MySQL 5.7` 的对应版本。原教材这里示例下载的是 `MySQL 5.7.34`。

![选择 MySQL 5.7 归档版本](./images/image-20211014163228051.png)
![下载 MySQL 5.7 安装包](./images/image-20211014163353156.png)

## 2.3 MySQL 8.0 版本的安装

MySQL 下载完成后，双击安装文件，按照安装向导完成程序安装。下面以 `mysql-installer-community-8.0.26.0.msi` 为例说明。

### 步骤 1：打开安装向导

双击下载好的 `mysql-installer-community-8.0.26.0.msi` 文件，进入安装向导。

### 步骤 2：选择安装类型

在 `Choosing a Setup Type` 窗口中，可以看到 5 种安装类型：

- `Developer Default`：默认开发环境安装
- `Server only`：仅安装服务器
- `Client only`：仅安装客户端
- `Full`：完全安装
- `Custom`：自定义安装

这里建议选择 `Custom`，因为这样可以更清楚地控制要安装哪些组件，以及安装路径放在哪里。

![选择 Custom 安装类型](./images/image-20211014170553535.png)

### 步骤 3：选择要安装的产品和安装目录

在 `Select Products` 窗口中，可以按需添加需要安装的产品。比如选择 `MySQL Server 8.0.26-X64` 后，单击右侧的 `→` 按钮，就可以把 MySQL 服务器加入安装列表。

![选择安装产品](./images/image-20211014170638699.png)

如果直接点击 `Next`，安装路径会使用默认值。如果你希望自定义安装目录，可以先选中对应产品，再点击下方的 `Advanced Options`。

![打开高级安装选项](./images/image-20211014170814386.png)

进入高级选项后，可以分别设置：

- MySQL 服务程序安装目录
- 数据存储目录

如果不修改，默认会放在 `C` 盘的 `Program Files` 和 `ProgramData` 目录中，其中 `ProgramData` 默认是隐藏目录。

自定义路径时，建议注意两点：

- 不要使用中文目录
- 服务目录和数据目录尽量分开存放

![自定义安装目录与数据目录](./images/image-20211014170857263.png)

### 步骤 4：执行安装

确认安装产品和安装路径后，点击 `Next` 进入确认窗口，再点击 `Execute` 开始安装。

![执行安装](./images/image-20211014170934889.png)

### 步骤 5：确认安装完成

安装完成后，在 `Status` 列表中会显示 `Complete`。

![安装完成状态](./images/image-20211014171002259.png)

## 2.4 配置 MySQL 8.0

程序安装完成后，还需要继续完成 MySQL 服务器的初始化配置。

### 步骤 1：进入产品配置窗口

在上一小节安装完成后的界面点击 `Next`，进入产品配置窗口。

![进入产品配置窗口](./images/clip_image002-1634203188594.jpg)

### 步骤 2：配置服务器类型与端口

继续点击 `Next`，进入 MySQL 服务器类型配置窗口。端口号通常保持默认的 `3306` 即可。

![配置服务器类型与端口](./images/clip_image004-1634203188595.jpg)

其中，`Config Type` 用来指定服务器使用场景，常见有 3 个选项：

- `Development Machine`：开发机器，适合个人电脑。因为机器上往往还会运行其他程序，所以 MySQL 会尽量少占用系统资源。
- `Server Machine`：服务器机器，适合与 Web 服务器等其他服务一起运行的场景。
- `Dedicated Machine`：专用服务器，表示整台机器主要只运行 MySQL 服务，MySQL 会尽量使用更多可用系统资源。

![Config Type 选项](./images/clip_image006-1634203188595.jpg)

### 步骤 3：选择授权方式

继续点击 `Next`，进入授权方式设置窗口。

上方选项是 `MySQL 8.0` 默认推荐的新授权方式，使用基于 `SHA256` 的密码加密方法；下方选项是传统授权方式，主要用于兼容 `5.x` 版本。

![设置授权方式](./images/clip_image008-1634203188595.jpg)

### 步骤 4：设置 root 密码

继续点击 `Next`，进入 `root` 超级管理员密码设置窗口。这里需要输入两次相同的登录密码。

如果需要，也可以通过 `Add User` 添加其他用户，并指定用户名、允许登录的主机范围以及角色等。不过这部分通常放到后续用户管理章节再学习即可，这里可以先不添加。

![设置 root 密码](./images/clip_image010-1634203188595.jpg)

### 步骤 5：设置 Windows 服务名

继续点击 `Next`，进入服务配置窗口。这里需要确认 MySQL 服务在 Windows 服务列表中显示的名称。

课程中将服务名设置为 `MySQL80`。如果希望系统启动时自动启动 MySQL，可以勾选 `Start the MySQL Server at System Startup`，一般也推荐勾选。

运行服务的账户可以选择：

- `Standard System Account`
- `Custom User`

这里推荐前者。

![设置服务名与启动方式](./images/clip_image012-1634203188596.jpg)

### 步骤 6：执行配置

继续点击 `Next`，进入确认配置界面，然后点击 `Execute` 执行配置。

![执行服务器配置](./images/clip_image014-1634203188596.jpg)

### 步骤 7：完成服务器配置

配置完成后，点击 `Finish` 即可完成服务器初始化配置。

![完成服务器配置](./images/clip_image016.jpg)

### 步骤 8：如果还有其他产品需要配置

如果你还安装了其他 MySQL 产品，可以继续逐个配置；如果没有，则直接点击 `Next`，结束整个安装流程。

![继续配置其他产品或进入结束步骤](./images/clip_image018.jpg)

### 步骤 9：结束安装与配置

到这里，整个安装和初始化配置过程就结束了。

![结束安装与配置](./images/clip_image020.jpg)

## 2.5 配置 MySQL 8.0 环境变量

如果没有配置 MySQL 环境变量，那么在命令行中通常不能直接输入 `mysql` 来登录数据库。

下面是配置 `Path` 环境变量的标准步骤：

### 步骤 1：打开系统属性

在桌面上右击【此电脑】，选择【属性】。

### 步骤 2：进入高级系统设置

在系统窗口中点击【高级系统设置】。

### 步骤 3：打开环境变量窗口

在【系统属性】对话框中切换到【高级】选项卡，再点击【环境变量】。

### 步骤 4：找到 Path 变量

在系统变量列表中找到 `Path` 变量。

### 步骤 5：把 MySQL 的 bin 目录加入 Path

点击【编辑】，然后把 MySQL 应用程序的 `bin` 目录加入变量值，例如：

```text
C:\Program Files\MySQL\MySQL Server 8.0\bin
```

如果系统中已经有其他路径，记得按系统要求与其他路径分隔保存。

### 步骤 6：保存并验证

保存设置后重新打开命令行，再执行 `mysql --version` 或后续登录命令，确认系统已经可以识别 `mysql`。

如果这里仍然报“不是内部或外部命令”，可以继续查看 [7 常见问题的解决（课外内容）](./7%20常见问题的解决(课外内容).md)。

## 2.6 MySQL 5.7 版本的安装、配置

### 安装

`MySQL 5.7` 的安装流程与前面 `MySQL 8.0` 的操作基本一致，除了版本号不同之外，其余大多数步骤都是相同的，所以这里省略 `MySQL 5.7.34` 的安装截图。

### 配置

`MySQL 5.7` 的配置环节与 `MySQL 8.0` 有细微差异，但大部分情况下按照安装器默认步骤继续点击 `Next` 即可，不会影响正常使用。

> ✏️ 配置 `MySQL 5.7` 时，最需要注意的一点是：如果你的机器上已经安装过 `MySQL 8.0`，那么 `MySQL 5.7` 不能继续使用相同的端口号。

## 2.7 安装失败问题

> 🧠 MySQL 的安装和配置本身并不复杂，但对初学者来说，最容易出错的往往不是安装步骤本身，而是系统依赖、旧版本残留和服务没有清理干净。

### 问题 1：无法打开 MySQL 8.0 安装包，或者安装过程中失败

#### 可能原因

在运行 `MySQL 8.0` 安装包之前，需要确认系统里已经安装相关依赖。如果缺少 `.NET Framework`，安装器可能无法正常启动或安装失败。

![缺少 .NET Framework 的提示](./images/clip_image002.gif)

#### 解决方案

到微软官网下载安装 `Microsoft .NET Framework 4.5` 后，再重新安装 MySQL：

[https://www.microsoft.com/en-us/download/details.aspx?id=42642](https://www.microsoft.com/en-us/download/details.aspx?id=42642)

另外，还要确保 `Windows Installer` 工作正常。Windows 安装 `MySQL 8.0` 时，通常也需要提前安装 `Microsoft Visual C++ 2015-2019` 相关运行库。

![Visual C++ 相关依赖提示 1](./images/clip_image004.gif)
![Visual C++ 相关依赖提示 2](./images/clip_image006.gif)

对应的下载地址可参考微软官方说明：

[https://support.microsoft.com/en-us/topic/the-latest-supported-visual-c-downloads-2647da03-1eea-4433-9aff-95f26a218cc0](https://support.microsoft.com/en-us/topic/the-latest-supported-visual-c-downloads-2647da03-1eea-4433-9aff-95f26a218cc0)

### 问题 2：卸载重装 MySQL 失败

#### 可能原因

这类问题通常是因为旧版本卸载时没有完全清除相关信息，导致重新安装时仍然检测到残留目录或历史配置。

#### 解决办法

把以前的安装目录删除。如果之前没有单独指定服务安装目录，则默认目录一般是：

```text
C:\Program Files\MySQL
```

同时，也要删除 MySQL 的数据目录。如果之前没有单独指定数据目录，则默认常见位置是：

```text
C:\ProgramData\MySQL
```

`ProgramData` 通常是隐藏目录。删除旧目录后，再重新安装即可。

如果你不确定哪些目录应该删除，可以先回看 [1 MySQL 的卸载](./1%20MySQL%20的卸载.md)。

### 问题 3：如何删除 Windows 中残留的 MySQL 服务

#### 适用场景

你已经卸载过 MySQL，但在 Windows 服务列表里仍然看到旧的 MySQL 服务名，或者重新安装时提示同名服务已存在。

#### 解决办法

在系统搜索框输入 `cmd`，按回车打开命令提示符，然后执行：

```bash
sc delete MySQL服务名
```

执行后，旧的残留服务就会被删除。

## 常见回查问题

- Windows 下推荐下载哪个 MySQL 安装包？
- `mysql-installer-web-community` 和 `mysql-installer-community` 有什么区别？
- 安装时为什么建议选择 `Custom`？
- 配置 MySQL 8.0 时，`Config Type`、端口号、授权方式和服务名分别在哪里设置？
- 配置完环境变量后，为什么命令行仍然找不到 `mysql`？
- 卸载后重装失败时，通常应该优先检查哪些残留目录和服务？

## 延伸阅读

- [1 MySQL 的卸载](./1%20MySQL%20的卸载.md)
- [3 MySQL 的登录](./3%20MySQL%20的登录.md)
- [7 常见问题的解决（课外内容）](./7%20常见问题的解决(课外内容).md)

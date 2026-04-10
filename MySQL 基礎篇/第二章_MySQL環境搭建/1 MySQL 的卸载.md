# 1 MySQL 的卸载

> 所属章节：[第二章_MySQL環境搭建](./README.md)
> 建議回查情境：安装失败需要重装 MySQL、卸载后仍然残留服务或环境变量、需要确认数据目录和注册表是否要清理时

## 本节导读

这一节主要整理在 Windows 环境下卸载 MySQL 的标准流程，包括停止服务、执行卸载、清理残留目录，以及必要时处理注册表和环境变量。

这篇内容偏操作型，适合在“安装失败需要重装”时查阅；复习时只要先记住卸载前备份数据、服务目录与数据目录要分开检查这两个重点即可。

## 关键字

- `MySQL80`：Windows 下常见的 MySQL 服务名
- `任务管理器`：停止 MySQL 服务的图形化入口
- `控制面板`：卸载 MySQL 程序的常见入口
- `mysql-installer-community`：通过安装器执行卸载
- `Remove the data directory`：卸载时同步删除数据目录
- `ProgramData`：Windows 下常见的 MySQL 数据目录位置
- `数据备份`：卸载和清理前需要先确认
- `regedit`：打开注册表编辑器
- `ControlSet001` `CurrentControlSet`：注册表中常见的服务路径
- `Path`：需要手动删除残留的 MySQL 环境变量

## 你会在这篇学到什么

- 卸载 MySQL 前为什么要先停止服务。
- 控制面板卸载和 MySQL Installer 卸载的差异。
- 哪些目录属于程序目录，哪些目录可能保存数据。
- 什么时候需要继续清理注册表和环境变量。
- 清理前为什么必须先确认数据备份。

## 操作前检查

- 确认是否需要保留原有数据库数据。
- 如果要保留数据，先完成备份，再继续卸载或删除目录。
- 区分 MySQL 的安装目录和数据目录，不要把仍需保留的数据误删。
- 注册表和环境变量属于系统级配置，只有在普通卸载后仍安装失败时再处理。

## 步骤1：停止 MySQL 服务

在卸载之前，先停止 `MySQL8.0` 的服务。按键盘上的 **Ctrl + Alt + Delete** 组合键，打开 **任务管理器** 对话框，可以在 **服务** 列表找到 **MySQL8.0** 的服务，如果现在 **正在运行** 状态，可以右键单击服务，选择 **停止** 选项停止MySQL8.0的服务，如图所示。

![image-20211014153604802.png](./images/image-20211014153604802.png)

---

## 步骤2：软件的卸载

### 方式1：通过控制面板方式

卸载 `MySQL8.0` 的程序可以和其他桌面应用程序一样直接在 **控制面板** 选择 **卸载程序**，并在程序列表中找到 `MySQL8.0` 服务器程序，直接双击卸载即可，如图所示。这种方式删除，数据目录下的数据不会跟着删除。

![image-20211014153657668.png](./images/image-20211014153657668.png)

### 方式2：通过安装包提供的卸载功能卸载

你也可以通过安装向导程序进行 `MySQL8.0` 服务器程序的卸载。

- ① 再次双击下载的 `mysql-installer-community-8.0.26.0.msi` 文件，打开安装向导。安装向导会自动检测已安装的 MySQL 服务器程序。
- ② 选择要卸载的 MySQL 服务器程序，单击 **Remove**（移除），即可进行卸载。
    
    ![image-20211014153722683.png](./images/image-20211014153722683.png)
    
- ③ 单击 **Next**（下一步）按钮，确认卸载。
    
    ![image-20211014153747283.png](./images/image-20211014153747283.png)
    
- ④ 弹出是否同时移除数据目录选择窗口。如果想要同时删除 MySQL 服务器中的数据，则勾选 **Remove the data directory**，如图所示。
    
    ![image-20211014154112574.png](./images/image-20211014154112574.png)
    
- ⑤ 执行卸载。单击 **Execute**（执行）按钮进行卸载。
    
    ![image-20211014154006530.png](./images/image-20211014154006530.png)
    
- ⑥ 完成卸载。单击 **Finish**（完成）按钮即可。如果想要同时卸载 `MySQL8.0` 的安装向导程序，勾选 **Yes，Uninstall MySQL Installer** 即可，如图所示。
    
    ![image-20211014154046268.png](./images/image-20211014154046268.png)
    
---

## 步骤3：残余文件的清理

如果再次安装不成功，可以卸载后对残余文件进行清理后再安装。

(1) 服务目录：mysql 服务的安装目录

(2) 数据目录：默认在 `C:\ProgramData\MySQL`

如果自己单独指定过数据目录，就找到自己的数据目录进行删除即可。

> ⚠️**注意：**
> - 请在卸载前做好数据备份
> - 在操作完以后，需要重启计算机，然后进行安装即可。**如果仍然安装失败，需要继续操作如下步骤4。**

---

## 步骤4：清理注册表（选做）

如果前几步做了，再次安装还是失败，那么可以清理注册表。

如何打开注册表编辑器：在系统的搜索框中输入 `regedit`

```bash
HKEY_LOCAL_MACHINE\\SYSTEM\\ControlSet001\\Services\\Eventlog\\Application\\MySQL服务 目录删除

HKEY_LOCAL_MACHINE\\SYSTEM\\ControlSet001\\Services\\MySQL服务 目录删除

HKEY_LOCAL_MACHINE\\SYSTEM\\ControlSet002\\Services\\Eventlog\\Application\\MySQL服务 目录删除

HKEY_LOCAL_MACHINE\\SYSTEM\\ControlSet002\\Services\\MySQL服务 目录删除

HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\Eventlog\\Application\\MySQL服务目录删除

HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\MySQL服务删除

```

> ✏️ **注册表中的 `ControlSet001`、`ControlSet002`，不一定是 `001` 和 `002`，可能是 `ControlSet005`、`ControlSet006` 之类**

---

## 步骤5：删除环境变量配置

找到 path 环境变量，将其中关于 mysql 的环境变量删除，**切记不要全部删除。**

例如：删除  `D:\develop_tools\mysql\MySQLServer8.0.26\bin;`  这个部分

![1575694476072.png](./images/1575694476072.png)

## 常见风险点

- **只卸载程序，不等于删除数据**：控制面板卸载通常不会自动删除数据目录。
- **勾选 `Remove the data directory` 会删除数据目录**：如果没有备份，可能导致原有数据库数据丢失。
- **注册表清理是选做项**：优先完成普通卸载和残留目录清理，仍然安装失败时再处理注册表。
- **环境变量只删除 MySQL 相关片段**：不要把整个 `Path` 变量清空。
- **清理后建议重启电脑**：让服务、注册表和环境变量变更更稳定地生效。

## 一句话抓核心

MySQL 卸载的核心顺序是：先停止服务，再卸载程序；如果重装仍失败，再按需清理数据目录、注册表和环境变量。

## 小结

这一节你需要记住：

- 卸载前先确认是否需要备份数据。
- 控制面板卸载通常只删除程序，不一定删除数据目录。
- 安装器卸载时，`Remove the data directory` 会影响数据目录，需要谨慎选择。
- 注册表和环境变量属于后续排查步骤，不建议一开始就随意删除。

## 延伸阅读

- [2 MySQL 的下载、安装、配置](./2%20MySQL%20的下载、安装、配置.md)

---

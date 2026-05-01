### 5.2.5 跨 database 移表的限制

`RENAME TABLE` 不只能改表名，也可以把表從一個 database 移到另一個 database。

例如：

```sql
RENAME TABLE current_db.employee TO archive_db.employee;
```

這表示：

```text
current_db.employee
移到
archive_db.employee
```

也就是把 `employee` 這張表從 `current_db` 搬到 `archive_db`。

---

#### 5.2.5.1 如果表有 Trigger，不能直接跨 database rename

如果表上有 Trigger，不能直接把表 rename 到另一個 database。

例如：

```sql
RENAME TABLE current_db.employee TO archive_db.employee;
```

如果 `current_db.employee` 上有 Trigger，可能會失敗，並出現類似：

```text
Trigger in wrong schema
```

原因是 Trigger 本身是屬於特定 database/schema 的物件。

---

#### 5.2.5.2 View 可以改名，但不能用 `RENAME TABLE` 跨 database 移動

MySQL 裡面，View 也可以使用 `RENAME TABLE` 改名。

例如：

```sql
RENAME TABLE old_view TO new_view;
```

但是 View 不能用這種方式搬到另一個 database。

例如下面這種操作是不建議，也可能不允許的：

```sql
RENAME TABLE current_db.v_employee TO archive_db.v_employee;
```

---

#### 5.2.5.3 如果跨不同檔案系統移動表，可能受作業系統影響

這一點比較抽象，但可以用「database 其實可能對應到底層資料目錄」來理解。

假設你執行：

```sql
RENAME TABLE current_db.employee TO archive_db.employee;
```

從 SQL 角度看，只是：

```text
current_db.employee 改成 archive_db.employee
```

但從 MySQL 底層角度看，這張表可能有對應的資料檔案。

概念上可以想成：

```text
/var/lib/mysql/current_db/employee.ibd
```

要變成：

```text
/var/lib/mysql/archive_db/employee.ibd
```

如果 `current_db` 和 `archive_db` 都在同一個檔案系統內，這種移動通常比較像「改路徑名稱」。

例如：

```text
/var/lib/mysql/current_db/employee.ibd
/var/lib/mysql/archive_db/employee.ibd
```

兩者都在：

```text
/var/lib/mysql
```

這種情況比較單純。

但是如果兩個 database 底層位置在不同磁碟、不同分割區、不同掛載點，情況就不同。

例如：

```text
/data1/mysql/current_db/employee.ibd
/data2/mysql/archive_db/employee.ibd
```

在 Windows 也可以想成：

```text
current_db 在 D:\mysql\data\current_db
archive_db 在 E:\mysql\data\archive_db
```

這時候就可能不是單純改名，而是牽涉到底層檔案移動。

可以把它想成：

```text
同一個檔案系統：
比較像「在同一個資料夾系統內改名字」

不同檔案系統：
比較像「從一顆硬碟搬到另一顆硬碟」
```

跨檔案系統移動時，底層可能會受到這些因素影響：

```text
作業系統是否支援這種移動
檔案權限是否允許
磁碟空間是否足夠
MySQL 資料檔案是否能正確搬移
儲存引擎與資料表檔案配置方式
```

所以這句話的重點不是說「一定會失敗」，而是提醒：

> 跨 database rename 雖然看起來只是 SQL 改名，但底層可能牽涉到資料表檔案的移動。如果兩個 database 位於不同檔案系統，成功與否就可能受到作業系統底層檔案操作能力影響。

因此正式環境中，不應該把跨 database rename 當成完全沒有風險的操作。

---

#### 5.2.5.4 如果有外鍵關係，正式環境要完整檢查

如果表有外鍵關係，也要特別小心。

例如：

```text
department
employee
```

其中 `employee.dept_id` 參考 `department.id`。

```sql
CREATE TABLE department (
    id BIGINT PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE employee (
    id BIGINT PRIMARY KEY,
    name VARCHAR(50),
    dept_id BIGINT,
    CONSTRAINT fk_employee_department
        FOREIGN KEY (dept_id)
        REFERENCES department(id)
);
```

如果你把 `department` 或 `employee` 移到另一個 database，外鍵關係可能會受到影響。

MySQL 的 InnoDB 會處理部分外鍵 metadata，例如某些外鍵 constraint 名稱可能會跟著表名調整；指向被 rename 表的外鍵名稱也可能自動更新。但如果發生命名衝突，`RENAME TABLE` 會失敗，需要手動 drop 並重新建立外鍵。

所以正式環境中，不能只看這張表本身，還要檢查：

```text
這張表是否引用其他表
其他表是否引用這張表
外鍵名稱是否可能衝突
搬移後 referenced table 是否仍然正確
```

尤其是跨 database 時，更要小心外鍵是否仍符合預期。

---

#### 5.2.5.5 如果有表級權限，權限不會自動搬到新表名

這一點也很重要。

假設原本有使用者被授權只能查詢舊表：

```sql
GRANT SELECT ON current_db.employee TO 'app_user'@'%';
```

接著你執行：

```sql
RENAME TABLE current_db.employee TO archive_db.employee;
```

表搬走之後，原本針對：

```text
current_db.employee
```

的權限，不會自動變成：

```text
archive_db.employee
```

也就是說，原本的表級權限不會自動跟著新表名一起搬移。

所以搬移後可能需要重新授權：

```sql
GRANT SELECT ON archive_db.employee TO 'app_user'@'%';
```

並視情況回收舊權限：

```sql
REVOKE SELECT ON current_db.employee FROM 'app_user'@'%';
```

---

#### 5.2.5.6 正式環境建議檢查項目

跨 database rename 前，至少要檢查下面幾類物件。

---

### 1. 檢查是否有 Trigger

```sql
SELECT 
    TRIGGER_SCHEMA,
    TRIGGER_NAME,
    EVENT_OBJECT_SCHEMA,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING,
    EVENT_MANIPULATION
FROM INFORMATION_SCHEMA.TRIGGERS
WHERE EVENT_OBJECT_SCHEMA = 'current_db'
  AND EVENT_OBJECT_TABLE = 'employee';
```

如果查得出資料，代表這張表有 Trigger。

這時候不建議直接跨 database rename。

比較安全的做法是：

```text
1. 先備份 Trigger 定義
2. 在目標 database 建立新表或搬移資料
3. 在目標 database 重新建立 Trigger
4. 測試 Trigger 是否正常
5. 確認沒問題後再處理舊表
```

可以用下面方式查看 Trigger 建立語句：

```sql
SHOW TRIGGERS FROM current_db LIKE 'employee';
```

或查詢：

```sql
SELECT 
    TRIGGER_NAME,
    ACTION_STATEMENT
FROM INFORMATION_SCHEMA.TRIGGERS
WHERE EVENT_OBJECT_SCHEMA = 'current_db'
  AND EVENT_OBJECT_TABLE = 'employee';
```

---

### 2. 檢查是否有外鍵關係

檢查這張表本身是否有外鍵，以及其他表是否引用這張表：

```sql
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_SCHEMA,
    REFERENCED_TABLE_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE (TABLE_SCHEMA = 'current_db' AND TABLE_NAME = 'employee')
   OR (REFERENCED_TABLE_SCHEMA = 'current_db' AND REFERENCED_TABLE_NAME = 'employee');
```

查詢結果可以分成兩種情況看。

第一種，這張表引用別人：

```text
TABLE_SCHEMA = current_db
TABLE_NAME = employee
REFERENCED_TABLE_NAME 不為 NULL
```

代表：

```text
employee 是子表
employee 裡面有外鍵指向其他表
```

第二種，別人引用這張表：

```text
REFERENCED_TABLE_SCHEMA = current_db
REFERENCED_TABLE_NAME = employee
```

代表：

```text
employee 是父表
其他表有外鍵指向 employee
```

這兩種情況都要小心。

---

### 3. 檢查是否有 View 依賴這張表

如果有 View 查詢這張表，表搬走後，View 可能失效或查到舊位置。

可以查：

```sql
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    VIEW_DEFINITION
FROM INFORMATION_SCHEMA.VIEWS
WHERE VIEW_DEFINITION LIKE '%employee%';
```

如果 View 裡面有明確寫：

```sql
current_db.employee
```

表搬到 `archive_db` 後，就要評估是否改成：

```sql
archive_db.employee
```

---

### 4. 檢查 Stored Procedure / Function 是否有用到舊表名

Stored Procedure 或 Function 裡面也可能寫死舊表名。

```sql
SELECT 
    ROUTINE_SCHEMA,
    ROUTINE_NAME,
    ROUTINE_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_DEFINITION LIKE '%employee%';
```

如果查到資料，要進一步確認裡面是否有使用：

```sql
current_db.employee
```

或：

```sql
employee
```

如果是沒有加 database 名稱的 `employee`，還要看執行時所在的預設 database 是哪一個。

---

### 5. 檢查 Event 排程是否有用到舊表名

如果 MySQL Event Scheduler 裡面有排程操作這張表，也要檢查。

```sql
SELECT 
    EVENT_SCHEMA,
    EVENT_NAME,
    EVENT_DEFINITION
FROM INFORMATION_SCHEMA.EVENTS
WHERE EVENT_DEFINITION LIKE '%employee%';
```

例如排程裡面有：

```sql
INSERT INTO current_db.employee ...
```

表搬走後就要改成：

```sql
INSERT INTO archive_db.employee ...
```

---

### 6. 檢查表級權限

可以先查看相關使用者的授權：

```sql
SHOW GRANTS FOR 'app_user'@'%';
```

如果看到類似：

```sql
GRANT SELECT ON `current_db`.`employee` TO `app_user`@`%`;
```

表搬到新 database 後，需要重新授權：

```sql
GRANT SELECT ON archive_db.employee TO 'app_user'@'%';
```

必要時移除舊權限：

```sql
REVOKE SELECT ON current_db.employee FROM 'app_user'@'%';
```

---

## 5.2.5.2 建議操作流程

如果只是測試環境，可以直接嘗試：

```sql
RENAME TABLE current_db.employee TO archive_db.employee;
```

但如果是正式環境，建議流程如下：

```text
1. 先確認表大小、資料量、使用情況
2. 檢查 Trigger
3. 檢查外鍵
4. 檢查 View
5. 檢查 Stored Procedure / Function
6. 檢查 Event
7. 檢查表級權限
8. 確認應用程式 SQL 是否寫死 database.table
9. 先在測試環境演練
10. 備份資料
11. 在低流量時段執行
12. 執行後驗證資料、外鍵、權限、應用程式功能
```

---

## 5.2.5.3 簡單範例

假設原本有：

```text
current_db.employee
```

現在要搬到：

```text
archive_db.employee
```

可以先檢查 Trigger：

```sql
SELECT 
    TRIGGER_SCHEMA,
    TRIGGER_NAME,
    EVENT_OBJECT_TABLE
FROM INFORMATION_SCHEMA.TRIGGERS
WHERE EVENT_OBJECT_SCHEMA = 'current_db'
  AND EVENT_OBJECT_TABLE = 'employee';
```

再檢查外鍵：

```sql
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_SCHEMA,
    REFERENCED_TABLE_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE (TABLE_SCHEMA = 'current_db' AND TABLE_NAME = 'employee')
   OR (REFERENCED_TABLE_SCHEMA = 'current_db' AND REFERENCED_TABLE_NAME = 'employee');
```

再檢查 View：

```sql
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    VIEW_DEFINITION
FROM INFORMATION_SCHEMA.VIEWS
WHERE VIEW_DEFINITION LIKE '%employee%';
```

再檢查 Stored Procedure / Function：

```sql
SELECT 
    ROUTINE_SCHEMA,
    ROUTINE_NAME,
    ROUTINE_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_DEFINITION LIKE '%employee%';
```

再檢查 Event：

```sql
SELECT 
    EVENT_SCHEMA,
    EVENT_NAME
FROM INFORMATION_SCHEMA.EVENTS
WHERE EVENT_DEFINITION LIKE '%employee%';
```

確認都沒有問題後，再執行：

```sql
RENAME TABLE current_db.employee TO archive_db.employee;
```

執行後再驗證：

```sql
SELECT COUNT(*) FROM archive_db.employee;
```

並確認舊表已不存在：

```sql
SHOW TABLES FROM current_db LIKE 'employee';
```

確認新表存在：

```sql
SHOW TABLES FROM archive_db LIKE 'employee';
```

---
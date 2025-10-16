# Усунення несправностей SSIS аналізу

## Поширені проблеми та їх вирішення

### ❌ Помилка: "SSISDB database not found"

**Проблема:** База даних SSISDB не існує на сервері.

**Вирішення:**
1. Відкрийте SQL Server Management Studio (SSMS)
2. Підключіться до екземпляра SQL Server
3. В Object Explorer розгорніть вузол сервера
4. Клацніть правою кнопкою на "Integration Services Catalogs"
5. Виберіть "Create Catalog..."
6. Встановіть пароль для каталогу
7. Активуйте опцію "Enable CLR Integration" (якщо потрібно)
8. Натисніть OK

**Альтернативний метод через T-SQL:**
```sql
USE master;
GO

-- Включити CLR
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
GO

-- Створити каталог SSISDB
EXEC catalog.create_catalog 'YourStrongPassword123!';
GO
```

### ❌ Помилка: "Invalid object name 'SSISDB.catalog.packages'"

**Проблема:** Каталог SSISDB існує, але представлення недоступні.

**Вирішення:**
```sql
-- Перевірити наявність бази даних
SELECT name FROM sys.databases WHERE name = 'SSISDB';

-- Перевірити права доступу
USE SSISDB;
GO
SELECT * FROM sys.fn_my_permissions('SSISDB', 'DATABASE');
GO
```

**Надання прав:**
```sql
USE SSISDB;
GO
-- Надати права читання для користувача
ALTER ROLE [ssis_admin] ADD MEMBER [YourUser];
-- або
ALTER ROLE [ssis_logreader] ADD MEMBER [YourUser];
GO
```

### ❌ Помилка: "Cannot execute as the database principal because the principal does not exist"

**Проблема:** Користувач не має прав на SSISDB.

**Вирішення:**
```sql
USE SSISDB;
GO

-- Створити користувача (якщо не існує)
CREATE USER [YourUser] FOR LOGIN [YourLogin];
GO

-- Додати до відповідної ролі
ALTER ROLE [ssis_logreader] ADD MEMBER [YourUser];
GO
```

### ⚠️ Попередження: "No data returned"

**Проблема:** Функції повертають порожні результати.

**Причини та вирішення:**

1. **Немає розгорнутих пакетів:**
   ```sql
   -- Перевірити наявність пакетів
   SELECT COUNT(*) FROM SSISDB.catalog.packages;
   ```
   **Рішення:** Розгорнути SSIS проекти в каталог SSISDB

2. **Немає виконань:**
   ```sql
   -- Перевірити наявність виконань
   SELECT COUNT(*) FROM SSISDB.catalog.executions;
   ```
   **Рішення:** Запустити хоча б один пакет

3. **Фільтр занадто строгий:**
   ```sql
   -- Замість
   SELECT * FROM util.ssisGetExecutions('Folder', 'Project', 'Package', NULL, 1);
   
   -- Спробувати
   SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, 168);
   ```

### 🔒 Помилка: "Cannot read encrypted connection string"

**Проблема:** Connection strings зашифровані і не можуть бути прочитані.

**Пояснення:** SSIS використовує різні рівні захисту для connection managers. Зашифровані рядки підключення можуть відображатися як NULL або порожні.

**Рішення:**
```sql
-- Переглянути рівень захисту
SELECT 
    ProjectName,
    ConnectionManagerName,
    protection_level,
    CASE protection_level
        WHEN 0 THEN 'DontSaveSensitive'
        WHEN 1 THEN 'EncryptSensitiveWithUserKey'
        WHEN 2 THEN 'EncryptSensitiveWithPassword'
        WHEN 3 THEN 'EncryptAllWithPassword'
        WHEN 4 THEN 'EncryptAllWithUserKey'
        WHEN 5 THEN 'ServerStorage'
        ELSE 'Unknown'
    END ProtectionLevelDescription
FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
WHERE ConnectionString IS NULL;
```

**Рекомендація:** Використовуйте SSIS Environment Variables або Project Parameters для зберігання чутливих даних.

### 📊 Продуктивність: "Query runs too slow"

**Проблема:** Запити виконуються повільно.

**Оптимізація:**

1. **Обмежити часовий діапазон:**
   ```sql
   -- Замість NULL (всі записи)
   SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, 24);
   ```

2. **Використовувати фільтри:**
   ```sql
   -- Фільтрувати по папці/проекту
   SELECT * FROM util.ssisGetExecutions('MyFolder', 'MyProject', NULL, NULL, 168);
   ```

3. **Створити індекси на SSISDB (обережно!):**
   ```sql
   -- НЕ рекомендується змінювати системні таблиці SSISDB
   -- Натомість використовуйте staging таблиці
   ```

4. **Використовувати staging підхід:**
   ```sql
   -- Завантажити дані в тимчасову таблицю
   SELECT * 
   INTO #TempExecutions
   FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, 168);
   
   -- Працювати з тимчасовою таблицею
   SELECT * FROM #TempExecutions
   WHERE PackageName LIKE '%Load%';
   ```

### 🔄 Помилка: "Execution ID not found"

**Проблема:** Execution ID не існує або видалений.

**Причина:** SSISDB автоматично очищає старі записи згідно з retention policy.

**Перевірити налаштування:**
```sql
USE SSISDB;
GO

-- Переглянути поточні налаштування
SELECT 
    property_name,
    property_value,
    description
FROM catalog.catalog_properties
WHERE property_name IN ('RETENTION_WINDOW', 'OPERATION_CLEANUP_ENABLED');
GO
```

**Змінити період зберігання:**
```sql
-- Встановити 90 днів (замість 365 за замовчуванням)
EXEC catalog.configure_catalog 
    @property_name = 'RETENTION_WINDOW',
    @property_value = 90;
GO
```

### 🎯 Помилка у функції ssisAnalyzeLastExecution: "No execution found"

**Проблема:** Не знайдено виконання для вказаного пакета.

**Діагностика:**
```sql
-- Перевірити чи існує пакет
SELECT * FROM util.ssisGetPackages('FolderName', 'ProjectName', 'PackageName');

-- Перевірити чи був пакет коли-небудь запущений
SELECT * FROM util.ssisGetExecutions('FolderName', 'ProjectName', 'PackageName', NULL, NULL);
```

**Вирішення:**
1. Перевірте правильність назв (регістр важливий!)
2. Запустіть пакет хоча б один раз
3. Переконайтесь що виконання не було видалене через retention policy

### 🛠️ Помилка: "Invalid column name"

**Проблема:** Колонка не існує в catalog view.

**Причина:** Різні версії SQL Server можуть мати різні набори колонок.

**Діагностика:**
```sql
-- Перевірити структуру представлення
SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'catalog'
    AND TABLE_NAME = 'executions'
ORDER BY ORDINAL_POSITION;
```

**Вирішення:** Перевірте версію SQL Server та офіційну документацію для вашої версії.

### 📝 Помилка: "Function does not exist"

**Проблема:** Функція util.ssisGetXXX не знайдена.

**Діагностика:**
```sql
-- Перевірити наявність функції
SELECT 
    SCHEMA_NAME(schema_id) SchemaName,
    name FunctionName,
    type_desc TypeDescription
FROM sys.objects
WHERE name LIKE 'ssisGet%'
    AND SCHEMA_NAME(schema_id) = 'util';
```

**Вирішення:**
1. Переконайтесь що схема `util` існує:
   ```sql
   IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'util')
       CREATE SCHEMA util;
   GO
   ```

2. Виконайте SQL скрипти створення функцій з папки `util/Functions/`

3. Запустіть валідацію:
   ```sql
   -- Виконати docs/ssis_validation.sql
   ```

### 💡 Корисні поради

#### Регулярне обслуговування

```sql
-- Очистити старі записи (виконувати з обережністю!)
EXEC catalog.cleanup_server_execution_keys;
GO

-- Очистити старі логи операцій
EXEC catalog.cleanup_server_log;
GO

-- Перевірити розмір SSISDB
EXEC sp_spaceused;
GO
```

#### Моніторинг розміру SSISDB

```sql
SELECT 
    DB_NAME(database_id) DatabaseName,
    (SUM(size) * 8) / 1024 SizeMB
FROM sys.master_files
WHERE database_id = DB_ID('SSISDB')
GROUP BY database_id;
```

#### Налаштування автоматичного очищення

```sql
-- Включити автоматичне очищення
EXEC catalog.configure_catalog 
    @property_name = 'OPERATION_CLEANUP_ENABLED',
    @property_value = 1;
GO

-- Налаштувати період зберігання (дні)
EXEC catalog.configure_catalog 
    @property_name = 'RETENTION_WINDOW',
    @property_value = 60;
GO
```

## 📞 Додаткова підтримка

Якщо проблема не вирішена:

1. Запустіть скрипт валідації: `docs/ssis_validation.sql`
2. Перегляньте демонстраційні приклади: `docs/ssis_analysis_demo.sql`
3. Перевірте офіційну документацію Microsoft
4. Перевірте версію SQL Server та сумісність функцій

## 🔗 Корисні посилання

- [SSIS Catalog Views](https://learn.microsoft.com/sql/integration-services/system-views/views-integration-services-catalog)
- [SSIS Catalog Stored Procedures](https://learn.microsoft.com/sql/integration-services/system-stored-procedures/stored-procedures-integration-services-catalog)
- [SSIS Deployment](https://learn.microsoft.com/sql/integration-services/packages/deploy-integration-services-ssis-projects-and-packages)

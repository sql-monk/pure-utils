# Приклади використання

## Огляд

Цей розділ містить практичні end-to-end приклади використання pure-utils для типових сценаріїв адміністрування та оптимізації SQL Server.

## 1. Управління індексами

### Сценарій: Виявлення та створення відсутніх індексів

**Мета**: Знайти індекси, які SQL Server рекомендує створити, та згенерувати скрипти для їх створення.

```sql
-- Крок 1: Знайти топ-20 найбільш корисних відсутніх індексів
SELECT TOP 20
    DatabaseName,
    SchemaName + '.' + TableName AS FullTableName,
    'CREATE INDEX IX_' + TableName + '_' + 
        REPLACE(REPLACE(EqualityColumns + ISNULL('_' + InequalityColumns, ''), '[', ''), ']', '') + 
        ISNULL('_INC', '') AS RecommendedIndexName,
    EqualityColumns,
    InequalityColumns,
    IncludedColumns,
    UserSeeks + UserScans AS TotalReads,
    ImprovementMeasure,
    CreateIndexStatement
FROM util.indexesGetMissing(NULL)
WHERE ImprovementMeasure > 1000  -- фільтр за важливістю
ORDER BY ImprovementMeasure DESC;

-- Крок 2: Виконати один з рекомендованих скриптів
-- (скопіюйте з колонки CreateIndexStatement)
CREATE NONCLUSTERED INDEX IX_Orders_CustomerId
ON dbo.Orders(CustomerId)
INCLUDE (OrderDate, TotalAmount);
```

### Сценарій: Знаходження та видалення невикористовуваних індексів

**Мета**: Знайти індекси, які займають місце але не використовуються.

```sql
-- Знайти невикористовувані індекси > 100 MB
SELECT 
    SchemaName + '.' + TableName AS FullTableName,
    IndexName,
    SizeKB / 1024.0 AS SizeMB,
    UserSeeks,
    UserScans,
    UserLookups,
    UserUpdates,
    'DROP INDEX ' + IndexName + ' ON ' + SchemaName + '.' + TableName AS DropScript
FROM util.indexesGetUnused(NULL)
WHERE SizeKB > 102400  -- > 100 MB
  AND UserUpdates > 1000  -- має writes
ORDER BY SizeKB DESC;

-- Видалити після підтвердження
-- DROP INDEX IX_OldIndex ON dbo.OldTable;
```

### Сценарій: Перейменування індексів згідно конвенцій

**Мета**: Стандартизувати назви всіх індексів у базі даних.

```sql
-- Крок 1: Переглянути індекси, які потребують перейменування
SELECT 
    SchemaName,
    TableName,
    IndexName AS CurrentName,
    NewIndexName AS RecommendedName,
    IndexType
FROM util.indexesGetConventionNames(NULL, NULL)
WHERE IndexName <> NewIndexName
  AND IndexType NOT IN ('HEAP');  -- пропустити heap таблиці

-- Крок 2: Згенерувати скрипти перейменування
SELECT 
    'EXEC sp_rename ''' + SchemaName + '.' + TableName + '.' + IndexName + 
    ''', ''' + NewIndexName + ''', ''INDEX'';' AS RenameScript
FROM util.indexesGetConventionNames(NULL, NULL)
WHERE IndexName <> NewIndexName
  AND IndexType NOT IN ('HEAP')
ORDER BY SchemaName, TableName;

-- Крок 3: Виконати скрипти (по одному або batch)
EXEC sp_rename 'dbo.Orders.IX_Orders_1', 'IX_Orders_CustomerId', 'INDEX';
```

## 2. Генерація DDL скриптів

### Сценарій: Створення DDL для таблиці з усіма залежностями

**Мета**: Експортувати структуру таблиці для version control або переносу.

```sql
-- Простий DDL для однієї таблиці
DECLARE @ddl NVARCHAR(MAX);

SELECT @ddl = DDLScript
FROM util.tablesGetScript('Orders', 'dbo');

PRINT @ddl;

-- Результат включає:
-- - CREATE TABLE з усіма колонками
-- - Primary Key
-- - Foreign Keys
-- - Indexes
-- - Check Constraints
-- - Default Constraints
-- - Compression settings
```

### Сценарій: Експорт представлення з усіма залежностями

**Мета**: Згенерувати скрипти для представлення та всіх об'єктів, від яких воно залежить.

```sql
-- Виклик процедури для генерації з залежностями
EXEC util.objesctsScriptWithDependencies 
    @object = 'vw_CustomerOrders',
    @includeReferences = 1,
    @maxDepth = 5;

-- Результат містить скрипти у правильному порядку:
-- 1. dbo.Customers (TABLE)
-- 2. dbo.Orders (TABLE)  
-- 3. dbo.OrderDetails (TABLE)
-- 4. dbo.vw_CustomerOrders (VIEW)
```

## 3. Моніторинг через Extended Events

### Сценарій: Аналіз помилок за останню добу

**Мета**: Знайти найчастіші помилки та їх джерела.

```sql
-- Топ-10 найчастіших помилок
SELECT TOP 10
    ErrorNumber,
    Severity,
    LEFT(Message, 100) AS MessagePreview,
    COUNT(*) AS ErrorCount,
    COUNT(DISTINCT ServerPrincipalName) AS AffectedUsers,
    COUNT(DISTINCT ClientAppName) AS AffectedApps,
    MAX(EventTime) AS LastOccurrence
FROM util.xeGetErrors(DEFAULT)
WHERE EventTime > DATEADD(DAY, -1, GETDATE())
GROUP BY ErrorNumber, Severity, LEFT(Message, 100)
ORDER BY COUNT(*) DESC;

-- Детальна інформація про конкретну помилку
SELECT 
    EventTime,
    DatabaseName,
    ObjectName,
    ServerPrincipalName,
    ClientAppName,
    Message,
    SqlText
FROM util.xeGetErrors(DEFAULT)
WHERE ErrorNumber = 1205  -- Deadlock
  AND EventTime > DATEADD(HOUR, -2, GETDATE())
ORDER BY EventTime DESC;
```

### Сценарій: Профілювання продуктивності процедур

**Мета**: Знайти найповільніші процедури та оптимізувати їх.

```sql
-- Процедури з найгіршою продуктивністю за останній тиждень
SELECT 
    ObjectName,
    COUNT(*) AS ExecutionCount,
    AVG(Duration) / 1000000.0 AS AvgDurationSeconds,
    MAX(Duration) / 1000000.0 AS MaxDurationSeconds,
    MIN(Duration) / 1000000.0 AS MinDurationSeconds,
    STDEV(Duration) / 1000000.0 AS StdDevSeconds,
    SUM(Duration) / 1000000.0 AS TotalDurationSeconds
FROM util.xeGetModules('Users', DATEADD(DAY, -7, GETDATE()))
WHERE ObjectName IS NOT NULL
GROUP BY ObjectName
HAVING COUNT(*) > 100  -- мінімум 100 виконань
ORDER BY AVG(Duration) DESC;

-- Детальний аналіз конкретної процедури
SELECT TOP 100
    EventTime,
    Duration / 1000000.0 AS DurationSeconds,
    ServerPrincipalName,
    ClientAppName,
    LEFT(Statement, 200) AS StatementPreview
FROM util.xeGetModules('Users', DATEADD(DAY, -1, GETDATE()))
WHERE ObjectName = 'dbo.GetCustomerOrders'
ORDER BY Duration DESC;
```

### Сценарій: Автоматизація копіювання XE даних

**Мета**: Налаштувати регулярне копіювання XE даних у таблиці для довгострокового зберігання.

```sql
-- SQL Agent Job для копіювання кожну годину
USE msdb;
GO

-- Створити Job
EXEC sp_add_job 
    @job_name = 'Util - Copy XE Data';

-- Крок 1: Копіювання помилок
EXEC sp_add_jobstep 
    @job_name = 'Util - Copy XE Data',
    @step_name = 'Copy Errors',
    @subsystem = 'TSQL',
    @database_name = 'YourDatabase',
    @command = 'EXEC util.xeCopyErrorsToTable;';

-- Крок 2: Копіювання виконань модулів
EXEC sp_add_jobstep 
    @job_name = 'Util - Copy XE Data',
    @step_name = 'Copy Modules',
    @subsystem = 'TSQL',
    @database_name = 'YourDatabase',
    @command = 'EXEC util.xeCopyModulesToTable @scope = ''Users'';';

-- Schedule: кожну годину
EXEC sp_add_schedule
    @schedule_name = 'Hourly',
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @freq_subday_type = 8,  -- Hours
    @freq_subday_interval = 1;

EXEC sp_attach_schedule 
    @job_name = 'Util - Copy XE Data',
    @schedule_name = 'Hourly';

EXEC sp_add_jobserver 
    @job_name = 'Util - Copy XE Data';
```

## 4. Робота з метаданими

### Сценарій: Масове додавання описів до колонок

**Мета**: Документувати структуру таблиць через MS_Description.

```sql
-- Додати описи до колонок таблиці Orders
EXEC util.metadataSetTableDescription 
    @table = 'dbo.Orders',
    @description = 'Таблиця замовлень клієнтів';

EXEC util.metadataSetColumnDescription 
    @table = 'dbo.Orders',
    @column = 'OrderId',
    @description = 'Унікальний ідентифікатор замовлення (PK)';

EXEC util.metadataSetColumnDescription 
    @table = 'dbo.Orders',
    @column = 'CustomerId',
    @description = 'ID клієнта (FK до Customers)';

EXEC util.metadataSetColumnDescription 
    @table = 'dbo.Orders',
    @column = 'OrderDate',
    @description = 'Дата створення замовлення';

-- Перевірити додані описи
SELECT 
    ColumnName,
    DataType,
    Description
FROM util.metadataGetColumns('dbo.Orders', NULL)
WHERE Description IS NOT NULL;
```

### Сценарій: Автоматичне витягування описів з коментарів коду

**Мета**: Синхронізувати описи з коментарів у код з MS_Description.

```sql
-- Отримати опис з коментарів процедури
SELECT 
    Section,
    Content
FROM util.modulesGetDescriptionFromComments('dbo.GetCustomerOrders', NULL);

-- Встановити опис автоматично
DECLARE @description NVARCHAR(MAX);

SELECT @description = Content
FROM util.modulesGetDescriptionFromComments('dbo.GetCustomerOrders', NULL)
WHERE Section = 'Description';

IF @description IS NOT NULL
BEGIN
    EXEC util.metadataSetProcedureDescription 
        @procedure = 'dbo.GetCustomerOrders',
        @description = @description;
END
```

## 5. Інтеграція з AI через MCP

### Сценарій: Отримання структури бази даних через Claude

**Користувач в Claude**:
```
Покажи мені всі таблиці в базі даних з їх розміром
```

**Claude виконує**:
```
mcp.GetTables()
```

**Результат**: JSON з усіма таблицями, їх розміром, кількістю рядків

**Користувач**:
```
Покажи детальну структуру таблиці Orders
```

**Claude виконує**:
```
mcp.GetTableInfo(database=null, schema='dbo', table='Orders')
```

**Результат**: Повна структура з колонками, індексами, foreign keys

### Сценарій: Аналіз планів виконання через AI

**Користувач в Claude**:
```
Отримай execution plan для запиту:
SELECT * FROM Orders WHERE CustomerId = 123
```

**Claude виконує (PlanSqlsMcp)**:
```
GetEstimatedPlan(query="SELECT * FROM Orders WHERE CustomerId = 123")
```

**Результат**: XML execution plan

**Claude аналізує**:
```
План виконання показує Table Scan на таблиці Orders.
Рекомендую створити індекс на колонці CustomerId для покращення продуктивності:

CREATE INDEX IX_Orders_CustomerId ON Orders(CustomerId);
```

### Сценарій: Генерація DDL через AI

**Користувач**:
```
Згенеруй DDL для представлення vw_CustomerOrders з усіма залежностями
```

**Claude виконує**:
```
mcp.ScriptObjectAndReferences(
    schema='dbo', 
    object='vw_CustomerOrders', 
    includeReferences=1
)
```

**Результат**: Повні DDL скрипти у правильному порядку

## 6. Аналіз залежностей

### Сценарій: Знайти всі об'єкти, що використовують таблицю

**Мета**: Перед зміною структури таблиці знайти всі залежності.

```sql
-- Знайти всі об'єкти, що посилаються на таблицю Orders
SELECT 
    Depth,
    ObjectType,
    ObjectName,
    ReferencedObjectName
FROM util.modulesRecureSearchForOccurrences('dbo.Orders', 10)
ORDER BY Depth, ObjectType, ObjectName;

-- Результат:
-- Depth=1: процедури, що безпосередньо використовують Orders
-- Depth=2: процедури, що викликають процедури з Depth=1
-- тощо...
```

### Сценарій: Аналіз впливу видалення об'єкта

**Мета**: Оцінити вплив видалення функції на інші об'єкти.

```sql
-- Знайти всі об'єкти, що використовують util.metadataGetAnyId
SELECT DISTINCT
    ObjectType,
    COUNT(*) AS AffectedObjects
FROM util.modulesRecureSearchForOccurrences('util.metadataGetAnyId', 5)
GROUP BY ObjectType
ORDER BY COUNT(*) DESC;

-- Детальний список
SELECT 
    ObjectName,
    ObjectType
FROM util.modulesRecureSearchForOccurrences('util.metadataGetAnyId', 5)
WHERE Depth = 1  -- тільки безпосередні залежності
ORDER BY ObjectType, ObjectName;
```

## 7. Оптимізація запитів

### Сценарій: Комплексний аналіз продуктивності

**Мета**: Знайти та виправити проблеми з продуктивністю запитів.

```sql
-- Крок 1: Знайти повільні запити
SELECT TOP 20
    ObjectName,
    AVG(Duration) / 1000000.0 AS AvgSeconds,
    MAX(Duration) / 1000000.0 AS MaxSeconds,
    COUNT(*) AS Executions
FROM util.xeGetModules('Users', DATEADD(DAY, -1, GETDATE()))
WHERE ObjectName LIKE 'dbo.%'
GROUP BY ObjectName
HAVING AVG(Duration) > 5000000  -- > 5 секунд
ORDER BY AVG(Duration) DESC;

-- Крок 2: Перевірити відсутні індекси для повільної процедури
EXEC mcp.GetTableInfo @table = 'Orders';  -- через AI
-- АБО
SELECT * FROM util.indexesGetMissing('Orders');

-- Крок 3: Отримати execution plan
-- Через PlanSqlsMcp (AI):
-- GetEstimatedPlan(query="EXEC dbo.SlowProcedure @param=123")

-- Крок 4: Створити рекомендовані індекси
CREATE INDEX IX_Orders_Status_INC 
ON Orders(Status) 
INCLUDE (OrderDate, CustomerId);

-- Крок 5: Перевірити покращення
SELECT 
    ObjectName,
    AVG(Duration) / 1000000.0 AS AvgSecondsAfter
FROM util.xeGetModules('Users', DATEADD(HOUR, -1, GETDATE()))
WHERE ObjectName = 'dbo.SlowProcedure'
GROUP BY ObjectName;
```

## 8. Автоматизація обслуговування

### Сценарій: Щотижневе обслуговування індексів

**Мета**: Автоматично перевіряти стан індексів та виконувати обслуговування.

```sql
-- SQL Agent Job для щотижневого обслуговування
USE msdb;
GO

EXEC sp_add_job 
    @job_name = 'Weekly Index Maintenance';

-- Крок 1: Звіт про фрагментацію
EXEC sp_add_jobstep 
    @job_name = 'Weekly Index Maintenance',
    @step_name = 'Fragmentation Report',
    @subsystem = 'TSQL',
    @command = '
        SELECT 
            TableName,
            IndexName,
            AvgFragmentationPercent,
            TotalSpaceMB
        FROM util.indexesGetSpaceUsed(NULL)
        WHERE AvgFragmentationPercent > 30
        ORDER BY TotalSpaceMB DESC;
    ';

-- Крок 2: Rebuild фрагментованих індексів > 50 GB
EXEC sp_add_jobstep 
    @job_name = 'Weekly Index Maintenance',
    @step_name = 'Rebuild Large Indexes',
    @subsystem = 'TSQL',
    @command = '
        DECLARE @sql NVARCHAR(MAX);
        DECLARE rebuild_cursor CURSOR FOR
        SELECT 
            ''ALTER INDEX '' + IndexName + '' ON '' + SchemaName + ''.'' + TableName + '' REBUILD WITH (ONLINE = ON);''
        FROM util.indexesGetSpaceUsed(NULL)
        WHERE AvgFragmentationPercent > 50
          AND TotalSpaceMB > 50000;  -- > 50 GB
        
        OPEN rebuild_cursor;
        FETCH NEXT FROM rebuild_cursor INTO @sql;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC sp_executesql @sql;
            FETCH NEXT FROM rebuild_cursor INTO @sql;
        END
        
        CLOSE rebuild_cursor;
        DEALLOCATE rebuild_cursor;
    ';

-- Schedule: кожної неділі о 02:00
EXEC sp_add_schedule
    @schedule_name = 'Weekly Sunday',
    @freq_type = 8,  -- Weekly
    @freq_interval = 1,  -- Sunday
    @active_start_time = 020000;

EXEC sp_attach_schedule 
    @job_name = 'Weekly Index Maintenance',
    @schedule_name = 'Weekly Sunday';
```

## Комбіновані сценарії

### Повний аудит бази даних

```sql
-- 1. Розмір таблиць
SELECT TOP 10 * 
FROM util.indexesGetSpaceUsed(NULL)
ORDER BY TotalSpaceMB DESC;

-- 2. Відсутні індекси
SELECT TOP 10 * 
FROM util.indexesGetMissing(NULL)
ORDER BY ImprovementMeasure DESC;

-- 3. Невикористовувані індекси
SELECT * 
FROM util.indexesGetUnused(NULL)
WHERE SizeKB > 102400;

-- 4. Найчастіші помилки
SELECT TOP 10
    ErrorNumber,
    COUNT(*) AS Count
FROM util.errorLog
WHERE EventTime > DATEADD(DAY, -7, GETDATE())
GROUP BY ErrorNumber
ORDER BY COUNT(*) DESC;

-- 5. Найповільніші процедури
SELECT TOP 10
    ObjectName,
    AVG(Duration) / 1000000.0 AS AvgSeconds
FROM util.executionModulesUsers
WHERE EventTime > DATEADD(DAY, -7, GETDATE())
GROUP BY ObjectName
ORDER BY AVG(Duration) DESC;
```

## Наступні кроки

- [FAQ](faq.md) - Часті питання
- [Модулі](modules/util.md) - Детальна документація функцій
- [Архітектура](architecture.md) - Розуміння внутрішньої структури

# pure utils

### Основні можливості
1. [DESCRIPTION & MS_DESCRIPTION] - 15 функцій/процедур
2. [OBJECTS & METADATA] - 25 функцій
3. [PARAMETERS] - 6 функцій  
4. [COLUMNS] - 8 функцій
5. [STRING & TEXT PROCESSING] - 12 функцій
6. [SCRIPT GENERATION] - 8 функцій
7. [TEMP TABLES] - 2 функції
8. [MODULES & CODE ANALYSIS] - 18 функцій
9. [ERROR HANDLING] - 2 функції/процедури + 1 таблиця
10. [EXTENDED EVENTS (XE)] - 8 функцій/процедур
11. [EXTENDED PROPERTIES] - 12 процедур
12. [INDEXES] - 10 функцій/процедур
13. [TABLES] - 4 функції
14. [LOGS & EVENTS] - 6 представлень + таблиці
15. [EXECUTION MONITORING] - 8 функцій/представлень
16. [PERMISSIONS] - 2 функції
17. [HISTORY] - 3 функції

---

## DESCRIPTION & MS_DESCRIPTION

### Компоненти системи документування (15 об'єктів)

**Автоматичне витягнення описів з коментарів:**
- `modulesGetDescriptionFromComments` - витягує описи з багаторядкових коментарів
- `modulesGetDescriptionFromCommentsLegacy` - витягує описи зі старого формату коментарів
- `stringSplitMultiLineComment` - парсить структуровані коментарі
- `modulesSetDescriptionFromComments` - автоматично встановлює описи з коментарів
- `modulesSetDescriptionFromCommentsLegacy` - для старого формату

**Ручне встановлення описів (12 процедур):**
- `metadataSetTableDescription` - описи таблиць
- `metadataSetColumnDescription` - описи колонок
- `metadataSetProcedureDescription` - описи процедур
- `metadataSetFunctionDescription` - описи функцій
- `metadataSetViewDescription` - описи представлень
- `metadataSetTriggerDescription` - описи тригерів
- `metadataSetParameterDescription` - описи параметрів
- `metadataSetIndexDescription` - описи індексів
- `metadataSetSchemaDescription` - описи схем
- `metadataSetDataspaceDescription` - описи просторів даних
- `metadataSetFilegroupDescription` - описи файлових груп
- `metadataSetExtendedProperty` - універсальна процедура

**Отримання описів:**
- `metadataGetDescriptions` - отримання описів об'єктів
- `metadataGetExtendedProperiesValues` - читання розширених властивостей

### Приклади використання:
```sql
-- Автоматичне встановлення описів з коментарів
EXEC util.modulesSetDescriptionFromComments 'dbo.MyProcedure';

-- Ручне встановлення описів
EXEC util.metadataSetTableDescription @table = 'dbo.Users', @description = 'Таблиця користувачів системи';
EXEC util.metadataSetColumnDescription @object = 'dbo.Users', @column = 'Email', @description = 'Email адреса користувача';

-- Отримання всіх описів
SELECT * FROM util.metadataGetDescriptions('dbo.Users', NULL);
SELECT * FROM util.metadataGetExtendedProperiesValues('dbo.Users', NULL, 'MS_Description');
```

---

## OBJECTS & METADATA

### Универсальні функції для об'єктів (25 функцій)
**Основні функції:**
- `metadataGetObjectName` - отримання назви об'єкта за ID
- `metadataGetObjectType` - тип об'єкта за назвою
- `metadataGetObjectsType` - типи кількох об'єктів
- `metadataGetAnyId` - універсальне отримання ID будь-якого об'єкта
- `metadataGetAnyName` - універсальне отримання назви будь-якого об'єкта

**Класифікація об'єктів:**
- `metadataGetClassByName` - код класу за назвою
- `metadataGetClassName` - назва класу за кодом

**Спеціалізовані функції:**
- `metadataGetCertificateName` - імена сертифікатів
- `metadataGetDataspaceId` / `metadataGetDataspaceName` - простори даних
- `metadataGetPartitionFunctionId` / `metadataGetPartitionFunctionName` - функції розділення

### Приклади використання:
```sql
-- Основна робота з об'єктами
SELECT util.metadataGetObjectName(OBJECT_ID('dbo.Users')); -- [dbo].[Users]
SELECT util.metadataGetObjectType('dbo.Users'); -- 'U' (User Table)
SELECT * FROM util.metadataGetObjectsType('dbo.Users,dbo.Orders,dbo.GetUserData');

-- Універсальні функції
SELECT util.metadataGetAnyId('dbo.Users', 'OBJECT'); -- object_id
SELECT util.metadataGetAnyId('dbo.Users', 'OBJECT', 'Email'); -- column_id
SELECT util.metadataGetAnyName(OBJECT_ID('dbo.Users'), 0, '1'); -- [dbo].[Users]

-- Класифікація
SELECT util.metadataGetClassByName('OBJECT_OR_COLUMN'); -- 1
SELECT util.metadataGetClassName(1); -- 'OBJECT_OR_COLUMN'
```

---

## PARAMETERS

### Функції для роботи з параметрами (6 функцій)
- `metadataGetParameters` - детальна інформація про параметри процедур/функцій
- `metadataGetParameterId` - ID параметра за назвою
- `metadataGetParameterName` - назва параметра за ID

### Приклади використання:
```sql
-- Отримання всіх параметрів процедури
SELECT * FROM util.metadataGetParameters('util.errorHandler');
SELECT * FROM util.metadataGetParameters(NULL); -- всі параметри всіх об'єктів

-- Робота з конкретними параметрами
SELECT util.metadataGetParameterId('dbo.MyProc', '@userId');
SELECT util.metadataGetParameterName(OBJECT_ID('dbo.MyProc'), 1);
```

---

## COLUMNS

### Функції для роботи з колонками (8 функцій)
- `metadataGetColumns` - детальна інформація про колонки
- `metadataGetColumnId` - ID колонки за назвою
- `metadataGetColumnName` - назва колонки за ID
- `tablesGetIndexedColumns` - аналіз індексованих колонок

### Приклади використання:
```sql
-- Детальна інформація про колонки
SELECT * FROM util.metadataGetColumns('dbo.Users');
SELECT * FROM util.metadataGetColumns(NULL); -- всі колонки всіх таблиць

-- Робота з конкретними колонками
SELECT util.metadataGetColumnId('dbo.Users', 'Email');
SELECT util.metadataGetColumnName('dbo.Users', 1);

-- Аналіз індексованих колонок
SELECT * FROM util.tablesGetIndexedColumns('dbo.Users');
-- Показує: IndexName, KeyOrdinal, IsIncludedColumn, IsUnique, IsPrimaryKey
```

---

## STRING & TEXT PROCESSING

### Функції для обробки тексту (12 функцій)

**Розбиття тексту:**
- `stringSplitToLines` - розбиття тексту на рядки
- `modulesSplitToLines` - розбиття коду модулів на рядки
- `stringSplitMultiLineComment` - парсинг багаторядкових коментарів

**Пошук позицій:**
- `stringFindCommentsPositions` - всі коментарі в тексті
- `stringFindInlineCommentsPositions` - однорядкові коментарі
- `stringFindLinesPositions` - позиції всіх рядків
- `stringFindMultilineCommentsPositions` - багаторядкові коментарі
- `stringGetCreateLineNumber` - рядок з CREATE

### Приклади використання:
```sql
-- Розбиття тексту на рядки
DECLARE @code NVARCHAR(MAX) = 'CREATE PROCEDURE test AS
SELECT * FROM users;
-- коментар
SELECT COUNT(*) FROM orders;';

SELECT * FROM util.stringSplitToLines(@code, 1); -- без порожніх рядків
SELECT * FROM util.stringGetCreateLineNumber(@code, 1); -- номер рядка з CREATE

-- Пошук коментарів
SELECT * FROM util.stringFindCommentsPositions(@code, 1);
SELECT * FROM util.stringFindInlineCommentsPositions(@code, 1);

-- Парсинг структурованих коментарів
DECLARE @comment NVARCHAR(MAX) = '/*
# Description
Test function
# Parameters
@id INT - identifier
*/';
SELECT * FROM util.stringSplitMultiLineComment(@comment);
```

---

## SCRIPT GENERATION

### Функції для генерації DDL скриптів (8 функцій)

**Скрипти індексів:**
- `indexesGetScript` - DDL для створення індексів
- `indexesGetScriptConventionRename` - скрипти перейменування індексів
- `indexesGetConventionNames` - рекомендовані назви індексів

**Скрипти таблиць:**
- `tablesGetScript` - повний DDL таблиці

### Приклади використання:
```sql
-- Генерація скриптів індексів
SELECT * FROM util.indexesGetScript('dbo.Users', NULL); -- всі індекси таблиці
SELECT * FROM util.indexesGetScript('dbo.Users', 'IX_Users_Email'); -- конкретний індекс

-- Скрипти перейменування за конвенціями
SELECT * FROM util.indexesGetConventionNames('dbo.Users', NULL); -- рекомендації
SELECT * FROM util.indexesGetScriptConventionRename('dbo.Users', NULL); -- скрипти

-- Повний DDL таблиці
SELECT createScript FROM util.tablesGetScript('dbo.Users');
```

---

## TEMP TABLES


інструменти для **автоматичного створення тимчасових таблиць** на основі аналізу SQL запитів та існуючих об'єктів бази даних. Система використовує вбудовану функцію SQL Server `sys.dm_exec_describe_first_result_set` для автоматичного визначення структури результуючого набору та генерації відповідного DDL скрипту.

### Ключові можливості:
- **Автоматичне визначення типів даних** та nullable constraints
- **Підтримка параметризованих запитів** через sp_executesql формат
- **Flexible іменування** тимчасових таблиць

### Функції для створення тимчасових таблиць (4 функції)

**Inline функції (повертають TABLE):**
- `stringGetCreateTempScriptInline` - аналіз SQL запиту з поверненням TABLE

**Scalar функції (повертають NVARCHAR(MAX)):**
- `stringGetCreateTempScript` - аналіз SQL запиту з поверненням скрипту

### Детальний опис функцій:

#### stringGetCreateTempScriptInline
- **Призначення**: Аналізує SQL запит та генерує CREATE TABLE DDL
- **Технологія**: sys.dm_exec_describe_first_result_set з підтримкою параметрів
- **Результат**: TABLE з колонкою createScript
- **Переваги**: Можна використовувати в JOIN та підзапитах

#### stringGetCreateTempScript  
- **Призначення**: Scalar обгортка для stringGetCreateTempScriptInline
- **Результат**: NVARCHAR(MAX) - готовий до виконання скрипт
- **Переваги**: Зручно для безпосереднього виконання через sp_executesql

### Приклади використання:

#### Базові сценарії використання
```sql
-- 1. Створення temp таблиці з простого SELECT
SELECT createScript 
FROM util.stringGetCreateTempScriptInline(
    'SELECT UserID, UserName, Email, CreatedDate FROM dbo.Users WHERE IsActive = 1', 
    '#ActiveUsers', 
    NULL
);

-- 2. Використання scalar функції для виконання
DECLARE @script NVARCHAR(MAX) = util.stringGetCreateTempScript(
    'SELECT OrderID, CustomerID, OrderDate, TotalAmount FROM dbo.Orders', 
    '#OrdersTemp', 
    NULL
);
EXEC sp_executesql @script;
-- Тепер можна використовувати #OrdersTemp (**але не забувайте про область видимості**)

-- 3. Створення temp таблиці з результату процедури
DECLARE @procScript NVARCHAR(MAX) = util.objectGetCreateTempScript(
    'dbo.GetMonthlyReport', 
    '#MonthlyReportData', 
    NULL
); 
EXEC sp_executesql @procScript;
INSERT INTO #MonthlyReportData EXEC dbo.GetMonthlyReport @Month = 12, @Year = 2024;
```

#### Параметризовані запити
```sql
-- Підтримка параметрів для складних запитів
DECLARE @params NVARCHAR(MAX) = '@StartDate DATETIME, @EndDate DATETIME, @MinAmount DECIMAL(10,2)';
DECLARE @query NVARCHAR(MAX) = N'
SELECT 
    o.OrderID,
    o.CustomerID, 
    c.CustomerName,
    o.OrderDate,
    o.TotalAmount,
    od.ProductCount
FROM dbo.Orders o
JOIN dbo.Customers c ON o.CustomerID = c.CustomerID
LEFT JOIN (
    SELECT OrderID, COUNT(*) as ProductCount 
    FROM dbo.OrderDetails 
    GROUP BY OrderID
) od ON o.OrderID = od.OrderID
WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
    AND o.TotalAmount >= @MinAmount';

-- Генерація скрипту з параметрами
SELECT createScript 
FROM util.stringGetCreateTempScriptInline(@query, '#FilteredOrders', @params);

-- Використання згенерованого скрипту
DECLARE @createScript NVARCHAR(MAX) = util.stringGetCreateTempScript(@query, '#FilteredOrders', @params);
EXEC sp_executesql @createScript;

-- Заповнення даними
INSERT INTO #FilteredOrders
EXEC sp_executesql @query, @params, 
    @StartDate = '2024-01-01', 
    @EndDate = '2024-12-31', 
    @MinAmount = 100.00;
```

#### Робота з функціями та процедурами
```sql
-- Створення temp таблиці для table-valued функції
SELECT createScript 
FROM util.objectGetCreateTempScriptInline('dbo.GetUserAnalytics', '#UserAnalytics', NULL);

-- Створення temp таблиці для процедури з параметрами
DECLARE @procScript NVARCHAR(MAX) = util.objectGetCreateTempScript(
    'dbo.GetSalesReport', 
    '#SalesReportTemp', 
    NULL
);
EXEC sp_executesql @procScript;

-- Заповнення через процедуру
INSERT INTO #SalesReportTemp 
EXEC dbo.GetSalesReport @RegionID = 5, @Quarter = 4, @Year = 2024;

-- Подальша робота з даними
SELECT Region, SUM(SalesAmount) as TotalSales
FROM #SalesReportTemp
GROUP BY Region
ORDER BY TotalSales DESC;
```

#### Складні сценарії та оптимізація
```sql
-- Створення temp таблиці з CTE та оконними функціями
DECLARE @complexQuery NVARCHAR(MAX) = N'
WITH RankedOrders AS (
    SELECT 
        CustomerID,
        OrderDate,
        TotalAmount,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate DESC) as OrderRank,
        LAG(TotalAmount) OVER (PARTITION BY CustomerID ORDER BY OrderDate) as PrevOrderAmount
    FROM dbo.Orders
    WHERE OrderDate >= DATEADD(year, -1, GETDATE())
),
CustomerMetrics AS (
    SELECT 
        CustomerID,
        COUNT(*) as OrderCount,
        AVG(TotalAmount) as AvgOrderAmount,
        MAX(TotalAmount) as MaxOrderAmount,
        SUM(TotalAmount) as TotalSpent
    FROM RankedOrders
    GROUP BY CustomerID
)
SELECT 
    ro.CustomerID,
    c.CustomerName,
    ro.OrderDate as LastOrderDate,
    ro.TotalAmount as LastOrderAmount,
    ro.PrevOrderAmount,
    cm.OrderCount,
    cm.AvgOrderAmount,
    cm.TotalSpent,
    CASE 
        WHEN cm.TotalSpent > 10000 THEN ''VIP''
        WHEN cm.TotalSpent > 5000 THEN ''Premium''
        ELSE ''Standard''
    END as CustomerTier
FROM RankedOrders ro
JOIN dbo.Customers c ON ro.CustomerID = c.CustomerID
JOIN CustomerMetrics cm ON ro.CustomerID = cm.CustomerID
WHERE ro.OrderRank = 1';

-- Генерація та створення складної temp таблиці
DECLARE @script NVARCHAR(MAX) = util.stringGetCreateTempScript(@complexQuery, '#CustomerAnalytics', NULL);
EXEC sp_executesql @script;

-- Використання створеної структури
INSERT INTO #CustomerAnalytics
EXEC sp_executesql @complexQuery;

-- Аналіз даних
SELECT 
    CustomerTier,
    COUNT(*) as CustomerCount,
    AVG(TotalSpent) as AvgTotalSpent,
    AVG(OrderCount) as AvgOrderCount
FROM #CustomerAnalytics
GROUP BY CustomerTier
ORDER BY 
    CASE CustomerTier 
        WHEN 'VIP' THEN 1 
        WHEN 'Premium' THEN 2 
        ELSE 3 
    END;
```

#### Практичні сценарії ETL та міграції
```sql
-- Сценарій 1: Підготовка staging таблиці для ETL
DECLARE @sourceQuery NVARCHAR(MAX) = N'
SELECT 
    CAST(SourceID as BIGINT) as SourceID,
    UPPER(LTRIM(RTRIM(SourceName))) as CleanedName,
    TRY_CAST(DateField as DATE) as ProcessedDate,
    CASE WHEN NumericField < 0 THEN 0 ELSE NumericField END as ValidatedAmount,
    HASHBYTES(''SHA2_256'', CONCAT(SourceID, SourceName, DateField)) as RowHash
FROM SourceSystem.dbo.RawData 
WHERE ImportDate = CAST(GETDATE() as DATE)
    AND SourceName IS NOT NULL';

-- Створення staging таблиці
DECLARE @stagingScript NVARCHAR(MAX) = util.stringGetCreateTempScript(
    @sourceQuery, 
    '#StagingData', 
    NULL
);
EXEC sp_executesql @stagingScript;

-- Заповнення та обробка
INSERT INTO #StagingData
EXEC sp_executesql @sourceQuery;

-- Сценарій 2: Динамічне створення temp таблиць для звітів
DECLARE @reportQuery NVARCHAR(MAX);
DECLARE @reportParams NVARCHAR(MAX) = '@ReportType NVARCHAR(50), @DateFrom DATE, @DateTo DATE';

SET @reportQuery = N'
SELECT 
    CASE @ReportType 
        WHEN ''Daily'' THEN FORMAT(TransactionDate, ''yyyy-MM-dd'')
        WHEN ''Weekly'' THEN FORMAT(TransactionDate, ''yyyy-\\W\\w-ww'')
        WHEN ''Monthly'' THEN FORMAT(TransactionDate, ''yyyy-MM'')
        ELSE ''Unknown''
    END as Period,
    COUNT(*) as TransactionCount,
    SUM(Amount) as TotalAmount,
    AVG(Amount) as AvgAmount,
    MIN(Amount) as MinAmount,
    MAX(Amount) as MaxAmount
FROM dbo.Transactions 
WHERE TransactionDate BETWEEN @DateFrom AND @DateTo
GROUP BY 
    CASE @ReportType 
        WHEN ''Daily'' THEN FORMAT(TransactionDate, ''yyyy-MM-dd'')
        WHEN ''Weekly'' THEN FORMAT(TransactionDate, ''yyyy-\\W\\w-ww'')
        WHEN ''Monthly'' THEN FORMAT(TransactionDate, ''yyyy-MM'')
        ELSE ''Unknown''
    END';

-- Створення гнучкої звітної структури
DECLARE @reportScript NVARCHAR(MAX) = util.stringGetCreateTempScript(
    @reportQuery, 
    '#DynamicReport', 
    @reportParams
);
EXEC sp_executesql @reportScript;
```

---

## ERROR HANDLING

### Компоненти системи обробки помилок (3 об'єкти)
- `util.errorHandler` - універсальний обробник помилок
- `util.errorLog` - централізований журнал помилок з повним контекстом
- `util.help` - довідкова система по Pure Utils

### Приклади використання:
```sql
-- Базове логування помилок
BEGIN TRY
    -- Ризикована операція
    EXEC dbo.BusinessProcedure;
END TRY
BEGIN CATCH
    EXEC util.errorHandler @attachment = 'Контекст операції';
END CATCH

-- Аналіз помилок
SELECT * FROM util.errorLog 
WHERE ErrorDateTime > DATEADD(DAY, -1, GETDATE())
ORDER BY ErrorDateTime DESC;

-- Довідка по системі
SELECT * FROM util.help('error');
```

---

## EXTENDED EVENTS (XE)

### Система моніторингу через Extended Events (15 об'єктів)
**XE Сесії:**
- `utilsErrors` - збір критичних помилок
- `utilsModulesUsers` - моніторинг виконання модулів користувачами  
- `utilsModulesFaust` - спеціальний моніторинг Faust користувачів
- `utilsModulesSSIS` - відстеження SSIS пакетів

**Функції для читання XE:**
- `util.xeGetErrors` - читання помилок з XE файлів
- `util.xeGetTargetFile` - інформація про поточні файли сесій
- `util.xeGetLogsPath` - генерація шляхів до логів

**Таблиці зберігання:**
- `util.executionModulesUsers/Faust/SSIS` - дані виконання модулів
- `util.executionSqlText` - кеш унікальних SQL текстів
- `util.xeOffsets` - позиції читання XE файлів

### Приклади використання:
```sql
-- Обробка XE даних
EXEC util.xeCopyModulesToTable 'Users';

-- Аналіз помилок з XE
SELECT * FROM util.xeGetErrors(DATEADD(HOUR, -1, GETDATE()));

-- Моніторинг виконання модулів  
SELECT * FROM util.viewExecutionModulesUsers
WHERE EventTime > DATEADD(HOUR, -1, GETDATE());
```

---

## EXTENDED PROPERTIES

### Процедури для роботи з розширеними властивостями (12 процедур)
- `metadataSetTableDescription` - описи таблиць
- `metadataSetColumnDescription` - описи колонок  
- `metadataSetProcedureDescription` - описи процедур
- `metadataSetFunctionDescription` - описи функцій
- `metadataSetViewDescription` - описи представлень
- `metadataSetTriggerDescription` - описи тригерів
- `metadataSetParameterDescription` - описи параметрів
- `metadataSetIndexDescription` - описи індексів
- `metadataSetSchemaDescription` - описи схем
- `metadataSetDataspaceDescription` - описи просторів даних
- `metadataSetFilegroupDescription` - описи файлових груп
- `metadataSetExtendedProperty` - універсальна процедура

### Приклади використання:
```sql
-- Встановлення описів різних об'єктів
EXEC util.metadataSetTableDescription @table = 'dbo.Users', @description = 'Таблиця користувачів';
EXEC util.metadataSetColumnDescription @object = 'dbo.Users', @column = 'Email', @description = 'Email користувача';
EXEC util.metadataSetProcedureDescription @procedure = 'dbo.GetUsers', @description = 'Отримання списку користувачів';

-- Універсальне встановлення властивості
EXEC util.metadataSetExtendedProperty 
    @name = 'MS_Description', 
    @value = 'Критична таблиця системи',
    @level0type = 'SCHEMA', @level0name = 'dbo',
    @level1type = 'TABLE', @level1name = 'Orders';
```

---

## INDEXES

### Функції та процедури для роботи з індексами (10 об'єктів)
- `indexesGetScript` - генерація DDL скриптів індексів
- `indexesGetConventionNames` - рекомендовані назви за конвенціями
- `indexesGetScriptConventionRename` - скрипти перейменування
- `indexesGetMissing` - аналіз відсутніх індексів
- `indexesGetUnused` - пошук невикористовуваних індексів
- `indexesGetDuplicates` - виявлення дублікатів індексів

### Приклади використання:
```sql
-- Генерація скриптів індексів
SELECT * FROM util.indexesGetScript('dbo.Users', NULL);

-- Аналіз рекомендацій по іменуванню
SELECT * FROM util.indexesGetConventionNames('dbo.Users', NULL);

-- Пошук проблемних індексів
SELECT * FROM util.indexesGetMissing('dbo.Users');
SELECT * FROM util.indexesGetUnused('dbo.Users');
SELECT * FROM util.indexesGetDuplicates('dbo.Users');
```

---

## TABLES

### Функції для роботи з таблицями (4 функції)
- `tablesGetScript` - повний DDL скрипт таблиці
- `tablesGetIndexedColumns` - аналіз індексованих колонок
- `tablesGetConstraints` - інформація про обмеження
- `tablesGetDependencies` - залежності таблиці

### Приклади використання:
```sql
-- Повний DDL таблиці
SELECT createScript FROM util.tablesGetScript('dbo.Users');

-- Аналіз структури
SELECT * FROM util.tablesGetIndexedColumns('dbo.Users');
SELECT * FROM util.tablesGetConstraints('dbo.Users');
SELECT * FROM util.tablesGetDependencies('dbo.Users');
```

---

## LOGS & EVENTS

### Представлення для аналізу логів та подій (6 представлень + таблиці)
- `util.viewErrorLog` - форматований перегляд помилок
- `util.viewExecutionStats` - статистика виконання
- `util.viewPerformanceCounters` - лічильники продуктивності
- `util.viewSessionActivity` - активність сесій
- `util.viewBlockingChains` - ланцюги блокувань
- `util.viewWaitStats` - статистика очікувань

### Приклади використання:
```sql
-- Аналіз останніх помилок
SELECT * FROM util.viewErrorLog 
WHERE ErrorDateTime > DATEADD(HOUR, -1, GETDATE());

-- Моніторинг продуктивності
SELECT * FROM util.viewPerformanceCounters;
SELECT * FROM util.viewWaitStats;

-- Аналіз блокувань
SELECT * FROM util.viewBlockingChains;
```

---

## EXECUTION MONITORING

### Функції та представлення для моніторингу виконання (8 об'єктів)
- `util.getActiveQueries` - поточні активні запити
- `util.getLongRunningQueries` - довготривалі операції
- `util.getBlockedProcesses` - заблоковані процеси
- `util.viewExecutionPlans` - плани виконання
- `util.viewResourceUsage` - використання ресурсів
- `util.viewQueryStats` - статистика запитів

### Приклади використання:
```sql
-- Моніторинг поточної активності
SELECT * FROM util.getActiveQueries();
SELECT * FROM util.getLongRunningQueries(30); -- більше 30 секунд

-- Аналіз продуктивності
SELECT * FROM util.viewQueryStats 
WHERE ExecutionCount > 100
ORDER BY AvgDuration DESC;

-- Використання ресурсів
SELECT * FROM util.viewResourceUsage;
```

---

## PERMISSIONS

### Функції для аналізу дозволів (2 функції)
- `permissionsGetUserRights` - права конкретного користувача
- `permissionsGetObjectAccess` - доступ до об'єкта

### Приклади використання:
```sql
-- Аналіз прав користувача
SELECT * FROM util.permissionsGetUserRights('domain\username');

-- Перевірка доступу до об'єкта
SELECT * FROM util.permissionsGetObjectAccess('dbo.Users');
```

---

## HISTORY

### Функції для роботи з історією (3 функції)
- `historyGetSchemaChanges` - зміни в схемі БД
- `historyGetDataChanges` - зміни в даних (CDC/CT)
- `historyGetBackupInfo` - інформація про резервні копії

### Приклади використання:
```sql
-- Аналіз змін в схемі
SELECT * FROM util.historyGetSchemaChanges(DATEADD(DAY, -7, GETDATE()));

-- Інформація про бекапи
SELECT * FROM util.historyGetBackupInfo('MyDatabase');
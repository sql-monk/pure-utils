# SSIS Package Analysis - Документація

## Огляд

Набір утиліт для програмного аналізу SSIS пакетів на локальному сервері.
Дозволяє отримувати інформацію про пакети, їх виконання, помилки, рядки підключення та потоки даних.

## Функції (util schema)

### 1. `util.ssisGetPackages` - Список SSIS пакетів

Отримує інформацію про SSIS пакети з каталогу SSISDB.

**Параметри:**
- `@folder` NVARCHAR(128) - Назва папки (NULL = всі)
- `@project` NVARCHAR(128) - Назва проекту (NULL = всі)
- `@package` NVARCHAR(128) - Назва пакету (NULL = всі)

**Приклади:**
```sql
-- Всі пакети
SELECT * FROM util.ssisGetPackages(NULL, NULL, NULL);

-- Пакети проекту
SELECT * FROM util.ssisGetPackages(NULL, 'ETL_Project', NULL);

-- Конкретний пакет
SELECT * FROM util.ssisGetPackages('Production', 'ETL_Project', 'LoadDimensions.dtsx');
```

### 2. `util.ssisGetExecutions` - Аналіз виконань

Детальна інформація про запуски пакетів з статистикою.

**Параметри:**
- `@folder` NVARCHAR(128) - Назва папки
- `@project` NVARCHAR(128) - Назва проекту
- `@package` NVARCHAR(128) - Назва пакету
- `@status` INT - Статус (1=Created, 2=Running, 3=Canceled, 4=Failed, 7=Succeeded)
- `@startTime` DATETIME - Фільтр за часом
- `@topN` INT - Кількість останніх результатів

**Приклади:**
```sql
-- Останні 10 виконань
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, NULL, 10)
ORDER BY StartTime DESC;

-- Невдалі виконання за добу
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, 4, DATEADD(DAY, -1, GETDATE()), NULL);

-- Статистика по пакетах за тиждень
SELECT 
    PackageName, 
    StatusDesc, 
    COUNT(*) ExecutionCount, 
    AVG(DurationSeconds) AvgDurationSec
FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, DATEADD(DAY, -7, GETDATE()), NULL)
GROUP BY PackageName, StatusDesc;
```

### 3. `util.ssisGetErrors` - Помилки виконання

Детальна інформація про помилки з кодами та повідомленнями.

**Параметри:**
- `@executionId` BIGINT - ID виконання
- `@folder` NVARCHAR(128) - Назва папки
- `@project` NVARCHAR(128) - Назва проекту
- `@package` NVARCHAR(128) - Назва пакету
- `@startTime` DATETIME - Фільтр за часом
- `@topN` INT - Кількість результатів

**Приклади:**
```sql
-- Помилки за останню добу
SELECT * FROM util.ssisGetErrors(NULL, NULL, NULL, NULL, DATEADD(DAY, -1, GETDATE()), NULL)
ORDER BY MessageTime DESC;

-- Помилки конкретного виконання
SELECT * FROM util.ssisGetErrors(12345, NULL, NULL, NULL, NULL, NULL);

-- Найчастіші помилки за місяць
SELECT 
    ErrorCode, 
    COUNT(*) ErrorCount, 
    MAX(Message) SampleMessage
FROM util.ssisGetErrors(NULL, NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()), NULL)
WHERE ErrorCode IS NOT NULL
GROUP BY ErrorCode
ORDER BY ErrorCount DESC;
```

### 4. `util.ssisGetConnectionStrings` - Рядки підключення

Витягує connection strings з параметрів пакетів.

**Параметри:**
- `@folder` NVARCHAR(128) - Назва папки
- `@project` NVARCHAR(128) - Назва проекту
- `@package` NVARCHAR(128) - Назва пакету

**Приклади:**
```sql
-- Всі рядки підключення
SELECT * FROM util.ssisGetConnectionStrings(NULL, NULL, NULL);

-- Рядки підключення проекту
SELECT ParameterName, ParameterValue
FROM util.ssisGetConnectionStrings('Production', 'ETL_Project', NULL)
WHERE ParameterValue IS NOT NULL;

-- Знайти підключення до конкретного сервера
SELECT FolderName, ProjectName, ParameterName, ParameterValue
FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
WHERE ParameterValue LIKE '%Server=MyServer%';
```

### 5. `util.ssisGetDataflows` - Потоки даних

Аналіз Data Flow компонентів для визначення джерел та призначень.

**Параметри:**
- `@executionId` BIGINT - ID виконання
- `@folder` NVARCHAR(128) - Назва папки
- `@project` NVARCHAR(128) - Назва проекту
- `@package` NVARCHAR(128) - Назва пакету
- `@componentType` NVARCHAR(50) - Тип ('Source', 'Destination', 'Transformation')
- `@startTime` DATETIME - Фільтр за часом

**Приклади:**
```sql
-- Всі джерела даних
SELECT DISTINCT ComponentName, Message
FROM util.ssisGetDataflows(NULL, NULL, NULL, NULL, 'Source', NULL);

-- Призначення даних (куди записуються дані)
SELECT DISTINCT PackageName, ComponentName, Message
FROM util.ssisGetDataflows(NULL, NULL, NULL, NULL, 'Destination', NULL);

-- Знайти пакети що записують в таблицю
SELECT DISTINCT PackageName, ComponentName, MessageTime
FROM util.ssisGetDataflows(NULL, NULL, NULL, NULL, 'Destination', NULL)
WHERE Message LIKE '%MyTable%'
ORDER BY MessageTime DESC;
```

### 6. `util.ssisFindTableUsage` - Пошук використання таблиць

Знаходить які пакети наповнюють або читають конкретну таблицю.

**Параметри:**
- `@tableName` NVARCHAR(128) - Назва таблиці (може містити %)
- `@databaseName` NVARCHAR(128) - Назва бази даних
- `@operationType` NVARCHAR(20) - Тип операції ('Read', 'Write')
- `@startTime` DATETIME - Фільтр за часом
- `@topN` INT - Кількість результатів

**Приклади:**
```sql
-- Які пакети наповнюють таблицю
SELECT * FROM util.ssisFindTableUsage('DimCustomer', NULL, 'Write', NULL, NULL);

-- Які пакети читають з таблиці
SELECT * FROM util.ssisFindTableUsage('FactSales', NULL, 'Read', NULL, NULL);

-- Всі пакети що працюють з Dim таблицями
SELECT * FROM util.ssisFindTableUsage('Dim%', 'DWH', NULL, DATEADD(DAY, -30, GETDATE()), NULL);

-- Топ таблиць з якими працюють пакети
SELECT TableName, OperationType, COUNT(DISTINCT PackageName) PackageCount
FROM util.ssisFindTableUsage(NULL, NULL, NULL, DATEADD(DAY, -7, GETDATE()), NULL)
GROUP BY TableName, OperationType
ORDER BY PackageCount DESC;
```

## Процедури

### `util.ssisAnalyze` - Комплексний аналіз

Надає повний огляд SSIS середовища.

**Параметри:**
- `@folder` NVARCHAR(128) - Назва папки
- `@project` NVARCHAR(128) - Назва проекту
- `@package` NVARCHAR(128) - Назва пакету
- `@daysBack` INT - Кількість днів для аналізу (за замовчуванням 7)
- `@output` TINYINT - Режим виводу (1=Packages, 2=Executions, 3=Errors, 4=Connections, 5=All)

**Приклади:**
```sql
-- Інформація про всі пакети
EXEC util.ssisAnalyze @output = 1;

-- Статистика виконань за місяць
EXEC util.ssisAnalyze @daysBack = 30, @output = 2;

-- Помилки конкретного пакету
EXEC util.ssisAnalyze @package = 'LoadDimensions.dtsx', @output = 3;

-- Повний аналіз проекту
EXEC util.ssisAnalyze @project = 'ETL_Project', @daysBack = 30, @output = 5;
```

## MCP Процедури (для AI інтеграції)

### `mcp.GetSsisPackages` - Список пакетів (JSON)

```sql
EXEC mcp.GetSsisPackages;
EXEC mcp.GetSsisPackages @project = 'ETL_Project';
```

### `mcp.GetSsisExecutions` - Виконання (JSON)

```sql
EXEC mcp.GetSsisExecutions;
EXEC mcp.GetSsisExecutions @status = 4, @daysBack = 1;
EXEC mcp.GetSsisExecutions @package = 'LoadDimensions.dtsx', @daysBack = 30, @topN = 50;
```

### `mcp.GetSsisErrors` - Помилки (JSON)

```sql
EXEC mcp.GetSsisErrors;
EXEC mcp.GetSsisErrors @daysBack = 1;
EXEC mcp.GetSsisErrors @executionId = 12345;
```

## Типові сценарії використання

### 1. Аналіз помилок при останньому виконанні

```sql
-- Знайти останнє невдале виконання
DECLARE @lastFailedExecution BIGINT = (
    SELECT TOP 1 ExecutionId
    FROM util.ssisGetExecutions(NULL, NULL, NULL, 4, DATEADD(DAY, -7, GETDATE()), 1)
);

-- Отримати всі помилки цього виконання
SELECT * FROM util.ssisGetErrors(@lastFailedExecution, NULL, NULL, NULL, NULL, NULL)
ORDER BY MessageTime;
```

### 2. Знайти які пакети наповнюють конкретну таблицю

```sql
SELECT 
    PackageName,
    ComponentName,
    OperationType,
    LastExecutionTime,
    ExecutionCount
FROM util.ssisFindTableUsage('MyTargetTable', 'MyDatabase', 'Write', NULL, NULL)
ORDER BY LastExecutionTime DESC;
```

### 3. Аналіз продуктивності пакетів

```sql
SELECT 
    PackageName,
    COUNT(*) TotalRuns,
    SUM(CASE WHEN StatusDesc = 'Succeeded' THEN 1 ELSE 0 END) SuccessCount,
    SUM(CASE WHEN StatusDesc = 'Failed' THEN 1 ELSE 0 END) FailCount,
    AVG(DurationSeconds) / 60.0 AvgDurationMinutes,
    MAX(DurationSeconds) / 60.0 MaxDurationMinutes
FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()), NULL)
GROUP BY PackageName
ORDER BY AvgDurationMinutes DESC;
```

### 4. Витягти всі рядки підключення проекту

```sql
SELECT 
    ProjectName,
    ParameterName,
    ParameterValue,
    Sensitive
FROM util.ssisGetConnectionStrings('Production', 'ETL_Project', NULL)
WHERE ParameterValue IS NOT NULL
ORDER BY ParameterName;
```

### 5. Моніторинг поточних виконань

```sql
SELECT 
    ExecutionId,
    PackageName,
    StatusDesc,
    StartTime,
    DurationFormatted,
    ExecutedAsName
FROM util.ssisGetExecutions(NULL, NULL, NULL, 2, NULL, NULL) -- Status 2 = Running
ORDER BY StartTime DESC;
```

## Вимоги

- SQL Server 2016+ з SSISDB каталогом
- Права доступу до SSISDB.catalog.* об'єктів
- Schema `util` та `mcp` мають існувати в базі даних

## Примітки

- Всі функції використовують NOLOCK для мінімізації блокувань
- Sensitive параметри маскуються як '*** SENSITIVE ***'
- Рекомендується використовувати параметр @topN для великих каталогів
- Для швидкого аналізу помилок використовуйте @daysBack для обмеження періоду

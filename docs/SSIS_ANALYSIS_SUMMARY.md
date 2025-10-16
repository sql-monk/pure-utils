# SSIS Package Analysis - Огляд рішення

## Створені утиліти

Реалізовано комплексне рішення для програмного аналізу SSIS пакетів на локальному SQL Server.

### Функції (util schema) - 6 шт.

1. **`util.ssisGetPackages`** - Список SSIS пакетів
   - Отримує інформацію про пакети, проекти, папки з SSISDB
   - Фільтрація за folder/project/package
   - Інформація про версії та розгортання

2. **`util.ssisGetExecutions`** - Аналіз виконань
   - Детальна статистика про запуски пакетів
   - Статуси виконання (Created/Running/Failed/Succeeded тощо)
   - Тривалість, користувачі, використання ресурсів
   - Підтримка фільтрації за період та topN

3. **`util.ssisGetErrors`** - Помилки виконання
   - Детальна інформація про помилки
   - Коди помилок, повідомлення, джерела
   - Шляхи до компонентів пакету
   - Фільтрація за executionId/folder/project/package

4. **`util.ssisGetConnectionStrings`** - Рядки підключення
   - Витягує connection strings з параметрів пакетів
   - Параметри проектного та пакетного рівня
   - Маскування sensitive параметрів
   - Пошук за назвою параметра

5. **`util.ssisGetDataflows`** - Аналіз потоків даних
   - Компоненти Data Flow Task
   - Визначення Source/Destination/Transformation
   - Аналіз повідомлень про обробку даних
   - Кількість оброблених рядків

6. **`util.ssisFindTableUsage`** - Пошук використання таблиць
   - Знаходить які пакети працюють з конкретною таблицею
   - Визначає операції Read/Write
   - Статистика використання
   - Підтримка шаблонів пошуку (%)

### Процедури (util schema) - 1 шт.

1. **`util.ssisAnalyze`** - Комплексний аналіз
   - Універсальна процедура для аналізу SSIS середовища
   - 5 режимів виводу (Packages/Executions/Errors/Connections/All)
   - Статистика та summary інформація
   - Топ помилок, топ виконань

### MCP Процедури (для AI інтеграції) - 3 шт.

1. **`mcp.GetSsisPackages`** - Список пакетів (JSON)
2. **`mcp.GetSsisExecutions`** - Виконання (JSON)
3. **`mcp.GetSsisErrors`** - Помилки (JSON)

## Відповіді на питання з task statement

### ✅ Аналіз виконання пакетів

```sql
-- Останні виконання
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, NULL, 20);

-- Невдалі виконання
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, 4, DATEADD(DAY, -1, GETDATE()), NULL);

-- Статистика
SELECT PackageName, StatusDesc, COUNT(*) ExecutionCount, AVG(DurationSeconds) AvgDuration
FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()), NULL)
GROUP BY PackageName, StatusDesc;
```

### ✅ Аналіз самих пакетів

```sql
-- Список всіх пакетів
SELECT * FROM util.ssisGetPackages(NULL, NULL, NULL);

-- Пакети з інформацією про розгортання
SELECT FolderName, ProjectName, PackageName, DeployedByName, LastDeployedTime
FROM util.ssisGetPackages(NULL, NULL, NULL)
ORDER BY LastDeployedTime DESC;
```

### ✅ Розуміти який пакет звідки що переносить

```sql
-- Джерела даних (звідки читає)
SELECT PackageName, ComponentName, Message
FROM util.ssisGetDataflows(NULL, NULL, NULL, NULL, 'Source', NULL);

-- Призначення даних (куди записує)
SELECT PackageName, ComponentName, Message
FROM util.ssisGetDataflows(NULL, NULL, NULL, NULL, 'Destination', NULL);
```

### ✅ Витягнути рядки підключення

```sql
-- Всі connection strings
SELECT ProjectName, ParameterName, ParameterValue
FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
WHERE ParameterValue IS NOT NULL;

-- Рядки підключення конкретного проекту
SELECT ParameterName, ParameterValue
FROM util.ssisGetConnectionStrings('Production', 'ETL_Project', NULL);

-- Знайти підключення до конкретного сервера
SELECT ProjectName, ParameterName, ParameterValue
FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
WHERE ParameterValue LIKE '%Server=MyServer%';
```

### ✅ Пошукати яким пакетом наповнюється та чи інша таблиця

```sql
-- Які пакети наповнюють таблицю DimCustomer
SELECT PackageName, ComponentName, OperationType, LastExecutionTime
FROM util.ssisFindTableUsage('DimCustomer', NULL, 'Write', NULL, NULL);

-- Які пакети працюють з усіма Dim таблицями
SELECT TableName, PackageName, OperationType
FROM util.ssisFindTableUsage('Dim%', 'DWH', NULL, NULL, NULL)
ORDER BY TableName;

-- Топ таблиць по використанню
SELECT TableName, COUNT(DISTINCT PackageName) PackageCount
FROM util.ssisFindTableUsage(NULL, NULL, NULL, DATEADD(DAY, -7, GETDATE()), NULL)
GROUP BY TableName
ORDER BY PackageCount DESC;
```

### ✅ Пошукати все для аналізу помилки при останньому виконанні

```sql
-- Помилки останнього невдалого виконання
DECLARE @lastFailedExecution BIGINT = (
    SELECT TOP 1 ExecutionId
    FROM util.ssisGetExecutions(NULL, NULL, NULL, 4, DATEADD(DAY, -7, GETDATE()), 1)
);

SELECT * FROM util.ssisGetErrors(@lastFailedExecution, NULL, NULL, NULL, NULL, NULL);

-- Або просто останні помилки конкретного пакету
SELECT MessageTime, ErrorCode, Message, PackagePath
FROM util.ssisGetErrors(NULL, NULL, NULL, 'MyPackage.dtsx', DATEADD(DAY, -1, GETDATE()), 10)
ORDER BY MessageTime DESC;

-- Найчастіші помилки за період
SELECT ErrorCode, COUNT(*) ErrorCount, MAX(Message) SampleMessage
FROM util.ssisGetErrors(NULL, NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()), NULL)
WHERE ErrorCode IS NOT NULL
GROUP BY ErrorCode
ORDER BY ErrorCount DESC;
```

## Комплексний аналіз одним викликом

```sql
-- Повний аналіз за 30 днів
EXEC util.ssisAnalyze 
    @folder = NULL,
    @project = NULL,
    @package = NULL,
    @daysBack = 30,
    @output = 5;  -- 5 = All (всі result sets)
```

## Документація та тести

- **[SSIS_ANALYSIS.md](SSIS_ANALYSIS.md)** - Детальна документація з прикладами
- **[SSIS_ANALYSIS_VALIDATION.sql](SSIS_ANALYSIS_VALIDATION.sql)** - Валідаційний скрипт

## Особливості реалізації

1. **Використання NOLOCK** - Мінімізація блокувань при читанні з SSISDB
2. **Параметризація** - Гнучкі фільтри для всіх функцій
3. **Масштабованість** - Підтримка topN для великих каталогів
4. **Безпека** - Маскування sensitive параметрів
5. **Стиль коду** - Відповідність codestyle.md та naming_convention.md
6. **Документація** - Детальні коментарі українською в кожному об'єкті
7. **MCP інтеграція** - JSON відповіді для AI-асистентів

## Вимоги

- SQL Server 2016+ з SSISDB каталогом
- Права доступу до SSISDB.catalog.* об'єктів
- Schema util та mcp

## Файли проекту

### Функції (util/Functions/)
- ssisGetPackages.sql (80 рядків)
- ssisGetExecutions.sql (128 рядків)
- ssisGetErrors.sql (129 рядків)
- ssisGetConnectionStrings.sql (148 рядків)
- ssisGetDataflows.sql (149 рядків)
- ssisFindTableUsage.sql (194 рядки)

### Процедури (util/Procedures/)
- ssisAnalyze.sql (148 рядків)

### MCP Процедури (mcp/Procedures/)
- GetSsisPackages.sql (84 рядки)
- GetSsisExecutions.sql (93 рядки)
- GetSsisErrors.sql (94 рядки)

### Документація (docs/)
- SSIS_ANALYSIS.md - Повна документація
- SSIS_ANALYSIS_VALIDATION.sql - Тестовий скрипт

**Всього**: 10 SQL об'єктів + 2 документи

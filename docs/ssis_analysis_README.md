# Аналіз SSIS пакетів в SQL Server 2022

Комплексний набір функцій та процедур для програмного аналізу SSIS пакетів на локальному сервері.

## Огляд

Цей набір інструментів дозволяє:
- ✅ Отримувати список всіх SSIS пакетів та їх метадані
- ✅ Витягувати рядки підключення з пакетів
- ✅ Аналізувати потоки даних (джерела та призначення)
- ✅ Знаходити пакети що наповнюють конкретні таблиці
- ✅ Моніторити виконання пакетів та аналізувати помилки
- ✅ Отримувати детальну статистику виконань

## Передумови

- SQL Server 2022
- Розгорнутий SSIS каталог (SSISDB)
- Права доступу до каталогу SSISDB

## Функції

### 1. `util.ssisGetPackages` - Список SSIS пакетів

Повертає список усіх SSIS пакетів з каталогу SSISDB.

**Параметри:**
- `@folder` NVARCHAR(128) - Назва папки (NULL = усі папки)
- `@project` NVARCHAR(128) - Назва проекту (NULL = усі проекти)
- `@package` NVARCHAR(128) - Назва пакета (NULL = усі пакети)

**Приклад використання:**
```sql
-- Отримати всі пакети
SELECT * FROM util.ssisGetPackages(NULL, NULL, NULL);

-- Отримати пакети конкретної папки
SELECT * FROM util.ssisGetPackages('ETL_Production', NULL, NULL);
```

### 2. `util.ssisGetConnectionStrings` - Рядки підключення

Витягує рядки підключення з SSIS пакетів (на рівні проекту та пакета).

**Параметри:**
- `@folder` NVARCHAR(128) - Назва папки (NULL = усі папки)
- `@project` NVARCHAR(128) - Назва проекту (NULL = усі проекти)
- `@package` NVARCHAR(128) - Назва пакета (NULL = усі пакети)

**Приклад використання:**
```sql
-- Отримати всі рядки підключення
SELECT * FROM util.ssisGetConnectionStrings(NULL, NULL, NULL);

-- Знайти підключення до конкретного сервера
SELECT * FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
WHERE ConnectionString LIKE '%MyServer%';
```

### 3. `util.ssisGetExecutions` - Виконання пакетів

Повертає історію виконань SSIS пакетів з детальною інформацією.

**Параметри:**
- `@folder` NVARCHAR(128) - Назва папки (NULL = усі папки)
- `@project` NVARCHAR(128) - Назва проекту (NULL = усі проекти)
- `@package` NVARCHAR(128) - Назва пакета (NULL = усі пакети)
- `@status` INT - Статус виконання (4=Failed, 7=Succeeded, NULL = всі)
- `@hoursBack` INT - Кількість годин назад (за замовчуванням 24)

**Приклад використання:**
```sql
-- Всі виконання за останню добу
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, 24)
ORDER BY StartTime DESC;

-- Невдалі виконання за тиждень
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, 4, 168)
ORDER BY StartTime DESC;
```

### 4. `util.ssisGetExecutionErrors` - Помилки виконання

Повертає помилки що виникли під час виконання SSIS пакетів.

**Параметри:**
- `@folder` NVARCHAR(128) - Назва папки (NULL = усі папки)
- `@project` NVARCHAR(128) - Назва проекту (NULL = усі проекти)
- `@package` NVARCHAR(128) - Назва пакета (NULL = усі пакети)
- `@executionId` BIGINT - ID конкретного виконання (NULL = всі)
- `@hoursBack` INT - Кількість годин назад (за замовчуванням 24)

**Приклад використання:**
```sql
-- Всі помилки за останню добу
SELECT * FROM util.ssisGetExecutionErrors(NULL, NULL, NULL, NULL, 24)
ORDER BY MessageTime DESC;

-- Помилки конкретного пакета
SELECT * FROM util.ssisGetExecutionErrors('ETL', 'DWH', 'LoadFacts', NULL, 168)
ORDER BY MessageTime DESC;

-- Найчастіші помилки
SELECT LEFT(Message, 100) ErrorMessage, COUNT(*) ErrorCount
FROM util.ssisGetExecutionErrors(NULL, NULL, NULL, NULL, 168)
GROUP BY LEFT(Message, 100)
ORDER BY ErrorCount DESC;
```

### 5. `util.ssisGetExecutionStats` - Статистика виконань

Агреговані дані про успішність виконань, середню тривалість та частоту запусків.

**Параметри:**
- `@folder` NVARCHAR(128) - Назва папки (NULL = усі папки)
- `@project` NVARCHAR(128) - Назва проекту (NULL = усі проекти)
- `@package` NVARCHAR(128) - Назва пакета (NULL = усі пакети)
- `@daysBack` INT - Кількість днів назад (за замовчуванням 30)

**Приклад використання:**
```sql
-- Статистика за останній місяць
SELECT * FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30)
ORDER BY FailedExecutions DESC;

-- Пакети з низькою успішністю
SELECT * FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30)
WHERE SuccessRate < 90
ORDER BY SuccessRate;

-- Найповільніші пакети
SELECT TOP 10 PackageName, AvgDurationMinutes, MaxDurationMinutes
FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30)
ORDER BY AvgDurationMinutes DESC;
```

### 6. `util.ssisGetPackagesByDestinationTable` - Пошук пакетів за таблицею

Знаходить SSIS пакети що наповнюють конкретну таблицю.

**Параметри:**
- `@tableName` NVARCHAR(128) - Назва таблиці (NULL = всі таблиці)
- `@schemaName` NVARCHAR(128) - Назва схеми (NULL = всі схеми)
- `@daysBack` INT - Кількість днів назад (за замовчуванням 30)

**Приклад використання:**
```sql
-- Знайти пакети що наповнюють таблицю FactSales
SELECT * FROM util.ssisGetPackagesByDestinationTable('FactSales', 'dbo', 30);

-- Всі пакети з Fact таблицями
SELECT DISTINCT PackageName, DestinationTable
FROM util.ssisGetPackagesByDestinationTable(NULL, NULL, 30)
WHERE DestinationTable LIKE '%Fact%'
ORDER BY PackageName;

-- Статистика навантаження на таблиці
SELECT DestinationTable, 
       COUNT(DISTINCT PackageName) PackageCount,
       SUM(TotalRows) TotalRowsProcessed
FROM util.ssisGetPackagesByDestinationTable(NULL, NULL, 30)
GROUP BY DestinationTable
ORDER BY TotalRowsProcessed DESC;
```

### 7. `util.ssisGetDataFlows` - Аналіз потоків даних

Аналізує потоки даних у SSIS пакетах (джерела, призначення, трансформації).

**Параметри:**
- `@folder` NVARCHAR(128) - Назва папки (NULL = усі папки)
- `@project` NVARCHAR(128) - Назва проекту (NULL = усі проекти)
- `@package` NVARCHAR(128) - Назва пакета (NULL = усі пакети)
- `@daysBack` INT - Кількість днів назад (за замовчуванням 30)

**Приклад використання:**
```sql
-- Всі потоки даних за останній тиждень
SELECT * FROM util.ssisGetDataFlows(NULL, NULL, NULL, 7)
ORDER BY ExecutionTime DESC;

-- Компоненти що обробили найбільше рядків
SELECT ComponentName, ComponentType, 
       SUM(RowsRead) TotalRowsRead,
       SUM(RowsWritten) TotalRowsWritten
FROM util.ssisGetDataFlows(NULL, NULL, NULL, 30)
GROUP BY ComponentName, ComponentType
ORDER BY TotalRowsRead DESC;
```

### 8. `util.ssisGetEventMessages` - Всі повідомлення виконань

Повертає всі повідомлення з виконання SSIS пакетів (інформаційні, попередження, помилки).

**Параметри:**
- `@folder` NVARCHAR(128) - Назва папки (NULL = усі папки)
- `@project` NVARCHAR(128) - Назва проекту (NULL = усі проекти)
- `@package` NVARCHAR(128) - Назва пакета (NULL = усі пакети)
- `@executionId` BIGINT - ID виконання (NULL = всі виконання)
- `@messageType` SMALLINT - Тип повідомлення (120=Error, 110=Warning, 70=Info, NULL = всі)
- `@hoursBack` INT - Кількість годин назад (за замовчуванням 24)

**Приклад використання:**
```sql
-- Всі повідомлення за останню добу
SELECT * FROM util.ssisGetEventMessages(NULL, NULL, NULL, NULL, NULL, 24)
ORDER BY MessageTime DESC;

-- Тільки помилки
SELECT * FROM util.ssisGetEventMessages(NULL, NULL, NULL, NULL, 120, 24)
ORDER BY MessageTime DESC;

-- Найчастіші повідомлення
SELECT LEFT(Message, 100) MessageText, 
       MessageTypeDescription,
       COUNT(*) MessageCount
FROM util.ssisGetEventMessages(NULL, NULL, NULL, NULL, NULL, 168)
GROUP BY LEFT(Message, 100), MessageTypeDescription
ORDER BY MessageCount DESC;
```

### 9. `util.ssisGetExecutionParameters` - Параметри виконань

Повертає параметри що використовувалися при запуску пакетів.

**Параметри:**
- `@folder` NVARCHAR(128) - Назва папки (NULL = усі папки)
- `@project` NVARCHAR(128) - Назва проекту (NULL = усі проекти)
- `@package` NVARCHAR(128) - Назва пакета (NULL = усі пакети)
- `@executionId` BIGINT - ID виконання (NULL = всі виконання)
- `@hoursBack` INT - Кількість годин назад (за замовчуванням 24)

**Приклад використання:**
```sql
-- Параметри виконань за останню добу
SELECT * FROM util.ssisGetExecutionParameters(NULL, NULL, NULL, NULL, 24)
ORDER BY ExecutionTime DESC;

-- Параметри конкретного виконання
SELECT ParameterName, ParameterValue
FROM util.ssisGetExecutionParameters(NULL, NULL, NULL, 12345, NULL)
ORDER BY ParameterName;
```

### 10. `util.ssisAnalyzeLastExecution` - Детальний аналіз виконання

Процедура для комплексного аналізу останнього (або конкретного) виконання пакета.

**Параметри:**
- `@folder` NVARCHAR(128) - Назва папки
- `@project` NVARCHAR(128) - Назва проекту
- `@package` NVARCHAR(128) - Назва пакета
- `@executionId` BIGINT - ID виконання (NULL = останнє виконання)

**Приклад використання:**
```sql
-- Аналіз останнього виконання
EXEC util.ssisAnalyzeLastExecution 
    @folder = 'ETL_Production',
    @project = 'DataWarehouse',
    @package = 'LoadFactSales',
    @executionId = NULL;

-- Аналіз конкретного виконання
EXEC util.ssisAnalyzeLastExecution 
    @folder = 'ETL_Production',
    @project = 'DataWarehouse',
    @package = 'LoadFactSales',
    @executionId = 12345;
```

**Результати процедури включають:**
1. Загальну інформацію про виконання (статус, час початку/кінця, тривалість)
2. Помилки та попередження з детальною інформацією
3. Параметри виконання
4. Статистику компонентів (рядки оброблені, тривалість)
5. Інформаційні повідомлення

## Типові сценарії використання

### Моніторинг здоров'я SSIS системи

```sql
-- Пакети з проблемами за останній тиждень
SELECT 
    PackageName,
    SuccessRate,
    FailedExecutions,
    LastFailureTime
FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 7)
WHERE SuccessRate < 100
ORDER BY SuccessRate, LastFailureTime DESC;
```

### Пошук причин помилок

```sql
-- Аналіз помилок конкретного пакета
DECLARE @packageName NVARCHAR(128) = 'LoadFactSales';

-- Отримати останні помилки
SELECT TOP 10
    MessageTime,
    Message,
    PackagePath
FROM util.ssisGetExecutionErrors(NULL, NULL, @packageName, NULL, 168)
ORDER BY MessageTime DESC;

-- Детальний аналіз останнього виконання
EXEC util.ssisAnalyzeLastExecution 
    @folder = 'ETL_Production',
    @project = 'DataWarehouse',
    @package = @packageName;
```

### Відстеження потоків даних

```sql
-- Які таблиці наповнюються яким пакетом
SELECT 
    PackageName,
    DestinationTable,
    SUM(TotalRows) RowsProcessed,
    MAX(LastExecutionTime) LastRun
FROM util.ssisGetPackagesByDestinationTable(NULL, NULL, 30)
GROUP BY PackageName, DestinationTable
ORDER BY PackageName, DestinationTable;
```

### Аудит підключень

```sql
-- Перевірка всіх рядків підключення
SELECT 
    ProjectName,
    ConnectionManagerName,
    ConnectionString
FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
ORDER BY ProjectName, ConnectionManagerName;
```

## Основні переваги

1. **Централізований моніторинг** - всі дані про SSIS в одному місці
2. **Швидка діагностика** - миттєвий доступ до помилок та їх контексту
3. **Історичний аналіз** - відстеження трендів та паттернів виконання
4. **Оптимізація** - виявлення найповільніших пакетів та компонентів
5. **Аудит** - повний контроль над підключеннями та параметрами

## Документація Microsoft

Базується на офіційній документації Microsoft SQL Server 2022:
- [SQL Server Integration Services](https://learn.microsoft.com/sql/integration-services/sql-server-integration-services)
- [SSIS Catalog Views](https://learn.microsoft.com/sql/integration-services/system-views/views-integration-services-catalog)
- [catalog.executions](https://learn.microsoft.com/sql/integration-services/system-views/catalog-executions-ssisdb-database)
- [catalog.operation_messages](https://learn.microsoft.com/sql/integration-services/system-views/catalog-operation-messages-ssisdb-database)
- [catalog.executable_statistics](https://learn.microsoft.com/sql/integration-services/system-views/catalog-executable-statistics)

## Демонстраційний скрипт

Повний демонстраційний скрипт з прикладами використання всіх функцій доступний в файлі:
`docs/ssis_analysis_demo.sql`

## Автор

Створено для проекту pure-utils - набір утиліт для SQL Server 2022

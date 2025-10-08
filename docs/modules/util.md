# Модуль util - Основна бібліотека

## Огляд

Схема `util` є серцем pure-utils і містить понад 100 об'єктів (функції, процедури, таблиці, представлення) для автоматизації та оптимізації роботи з SQL Server. Модуль організований за функціональними категоріями.

## Категорії функціональності

### 1. Metadata - Управління метаданими

#### metadataGetAnyId

**Призначення**: Універсальне отримання ID будь-якого об'єкта бази даних за його назвою.

**Сигнатура**:
```sql
CREATE FUNCTION util.metadataGetAnyId(
    @object NVARCHAR(128),
    @class NVARCHAR(128) = NULL
)
RETURNS INT
```

**Параметри**:
- `@object` - назва об'єкта (може включати схему: `schema.object`)
- `@class` - тип об'єкта (OBJECT, INDEX, COLUMN, DATABASE, тощо), NULL = автоматичне визначення

**Повертає**: INT - ID об'єкта або NULL якщо не знайдено

**Приклади**:
```sql
-- Отримати object_id таблиці
SELECT util.metadataGetAnyId('sys.tables', 'OBJECT');

-- Отримати database_id
SELECT util.metadataGetAnyId('master', 'DATABASE');

-- Автоматичне визначення типу
SELECT util.metadataGetAnyId('dbo.MyTable', DEFAULT);
```

#### metadataGetAnyName

**Призначення**: Універсальне отримання назви об'єкта за його ID.

**Сигнатура**:
```sql
CREATE FUNCTION util.metadataGetAnyName(
    @objectId INT,
    @class NVARCHAR(128) = NULL
)
RETURNS NVARCHAR(128)
```

**Параметри**:
- `@objectId` - ID об'єкта
- `@class` - тип об'єкта (OBJECT, INDEX, COLUMN, тощо)

**Повертає**: NVARCHAR(128) - назва об'єкта

**Приклади**:
```sql
-- Отримати назву об'єкта
SELECT util.metadataGetAnyName(OBJECT_ID('sys.tables'), 'OBJECT');

-- Отримати назву індексу
DECLARE @indexId INT = 1;
SELECT util.metadataGetAnyName(@indexId, 'INDEX');
```

#### metadataGetColumns

**Призначення**: Отримання детальної інформації про колонки таблиці.

**Сигнатура**:
```sql
CREATE FUNCTION util.metadataGetColumns(
    @object NVARCHAR(128) = NULL,
    @objectId INT = NULL
)
RETURNS TABLE
```

**Параметри**:
- `@object` - назва таблиці
- `@objectId` - ID таблиці (альтернатива назві)

**Повертає**: TABLE з колонками:
- ColumnId, ColumnName, DataType, MaxLength, Precision, Scale
- IsNullable, IsIdentity, IsComputed, DefaultValue, Description

**Приклади**:
```sql
-- Всі колонки таблиці
SELECT * FROM util.metadataGetColumns('sys.tables', NULL);

-- З фільтрацією
SELECT ColumnName, DataType, IsNullable
FROM util.metadataGetColumns('dbo.MyTable', NULL)
WHERE IsIdentity = 0;
```

#### metadataSetTableDescription, metadataSetColumnDescription

**Призначення**: Встановлення описів (MS_Description) для таблиць та колонок.

**Сигнатури**:
```sql
CREATE PROCEDURE util.metadataSetTableDescription
    @table NVARCHAR(128),
    @description NVARCHAR(MAX)

CREATE PROCEDURE util.metadataSetColumnDescription
    @table NVARCHAR(128),
    @column NVARCHAR(128),
    @description NVARCHAR(MAX)
```

**Приклади**:
```sql
-- Встановити опис таблиці
EXEC util.metadataSetTableDescription 
    @table = 'dbo.Users', 
    @description = 'Таблиця користувачів системи';

-- Встановити опис колонки
EXEC util.metadataSetColumnDescription 
    @table = 'dbo.Users',
    @column = 'UserId',
    @description = 'Унікальний ідентифікатор користувача';
```

### 2. Indexes - Аналіз та оптимізація індексів

#### indexesGetMissing

**Призначення**: Виявлення відсутніх індексів на основі рекомендацій SQL Server.

**Сигнатура**:
```sql
CREATE FUNCTION util.indexesGetMissing(
    @table NVARCHAR(128) = NULL
)
RETURNS TABLE
```

**Параметри**:
- `@table` - назва таблиці для аналізу (NULL = всі таблиці)

**Повертає**: TABLE з колонками:
- DatabaseName, SchemaName, TableName
- EqualityColumns, InequalityColumns, IncludedColumns
- UniqueCompiles, UserSeeks, UserScans
- AvgTotalUserCost, ImprovementMeasure
- CreateIndexStatement

**Приклади**:
```sql
-- Топ-10 найбільш корисних відсутніх індексів
SELECT TOP 10
    TableName,
    EqualityColumns,
    IncludedColumns,
    ImprovementMeasure,
    CreateIndexStatement
FROM util.indexesGetMissing(NULL)
ORDER BY ImprovementMeasure DESC;

-- Для конкретної таблиці
SELECT * 
FROM util.indexesGetMissing('dbo.Orders')
WHERE ImprovementMeasure > 1000;
```

**Обмеження**:
- Базується на DMV `sys.dm_db_missing_index_*`
- Статистика скидається при перезапуску SQL Server
- Не враховує overhead на запис

#### indexesGetUnused

**Призначення**: Виявлення невикористовуваних індексів.

**Сигнатура**:
```sql
CREATE FUNCTION util.indexesGetUnused(
    @table NVARCHAR(128) = NULL
)
RETURNS TABLE
```

**Повертає**: TABLE з індексами без операцій читання

**Приклади**:
```sql
-- Невикористовувані індекси з розміром > 10 MB
SELECT 
    SchemaName,
    TableName,
    IndexName,
    UserSeeks,
    UserScans,
    UserLookups,
    SizeKB / 1024.0 AS SizeMB
FROM util.indexesGetUnused(NULL)
WHERE SizeKB > 10240
ORDER BY SizeKB DESC;
```

#### indexesGetConventionNames

**Призначення**: Генерація стандартизованих назв індексів згідно з конвенціями.

**Сигнатура**:
```sql
CREATE FUNCTION util.indexesGetConventionNames(
    @object NVARCHAR(128) = NULL,
    @index NVARCHAR(128) = NULL
)
RETURNS TABLE
```

**Повертає**: TABLE з поточними та рекомендованими назвами

**Конвенція назв**:
- `PK_TableName` - Primary Key
- `CI_TableName` - Clustered Index
- `IX_TableName_Columns[_INC][_FLT][_UQ]` - Nonclustered Index
  - `_INC` - має included колонки
  - `_FLT` - має filter
  - `_UQ` - unique

**Приклади**:
```sql
-- Генерація скриптів перейменування
SELECT 
    'EXEC sp_rename ''' + SchemaName + '.' + TableName + '.' + IndexName + 
    ''', ''' + NewIndexName + ''', ''INDEX'';' AS RenameScript
FROM util.indexesGetConventionNames(NULL, NULL)
WHERE IndexName <> NewIndexName;
```

#### indexesGetSpaceUsed

**Призначення**: Детальна статистика використання дискового простору індексами.

**Сигнатура**:
```sql
CREATE FUNCTION util.indexesGetSpaceUsed(
    @object NVARCHAR(128) = NULL
)
RETURNS TABLE
```

**Повертає**: TABLE з інформацією про розмір та фрагментацію

**Приклади**:
```sql
-- Найбільші індекси
SELECT TOP 20
    TableName,
    IndexName,
    TotalSpaceMB,
    UsedSpaceMB,
    AvgFragmentationPercent
FROM util.indexesGetSpaceUsed(NULL)
ORDER BY TotalSpaceMB DESC;

-- Фрагментовані індекси > 30%
SELECT *
FROM util.indexesGetSpaceUsed(NULL)
WHERE AvgFragmentationPercent > 30
  AND TotalSpaceMB > 100;
```

### 3. Modules - Робота з SQL кодом

#### modulesRecureSearchForOccurrences

**Призначення**: Рекурсивний пошук входжень об'єкта в інших об'єктах.

**Сигнатура**:
```sql
CREATE FUNCTION util.modulesRecureSearchForOccurrences(
    @object NVARCHAR(128),
    @maxDepth INT = 10
)
RETURNS TABLE
```

**Параметри**:
- `@object` - назва об'єкта для пошуку
- `@maxDepth` - максимальна глибина рекурсії

**Приклади**:
```sql
-- Знайти всі об'єкти, що використовують функцію
SELECT 
    Depth,
    ObjectType,
    ObjectName,
    ReferencedObjectName
FROM util.modulesRecureSearchForOccurrences('util.metadataGetAnyId', 5)
ORDER BY Depth, ObjectName;
```

#### modulesFindCommentsPositions

**Призначення**: Знаходження позицій коментарів у SQL коді.

**Сигнатура**:
```sql
CREATE FUNCTION util.modulesFindCommentsPositions(
    @object NVARCHAR(128) = NULL,
    @objectId INT = NULL
)
RETURNS TABLE
```

**Повертає**: TABLE з типами коментарів та позиціями

**Приклади**:
```sql
-- Витягти всі коментарі з процедури
SELECT 
    CommentType,
    StartPosition,
    EndPosition,
    CommentText
FROM util.modulesFindCommentsPositions('dbo.MyProcedure', NULL);
```

#### modulesGetDescriptionFromComments

**Призначення**: Автоматичне витягування описів з структурованих коментарів.

**Сигнатура**:
```sql
CREATE FUNCTION util.modulesGetDescriptionFromComments(
    @object NVARCHAR(128) = NULL,
    @objectId INT = NULL
)
RETURNS TABLE
```

**Повертає**: Розпарсені секції Description, Parameters, Returns, Usage

**Приклади**:
```sql
-- Отримати документацію з коментарів
SELECT 
    Section,
    Content
FROM util.modulesGetDescriptionFromComments('util.indexesGetMissing', NULL);
```

#### modulesSplitToLines

**Призначення**: Розбиття SQL коду на рядки з нумерацією.

**Сигнатура**:
```sql
CREATE FUNCTION util.modulesSplitToLines(
    @object NVARCHAR(128) = NULL,
    @objectId INT = NULL
)
RETURNS TABLE
```

**Повертає**: TABLE з номерами рядків та текстом

**Приклади**:
```sql
-- Показати код з номерами рядків
SELECT 
    LineNumber,
    LineText
FROM util.modulesSplitToLines('dbo.MyProcedure', NULL)
ORDER BY LineNumber;
```

### 4. XE (Extended Events) - Моніторинг

#### xeGetErrors

**Призначення**: Читання помилок з Extended Events файлів.

**Сигнатура**:
```sql
CREATE FUNCTION util.xeGetErrors(
    @scope NVARCHAR(10) = NULL
)
RETURNS TABLE
```

**Параметри**:
- `@scope` - NULL для всіх файлів або 'Users'/'SSIS' для специфічних

**Повертає**: TABLE з інформацією про помилки

**Приклади**:
```sql
-- Останні 100 помилок
SELECT TOP 100
    EventTime,
    ErrorNumber,
    Severity,
    State,
    Message,
    DatabaseName,
    ObjectName,
    ClientAppName
FROM util.xeGetErrors(DEFAULT)
ORDER BY EventTime DESC;

-- Критичні помилки за останню годину
SELECT *
FROM util.xeGetErrors(NULL)
WHERE EventTime > DATEADD(HOUR, -1, GETDATE())
  AND Severity >= 16;
```

#### xeGetModules

**Призначення**: Читання виконань модулів (процедур, функцій) з XE файлів.

**Сигнатура**:
```sql
CREATE FUNCTION util.xeGetModules(
    @scope NVARCHAR(10) = 'Users',
    @lastEventTime DATETIME2 = NULL
)
RETURNS TABLE
```

**Параметри**:
- `@scope` - 'Users' або 'SSIS'
- `@lastEventTime` - з якого часу читати (інкрементальне завантаження)

**Приклади**:
```sql
-- Найдовші виконання за сьогодні
SELECT TOP 20
    EventTime,
    ObjectName,
    Duration / 1000000.0 AS DurationSeconds,
    ServerPrincipalName,
    ClientAppName
FROM util.xeGetModules('Users', CAST(GETDATE() AS DATE))
ORDER BY Duration DESC;

-- Інкрементальне завантаження
DECLARE @lastTime DATETIME2;
SELECT @lastTime = MAX(EventTime) FROM util.executionModulesUsers;

SELECT * FROM util.xeGetModules('Users', @lastTime);
```

#### xeCopyModulesToTable

**Призначення**: Копіювання даних з XE файлів у таблиці для довгострокового зберігання.

**Сигнатура**:
```sql
CREATE PROCEDURE util.xeCopyModulesToTable
    @scope NVARCHAR(10) = 'Users'
```

**Приклади**:
```sql
-- Завантажити нові дані у таблиці
EXEC util.xeCopyModulesToTable @scope = 'Users';

-- Налаштувати як SQL Agent Job для регулярного виконання
```

### 5. DDL Scripts - Генерація скриптів

#### tablesGetScript

**Призначення**: Генерація повного DDL скрипту таблиці з усіма обмеженнями.

**Сигнатура**:
```sql
CREATE FUNCTION util.tablesGetScript(
    @table NVARCHAR(128),
    @schema NVARCHAR(128) = NULL
)
RETURNS TABLE
```

**Повертає**: TABLE з DDL скриптом

**Особливості**:
- Включає всі колонки з типами даних
- Primary Key, Foreign Keys
- Indexes, Constraints
- Compression settings
- Partition schemes

**Приклади**:
```sql
-- Отримати DDL таблиці
DECLARE @ddl NVARCHAR(MAX);
SELECT @ddl = DDLScript
FROM util.tablesGetScript('Orders', 'dbo');
PRINT @ddl;

-- Зберегти у файл через SSMS або bcp
```

#### objesctsScriptWithDependencies

**Призначення**: Рекурсивна генерація DDL з урахуванням залежностей.

**Сигнатура**:
```sql
CREATE PROCEDURE util.objesctsScriptWithDependencies
    @object NVARCHAR(128),
    @includeReferences BIT = 1,
    @maxDepth INT = 10
```

**Параметри**:
- `@object` - початковий об'єкт
- `@includeReferences` - включити залежності
- `@maxDepth` - максимальна глибина

**Особливості**:
- Topological sort (правильний порядок створення)
- Підтримка cross-database залежностей
- Обробка синонімів

**Приклади**:
```sql
-- Згенерувати скрипт з усіма залежностями
EXEC util.objesctsScriptWithDependencies 
    @object = 'dbo.ComplexView',
    @includeReferences = 1,
    @maxDepth = 5;
```

### 6. Utilities - Утилітарні функції

#### stringGetCreateTempScript

**Призначення**: Генерація CREATE TABLE для тимчасової таблиці з аналізу SELECT запиту.

**Сигнатура**:
```sql
CREATE FUNCTION util.stringGetCreateTempScript(
    @query NVARCHAR(MAX),
    @tableName NVARCHAR(128) = '#temp'
)
RETURNS NVARCHAR(MAX)
```

**Приклади**:
```sql
-- Згенерувати CREATE TABLE з SELECT
DECLARE @createScript NVARCHAR(MAX);
SET @createScript = util.stringGetCreateTempScript(
    'SELECT CustomerID, OrderDate, TotalAmount FROM Orders',
    '#OrdersSummary'
);
EXEC(@createScript);
```

#### stringSplitMultiLineComment

**Призначення**: Парсинг структурованих багаторядкових коментарів.

**Сигнатура**:
```sql
CREATE FUNCTION util.stringSplitMultiLineComment(
    @comment NVARCHAR(MAX)
)
RETURNS TABLE
```

**Приклади**:
```sql
-- Розпарсити коментар header
DECLARE @comment NVARCHAR(MAX) = '
# Description
Функція для...

# Parameters
@param1 - опис
';

SELECT Section, Content
FROM util.stringSplitMultiLineComment(@comment);
```

## Таблиці

### errorLog

**Призначення**: Централізоване логування помилок.

**Структура**:
```sql
CREATE TABLE util.errorLog (
    ErrorId INT IDENTITY(1,1) PRIMARY KEY,
    EventTime DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ErrorNumber INT,
    ErrorMessage NVARCHAR(MAX),
    ErrorProcedure NVARCHAR(128),
    ErrorLine INT,
    UserName NVARCHAR(128),
    HostName NVARCHAR(128)
);
```

### eventsNotifications

**Призначення**: Журнал DDL операцій.

**Використання**: Аудит змін структури БД

### executionModulesUsers, executionModulesSSIS

**Призначення**: Історія виконання модулів.

**Використання**: Аналіз продуктивності, профілювання

## Best Practices

1. **Використовуйте @objectId замість @object** де можливо для кращої продуктивності
2. **Обмежуйте результати** при запиті великих таблиць через TOP або WHERE
3. **Регулярно копіюйте XE дані** у таблиці для зменшення розміру файлів
4. **Створюйте індекси** на таблицях audit/monitoring для швидких запитів
5. **Тестуйте DDL скрипти** на dev середовищі перед production

## Наступні кроки

- [MCP адаптери](mcp.md) - Інтеграція з AI
- [Приклади використання](../examples.md)
- [FAQ](../faq.md)

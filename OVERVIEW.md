# Pure Utils - Detailed Comprehensive Overview

Комплексна бібліотека утилітарних функцій та процедур для SQL Server, розроблена для спрощення роботи з метаданими, моніторингу, аналізу продуктивності та автоматизації рутинних завдань DBA.

## ЗМІСТ

### Основні розділи
1. [DESCRIPTION & MS_DESCRIPTION](#description--ms_description) - 15 функцій/процедур
2. [OBJECTS & METADATA](#objects--metadata) - 25 функцій
3. [PARAMETERS](#parameters) - 6 функцій  
4. [COLUMNS](#columns) - 8 функцій
5. [STRING & TEXT PROCESSING](#string--text-processing) - 12 функцій
6. [SCRIPT GENERATION](#script-generation) - 8 функцій
7. [TEMP TABLES](#temp-tables) - 4 функції
8. [MODULES & CODE ANALYSIS](#modules--code-analysis) - 18 функцій
9. [ERROR HANDLING](#error-handling) - 2 функції/процедури + 1 таблиця
10. [EXTENDED EVENTS (XE)](#extended-events-xe) - 8 функцій/процедур
11. [EXTENDED PROPERTIES](#?extended-properties) - 12 процедур
12. [INDEXES](#indexes) - 10 функцій/процедур
13. [TABLES](#tables) - 4 функції
14. [LOGS & EVENTS](#logs--events) - 6 представлень + таблиці
15. [EXECUTION MONITORING](#execution-monitoring) - 8 функцій/представлень
16. [PERMISSIONS](#permissions) - 2 функції
17. [HISTORY](#history) - 3 функції

---

## DESCRIPTION & MS_DESCRIPTION

### Автоматичне витягнення описів з коментарів
**Функції для парсингу коментарів:**
- `modulesGetDescriptionFromComments` - витягує описи з багаторядкових коментарів
- `modulesGetDescriptionFromCommentsLegacy` - витягує описи зі старого формату коментарів
- `stringSplitMultiLineComment` - парсить структуровані коментарі

**Процедури для встановлення описів:**
- `modulesSetDescriptionFromComments` - автоматично встановлює описи з коментарів
- `modulesSetDescriptionFromCommentsLegacy` - для старого формату

### Ручне встановлення описів
**Процедури для різних типів об'єктів (12 штук):**
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

### Отримання описів
**Функції для читання:**
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

### Функції для створення тимчасових таблиць (4 функції)

**Inline функції (повертають TABLE):**
- `stringGetCreateTempScriptInline` - на основі SQL запиту
- `objectGetCreateTempScriptInline` - на основі об'єкта БД

**Scalar функції (повертають NVARCHAR(MAX)):**
- `stringGetCreateTempScript` - на основі SQL запиту  
- `objectGetCreateTempScript` - на основі об'єкта БД

### Приклади використання:
```sql
-- Inline функції
SELECT createScript FROM util.stringGetCreateTempScriptInline('SELECT * FROM dbo.Users', '#UsersCopy', NULL);
SELECT createScript FROM util.objectGetCreateTempScriptInline('dbo.GetUserStats', '#UserStats', NULL);

-- Scalar функції для виконання
DECLARE @script NVARCHAR(MAX) = util.stringGetCreateTempScript('SELECT ID, Name, Email FROM dbo.Users', '#ActiveUsers', NULL);
EXEC sp_executesql @script;
-- Тепер можна використовувати #ActiveUsers

DECLARE @procScript NVARCHAR(MAX) = util.objectGetCreateTempScript('dbo.GetUserData', '#UserData', NULL);  
EXEC sp_executesql @procScript;
INSERT INTO #UserData EXEC dbo.GetUserData @userId = 123;

-- Параметризовані запити
DECLARE @params NVARCHAR(MAX) = '@startDate DATETIME, @endDate DATETIME';
DECLARE @query NVARCHAR(MAX) = 'SELECT * FROM dbo.Orders WHERE OrderDate BETWEEN @startDate AND @endDate';
SELECT createScript FROM util.stringGetCreateTempScriptInline(@query, '#OrdersTemp', @params);
```

---

## MODULES & CODE ANALYSIS

### Функції для аналізу коду модулів (18 функцій)

**Розбиття та аналіз коду:**
- `modulesSplitToLines` - розбиття модулів на рядки
- `modulesGetCreateLineNumber` - номер рядка з CREATE

**Пошук коментарів:**
- `modulesFindCommentsPositions` - всі коментарі (inline + multiline)
- `modulesFindInlineCommentsPositions` - однорядкові коментарі (--)
- `modulesFindMultilineCommentsPositions` - багаторядкові коментарі (/* */)
- `modulesFindLinesPositions` - позиції всіх рядків

**Пошук входжень:**
- `modulesRecureSearchForOccurrences` - рекурсивний пошук входжень
- `modulesRecureSearchStartEndPositions` - пошук блоків початок/кінець
- `modulesRecureSearchStartEndPositionsExtended` - розширений пошук блоків

**Аналіз описів:**
- `modulesGetDescriptionFromComments` - витягання описів з коментарів
- `modulesGetDescriptionFromCommentsLegacy` - для старого формату

### Приклади використання:
```sql
-- Розбиття коду на рядки
SELECT * FROM util.modulesSplitToLines('dbo.MyProcedure', 1); -- без порожніх рядків
SELECT * FROM util.modulesSplitToLines(NULL, 1); -- всі модулі в БД

-- Знаходження CREATE
SELECT * FROM util.modulesGetCreateLineNumber(OBJECT_ID('dbo.MyProc'));
SELECT * FROM util.modulesGetCreateLineNumber(NULL); -- для всіх об'єктів

-- Аналіз коментарів
SELECT * FROM util.modulesFindCommentsPositions(OBJECT_ID('dbo.MyProc'));
SELECT * FROM util.modulesFindInlineCommentsPositions(NULL); -- всі однорядкові коментарі
SELECT * FROM util.modulesFindMultilineCommentsPositions(OBJECT_ID('dbo.MyProc'));

-- Пошук входжень
SELECT * FROM util.modulesRecureSearchForOccurrences('SELECT', 6); -- з опціями
SELECT * FROM util.modulesRecureSearchForOccurrences('util.', 2); -- пропускати перед крапкою

-- Пошук блоків коду
SELECT * FROM util.modulesRecureSearchStartEndPositions('BEGIN', 'END');
SELECT * FROM util.modulesRecureSearchStartEndPositions('TRY', 'CATCH');
SELECT * FROM util.modulesRecureSearchStartEndPositionsExtended('/*', '*/', 1, NULL); -- з нормалізацією CR/LF

-- Витягання описів з коментарів
SELECT * FROM util.modulesGetDescriptionFromComments(OBJECT_ID('util.errorHandler'));
SELECT * FROM util.modulesGetDescriptionFromComments(NULL); -- для всіх модулів
```

---

## ERROR HANDLING

### Компоненти системи обробки помилок
**Процедура:**
- `errorHandler` - універсальна обробка помилок

**Таблиця:**
- `errorLog` - журнал помилок з повною контекстною інформацією

**Функція:**
- `help` - довідкова система

### Структура таблиці errorLog:
```sql
-- Основна інформація про помилку
ErrorNumber INT, ErrorSeverity INT, ErrorState INT, ErrorMessage NVARCHAR(4000)
-- Контекстна інформація  
ErrorProcedure NVARCHAR(128), ErrorLine INT, ErrorLineText NVARCHAR(MAX)
-- Сесійна інформація
OriginalLogin NVARCHAR(128), SessionId SMALLINT, HostName NVARCHAR(128)
ProgramName NVARCHAR(128), DatabaseName NVARCHAR(128), UserName NVARCHAR(128)
-- Додткові дані
Attachment NVARCHAR(MAX), SessionInfo XML
```

### Приклади використання:
```sql
-- Стандартна обробка помилок
BEGIN TRY
    -- Небезпечний код
    EXEC dbo.SomeRiskyProcedure @param = 'value';
    DELETE FROM dbo.ImportantTable WHERE SomeCondition = 1;
END TRY  
BEGIN CATCH
    -- Детальне логування з контекстом
    EXEC util.errorHandler @attachment = 'Контекст: обробка замовлення #12345';
    
    -- Повторне викидання помилки якщо потрібно
    THROW;
END CATCH

-- Перегляд журналу помилок
SELECT TOP 10 * FROM util.errorLog ORDER BY ErrorDateTime DESC;

-- Аналіз помилок за період
SELECT 
    ErrorNumber,
    COUNT(*) as ErrorCount,
    MAX(ErrorDateTime) as LastOccurrence,
    ErrorMessage
FROM util.errorLog 
WHERE ErrorDateTime > DATEADD(day, -7, GETDATE())
GROUP BY ErrorNumber, ErrorMessage
ORDER BY ErrorCount DESC;

-- Довідка по системі
EXEC util.help; -- вся довідка
EXEC util.help 'metadata'; -- фільтрація за ключовим словом
```

---

## EXTENDED EVENTS (XE)

### Функції та процедури для XE (8 компонентів)

**Функції для читання XE:**
- `xeGetErrors` - отримання помилок з XE файлів
- `xeGetTargetFile` - інформація про поточний файл сесії  
- `xeGetLogsPath` - шлях до директорії логів XE

**Процедури для роботи з XE:**
- `xeCopyModulesToTable` - копіювання модулів з XE у таблиці

**Сесії XE:**
- `utilsErrors` - моніторинг помилок
- `utilsModulesUsers` - моніторинг виконання модулів користувачами
- `utilsModulesFaust` - моніторинг модулів Faust користувачів  
- `utilsModulesSSIS` - моніторинг SSIS пакетів

### Приклади використання:
```sql
-- Отримання помилок з XE
SELECT * FROM util.xeGetErrors(NULL); -- всі помилки
SELECT * FROM util.xeGetErrors(DATEADD(hour, -1, GETDATE())); -- за останню годину

-- Аналіз критичних помилок
SELECT EventTime, ErrorNumber, Severity, Message, DatabaseName, SqlText
FROM util.xeGetErrors(DATEADD(day, -1, GETDATE()))  
WHERE Severity >= 16
ORDER BY EventTime DESC;

-- Топ помилок за частотою
SELECT ErrorNumber, COUNT(*) as ErrorCount, MAX(EventTime) as LastOccurrence  
FROM util.xeGetErrors(DATEADD(day, -7, GETDATE()))
GROUP BY ErrorNumber
ORDER BY ErrorCount DESC;

-- Управління XE файлами
SELECT util.xeGetLogsPath('utilsErrors'); -- шлях до логів
SELECT * FROM util.xeGetTargetFile('utilsErrors'); -- поточний файл

-- Копіювання модулів з XE
EXEC util.xeCopyModulesToTable 'Users'; -- користувачі
EXEC util.xeCopyModulesToTable 'Faust'; -- Faust користувачі
EXEC util.xeCopyModulesToTable 'SSIS';  -- SSIS пакети
```

---

## EXTENDED PROPERTIES

### Процедури для управління розширеними властивостями (12 процедур)

**Універсальна процедура:**
- `metadataSetExtendedProperty` - встановлення будь-якої розширеної властивості

**Спеціалізовані процедури для MS_Description:**
- `metadataSetTableDescription` - таблиці
- `metadataSetColumnDescription` - колонки
- `metadataSetProcedureDescription` - процедури  
- `metadataSetFunctionDescription` - функції
- `metadataSetViewDescription` - представлення
- `metadataSetTriggerDescription` - тригери
- `metadataSetParameterDescription` - параметри
- `metadataSetIndexDescription` - індекси
- `metadataSetSchemaDescription` - схеми
- `metadataSetDataspaceDescription` - простори даних
- `metadataSetFilegroupDescription` - файлові групи

### Приклади використання:
```sql
-- Встановлення описів для різних об'єктів
EXEC util.metadataSetTableDescription @table = 'dbo.Users', @description = 'Таблиця користувачів системи';
EXEC util.metadataSetColumnDescription @object = 'dbo.Users', @column = 'Email', @description = 'Email адреса користувача';
EXEC util.metadataSetProcedureDescription @procedure = 'dbo.GetUserData', @description = 'Отримання даних користувача за ID';
EXEC util.metadataSetFunctionDescription @function = 'dbo.CalculateDiscount', @description = 'Розрахунок знижки клієнта';
EXEC util.metadataSetParameterDescription @major = 'dbo.GetUserData', @parameter = '@userId', @description = 'Унікальний ідентифікатор користувача';

-- Встановлення індивідуальних властивостей
EXEC util.metadataSetExtendedProperty 
    @name = 'Author', @value = 'John Doe',
    @level0type = 'SCHEMA', @level0name = 'dbo', 
    @level1type = 'TABLE', @level1name = 'Users';

EXEC util.metadataSetExtendedProperty
    @name = 'Version', @value = '2.1.0',
    @level0type = 'SCHEMA', @level0name = 'dbo',
    @level1type = 'PROCEDURE', @level1name = 'GetUserData';

-- Встановлення описів для інфраструктурних об'єктів
EXEC util.metadataSetSchemaDescription @schema = 'sales', @description = 'Схема для модулів продажів';
EXEC util.metadataSetFilegroupDescription @filegroup = 'SALES_DATA', @description = 'Файлова група для даних продажів';
```

---

## INDEXES

### Функції та процедури для роботи з індексами (10 компонентів)

**Аналіз індексів:**
- `indexesGetUnused` - невикористовувані індекси
- `indexesGetMissing` - відсутні індекси (рекомендації SQL Server)  
- `indexesGetSpaceUsed` - використання дискового простору (агреговане)
- `indexesGetSpaceUsedDetailed` - використання простору (по партиціях)

**Генерація скриптів:**
- `indexesGetScript` - DDL для створення індексів
- `indexesGetConventionNames` - рекомендовані назви за стандартами  
- `indexesGetScriptConventionRename` - скрипти перейменування

**Управління індексами:**
- `indexesSetConventionNames` - автоматичне перейменування індексів

**Моніторинг:**
- `myselfActiveIndexCreation` - відстеження прогресу створення індексів

### Приклади використання:
```sql
-- Аналіз проблемних індексів  
SELECT * FROM util.indexesGetUnused('dbo.Orders'); -- невикористовувані
SELECT * FROM util.indexesGetMissing('dbo.Orders') ORDER BY IndexAdvantage DESC; -- відсутні

-- Аналіз використання простору
SELECT * FROM util.indexesGetSpaceUsed('dbo.Orders'); -- загальна статистика
SELECT * FROM util.indexesGetSpaceUsedDetailed('dbo.Orders'); -- по партиціях

-- Топ найбільших індексів в БД
SELECT TOP 10 SchemaName, TableName, IndexName, TotalSizeMB  
FROM util.indexesGetSpaceUsed(NULL)
ORDER BY TotalSizeMB DESC;

-- Генерація DDL скриптів
SELECT * FROM util.indexesGetScript('dbo.Orders', NULL); -- всі індекси таблиці
SELECT createScript FROM util.indexesGetScript('dbo.Orders', 'IX_Orders_CustomerID');

-- Конвенції найменування
SELECT * FROM util.indexesGetConventionNames('dbo.Orders', NULL); -- рекомендації
SELECT * FROM util.indexesGetScriptConventionRename('dbo.Orders', NULL); -- скрипти перейменування

-- Автоматичне перейменування
EXEC util.indexesSetConventionNames @table = 'dbo.Orders', @output = 1; -- показати скрипти
EXEC util.indexesSetConventionNames @table = 'dbo.Orders', @output = 8; -- виконати перейменування

-- Моніторинг створення індексів  
SELECT * FROM util.myselfActiveIndexCreation(); -- поточний прогрес
```

---

## TABLES

### Функції для роботи з таблицями (4 функції)

**Аналіз структури:**
- `tablesGetScript` - повний DDL скрипт таблиці
- `tablesGetIndexedColumns` - аналіз індексованих колонок

**Інфраструктурні:**
- `metadataGetIndexes` - інформація про індекси таблиць

### Приклади використання:
```sql
-- Повний DDL таблиці
SELECT createScript FROM util.tablesGetScript('dbo.Orders');
SELECT * FROM util.tablesGetScript(NULL); -- всі таблиці

-- Аналіз індексованих колонок  
SELECT * FROM util.tablesGetIndexedColumns('dbo.Orders');
-- Показує: ColumnName, IndexName, KeyOrdinal, IsIncludedColumn, IsUnique, IsPrimaryKey

-- Колонки які є першими в індексах
SELECT DISTINCT SchemaName, TableName, ColumnName
FROM util.tablesGetIndexedColumns('dbo.Orders')  
WHERE KeyOrdinal = 1;

-- Статистика покриття колонок індексами
SELECT SchemaName, TableName, ColumnName, COUNT(*) as IndexCount
FROM util.tablesGetIndexedColumns('dbo.Orders')
GROUP BY SchemaName, TableName, ColumnName
ORDER BY IndexCount DESC;

-- Інформація про індекси
SELECT * FROM util.metadataGetIndexes('dbo.Orders');
SELECT * FROM util.metadataGetIndexes(NULL); -- всі індекси в БД
```

---

## LOGS & EVENTS

### Таблиці для зберігання логів (6 таблиць)

**Журнали помилок:**
- `errorLog` - централізований журнал помилок з повним контекстом

**Журнали виконання модулів:**
- `executionModulesFaust` - логи виконання модулів (Faust користувачі)
- `executionModulesUsers` - логи виконання модулів (звичайні користувачі)  
- `executionModulesSSIS` - логи виконання SSIS пакетів
- `executionSqlText` - кеш SQL текстів з хешуванням

**Інфраструктурні:**
- `xeOffsets` - позиції читання XE файлів для продовження обробки

### Представлення для доступу до даних (3 представлення)

**Представлення з приєднаними SQL текстами:**
- `viewExecutionModulesFaust` - виконання модулів Faust з SQL кодом
- `viewExecutionModulesUsers` - виконання модулів користувачів з SQL кодом
- `viewExecutionModulesSSIS` - виконання SSIS з SQL кодом

### Приклади використання:
```sql
-- Аналіз помилок
SELECT TOP 20 ErrorDateTime, ErrorNumber, ErrorMessage, ErrorProcedure, HostName  
FROM util.errorLog 
ORDER BY ErrorDateTime DESC;

-- Топ помилок за частотою
SELECT ErrorNumber, COUNT(*) as Count, MAX(ErrorDateTime) as LastSeen
FROM util.errorLog
WHERE ErrorDateTime > DATEADD(day, -30, GETDATE())
GROUP BY ErrorNumber  
ORDER BY Count DESC;

-- Моніторинг виконання модулів
SELECT TOP 100 EventTime, ObjectName, Duration, ClientHostname, ServerPrincipalName
FROM util.viewExecutionModulesUsers
WHERE EventTime > DATEADD(hour, -1, GETDATE())
ORDER BY Duration DESC;

-- Повільні процедури за останню добу  
SELECT 
    ObjectName,
    COUNT(*) as ExecutionCount,
    AVG(Duration) as AvgDurationMs,
    MAX(Duration) as MaxDurationMs,
    MIN(Duration) as MinDurationMs
FROM util.viewExecutionModulesUsers
WHERE EventTime > DATEADD(day, -1, GETDATE())
    AND Duration > 1000000 -- > 1 сек
GROUP BY ObjectName
ORDER BY AvgDurationMs DESC;

-- Аналіз SSIS пакетів
SELECT ObjectName, COUNT(*) as RunCount, AVG(Duration) as AvgDuration
FROM util.viewExecutionModulesSSIS
WHERE EventTime > DATEADD(day, -7, GETDATE())
GROUP BY ObjectName
ORDER BY RunCount DESC;
```

---

## EXECUTION MONITORING

### Функції та представлення для моніторингу (8 компонентів)

**Представлення для аналізу виконання:**
- `viewExecutionModulesFaust` - виконання модулів (Faust користувачі)
- `viewExecutionModulesUsers` - виконання модулів (звичайні користувачі)
- `viewExecutionModulesSSIS` - виконання SSIS пакетів

**Функції моніторингу:**
- `myselfActiveIndexCreation` - прогрес створення індексів
- `executionGetModulesFaust` - отримання модулів Faust

**Таблиці логування:**
- `executionModulesFaust`, `executionModulesUsers`, `executionModulesSSIS`
- `executionSqlText` - кеш SQL текстів

### Приклади використання:
```sql
-- Моніторинг поточної активності
SELECT * FROM util.myselfActiveIndexCreation(); -- прогрес створення індексів

-- Топ повільних процедур за добу
SELECT 
    ObjectName,
    COUNT(*) as ExecutionCount,
    AVG(Duration) as AvgDurationMs,
    MAX(Duration) as MaxDurationMs,
    MIN(Duration) as MinDurationMs
FROM util.viewExecutionModulesUsers
WHERE EventTime > DATEADD(day, -1, GETDATE())
GROUP BY ObjectName
HAVING COUNT(*) > 1
ORDER BY AvgDurationMs DESC;

-- Аналіз активності по користувачах
SELECT 
    ServerPrincipalName,
    ClientHostname, 
    COUNT(*) as ExecutionCount,
    COUNT(DISTINCT ObjectName) as UniqueObjects,
    AVG(Duration) as AvgDuration
FROM util.viewExecutionModulesFaust  
WHERE EventTime > DATEADD(day, -1, GETDATE())
GROUP BY ServerPrincipalName, ClientHostname
ORDER BY ExecutionCount DESC;

-- Моніторинг SSIS пакетів
SELECT 
    ObjectName,
    COUNT(*) as RunCount,
    AVG(Duration) as AvgDuration,
    MAX(EventTime) as LastRun,
    COUNT(CASE WHEN Duration > 300000000 THEN 1 END) as LongRunsCount -- > 30 сек
FROM util.viewExecutionModulesSSIS
WHERE EventTime > DATEADD(day, -7, GETDATE())
GROUP BY ObjectName
ORDER BY LongRunsCount DESC, AvgDuration DESC;

-- Аналіз SQL текстів
SELECT 
    LEFT(sqlText, 100) as SqlPreview,
    COUNT(*) as UsageCount
FROM util.executionSqlText est
JOIN util.executionModulesUsers emu ON est.sqlHash = emu.SqlTextHash
WHERE emu.EventTime > DATEADD(day, -1, GETDATE())
GROUP BY est.sqlHash, LEFT(sqlText, 100)
ORDER BY UsageCount DESC;
```

---

## PERMISSIONS

### Функції для аналізу прав доступу (2 функції)

**Аналіз залежностей:**
- `metadataGetRequiredPermission` - визначення потрібних прав для об'єкта

### Приклади використання:
```sql
-- Аналіз прав доступу для процедури
SELECT * FROM util.metadataGetRequiredPermission('dbo.ComplexProcedure');
-- Показує об'єкти які потребують додаткових прав:
-- - з інших БД (завжди потребують прав)  
-- - з різними власниками схем

-- Групування по причинам
SELECT 
    PermissionReason,
    COUNT(*) as ObjectCount,
    STRING_AGG(ObjectName, '; ') as Objects
FROM util.metadataGetRequiredPermission('dbo.ComplexProcedure')
GROUP BY PermissionReason;

-- Аналіз всіх процедур схеми на права
SELECT 
    o.name as ProcedureName,
    perm.ObjectName,
    perm.PermissionReason  
FROM sys.objects o
CROSS APPLY util.metadataGetRequiredPermission(SCHEMA_NAME(o.schema_id) + '.' + o.name) perm
WHERE o.schema_id = SCHEMA_ID('dbo') AND o.type = 'P'
ORDER BY o.name, perm.PermissionReason;
```

---

## HISTORY  

### Функції для отримання історії (3 функції)

**Історія користувача:**
- `myselfGetHistory` - історія подій для поточного користувача

**Історія об'єктів:**  
- `objectGetHistory` - історія змін конкретного об'єкта

### Приклади використання:
```sql
-- Історія поточного користувача
SELECT * FROM util.myselfGetHistory(NULL); -- вся історія
SELECT * FROM util.myselfGetHistory(DATEADD(day, -7, GETDATE())); -- за тиждень

-- Історія конкретного об'єкта  
SELECT * FROM util.objectGetHistory('dbo.Users', NULL); -- вся історія таблиці
SELECT * FROM util.objectGetHistory('dbo.Users', DATEADD(day, -1, GETDATE())); -- за добу

-- Аналіз активності за період
SELECT 
    eventType,
    COUNT(*) as EventCount,
    COUNT(DISTINCT objectName) as UniqueObjects,
    MIN(postTime) as FirstEvent,
    MAX(postTime) as LastEvent
FROM util.myselfGetHistory(DATEADD(week, -1, GETDATE()))
GROUP BY eventType
ORDER BY EventCount DESC;

-- Топ найактивніших об'єктів
SELECT 
    objectName,
    objectType, 
    COUNT(*) as ChangeCount,
    MAX(postTime) as LastChange
FROM util.myselfGetHistory(DATEADD(month, -1, GETDATE()))
WHERE objectName IS NOT NULL
GROUP BY objectName, objectType  
ORDER BY ChangeCount DESC;

-- DDL зміни за період
SELECT postTime, eventType, objectName, objectType, tsql_command
FROM util.objectGetHistory('dbo.ImportantTable', DATEADD(month, -1, GETDATE()))  
WHERE eventType LIKE '%DDL%'
ORDER BY postTime DESC;
```

---

## PRACTICAL SCENARIOS

### Комплексний аудит таблиці
```sql
DECLARE @tableName NVARCHAR(128) = 'dbo.Orders';

-- 1. Основна інформація
SELECT 'Колонки таблиці' as Section;
SELECT * FROM util.metadataGetColumns(@tableName);

SELECT 'Індекси таблиці' as Section;  
SELECT * FROM util.metadataGetIndexes(@tableName);

-- 2. Аналіз продуктивності індексів
SELECT 'Використання дискового простору' as Section;
SELECT * FROM util.indexesGetSpaceUsed(@tableName);

SELECT 'Невикористовувані індекси' as Section;
SELECT * FROM util.indexesGetUnused(@tableName);

SELECT 'Рекомендовані індекси' as Section; 
SELECT * FROM util.indexesGetMissing(@tableName) ORDER BY IndexAdvantage DESC;

-- 3. Історія змін
SELECT 'Історія змін за місяць' as Section;
SELECT * FROM util.objectGetHistory(@tableName, DATEADD(month, -1, GETDATE()));

-- 4. Генерація скриптів
SELECT 'DDL таблиці' as Section;
SELECT createScript FROM util.tablesGetScript(@tableName);
```

### Моніторинг продуктивності системи
```sql
-- Топ повільних процедур за добу
SELECT 'Повільні процедури' as Section;
SELECT TOP 10
    ObjectName,
    COUNT(*) as ExecutionCount,
    AVG(Duration) as AvgDurationMs,
    MAX(Duration) as MaxDurationMs,
    MIN(Duration) as MinDurationMs
FROM util.viewExecutionModulesUsers  
WHERE EventTime > DATEADD(day, -1, GETDATE())
    AND Duration > 1000000 -- > 1 сек
GROUP BY ObjectName
ORDER BY AvgDurationMs DESC;

-- Аналіз помилок за тиждень  
SELECT 'Топ помилок' as Section;
SELECT 
    ErrorNumber,
    COUNT(*) as ErrorCount, 
    ErrorMessage,
    MAX(ErrorDateTime) as LastOccurrence
FROM util.errorLog
WHERE ErrorDateTime > DATEADD(week, -1, GETDATE())
GROUP BY ErrorNumber, ErrorMessage
ORDER BY ErrorCount DESC;

-- Активні сесії створення індексів
SELECT 'Прогрес створення індексів' as Section;
SELECT * FROM util.myselfActiveIndexCreation();
```

### Автоматизація документування
```sql
-- Встановлення описів для всіх об'єктів схеми dbo
DECLARE @sql NVARCHAR(MAX) = N'';

-- Генерація команд для автоматичного встановлення описів
SELECT @sql = @sql + 
    'EXEC util.modulesSetDescriptionFromComments ''' + 
    QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) + ''';' + CHAR(10)
FROM sys.objects 
WHERE type IN ('P', 'FN', 'IF', 'TF', 'TR', 'V')
    AND schema_id = SCHEMA_ID('dbo')
    AND name NOT LIKE 'sp_%'  
ORDER BY type, name;

PRINT @sql;  
-- EXEC sp_executesql @sql; -- розкоментувати для виконання
```

---

## SUMMARY BY NUMBERS

### Статистика компонентів системи:
- **Функції**: 65+ функцій
- **Процедури**: 20+ процедур  
- **Таблиці**: 6 таблиць для логування
- **Представлення**: 4 представлення
- **XE Сесії**: 4 сесії моніторингу

### Розподіл за категоріями:
- **Metadata & Objects**: 25 функцій
- **Modules & Code Analysis**: 18 функцій  
- **Description & Properties**: 15 функцій/процедур
- **Indexes & Performance**: 10 функцій/процедур
- **String & Text Processing**: 12 функцій
- **Extended Events**: 8 компонентів
- **Script Generation**: 8 функцій
- **Execution Monitoring**: 8 компонентів
- **Columns & Parameters**: 14 функцій
- **Temp Tables**: 4 функції

Pure Utils - це потужна екосистема, що покриває всі аспекти роботи DBA: від базового управління метаданими до продвинутого моніторингу продуктивності та автоматизації рутинних завдань. Система розроблена з урахуванням best practices SQL Server та надає інструменти для ефективного управління enterprise-рівня базами даних.
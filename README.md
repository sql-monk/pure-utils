# Utils - SQL Server Database Utilities

Набір функцій та процедур для SQL Server адміністрування, моніторингу та розробки.

## Зміст

- [Error - Обробка помилок](#error---обробка-помилок)
- [Description - Робота з описами](#description---робота-з-описами)
- [Myself - Саморефлексія системи](#myself---саморефлексія-системи)
- [History - Історія змін](#history---історія-змін)
- [Script - Генерація скриптів](#script---генерація-скриптів)
- [Table - Робота з таблицями](#table---робота-з-таблицями)
- [Index - Управління індексами](#index---управління-індексами)
- [Metadata - Метадані об'єктів](#metadata---метадані-обєктів)
- [Column - Робота з колонками](#column---робота-з-колонками)
- [ExtendedProperty - Розширені властивості](#extendedproperty---розширені-властивості)
- [Object - Робота з об'єктами](#object---робота-з-обєктами)
- [Parameter - Параметри функцій](#parameter---параметри-функцій)
- [Function - Системні функції](#function---системні-функції)
- [Permission - Дозволи та безпека](#permission---дозволи-та-безпека)
- [Comment - Аналіз коментарів](#comment---аналіз-коментарів)
- [Modules - Робота з модулями](#modules---робота-з-модулями)
- [XE - Extended Events](#xe---extended-events)

## Error - Обробка помилок

### Функції та процедури:
- `util.errorHandler` - централізована обробка помилок з логуванням
- `util.errorLog` - таблиця для збереження деталей помилок

### Використання:
```sql
-- Обробка помилки в блоці TRY/CATCH
BEGIN TRY
    -- Ваш код
    SELECT 1/0; -- Помилка ділення на нуль
END TRY
BEGIN CATCH
    EXEC util.errorHandler @attachment = 'Контекст: тестування ділення';
END CATCH

-- Переглянути всі помилки
SELECT * FROM util.errorLog ORDER BY ErrorDateTime DESC;
```

## Description - Робота з описами

### Функції та процедури:
- `util.modulesGetDescriptionFromComments` - витягування описів з коментарів
- `util.modulesSetDescriptionFromComments` - автоматичне встановлення описів
- `util.modulesGetDescriptionFromCommentsLegacy` - підтримка legacy формату

### Використання:
```sql
-- Витягти опис з коментарів конкретної функції
SELECT * FROM util.modulesGetDescriptionFromComments('util.xeGetErrors');

-- Автоматично встановити описи для всіх об'єктів
EXEC util.modulesSetDescriptionFromComments;

-- Встановити опис для конкретного об'єкта
EXEC util.modulesSetDescriptionFromComments 'util.errorHandler';
```

## Myself - Саморефлексія системи

### Функції:
- `util.myselfActiveIndexCreation` - моніторинг активних операцій створення індексів
- `util.myselfGetHistory` - історія виконання операцій

### Використання:
```sql
-- Переглянути активні операції створення індексів
SELECT * FROM util.myselfActiveIndexCreation();

-- Отримати історію виконання
SELECT * FROM util.myselfGetHistory();
```

## History - Історія змін

### Функції:
- `util.objectGetHistory` - історія змін об'єктів бази даних

### Використання:

```sql
-- Отримати історію змін конкретного об'єкта
SELECT * FROM util.objectGetHistory('myTable');

-- Переглянути всі зміни за останній тиждень
SELECT * FROM util.objectGetHistory(NULL) 
WHERE ChangeDate >= DATEADD(week, -1, GETDATE());
```

## Script - Генерація скриптів

### Функції:
- `util.tablesGetScript` - генерація DDL скриптів таблиць
- `util.indexesGetScript` - скрипти створення індексів
- `util.indexesGetScriptConventionRename` - скрипти перейменування за конвенціями
- `util.indexesGetConventionNames` - отримання стандартних назв індексів

### Використання:
```sql
-- Згенерувати скрипт створення таблиці
SELECT * FROM util.tablesGetScript('myTable');

-- Отримати скрипти для всіх індексів таблиці
SELECT * FROM util.indexesGetScript('myTable');

-- Згенерувати скрипти перейменування індексів за конвенціями
SELECT * FROM util.indexesGetScriptConventionRename('myTable');
```

## Table - Робота з таблицями

### Функції:
- `util.tablesGetScript` - генерація DDL скриптів таблиць
- `util.tablesGetIndexedColumns` - аналіз індексованих колонок

### Використання:
```sql
-- Переглянути індексовані колонки таблиці
SELECT * FROM util.tablesGetIndexedColumns('myTable');

-- Отримати перші колонки всіх індексів
SELECT * FROM util.tablesGetIndexedColumns(NULL);
```

## Index - Управління індексами

### Функції та процедури:
- `util.indexesGetUnused` - виявлення невикористовуваних індексів
- `util.indexesGetSpaceUsed` - аналіз використання простору індексами
- `util.indexesGetSpaceUsedDetailed` - детальний аналіз простору по партиціях
- `util.indexesGetMissing` - рекомендації відсутніх індексів
- `util.indexesGetScript` - генерація DDL скриптів індексів
- `util.indexesGetConventionNames` - стандартні назви індексів
- `util.indexesGetScriptConventionRename` - скрипти перейменування
- `util.indexesSetConventionNames` - процедура перейменування індексів

### Використання:
```sql
-- Знайти невикористовувані індекси
SELECT * FROM util.indexesGetUnused();

-- Проаналізувати використання простору індексами
SELECT * FROM util.indexesGetSpaceUsed('myTable');

-- Детальний аналіз по партиціях
SELECT * FROM util.indexesGetSpaceUsedDetailed('myTable') ORDER BY TotalSpaceMB DESC;

-- Отримати рекомендації відсутніх індексів
SELECT * FROM util.indexesGetMissing('myTable') 
WHERE IndexAdvantage > 1000 ORDER BY IndexAdvantage DESC;

-- Перейменувати індекси за конвенціями
EXEC util.indexesSetConventionNames @table = 'myTable', @output = 1;
```

## Metadata - Метадані об'єктів

### Функції:
- `util.metadataGetAnyId`, `util.metadataGetAnyName` - універсальні функції пошуку
- `util.metadataGetColumns`, `util.metadataGetColumnId`, `util.metadataGetColumnName` - робота з колонками
- `util.metadataGetIndexes`, `util.metadataGetIndexId`, `util.metadataGetIndexName` - управління індексами
- `util.metadataGetParameters`, `util.metadataGetParameterId`, `util.metadataGetParameterName` - параметри функцій
- `util.metadataGetDataspaceId`, `util.metadataGetDataspaceName` - простори даних
- `util.metadataGetObjectType`, `util.metadataGetObjectsType` - типи об'єктів
- `util.metadataGetCertificateName` - сертифікати
- `util.metadataGetClassByName`, `util.metadataGetClassName` - класи об'єктів
- `util.metadataGetPartitionFunctionId`, `util.metadataGetPartitionFunctionName` - функції розділення
- `util.metadataGetDescriptions`, `util.metadataGetExtendedProperiesValues` - описи та властивості
- `util.metadataGetRequiredPermission` - аналіз необхідних дозволів

### Використання:
```sql
-- Отримати ID об'єкта за назвою
SELECT util.metadataGetAnyId('myTable', 1, NULL, NULL);

-- Отримати назву об'єкта за ID
SELECT util.metadataGetAnyName(OBJECT_ID('myTable'), 1, NULL);

-- Переглянути всі колонки таблиці
SELECT * FROM util.metadataGetColumns('myTable');

-- Отримати всі індекси об'єкта
SELECT * FROM util.metadataGetIndexes('myTable');

-- Знайти ID колонки
SELECT util.metadataGetColumnId('myTable', 'myColumn');
```

## Column - Робота з колонками

### Процедури:
- `util.metadataSetColumnDescription` - встановлення описів колонок

```sql
EXEC util.metadataSetColumnDescription 
    @object = 'myTable', 
    @column = 'myColumn', 
    @description = 'Опис важливої колонки';

SELECT util.metadataGetColumnName('myTable', 1);
```

## ExtendedProperty - Розширені властивості

### Функції та процедури:
- `util.metadataSetExtendedProperty` - встановлення розширених властивостей
- `util.metadataGetExtendedProperiesValues` - отримання значень властивостей
- `util.metadataSetColumnDescription`, `util.metadataSetTableDescription`, `util.metadataSetIndexDescription` та інші - спеціалізовані процедури

```sql
EXEC util.metadataSetExtendedProperty 
    @name = 'MS_Description',
    @value = 'Важлива таблиця для системи',
    @level0type = 'SCHEMA',
    @level0name = 'dbo',
    @level1type = 'TABLE',
    @level1name = 'myTable';

SELECT * FROM util.metadataGetExtendedProperiesValues();
```

## Object - Робота з об'єктами

### Функції:
- `util.metadataGetObjectType` - отримання типів об'єктів
- `util.objectGetHistory` - історія змін об'єктів

```sql
SELECT util.metadataGetObjectType(OBJECT_ID('myTable'));
SELECT * FROM util.objectGetHistory('myTable');
```

## Parameter - Параметри функцій

### Функції та процедури:
- `util.metadataGetParameters` - отримання списку параметрів
- `util.metadataGetParameterId`, `util.metadataGetParameterName` - пошук параметрів
- `util.metadataSetParameterDescription` - встановлення описів параметрів

```sql
SELECT * FROM util.metadataGetParameters('util.errorHandler');
SELECT util.metadataGetParameterName('util.errorHandler', 1);

EXEC util.metadataSetParameterDescription 
    @object = 'util.errorHandler',
    @parameter = '@attachment',
    @description = 'Додаткова інформація для логування';
```

## Function - Системні функції

### Процедури:
- `util.metadataSetFunctionDescription` - управління описами функцій

```sql
EXEC util.metadataSetFunctionDescription 
    @function = 'util.xeGetErrors',
    @description = 'Функція для отримання помилок з Extended Events';
```

## Permission - Дозволи та безпека

### Функції:
- `util.metadataGetRequiredPermission` - аналіз необхідних дозволів та cross-database залежностей

```sql
SELECT * FROM util.metadataGetRequiredPermission('myView');
SELECT * FROM util.metadataGetRequiredPermission(NULL) WHERE CrossDatabase = 1;
```

## Comment - Аналіз коментарів

### Функції:
- `util.modulesFindCommentsPositions` - пошук всіх коментарів
- `util.modulesFindMultilineCommentsPositions` - багаторядкові коментарі
- `util.modulesFindInlineCommentsPositions` - однорядкові коментарі

```sql
SELECT * FROM util.modulesFindCommentsPositions(OBJECT_ID('myProc'));
SELECT * FROM util.modulesFindMultilineCommentsPositions(NULL);
SELECT * FROM util.modulesFindInlineCommentsPositions(OBJECT_ID('util.errorHandler'));
```

## Modules - Робота з модулями

### Функції:
- `util.modulesSplitToLines` - розділення на рядки
- `util.modulesRecureSearchForOccurrences` - рекурсивний пошук
- `util.modulesRecureSearchStartEndPositions` - пошук позицій блоків
- `util.modulesRecureSearchStartEndPositionsExtended` - розширений пошук
- `util.modulesFindLinesPositions` - пошук позицій рядків
- `util.modulesGetCreateLineNumber` - номер рядка CREATE
- `util.modulesGetDescriptionFromComments` - витягування описів з коментарів
- `util.stringSplitMultiLineComment` - розділення багаторядкових коментарів

```sql
SELECT * FROM util.modulesSplitToLines('util.errorHandler', DEFAULT);
SELECT * FROM util.modulesRecureSearchForOccurrences('ERROR_NUMBER', 0);
SELECT * FROM util.modulesRecureSearchStartEndPositions('BEGIN', 'END');
SELECT * FROM util.modulesFindLinesPositions(OBJECT_ID('util.errorHandler'));
```

## XE - Extended Events

### Функції:
- `util.xeGetErrors` - відстеження помилок на рівні сервера

```sql
-- Всі помилки
SELECT * FROM util.xeGetErrors(NULL) ORDER BY EventTime DESC;

-- Помилки за останню годину
SELECT * FROM util.xeGetErrors(DATEADD(hour, -1, GETDATE())) WHERE Severity >= 16;

-- Статистика помилок
SELECT ErrorNumber, COUNT(*) as ErrorCount, MAX(EventTime) as LastOccurrence
FROM util.xeGetErrors(DATEADD(day, -7, GETDATE()))
GROUP BY ErrorNumber ORDER BY ErrorCount DESC;
```

## Встановлення

```sql
-- Створити схему
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'util')
    EXEC('CREATE SCHEMA util');
```

Виконати скрипти у порядку: Tables/ → Functions/ → Procedures/
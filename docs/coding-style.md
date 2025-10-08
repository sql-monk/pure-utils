# Стиль коду та конвенції найменування

## Огляд

pure-utils дотримується чітких конвенцій найменування та стилю коду для забезпечення консистентності, читабельності та підтримуваності. Цей документ описує всі стандарти, які слід дотримуватись при додаванні нового коду.

## Мова

- **Документація**: Українська мова (коментарі, описи)
- **Код**: Англійська мова (назви змінних, функцій, колонок)

## Конвенції найменування

### Функції (Functions)

**Паттерн**: `{category}{Action}{Entity}`

**Приклади**:
```sql
-- Категорія metadata
metadataGetAnyId
metadataGetAnyName
metadataGetCertificateName
metadataGetColumnId
metadataGetColumnName
metadataGetObjectName

-- Категорія indexes
indexesGetConventionNames
indexesGetScript
indexesGetMissing
indexesGetUnused
indexesGetSpaceUsed

-- Категорія modules
modulesRecureSearchForOccurrences
modulesFindCommentsPositions
modulesSplitToLines

-- Категорія xe (Extended Events)
xeGetErrors
xeGetDebug
xeGetModules
xeGetLogsPath
```

**Категорії**:
- `metadata` - робота з метаданими
- `indexes` - робота з індексами
- `modules` - робота з SQL кодом
- `tables` - робота з таблицями
- `string` - робота з рядками
- `xe` - Extended Events
- `jobs` - SQL Agent jobs
- `partition` - партиціювання
- `mcp` - MCP інтеграція

### Процедури (Procedures)

**Паттерн для SET операцій**: `{entity}Set{Property}`

**Приклади**:
```sql
metadataSetColumnDescription
metadataSetFunctionDescription
metadataSetProcedureDescription
metadataSetTableDescription
indexesSetConventionNames
```

**Спеціальні процедури**:
```sql
errorHandler           -- обробка помилок
help                   -- довідка
xeCopyModulesToTable   -- копіювання XE даних
objesctsScriptWithDependencies  -- генерація скриптів
```

### Параметри

**Стандартні назви**:
```sql
@object NVARCHAR(128) = NULL     -- для об'єктів (може бути назва або ID)
@objectId INT = NULL             -- для ID об'єктів
@index NVARCHAR(128) = NULL      -- для індексів
@table NVARCHAR(128) = NULL      -- для таблиць
@schema NVARCHAR(128) = NULL     -- для схем
@database NVARCHAR(128) = NULL   -- для баз даних
@column NVARCHAR(128) = NULL     -- для колонок
```

**Boolean параметри**:
```sql
@skipEmpty BIT = 1
@replaceCRwithLF BIT = 1
@includeReferences BIT = 1
```

### Змінні

**CamelCase**:
```sql
@schemaName NVARCHAR(128)
@functionName NVARCHAR(128)
@procedureName NVARCHAR(128)
@indexName NVARCHAR(128)
@currentValue SQL_VARIANT
```

### Колонки у результатах

**CamelCase** (без AS):
```sql
SELECT 
    c.object_id objectId,
    OBJECT_SCHEMA_NAME(c.object_id) schemaName,
    OBJECT_NAME(c.object_id) objectName,
    c.column_id columnId,
    c.name columnName
```

### Назви індексів (Convention Names)

**Primary Key**:
```sql
PK_{TableName}_{KeyColumns}
-- Приклад: PK_Orders_OrderId
```

**Clustered Index**:
```sql
CI_{TableName}_{KeyColumns}
-- Приклад: CI_Orders_OrderDate_OrderId
```

**Non-clustered Index**:
```sql
IX_{TableName}_{KeyColumns}[_INC][_FLT][_UQ][_P]
-- Приклади:
-- IX_Orders_CustomerId
-- IX_Orders_OrderDate_INC  (має included колонки)
-- IX_Orders_Status_FLT     (має filter)
-- IX_Orders_OrderId_UQ     (unique)
```

**Суфікси**:
- `_INC` - має included колонки
- `_FLT` - має filter
- `_UQ` - unique
- `_P` - partitioned
- `_D` - descending sort (в назві колонки)

**Columnstore**:
```sql
CCSI              -- Clustered Columnstore Index
CS_{KeyColumns}   -- Nonclustered Columnstore
```

## Структура коду

### Блочні коментарі (Header)

**Обов'язкові секції**:
```sql
/*
# Description
Детальний опис функціональності українською мовою.
Може бути багаторядковим.

# Parameters
@param1 TYPE = DEFAULT - опис параметра українською
@param2 TYPE - опис параметра

# Returns  
Опис того що повертається (TABLE structure, scalar type, тощо)

# Usage
-- Приклад використання
SELECT * FROM util.functionName('value');

-- Ще один приклад
SELECT * FROM util.functionName(DEFAULT) WHERE condition;
*/
```

**Опціональні секції**:
```sql
/*
...

# Notes
Додаткові примітки, обмеження, передумови

# Examples
-- Детальні приклади

# See Also
util.relatedFunction, util.anotherFunction
*/
```

### CREATE statements

**Inline Table Functions**:
```sql
CREATE OR ALTER FUNCTION util.functionName(@param TYPE = NULL)
RETURNS TABLE
AS
RETURN(
    SELECT ... 
    FROM ...
    WHERE ...
);
GO
```

**Scalar Functions**:
```sql
CREATE OR ALTER FUNCTION util.functionName(@param TYPE)
RETURNS TYPE
AS
BEGIN
    RETURN (SELECT ... FROM ... WHERE ...);
END;
GO
```

**Procedures**:
```sql
CREATE OR ALTER PROCEDURE util.procedureName
    @param TYPE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- код тут
END;
GO
```

### Параметри з DEFAULT значеннями

```sql
@object NVARCHAR(128) = NULL
@skipEmpty BIT = 1  
@replaceCRwithLF BIT = 1
@output TINYINT = 1
@maxDepth INT = 10
```

## Стилістичні паттерни

### Процедури - стандартні налаштування

```sql
CREATE OR ALTER PROCEDURE util.procedureName
AS
BEGIN
    SET NOCOUNT ON;                              -- завжди в процедурах
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  -- якщо потрібно
    
    -- код
END;
```

### Декларації змінних

**З ініціалізацією**:
```sql
DECLARE @ErrorNumber INT = ERROR_NUMBER();
DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
DECLARE @count INT = 0;
```

**Без ініціалізації**:
```sql
DECLARE @currentValue SQL_VARIANT;
DECLARE @result NVARCHAR(MAX);
```

### CTE (Common Table Expressions)

**Послідовна структура**:
```sql
WITH cteRn AS (
    SELECT 
        column1,
        ROW_NUMBER() OVER (ORDER BY column1) rn
    FROM table1
),
cteFiltered AS (
    SELECT * 
    FROM cteRn 
    WHERE rn = 1
)
SELECT * FROM cteFiltered;
```

**Іменування CTE**: camelCase з префіксом `cte`
```sql
WITH cteIndexes AS (...),
     cteColumns AS (...),
     cteResult AS (...)
```

### Паттерни умов та фільтрації

**Універсальний об'єкт (ID або назва)**:
```sql
WHERE (@object IS NULL 
    OR column = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
```

**Опціональний фільтр**:
```sql
WHERE (@index IS NULL OR i.name = @index)
WHERE (@columnId IS NULL OR c.column_id = @columnId)
WHERE (@database IS NULL OR db.name = @database)
```

**Конвертація з безпекою**:
```sql
ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object))
TRY_CAST(@value AS INT)
```

### Системні каталоги

**Використовуйте (NOLOCK)**:
```sql
FROM sys.indexes i (NOLOCK)
    INNER JOIN sys.tables t (NOLOCK) ON i.object_id = t.object_id
    LEFT JOIN sys.data_spaces ds (NOLOCK) ON i.data_space_id = ds.data_space_id
    LEFT JOIN sys.key_constraints kc (NOLOCK) ON i.object_id = kc.parent_object_id
```

**Alias patterns**:

Короткі (рекомендовано):
```sql
FROM sys.indexes i
FROM sys.tables t
FROM sys.columns c
FROM util.functionName f
```

Довгі (якщо багато таблиць):
```sql
FROM sys.indexes idx         
FROM sys.tables tab
FROM sys.columns cols
FROM util.functionName fn
```

### SELECT statements

**Форматування колонок** (без AS):
```sql
SELECT 
    c.object_id objectId,
    OBJECT_SCHEMA_NAME(c.object_id) schemaName,
    OBJECT_NAME(c.object_id) objectName,
    c.column_id columnId,
    c.name columnName
FROM sys.columns c
```

**CASE statements**:
```sql
CASE 
    WHEN condition1 THEN value1
    WHEN condition2 THEN value2  
    ELSE defaultValue
END AS columnName
```

**CONCAT замість +**:
```sql
-- Замість:
'PK_' + ii.TableName + '_' + LEFT(ISNULL(ic.KeyColumns, ''), 100)

-- Використовуйте:
CONCAT('PK_', ii.TableName, '_', LEFT(ISNULL(ic.KeyColumns, ''), 100))
```

**QUOTENAME для безпеки**:
```sql
CONCAT(QUOTENAME(s.name), '.', QUOTENAME(t.name))
QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) + '.' + QUOTENAME(OBJECT_NAME(object_id))
```

## Форматування

### Відступи

- **4 пробіли** для основних блоків
- **8 пробілів** для вкладених блоків
- **Вирівнювання** за ключовими словами

**Приклад**:
```sql
CREATE OR ALTER FUNCTION util.example(@param INT)
RETURNS TABLE
AS
RETURN(
    WITH cteExample AS (
        SELECT 
            column1,
            column2
        FROM table1
        WHERE condition
    )
    SELECT 
        e.column1,
        e.column2,
        CASE 
            WHEN e.column1 > 10 THEN 'High'
            ELSE 'Low'
        END status
    FROM cteExample e
    WHERE e.column2 IS NOT NULL
);
```

### Перенос рядків

**SELECT**:
```sql
SELECT 
    column1,
    column2,
    column3
FROM table1
    INNER JOIN table2 ON condition
WHERE condition1
    AND condition2
    AND condition3
ORDER BY column1, column2
```

**Довгі умови**:
```sql
WHERE 
    (
        condition1 = value1
        OR condition2 = value2
    )
    AND condition3 = value3
    AND (
        @param IS NULL 
        OR column = @param
    )
```

## Best Practices

### 1. Мова
- Документація українською
- Код англійською
- Коментарі в коді українською

### 2. Консистентність
- Однакові паттерни у всіх файлах
- Єдиний стиль форматування
- Стандартні назви параметрів

### 3. Безпечність
- Використовуйте `TRY_CONVERT`, `TRY_CAST`
- Використовуйте `QUOTENAME` для динамічного SQL
- Використовуйте `ISNULL` для NULL handling

### 4. Читабельність
- Коментарі для складних блоків
- Логічне форматування
- Осмислені назви змінних

### 5. Універсальність
- NULL parameters для "всі записи"
- Підтримка і ID і назв об'єктів
- Гнучкі фільтри

### 6. Оптимізація
- `NOLOCK` для sys каталогів
- Ефективні JOIN-и
- Уникайте курсорів де можливо

### 7. Стандартизація
- Однакова структура коментарів
- Стандартні секції (Description, Parameters, Returns, Usage)
- Єдиний формат прикладів

### 8. Модульність
- Невеликі, сфокусовані функції
- Одна відповідальність на функцію
- Повторне використання коду

## Приклади поганого / хорошого коду

### Погано

```sql
CREATE FUNCTION dbo.GetData(@id int)
RETURNS TABLE
AS
RETURN(
SELECT t.id,t.name,t.value FROM dbo.MyTable t where t.id=@id
);
```

**Проблеми**:
- Немає коментарів
- Неправильна схема (dbo замість util)
- Немає форматування
- Немає перевірки на NULL
- Немає алгоритму найменування

### Добре

```sql
/*
# Description
Отримує дані з таблиці за ID

# Parameters
@objectId INT = NULL - ID об'єкта (NULL = всі записи)

# Returns
TABLE з колонками: objectId, objectName, objectValue

# Usage
SELECT * FROM util.objectsGetData(123);
SELECT * FROM util.objectsGetData(NULL);  -- всі записи
*/
CREATE OR ALTER FUNCTION util.objectsGetData(@objectId INT = NULL)
RETURNS TABLE
AS
RETURN(
    SELECT 
        t.id objectId,
        t.name objectName,
        t.value objectValue
    FROM dbo.MyTable t (NOLOCK)
    WHERE @objectId IS NULL OR t.id = @objectId
);
GO
```

## Перевірка коду

### Чеклист перед commit

- [ ] Додано структуровані коментарі (Description, Parameters, Returns, Usage)
- [ ] Дотримано конвенції найменування
- [ ] Використано правильну схему (util/mcp)
- [ ] Форматування з 4 пробілами
- [ ] Параметри мають DEFAULT значення де потрібно
- [ ] NULL handling для опціональних параметрів
- [ ] NOLOCK для sys каталогів
- [ ] QUOTENAME для динамічного SQL
- [ ] TRY_CONVERT/TRY_CAST для конвертації
- [ ] Тестовані приклади у секції Usage
- [ ] GO в кінці файлу

## Інтеграція з AI

### Структуровані коментарі для AI

Коментарі в форматі Markdown дозволяють AI-асистентам:
- Витягувати опис функціональності
- Генерувати JSON schema для MCP
- Створювати автоматичну документацію
- Відповідати на питання про код

**Приклад для MCP**:
```sql
/*
# Description
Отримує список баз даних на сервері

# Returns
JSON масив з інформацією про бази даних
*/
CREATE OR ALTER PROCEDURE mcp.GetDatabases
AS
BEGIN
    -- код
END;
```

AI автоматично генерує MCP tool:
```json
{
  "name": "GetDatabases",
  "description": "Отримує список баз даних на сервері",
  "inputSchema": {
    "type": "object",
    "properties": {}
  }
}
```

## Наступні кроки

- [Приклади коду](examples.md)
- [Архітектура](architecture.md)
- [FAQ](faq.md)

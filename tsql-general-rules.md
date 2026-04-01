# T-SQL General Rules

Загальні правила написання T-SQL коду та корисні запити для проекту pure-utils.  
Цей документ охоплює стиль коду, паттерни, оптимізацію та приклади корисних запитів.

---

## Структура файлу

Кожен SQL файл має наступну структуру:

```sql
/*
# Description
Детальний опис функціональності українською мовою.

# Parameters
@param1 TYPE = DEFAULT - опис параметра українською
@param2 TYPE - опис параметра

# Returns
Опис того що повертається (TABLE structure, scalar type, тощо)

# Usage
-- Приклад використання
SELECT * FROM util.functionName('value');
*/
CREATE OR ALTER FUNCTION util.functionName(@param TYPE = NULL)
RETURNS TABLE
AS
RETURN(
    -- код
);
GO
```

### Обов'язкові секції коментарів

| Секція | Призначення |
|---|---|
| `# Description` | Опис функціональності українською |
| `# Parameters` | Кожен параметр з типом, default та описом |
| `# Returns` | Що повертає функція/процедура |
| `# Usage` | Робочі приклади використання |

### Опціональні секції

| Секція | Призначення |
|---|---|
| `# Notes` | Додаткові примітки, обмеження |
| `# Examples` | Детальні приклади |
| `# See Also` | Пов'язані об'єкти |

---

## CREATE Statements

### Inline Table-Valued Function (основний тип)

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

### Scalar Function

```sql
CREATE OR ALTER FUNCTION util.functionName(@param TYPE)
RETURNS TYPE
AS
BEGIN
    RETURN (SELECT ... FROM ... WHERE ...);
END;
GO
```

### Procedure

```sql
CREATE OR ALTER PROCEDURE util.procedureName
    @param1 TYPE = NULL,
    @param2 TYPE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- код
END;
GO
```

### Правила

- Завжди `CREATE OR ALTER` (не DROP + CREATE)
- Завжди `GO` в кінці файлу
- `SET NOCOUNT ON` — обов'язково в процедурах
- Inline TVF переважно над Multi-statement TVF
- Один об'єкт на файл

---

## Форматування

### Відступи

- **4 пробіли** для основних блоків
- **8 пробілів** для вкладених блоків
- Без табуляції

### SELECT

```sql
SELECT 
    c.object_id objectId,
    OBJECT_SCHEMA_NAME(c.object_id) schemaName,
    OBJECT_NAME(c.object_id) objectName,
    c.column_id columnId,
    c.name columnName
FROM sys.columns c (NOLOCK)
    INNER JOIN sys.tables t (NOLOCK) ON c.object_id = t.object_id
WHERE (@object IS NULL OR c.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
    AND c.is_computed = 0
ORDER BY c.column_id
```

### JOIN

```sql
FROM sys.indexes i (NOLOCK)
    INNER JOIN sys.tables t (NOLOCK) ON i.object_id = t.object_id
    INNER JOIN sys.schemas s (NOLOCK) ON t.schema_id = s.schema_id
    LEFT JOIN sys.data_spaces ds (NOLOCK) ON i.data_space_id = ds.data_space_id
    LEFT JOIN sys.key_constraints kc (NOLOCK) ON i.object_id = kc.parent_object_id
        AND i.index_id = kc.unique_index_id
        AND kc.type = 'PK'
```

### WHERE з довгими умовами

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

### CASE

```sql
CASE 
    WHEN condition1 THEN value1
    WHEN condition2 THEN value2
    ELSE defaultValue
END AS columnName
```

### CTE

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

---

## Паттерни фільтрації

### Універсальний об'єкт (ID або назва)

```sql
WHERE (@object IS NULL OR column = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
```

Цей паттерн дозволяє передати як ім'я об'єкта (`'myTable'`), так і його ID (`12345`), а також `NULL` для отримання всіх записів.

### Опціональні фільтри

```sql
WHERE (@index IS NULL OR i.name = @index)
WHERE (@columnId IS NULL OR c.column_id = @columnId)
WHERE (@database IS NULL OR db.name = @database)
WHERE (@schema IS NULL OR s.name = @schema)
```

### Безпечна конвертація

```sql
ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object))
TRY_CAST(@value AS INT)
```

---

## Безпека

### QUOTENAME для динамічного SQL

```sql
-- Завжди використовуйте QUOTENAME для ідентифікаторів
CONCAT(QUOTENAME(s.name), '.', QUOTENAME(t.name))

-- В динамічних запитах
SET @sql = CONCAT(N'SELECT * FROM ', QUOTENAME(@schemaName), '.', QUOTENAME(@tableName));
```

### TRY_CONVERT / TRY_CAST

```sql
-- Замість CONVERT/CAST використовуйте безпечні варіанти
ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object))
TRY_CAST(@value AS DATETIME)
```

### CONCAT замість +

```sql
-- Замість конкатенації +
CONCAT('PK_', ii.TableName, '_', LEFT(ISNULL(ic.KeyColumns, ''), 100))

-- CONCAT ігнорує NULL (не повертає NULL як +)
```

---

## Оптимізація

### NOLOCK для системних каталогів

```sql
FROM sys.indexes i (NOLOCK)
    INNER JOIN sys.tables t (NOLOCK) ON i.object_id = t.object_id
    INNER JOIN sys.schemas s (NOLOCK) ON t.schema_id = s.schema_id
```

Завжди додавайте `(NOLOCK)` при читанні з `sys.*` каталогів і DMV.

### Уникайте курсорів

Використовуйте `STRING_AGG`, `FOR XML PATH`, CTE з рекурсією замість курсорів.

### Inline TVF замість Multi-statement TVF

Inline TVF оптимізуються як підзапити; Multi-statement TVF створюють табличну змінну.

---

## Корисні запити

### Пошук відсутніх індексів

```sql
-- Топ-10 найбільш корисних відсутніх індексів з готовим DDL
SELECT TOP 10 
    SchemaName,
    TableName,
    IndexAdvantage,
    EqualityColumns,
    InequalityColumns,
    IncludedColumns,
    CreateIndexStatement
FROM util.indexesGetMissing(NULL)
ORDER BY IndexAdvantage DESC;
```

### Пошук невикористовуваних індексів

```sql
-- Індекси які не використовуються для читання
SELECT 
    SchemaName,
    TableName,
    IndexName,
    IndexType,
    UnusedReason
FROM util.indexesGetUnused(NULL);
```

### Аналіз простору індексів

```sql
-- Скільки місця займають індекси таблиці
SELECT * FROM util.indexesGetSpaceUsed('myTable');

-- Детальний аналіз по партиціях
SELECT * FROM util.indexesGetSpaceUsedDetailed('myTable');
```

### Невикористовувані таблиці

```sql
-- Таблиці без читань і без записів
SELECT * FROM util.tablesGetUnused(0);

-- Таблиці тільки для запису (без читань)
SELECT * FROM util.tablesGetUnused(1);
```

### Генерація стандартних назв індексів

```sql
-- Порівняти поточні та рекомендовані назви індексів
SELECT * FROM util.indexesGetConventionNames(NULL, NULL);

-- Для конкретної таблиці
SELECT * FROM util.indexesGetConventionNames('Orders', NULL);
```

### Пошук об'єктів в базі даних

```sql
-- Пошук по всіх об'єктах, колонках, параметрах та визначеннях
EXEC util.objectsFind @search = 'CustomerName';
```

### Метадані об'єктів

```sql
-- Всі колонки таблиці з типами
SELECT * FROM util.metadataGetColumns('myTable');

-- Всі параметри процедури/функції
SELECT * FROM util.metadataGetParameters('myProcedure');

-- Описи (extended properties) об'єкта
SELECT * FROM util.metadataGetDescriptions('myTable', NULL);

-- Всі індекси таблиці
SELECT * FROM util.metadataGetIndexes('myTable');
```

### Залежності об'єктів

```sql
-- Об'єкти на які посилається заданий об'єкт
EXEC util.objectsGetReferenced @object = 'myProcedure';

-- Об'єкти які посилаються на заданий об'єкт
EXEC util.objectsGetReferences @object = 'myTable';

-- Генерація DDL скрипта з усіма залежностями
EXEC util.objesctsScriptWithDependencies @object = 'myProcedure';
```

### Описи об'єктів з коментарів

```sql
-- Автоматичне витягування описів з коментарів у код
EXEC util.modulesSetDescriptionFromComments @object = 'myFunction';
```

### Встановлення описів

```sql
-- Опис таблиці
EXEC util.metadataSetTableDescription @object = 'myTable', @description = N'Опис таблиці';

-- Опис колонки
EXEC util.metadataSetColumnDescription @object = 'myTable', @column = 'myColumn', @description = N'Опис колонки';

-- Опис індексу
EXEC util.metadataSetIndexDescription @object = 'myTable', @index = 'IX_myIndex', @description = N'Опис індексу';
```

### Extended Events (моніторинг)

```sql
-- Помилки з XE сесії
SELECT * FROM util.xeGetErrors();

-- Debug дані
SELECT * FROM util.xeGetDebug();

-- Дані модулів (запити користувачів)
SELECT * FROM util.xeGetModules();
```

### Аналіз планів виконання

```sql
-- Пошук плану виконання за назвою об'єкта
EXEC util.executionSearchPlanByObjectName @object = 'myProcedure';

-- Поточний виконуваний запит
SELECT * FROM util.executionGetCurrentStatement();

-- Параметри з XML плану виконання
SELECT * FROM util.planGetParameters(@xmlPlan);

-- Зведена інформація плану
SELECT * FROM util.planSummary(@xmlPlan);
```

### Безпека

```sql
-- Дозволи на рівні бази даних
SELECT * FROM util.securityGetDatabasePermissions(NULL);

-- Членство в ролях зі скриптами
SELECT * FROM util.securityGetRoleMembership(NULL);
```

### Історія DDL змін

```sql
-- Історія змін моїх об'єктів
SELECT * FROM util.myselfGetHistory();

-- Історія змін конкретного об'єкта
SELECT * FROM util.objectGetHistory('myTable');

-- Активні операції створення індексів
SELECT * FROM util.myselfActiveIndexCreation();
```

### Генерація DDL скриптів

```sql
-- Повний DDL таблиці зі всіма constraint та індексами
SELECT * FROM util.tablesGetScript('myTable');

-- DDL конкретного індексу
SELECT * FROM util.indexesGetScript('myTable', 'IX_myIndex');

-- DDL партиційної функції
SELECT * FROM util.partitionFunctionsGetScript('myPartitionFunction');

-- DDL партиційної схеми
SELECT * FROM util.partitionSchemesGetScript('myPartitionScheme');
```

### Пошук подібних модулів

```sql
-- Знаходить функції/процедури з подібним кодом (через токенізацію і SHA1)
SELECT * FROM util.modulesFindSimilar(NULL);
```

### Аналіз коментарів в коді

```sql
-- Позиції всіх коментарів в модулі
SELECT * FROM util.modulesFindCommentsPositions('myFunction');

-- Розбити модуль на рядки з нумерацією
SELECT * FROM util.modulesSplitToLines('myFunction');
```

### Генерація тимчасових таблиць з SELECT

```sql
-- Згенерувати CREATE TABLE скрипт з результату SELECT
SELECT util.stringGetCreateTempScript('SELECT * FROM sys.tables');
```

---

## Обробка помилок

### Стандартний паттерн

```sql
BEGIN TRY
    -- основний код
END TRY
BEGIN CATCH
    EXEC util.errorHandler;
END CATCH;
```

Процедура `util.errorHandler`:
- Логує помилку в `util.errorLog`
- Зберігає контекст сесії (XML)
- Повторно кидає помилку через `THROW`

### Структура таблиці errorLog

```
ErrorId, ErrorDateTime, ErrorNumber, ErrorSeverity, ErrorState,
ErrorProcedure, ErrorLine, ErrorLineText, ErrorMessage,
OriginalLogin, SessionId, HostName, ProgramName, DatabaseName,
UserName, Attachment, SessionInfo (XML)
```

---

## Довідка

```sql
-- Інтерактивна довідка по всіх об'єктах util
EXEC util.help;

-- Довідка по конкретному об'єкту
EXEC util.help @object = 'indexesGetMissing';
```

---

## Best Practices (зведення)

1. **Документація українською**, код англійською
2. **NULL параметри** — означає "всі записи"
3. **TRY_CONVERT / QUOTENAME / ISNULL** — для безпеки
4. **NOLOCK** для sys.* каталогів
5. **CONCAT** замість `+` для конкатенації рядків
6. **Inline TVF** — основний тип функцій
7. **CREATE OR ALTER** — ніколи DROP + CREATE
8. **SET NOCOUNT ON** — завжди в процедурах
9. **4 пробіли** — єдиний відступ
10. **Колонки без AS** — `column_id columnId` (окрім CASE)
11. **Один файл — один об'єкт**
12. **Модульність** — невеликі, сфокусовані функції з однією відповідальністю
13. **Повторне використання** — використовуйте існуючі util.* функції замість дублювання
14. **Стиснення** — `DATA_COMPRESSION = PAGE` для таблиць де доцільно
15. **GO** — завжди в кінці файлу

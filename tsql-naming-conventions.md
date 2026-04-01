# T-SQL Naming Conventions

Правила іменування для T-SQL об'єктів у проекті pure-utils.  
Застосовуються при створенні, перейменуванні та рев'ю будь-яких SQL об'єктів.

---

## Мова

| Контекст | Мова |
|---|---|
| Назви об'єктів, змінних, колонок | Англійська |
| Коментарі, описи, документація | Українська |

---

## Схеми

| Схема | Призначення |
|---|---|
| `util` | Основні утиліти (функції, процедури, таблиці, в'юхи) |
| `mcp` | Адаптери для MCP-протоколу (AI інтеграція) |
| `api` | REST API ендпоінти |
| `dbo` | **НЕ використовувати** для нових об'єктів |

---

## Функції

**Паттерн:** `{category}{Action}{Entity}`

- Назва починається з **категорії** (lowercase)
- Далі **дія** (PascalCase)
- Далі **сутність** (PascalCase)

### Категорії

| Категорія | Призначення | Приклади |
|---|---|---|
| `metadata` | Метадані об'єктів БД | `metadataGetAnyId`, `metadataGetColumnName`, `metadataGetObjectType` |
| `indexes` | Робота з індексами | `indexesGetConventionNames`, `indexesGetMissing`, `indexesGetSpaceUsed` |
| `modules` | Аналіз SQL коду (модулів) | `modulesFindSimilar`, `modulesSplitToLines`, `modulesGetCreateLineNumber` |
| `tables` | Операції з таблицями | `tablesGetScript`, `tablesGetUnused`, `tablesGetIndexedColumns` |
| `string` | Робота з рядками | `stringSplitToLines`, `stringSplitToChars`, `stringConvertFromSID` |
| `xe` | Extended Events | `xeGetErrors`, `xeGetDebug`, `xeGetModules`, `xeGetLogsPath` |
| `jobs` | SQL Agent Jobs | `jobsGetNameByAppName`, `jobsGetNameByAppNameInline` |
| `partition` | Партиціювання | `partitionFunctionsGetScript`, `partitionSchemesGetScript` |
| `mcp` | MCP інтеграція | `mcpBuildToolJson`, `mcpMapSqlTypeToJsonType` |
| `security` | Безпека | `securityGetDatabasePermissions`, `securityGetRoleMembership` |
| `execution` | Аналіз виконання | `executionGetCurrentStatement` |
| `object` | Операції з об'єктами | `objectGetHistory` |
| `myself` | Поточна сесія/логін | `myselfGetHistory`, `myselfActiveIndexCreation` |
| `plan` | Плани виконання | `planGetParameters`, `planSummary` |

### Дії (Actions)

| Дія | Призначення | Приклад |
|---|---|---|
| `Get` | Отримати дані | `metadataGetColumns`, `indexesGetScript` |
| `Find` | Пошук/виявлення | `modulesFindSimilar`, `modulesFindCommentsPositions` |
| `Split` | Розбити на частини | `modulesSplitToLines`, `stringSplitToChars` |
| `Convert` | Конвертація | `stringConvertFromSID`, `stringConvertToSID` |
| `Build` | Побудувати/згенерувати | `mcpBuildToolJson`, `mcpBuildParameterJson` |
| `Map` | Маппінг типів | `mcpMapSqlTypeToJsonType` |
| `RecureSearch` | Рекурсивний пошук | `modulesRecureSearchInvalidReferences` |

---

## Процедури

### SET-операції

**Паттерн:** `{entity}Set{Property}`

```
metadataSetColumnDescription
metadataSetTableDescription
metadataSetFunctionDescription
metadataSetProcedureDescription
metadataSetViewDescription
metadataSetIndexDescription
metadataSetParameterDescription
metadataSetSchemaDescription
metadataSetTriggerDescription
metadataSetDataspaceDescription
metadataSetFilegroupDescription
metadataSetExtendedProperty
indexesSetConventionNames
modulesSetDescriptionFromComments
```

### Спеціальні процедури

```
errorHandler                      -- обробка помилок
help                              -- інтерактивна довідка по util
objectsFind                       -- пошук об'єктів, колонок, параметрів
objectsGetReferenced              -- об'єкти, на які посилається заданий об'єкт
objectsGetReferences              -- об'єкти, які посилаються на заданий об'єкт
objesctsScriptWithDependencies    -- DDL скрипт з залежностями
xeCopyModulesToTable              -- копіювання XE подій до таблиці
executionSearchPlanByHandle       -- пошук плану за handle
executionSearchPlanByObjectName   -- пошук плану за назвою об'єкта
```

### MCP процедури

**Паттерн:** `{Action}{Entity}` (PascalCase)

```
GetDatabases
GetTables
GetViews
GetFunctions
GetProcedures
GetTableInfo
GetSqlModule
GetDdlHistory
FindObjects
FindLastModulePlan
GetIndexesMissing
GetIndexesUnused
GetIndexesScript
GetObjectsReferences
GetObjectsReferenced
ScriptObjectAndReferences
GetSecurityDatabasePermissions
GetSecurityRoleMembership
```

---

## Параметри

### Стандартні назви параметрів

| Параметр | Тип | Default | Призначення |
|---|---|---|---|
| `@object` | `NVARCHAR(128)` | `NULL` | Назва або ID об'єкта (таблиці, функції тощо) |
| `@objectId` | `INT` | `NULL` | ID об'єкта |
| `@index` | `NVARCHAR(128)` | `NULL` | Назва індексу |
| `@table` | `NVARCHAR(128)` | `NULL` | Назва таблиці |
| `@schema` | `NVARCHAR(128)` | `NULL` | Назва схеми |
| `@database` | `NVARCHAR(128)` | `NULL` | Назва бази даних |
| `@column` | `NVARCHAR(128)` | `NULL` | Назва колонки |
| `@columnId` | `INT` | `NULL` | ID колонки |

### Boolean параметри

| Параметр | Default | Призначення |
|---|---|---|
| `@skipEmpty` | `1` | Пропустити пусті значення |
| `@replaceCRwithLF` | `1` | Замінити CR на LF |
| `@includeReferences` | `1` | Включити залежності |
| `@output` | `1` | Режим виводу |

### Правила

- `NULL` = "всі записи" (опціональний фільтр)
- Параметри завжди мають DEFAULT значення де це доцільно
- camelCase для назв параметрів: `@schemaName`, `@functionName`
- Типова довжина для рядкових параметрів: `NVARCHAR(128)`

---

## Змінні

**Стиль:** camelCase

```sql
DECLARE @schemaName NVARCHAR(128);
DECLARE @functionName NVARCHAR(128);
DECLARE @procedureName NVARCHAR(128);
DECLARE @indexName NVARCHAR(128);
DECLARE @currentValue SQL_VARIANT;
DECLARE @ErrorNumber INT = ERROR_NUMBER();
```

---

## Колонки у результатах

**Стиль:** camelCase, **без AS**

```sql
SELECT 
    c.object_id objectId,
    OBJECT_SCHEMA_NAME(c.object_id) schemaName,
    OBJECT_NAME(c.object_id) objectName,
    c.column_id columnId,
    c.name columnName
```

Виняток — `CASE ... END AS columnName` (з AS для читабельності).

---

## Індекси (Convention Names)

### Префікси

| Префікс | Тип індексу | Приклад |
|---|---|---|
| `PK_` | Primary Key | `PK_Orders_OrderId` |
| `CI_` | Clustered Index | `CI_OrderDate_OrderId` |
| `IX_` | Non-clustered Index | `IX_CustomerId` |
| `CCSI` | Clustered Columnstore | `CCSI` |
| `CS_` | Nonclustered Columnstore | `CS_OrderDate` |

### Суфікси

| Суфікс | Значення | Приклад |
|---|---|---|
| `_INC` | Має included колонки | `IX_CustomerId_INC` |
| `_FLT` | Має filter | `IX_Status_FLT` |
| `_UQ` | Unique | `IX_Email_UQ` |
| `_P` | Partitioned | `IX_OrderDate_P` |
| `_D` | Descending sort (в назві колонки) | `IX_OrderDate_D_OrderId` |

### Повний формат

```
{Prefix}_{TableName}_{KeyCol1}_{KeyCol2}[_INC][_FLT][_UQ][_P]
```

Приклади:
```
PK_Orders_OrderId
CI_OrderDate_OrderId
IX_CustomerId_INC
IX_Status_OrderDate_FLT_UQ
IX_OrderDate_D_OrderId_P
CCSI
CS_OrderDate_Amount
```

### Primary Key

```
PK_{TableName}_{KeyColumns}
```

Завжди включає назву таблиці.

### Clustered Index (не PK)

```
CI_{KeyColumns}
```

Без назви таблиці в основному імені.

### Non-clustered Index

```
IX_{KeyColumns}[_INC][_FLT][_UQ][_P]
```

Суфікси додаються в порядку: `_INC` → `_FLT` → `_UQ` → `_P`.

---

## Таблиці

### Системні таблиці util

| Таблиця | Призначення |
|---|---|
| `errorLog` | Лог помилок |
| `eventsNotifications` | DDL аудит подій |
| `executionModulesSSIS` | XE дані модулів SSIS |
| `executionModulesUsers` | XE дані модулів користувачів |
| `executionPlanHandleHash` | Маппінг plan handle → hash |
| `executionSqlText` | Дедуплікований текст SQL |
| `xeModule` | Індексація XE модулів |
| `xeOffsets` | Позиції читання XE |

### Правила

- Назви таблиць: camelCase
- Стиснення: `DATA_COMPRESSION = PAGE` де доцільно
- Кластерний індекс обов'язковий (уникати heap)

---

## CTE (Common Table Expressions)

**Префікс:** `cte` + PascalCase

```sql
WITH cteIndexes AS (...),
     cteColumns AS (...),
     cteResult AS (...)
```

Приклади з кодової бази:
```
cteRn, cteFiltered, cteIndexes, cteColumns, cteResult
IndexInfo, IndexColumns, IndexInclude, ProposedIndexNames, FinalIndexNames
MissingIndexes, TableUsageStats, IndexUsageStats
```

---

## Aliases

### Системні каталоги

| Alias | Об'єкт |
|---|---|
| `i` або `idx` | `sys.indexes` |
| `t` або `tab` | `sys.tables` |
| `c` або `cols` | `sys.columns` |
| `s` | `sys.schemas` |
| `ic` | `sys.index_columns` |
| `ds` | `sys.data_spaces` |
| `kc` | `sys.key_constraints` |
| `ep` | `sys.extended_properties` |
| `ius` | `sys.dm_db_index_usage_stats` |
| `mid` | `sys.dm_db_missing_index_details` |
| `mig` | `sys.dm_db_missing_index_groups` |
| `migs` | `sys.dm_db_missing_index_group_stats` |

### Утиліти

| Alias | Приклад |
|---|---|
| `f` або `fn` | `util.functionName f` |
| `p` | `util.procedureName p` |

### Правила

- Короткі alias (1-3 літери) — рекомендовано для простих запитів
- Довгі alias (3+ літери) — якщо в запиті багато таблиць
- Alias завжди без `AS`: `FROM sys.indexes i` (не `AS i`)

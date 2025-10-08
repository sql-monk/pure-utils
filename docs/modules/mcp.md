# Модуль mcp - Адаптери для AI-інтеграції

## Огляд

Схема `mcp` містить процедури-обгортки, які формують JSON відповіді у форматі Model Context Protocol (MCP). Ці процедури є адаптерами між функціями util та AI-асистентами, забезпечуючи стандартизований інтерфейс для отримання метаданих бази даних.

## Призначення

MCP адаптери дозволяють AI-асистентам:
- Отримувати структуру бази даних
- Аналізувати метадані таблиць
- Генерувати DDL скрипти
- Переглядати історію змін
- Шукати execution plans

## Формат відповіді MCP

Всі процедури повертають JSON у стандартному форматі MCP:

```json
{
  "content": [
    {
      "type": "text",
      "text": "... actual data in JSON format ..."
    }
  ]
}
```

## Процедури

### GetDatabases

**Призначення**: Отримання списку всіх баз даних на сервері.

**Сигнатура**:
```sql
CREATE PROCEDURE mcp.GetDatabases
```

**Параметри**: Немає

**Повертає**: JSON з масивом баз даних

**Структура відповіді**:
```json
{
  "content": [{
    "type": "text",
    "text": "[{
      \"name\": \"master\",
      \"databaseId\": 1,
      \"createDate\": \"2023-01-15T10:30:00\",
      \"compatibilityLevel\": 150,
      \"isReadOnly\": false,
      \"stateDesc\": \"ONLINE\",
      \"recoveryModelDesc\": \"SIMPLE\"
    }, ...]"
  }]
}
```

**Приклади використання**:
```sql
-- Через T-SQL
EXEC mcp.GetDatabases;

-- Через MCP клієнт (Claude Desktop, etc)
-- Tool: GetDatabases (без параметрів)
```

**Використовувані util функції**: Системні каталоги `sys.databases`

---

### GetTables

**Призначення**: Отримання списку таблиць у базі даних.

**Сигнатура**:
```sql
CREATE PROCEDURE mcp.GetTables
    @database NVARCHAR(128) = NULL
```

**Параметри**:
- `@database` - назва бази даних (NULL = поточна БД)

**Повертає**: JSON з масивом таблиць

**Структура відповіді**:
```json
{
  "content": [{
    "type": "text",
    "text": "[{
      \"schemaName\": \"dbo\",
      \"tableName\": \"Orders\",
      \"createDate\": \"2023-01-15T10:30:00\",
      \"modifyDate\": \"2023-06-20T15:45:00\",
      \"rowCount\": 150000,
      \"totalSpaceMB\": 245.5,
      \"description\": \"Таблиця замовлень\"
    }, ...]"
  }]
}
```

**Приклади**:
```sql
-- Таблиці поточної БД
EXEC mcp.GetTables;

-- Таблиці конкретної БД
EXEC mcp.GetTables @database = 'AdventureWorks';
```

**Використовувані util функції**: `sys.tables`, `sys.dm_db_partition_stats`

---

### GetViews

**Призначення**: Отримання списку представлень у базі даних.

**Сигнатура**:
```sql
CREATE PROCEDURE mcp.GetViews
    @database NVARCHAR(128) = NULL
```

**Параметри**:
- `@database` - назва бази даних (NULL = поточна БД)

**Повертає**: JSON з масивом представлень

**Приклади**:
```sql
EXEC mcp.GetViews @database = 'master';
```

---

### GetProcedures

**Призначення**: Отримання списку збережених процедур.

**Сигнатура**:
```sql
CREATE PROCEDURE mcp.GetProcedures
    @database NVARCHAR(128) = NULL
```

**Параметри**:
- `@database` - назва бази даних (NULL = поточна БД)

**Повертає**: JSON з масивом процедур

**Приклади**:
```sql
EXEC mcp.GetProcedures;
```

---

### GetFunctions

**Призначення**: Отримання списку функцій.

**Сигнатура**:
```sql
CREATE PROCEDURE mcp.GetFunctions
    @database NVARCHAR(128) = NULL
```

**Параметри**:
- `@database` - назва бази даних (NULL = поточна БД)

**Повертає**: JSON з масивом функцій

**Приклади**:
```sql
EXEC mcp.GetFunctions @database = 'master';
```

---

### GetTableInfo

**Призначення**: Детальна інформація про структуру таблиці.

**Сигнатура**:
```sql
CREATE PROCEDURE mcp.GetTableInfo
    @database NVARCHAR(128) = NULL,
    @schema NVARCHAR(128) = 'dbo',
    @table NVARCHAR(128)
```

**Параметри**:
- `@database` - назва бази даних (NULL = поточна БД)
- `@schema` - назва схеми (за замовчуванням 'dbo')
- `@table` - назва таблиці (обов'язковий)

**Повертає**: JSON з детальною інформацією про таблицю

**Структура відповіді**:
```json
{
  "content": [{
    "type": "text",
    "text": "{
      \"tableName\": \"Orders\",
      \"schemaName\": \"dbo\",
      \"columns\": [{
        \"columnName\": \"OrderId\",
        \"dataType\": \"int\",
        \"isNullable\": false,
        \"isIdentity\": true,
        \"isPrimaryKey\": true,
        \"description\": \"Унікальний ідентифікатор\"
      }, ...],
      \"indexes\": [{
        \"indexName\": \"PK_Orders\",
        \"indexType\": \"CLUSTERED\",
        \"columns\": [\"OrderId\"],
        \"isUnique\": true
      }, ...],
      \"foreignKeys\": [...],
      \"statistics\": {
        \"rowCount\": 150000,
        \"totalSpaceMB\": 245.5
      }
    }"
  }]
}
```

**Приклади**:
```sql
-- Інформація про таблицю у поточній БД
EXEC mcp.GetTableInfo 
    @database = NULL,
    @schema = 'dbo',
    @table = 'Orders';

-- Інформація про системну таблицю
EXEC mcp.GetTableInfo 
    @database = 'master',
    @schema = 'sys',
    @table = 'objects';
```

**Використовувані util функції**: 
- `util.metadataGetColumns`
- `util.metadataGetIndexes`
- `util.metadataGetDescriptions`

---

### GetDdlHistory

**Призначення**: Історія DDL операцій (CREATE, ALTER, DROP) за період.

**Сигнатура**:
```sql
CREATE PROCEDURE mcp.GetDdlHistory
    @database NVARCHAR(128) = NULL,
    @startDate DATETIME2 = NULL,
    @endDate DATETIME2 = NULL,
    @eventType NVARCHAR(50) = NULL,
    @objectName NVARCHAR(128) = NULL
```

**Параметри**:
- `@database` - назва бази даних (NULL = поточна БД)
- `@startDate` - початок періоду (NULL = 30 днів тому)
- `@endDate` - кінець періоду (NULL = зараз)
- `@eventType` - тип події (CREATE, ALTER, DROP) (NULL = всі)
- `@objectName` - назва об'єкта для фільтрації (NULL = всі)

**Повертає**: JSON з історією DDL операцій

**Структура відповіді**:
```json
{
  "content": [{
    "type": "text",
    "text": "[{
      \"eventTime\": \"2023-06-20T15:45:30\",
      \"eventType\": \"ALTER_TABLE\",
      \"objectName\": \"dbo.Orders\",
      \"objectType\": \"TABLE\",
      \"userName\": \"DOMAIN\\user\",
      \"clientHost\": \"WORKSTATION01\",
      \"applicationName\": \"SSMS\"
    }, ...]"
  }]
}
```

**Приклади**:
```sql
-- Всі DDL за останні 7 днів
EXEC mcp.GetDdlHistory 
    @startDate = DATEADD(DAY, -7, GETDATE());

-- Тільки ALTER операції для конкретної таблиці
EXEC mcp.GetDdlHistory 
    @eventType = 'ALTER',
    @objectName = 'dbo.Orders';

-- За конкретний період
EXEC mcp.GetDdlHistory 
    @startDate = '2023-06-01',
    @endDate = '2023-06-30';
```

**Використовувані таблиці**: `util.eventsNotifications`

**Передумови**: Має бути налаштований DDL trigger для логування подій

---

### ScriptObjectAndReferences

**Призначення**: Генерація DDL скрипту об'єкта з усіма залежностями.

**Сигнатура**:
```sql
CREATE PROCEDURE mcp.ScriptObjectAndReferences
    @database NVARCHAR(128) = NULL,
    @schema NVARCHAR(128) = 'dbo',
    @object NVARCHAR(128),
    @includeReferences BIT = 1
```

**Параметри**:
- `@database` - назва бази даних (NULL = поточна БД)
- `@schema` - назва схеми
- `@object` - назва об'єкта
- `@includeReferences` - включити залежності (1 = так, 0 = ні)

**Повертає**: JSON з DDL скриптами у правильному порядку

**Структура відповіді**:
```json
{
  "content": [{
    "type": "text",
    "text": "{
      \"mainObject\": \"dbo.MyView\",
      \"scripts\": [{
        \"order\": 1,
        \"objectName\": \"dbo.BaseTable\",
        \"objectType\": \"TABLE\",
        \"script\": \"CREATE TABLE ...\"
      }, {
        \"order\": 2,
        \"objectName\": \"dbo.MyView\",
        \"objectType\": \"VIEW\",
        \"script\": \"CREATE VIEW ...\"
      }]
    }"
  }]
}
```

**Приклади**:
```sql
-- Скрипт представлення з залежностями
EXEC mcp.ScriptObjectAndReferences 
    @schema = 'dbo',
    @object = 'CustomerOrders',
    @includeReferences = 1;

-- Тільки сам об'єкт без залежностей
EXEC mcp.ScriptObjectAndReferences 
    @schema = 'dbo',
    @object = 'MyProcedure',
    @includeReferences = 0;
```

**Використовувані util функції**: 
- `util.objesctsScriptWithDependencies`
- `util.tablesGetScript`

**Обмеження**: 
- Cross-database залежності вимагають прав SELECT
- Максимальна глибина рекурсії = 10

---

### GetSqlModule

**Призначення**: Отримання коду (definition) модуля.

**Сигнатура**:
```sql
CREATE PROCEDURE mcp.GetSqlModule
    @database NVARCHAR(128) = NULL,
    @schema NVARCHAR(128) = 'dbo',
    @object NVARCHAR(128)
```

**Параметри**:
- `@database` - назва бази даних
- `@schema` - назва схеми
- `@object` - назва об'єкта (процедура, функція, представлення)

**Повертає**: JSON з кодом модуля

**Приклади**:
```sql
-- Отримати код процедури
EXEC mcp.GetSqlModule 
    @schema = 'util',
    @object = 'indexesGetMissing';
```

---

### FindLastModulePlan

**Призначення**: Пошук останнього execution plan для модуля.

**Сигнатура**:
```sql
CREATE PROCEDURE mcp.FindLastModulePlan
    @database NVARCHAR(128) = NULL,
    @schema NVARCHAR(128) = 'dbo',
    @module NVARCHAR(128)
```

**Параметри**:
- `@database` - назва бази даних
- `@schema` - назва схеми
- `@module` - назва модуля (процедура або функція)

**Повертає**: JSON з execution plan у форматі XML

**Структура відповіді**:
```json
{
  "content": [{
    "type": "text",
    "text": "{
      \"moduleName\": \"dbo.GetCustomerOrders\",
      \"lastExecutionTime\": \"2023-06-20T15:45:30\",
      \"executionCount\": 1250,
      \"avgDurationMs\": 125.5,
      \"planXml\": \"<ShowPlanXML ...>...</ShowPlanXML>\"
    }"
  }]
}
```

**Приклади**:
```sql
-- Знайти план виконання процедури
EXEC mcp.FindLastModulePlan 
    @schema = 'dbo',
    @module = 'GetCustomerOrders';
```

**Використовувані DMV**: 
- `sys.dm_exec_cached_plans`
- `sys.dm_exec_query_plan`
- `sys.dm_exec_sql_text`

**Обмеження**: 
- План має бути у кеші
- Потребує права VIEW SERVER STATE

---

## Внутрішні допоміжні функції

### mcpBuildToolJson

**Призначення**: Генерація JSON опису MCP tool з процедури.

**Використання**: Автоматична генерація metadata для MCP серверів

### mcpBuildParameterJson

**Призначення**: Генерація JSON схеми параметрів для MCP tool.

**Використання**: Формування JSON schema для параметрів процедур

### mcpGetObjectParameters

**Призначення**: Отримання списку параметрів об'єкта.

**Використання**: Витягування параметрів процедур та функцій

### mcpMapSqlTypeToJsonType

**Призначення**: Мапінг SQL типів даних у JSON типи.

**Приклад**:
```sql
SELECT util.mcpMapSqlTypeToJsonType('int'); -- повертає 'integer'
SELECT util.mcpMapSqlTypeToJsonType('nvarchar'); -- повертає 'string'
```

---

## Використання з AI-асистентами

### Приклад діалогу з Claude через MCP

**Користувач**: "Покажи мені структуру таблиці Orders"

**Claude викликає**:
```
mcp.GetTableInfo(database=null, schema='dbo', table='Orders')
```

**Відповідь** містить JSON з колонками, індексами, foreign keys

**Claude відповідає**: "Таблиця Orders має наступну структуру: ..."

### Приклад генерації DDL

**Користувач**: "Згенеруй DDL для представлення CustomerOrders з усіма залежностями"

**Claude викликає**:
```
mcp.ScriptObjectAndReferences(
    schema='dbo', 
    object='CustomerOrders', 
    includeReferences=1
)
```

**Відповідь** містить повні DDL скрипти у правильному порядку

## Best Practices

1. **Використовуйте параметр @database** для роботи з іншими БД
2. **Обмежуйте періоди** при виклику GetDdlHistory
3. **Тестуйте DDL скрипти** перед виконанням на production
4. **Перевіряйте права доступу** для cross-database операцій
5. **Налаштуйте DDL triggers** для логування історії змін

## Обмеження

- Всі процедури повертають результат як NVARCHAR(MAX)
- Максимальний розмір відповіді обмежений SQL Server (2GB)
- Cross-database запити вимагають додаткових прав
- Деякі функції потребують VIEW SERVER STATE

## Інтеграція з PureSqlsMcp сервером

PureSqlsMcp .NET сервер автоматично:
1. Сканує всі процедури у схемі mcp
2. Витягує параметри через `util.mcpGetObjectParameters`
3. Генерує JSON schema через `util.mcpBuildToolJson`
4. Реєструє як MCP tools

Детальніше: [PureSqlsMcp документація](PureSqlsMcp.md)

## Наступні кроки

- [PureSqlsMcp сервер](PureSqlsMcp.md)
- [PlanSqlsMcp сервер](PlanSqlsMcp.md)
- [Конфігурація MCP](../config.md)
- [Приклади використання](../examples.md)

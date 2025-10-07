# mcp.GetTables

## Опис

Процедура для отримання списку таблиць у заданій базі даних через MCP протокол. Підтримує фільтрацію за назвою таблиці. Повертає валідний JSON для MCP відповіді з інформацією про кожну таблицю, включаючи метадані та кількість рядків.

## Синтаксис

```sql
EXEC mcp.GetTables 
    @database = '<database_name>',
    [@filter = '<filter_pattern>'];
```

## Параметри

| Параметр | Тип | Обов'язковий | Опис |
|----------|-----|--------------|------|
| `@database` | NVARCHAR(128) | Так | Назва бази даних для отримання списку таблиць |
| `@filter` | NVARCHAR(128) | Ні | Фільтр за назвою таблиці (підтримує LIKE pattern). NULL або порожній рядок = всі таблиці |

## Повертає

**Тип:** JSON string  
**Формат:** MCP response з масивом content

### Структура відповіді

```json
{
  "content": [
    {
      "type": "text",
      "text": "[{\"schemaName\":\"...\",\"tableName\":\"...\",\"objectId\":..., ...}]"
    }
  ]
}
```

### Поля в JSON масиві таблиць

| Поле | Тип | Опис |
|------|-----|------|
| `schemaName` | string | Назва схеми |
| `tableName` | string | Назва таблиці |
| `objectId` | int | Object ID таблиці |
| `createDate` | string (ISO 8601) | Дата створення таблиці |
| `modifyDate` | string (ISO 8601) | Дата останньої модифікації |
| `typeDesc` | string | Тип об'єкта (зазвичай "USER_TABLE") |
| `rowsCount` | int | Кількість рядків в таблиці |

## Приклади

### Отримати всі таблиці в базі даних

```sql
EXEC mcp.GetTables @database = 'AdventureWorks';
```

### Отримати таблиці з фільтром (починаються з "Sales")

```sql
EXEC mcp.GetTables 
    @database = 'AdventureWorks',
    @filter = 'Sales%';
```

### Отримати таблиці що містять "Order"

```sql
EXEC mcp.GetTables 
    @database = 'AdventureWorks',
    @filter = '%Order%';
```

### Отримати таблиці конкретної схеми (через фільтр після USE)

```sql
-- Примітка: фільтр застосовується лише до назви таблиці, не схеми
-- Для фільтрації по схемі потрібно обробляти результат на клієнті
EXEC mcp.GetTables @database = 'AdventureWorks';
```

## Результат

### Приклад відповіді

```json
{
  "content": [
    {
      "type": "text",
      "text": "[{\"schemaName\":\"dbo\",\"tableName\":\"Users\",\"objectId\":245575913,\"createDate\":\"2023-05-20T14:30:00\",\"modifyDate\":\"2024-01-15T09:22:11\",\"typeDesc\":\"USER_TABLE\",\"rowsCount\":1523},{\"schemaName\":\"Sales\",\"tableName\":\"Orders\",\"objectId\":277576027,\"createDate\":\"2023-06-01T10:15:00\",\"modifyDate\":\"2024-03-20T16:45:33\",\"typeDesc\":\"USER_TABLE\",\"rowsCount\":45678}]"
    }
  ]
}
```

## Використання з MCP Client

### В AI асистенті

```
Покажи мені всі таблиці в базі даних AdventureWorks
```

```
Які таблиці починаються з "Product" в базі AdventureWorks?
```

### Обробка в PowerShell

```powershell
# Виконання процедури
$result = Invoke-DbaQuery -SqlInstance "localhost" -Database "Utils" `
    -Query "EXEC mcp.GetTables @database = 'AdventureWorks', @filter = 'Sales%'"

# Парсинг JSON
$mcpResponse = $result.result | ConvertFrom-Json
$tables = $mcpResponse.content[0].text | ConvertFrom-Json

# Вивід таблиць з найбільшою кількістю рядків
$tables | Sort-Object -Property rowsCount -Descending | 
    Select-Object -First 10 |
    Format-Table schemaName, tableName, rowsCount, modifyDate
```

### Обробка в Python

```python
import pyodbc
import json

conn = pyodbc.connect('DRIVER={SQL Server};SERVER=localhost;DATABASE=Utils;Trusted_Connection=yes')
cursor = conn.cursor()

# Виконання з фільтром
cursor.execute("EXEC mcp.GetTables @database = ?, @filter = ?", 'AdventureWorks', 'Sales%')
result = cursor.fetchone()[0]

# Парсинг
mcp_response = json.loads(result)
tables = json.loads(mcp_response['content'][0]['text'])

# Аналіз
total_rows = sum(t['rowsCount'] for t in tables)
print(f"Знайдено таблиць: {len(tables)}")
print(f"Всього рядків: {total_rows}")

for table in tables:
    print(f"{table['schemaName']}.{table['tableName']}: {table['rowsCount']:,} rows")
```

## Примітки

1. **Фільтрація**:
   - Фільтр використовує LIKE pattern
   - Пусті рядки та NULL трактуються як "всі таблиці"
   - Фільтр застосовується лише до назви таблиці, не схеми

2. **Кількість рядків**:
   - Отримується з sys.partitions (індекси 0 та 1)
   - Для партиційованих таблиць - сума по всіх партиціях
   - Може не бути точною для дуже великих таблиць

3. **Виключення**:
   - Системні таблиці (is_ms_shipped = 0) не включаються
   - Тільки USER_TABLE об'єкти

4. **Права доступу**:
   - Користувач повинен мати VIEW DEFINITION на базу даних
   - Або бути членом db_datareader або вищих ролей

5. **Продуктивність**:
   - Для баз даних з великою кількістю таблиць використовуйте фільтр
   - JOIN з sys.partitions може бути ресурсномістким

## Динамічний SQL

Процедура використовує динамічний SQL (sp_executesql) для виконання запиту в контексті вказаної бази даних:

```sql
USE [TargetDatabase];
-- Запит виконується тут
```

Це дозволяє отримувати дані з будь-якої бази даних без необхідності змінювати контекст підключення.

## Використання в MCP серверах

### Tool Definition

```json
{
  "name": "GetTables",
  "description": "Процедура для отримання списку таблиць через MCP протокол",
  "inputSchema": {
    "type": "object",
    "properties": {
      "database": {
        "type": "string",
        "description": "Назва бази даних"
      },
      "filter": {
        "type": "string",
        "description": "Фільтр за назвою таблиці (LIKE pattern)"
      }
    },
    "required": ["database"]
  }
}
```

## Пов'язані об'єкти

- `mcp.GetTableInfo` - детальна інформація про конкретну таблицю
- `mcp.GetViews` - отримання списку представлень
- `mcp.GetDatabases` - отримання списку баз даних
- `util.tablesGetIndexedColumns` - аналіз індексованих колонок
- `util.tablesGetScript` - генерація DDL таблиці

## Вихідний код

Розташування: `/mcp/Procedures/GetTables.sql`

## Див. також

- [Огляд схеми mcp](../README.md)
- [Список всіх MCP об'єктів](../objects-list.md)
- [mcp.GetTableInfo](GetTableInfo.md)
- [mcp.GetDatabases](GetDatabases.md)
- [Інструкції по розгортанню](../../deploy.md)

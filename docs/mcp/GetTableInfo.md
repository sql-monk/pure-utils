# mcp.GetTableInfo

## Опис

Процедура для отримання детальної інформації про таблицю через MCP протокол. Повертає валідний JSON з повною інформацією про структуру таблиці, включаючи колонки, індекси, партиції, та статистику використання простору.

## Синтаксис

```sql
EXEC mcp.GetTableInfo 
    @database = '<database_name>',
    @table = '<table_name>';
```

## Параметри

| Параметр | Тип | Обов'язковий | Опис |
|----------|-----|--------------|------|
| `@database` | NVARCHAR(128) | Так | Назва бази даних |
| `@table` | NVARCHAR(128) | Так | Назва таблиці (може бути у форматі schema.table або просто table) |

## Повертає

**Тип:** JSON string  
**Формат:** MCP response з детальною інформацією про таблицю

### Структура відповіді

```json
{
  "content": [
    {
      "type": "text",
      "text": "{\"tableName\":\"...\",\"description\":\"...\",\"createDate\":\"...\",\"rowsCount\":...,\"columns\":[...],\"indexes\":[...]}"
    }
  ]
}
```

### Основні поля

| Поле | Тип | Опис |
|------|-----|------|
| `tableName` | string | Повна назва таблиці (schema.table) |
| `description` | string | Опис таблиці з extended properties |
| `createDate` | string (ISO 8601) | Дата створення таблиці |
| `modifyDate` | string (ISO 8601) | Дата останньої модифікації |
| `rowsCount` | int | Кількість рядків |
| `columns` | array | Масив об'єктів з інформацією про колонки |
| `indexes` | array | Масив об'єктів з інформацією про індекси |

### Структура об'єкта Column

```json
{
  "name": "UserId",
  "dataType": "int",
  "isNullable": false,
  "isIdentity": true,
  "isComputed": false,
  "defaultValue": null,
  "description": "Унікальний ідентифікатор користувача"
}
```

### Структура об'єкта Index

```json
{
  "name": "PK_Users",
  "type": "CLUSTERED",
  "isUnique": true,
  "isPrimaryKey": true,
  "columns": ["UserId"],
  "includedColumns": [],
  "filter": null,
  "partitions": [{"partition_number": 1}],
  "spaceUsed": {
    "totalSpaceMB": 125.50,
    "usedSpaceMB": 98.25,
    "dataSpaceMB": 95.00
  }
}
```

## Приклади

### Базове використання

```sql
-- З повною назвою (schema.table)
EXEC mcp.GetTableInfo 
    @database = 'AdventureWorks',
    @table = 'Sales.SalesOrderHeader';

-- Тільки назва таблиці (пошук в усіх схемах)
EXEC mcp.GetTableInfo 
    @database = 'AdventureWorks',
    @table = 'SalesOrderHeader';
```

### Результат (скорочений приклад)

```json
{
  "content": [
    {
      "type": "text",
      "text": "{\"tableName\":\"Sales.SalesOrderHeader\",\"description\":\"General sales order information\",\"createDate\":\"2023-01-15T10:30:00\",\"modifyDate\":\"2024-02-20T14:22:11\",\"rowsCount\":31465,\"columns\":[{\"name\":\"SalesOrderID\",\"dataType\":\"int\",\"isNullable\":false,\"isIdentity\":true,\"isComputed\":false,\"defaultValue\":null,\"description\":\"Primary key\"},{\"name\":\"OrderDate\",\"dataType\":\"datetime\",\"isNullable\":false,\"isIdentity\":false,\"isComputed\":false,\"defaultValue\":\"(getdate())\",\"description\":\"Order date\"}],\"indexes\":[{\"name\":\"PK_SalesOrderHeader_SalesOrderID\",\"type\":\"CLUSTERED\",\"isUnique\":true,\"isPrimaryKey\":true,\"columns\":[\"SalesOrderID\"],\"includedColumns\":[],\"filter\":null,\"partitions\":[{\"partition_number\":1}],\"spaceUsed\":{\"totalSpaceMB\":12.5,\"usedSpaceMB\":10.2,\"dataSpaceMB\":9.8}}]}"
    }
  ]
}
```

## Використання з MCP Client

### В AI асистенті

```
Покажи мені детальну інформацію про таблицю Sales.SalesOrderHeader в базі AdventureWorks
```

```
Які колонки має таблиця Users?
```

### Обробка в PowerShell

```powershell
# Виконання
$result = Invoke-DbaQuery -SqlInstance "localhost" -Database "Utils" `
    -Query "EXEC mcp.GetTableInfo @database = 'AdventureWorks', @table = 'Sales.SalesOrderHeader'"

# Парсинг
$mcpResponse = $result.result | ConvertFrom-Json
$tableInfo = $mcpResponse.content[0].text | ConvertFrom-Json

# Вивід колонок
Write-Host "Таблиця: $($tableInfo.tableName)"
Write-Host "Рядків: $($tableInfo.rowsCount)"
Write-Host "`nКолонки:"
$tableInfo.columns | Format-Table name, dataType, isNullable, isIdentity

# Вивід індексів
Write-Host "`nІндекси:"
$tableInfo.indexes | ForEach-Object {
    Write-Host "$($_.name) - $($_.type) - Колонки: $($_.columns -join ', ')"
}
```

### Обробка в Python

```python
import pyodbc
import json
import pandas as pd

conn = pyodbc.connect('DRIVER={SQL Server};SERVER=localhost;DATABASE=Utils;Trusted_Connection=yes')
cursor = conn.cursor()

# Виконання
cursor.execute("""
    EXEC mcp.GetTableInfo 
        @database = ?, 
        @table = ?
""", 'AdventureWorks', 'Sales.SalesOrderHeader')

result = cursor.fetchone()[0]

# Парсинг
mcp_response = json.loads(result)
table_info = json.loads(mcp_response['content'][0]['text'])

# Аналіз колонок
columns_df = pd.DataFrame(table_info['columns'])
print(f"Таблиця: {table_info['tableName']}")
print(f"Рядків: {table_info['rowsCount']:,}")
print("\nКолонки:")
print(columns_df[['name', 'dataType', 'isNullable', 'isIdentity']])

# Аналіз індексів
print("\nІндекси:")
for idx in table_info['indexes']:
    space_mb = idx['spaceUsed']['totalSpaceMB']
    print(f"{idx['name']}: {idx['type']}, {space_mb:.2f} MB")
```

## Примітки

1. **Пошук таблиці**:
   - Якщо вказано schema.table - пошук точний
   - Якщо тільки table - пошук в усіх схемах
   - Повертається перша знайдена таблиця

2. **Колонки**:
   - Включає всі типи даних з точністю та розміром
   - Computed колонки позначені окремо
   - Описи колонок з extended properties

3. **Індекси**:
   - Інформація про всі індекси таблиці
   - Включає партиції та їх розміри
   - Статистика використання простору

4. **Опис таблиці**:
   - Отримується через `util.metadataGetObjectName`
   - Використовує extended properties (MS_Description)

5. **Продуктивність**:
   - Для великих таблиць запит може виконуватись довго
   - Розрахунок розміру партицій ресурсномісткий

## Використання в MCP серверах

### Tool Definition

```json
{
  "name": "GetTableInfo",
  "description": "Процедура для отримання детальної інформації про таблицю",
  "inputSchema": {
    "type": "object",
    "properties": {
      "database": {
        "type": "string",
        "description": "Назва бази даних"
      },
      "table": {
        "type": "string",
        "description": "Назва таблиці (schema.table або table)"
      }
    },
    "required": ["database", "table"]
  }
}
```

## Пов'язані об'єкти

- `mcp.GetTables` - отримання списку таблиць
- `util.tablesGetScript` - генерація DDL таблиці
- `util.tablesGetIndexedColumns` - аналіз індексованих колонок
- `util.metadataGetColumns` - детальна інформація про колонки
- `util.indexesGetSpaceUsedDetailed` - детальна статистика індексів

## Вихідний код

Розташування: `/mcp/Procedures/GetTableInfo.sql`

## Див. також

- [Огляд схеми mcp](../README.md)
- [Список всіх MCP об'єктів](../objects-list.md)
- [mcp.GetTables](GetTables.md)
- [mcp.GetDatabases](GetDatabases.md)
- [Інструкції по розгортанню](../../deploy.md)

# mcp.GetDatabases

## Опис

Процедура для отримання списку всіх баз даних на SQL Server інстансі через MCP протокол. Повертає валідний JSON для MCP відповіді з повною інформацією про кожну базу даних.

## Синтаксис

```sql
EXEC mcp.GetDatabases;
```

## Параметри

Процедура не має параметрів.

## Повертає

**Тип:** JSON string  
**Формат:** MCP response з масивом content

### Структура відповіді

```json
{
  "content": [
    {
      "type": "text",
      "text": "[{\"name\":\"...\",\"databaseId\":...,\"createDate\":\"...\", ...}]"
    }
  ]
}
```

### Поля в JSON масиві баз даних

| Поле | Тип | Опис |
|------|-----|------|
| `name` | string | Назва бази даних |
| `databaseId` | int | ID бази даних |
| `createDate` | string (ISO 8601) | Дата створення бази даних |
| `compatibilityLevel` | int | Рівень сумісності (90, 100, 110, 120, 130, 140, 150, 160) |
| `isReadOnly` | boolean | Чи база даних тільки для читання |
| `stateDesc` | string | Стан бази даних (ONLINE, OFFLINE, RESTORING, тощо) |
| `snapshotIsolationStateDesc` | string | Стан snapshot isolation |
| `isReadCommittedSnapshotOn` | boolean | Чи увімкнено Read Committed Snapshot |
| `isBrokerEnabled` | boolean | Чи увімкнено Service Broker |
| `recoveryModelDesc` | string | Модель відновлення (SIMPLE, FULL, BULK_LOGGED) |
| `isPublished` | boolean | Чи база даних публікується (replication) |
| `isTrustworthyOn` | boolean | Чи база даних має TRUSTWORTHY ON |

## Приклади

### Базове використання

```sql
EXEC mcp.GetDatabases;
```

**Результат:**
```json
{
  "content": [
    {
      "type": "text",
      "text": "[{\"name\":\"master\",\"databaseId\":1,\"createDate\":\"2023-01-15T10:30:00\",\"compatibilityLevel\":150,\"isReadOnly\":false,\"stateDesc\":\"ONLINE\",\"recoveryModelDesc\":\"SIMPLE\",\"isPublished\":false,\"isTrustworthyOn\":true},{\"name\":\"tempdb\",\"databaseId\":2,\"createDate\":\"2024-01-10T08:15:23\",\"compatibilityLevel\":150,\"isReadOnly\":false,\"stateDesc\":\"ONLINE\",\"recoveryModelDesc\":\"SIMPLE\",\"isPublished\":false,\"isTrustworthyOn\":false}]"
    }
  ]
}
```

### Використання з MCP Client

В AI асистенті (через MCP client):
```
Покажи мені список всіх баз даних на сервері
```

AI виконає:
```sql
EXEC mcp.GetDatabases;
```

Та поверне відформатовану інформацію про бази даних.

### Обробка результату в PowerShell

```powershell
# Виконання процедури
$result = Invoke-DbaQuery -SqlInstance "localhost" -Database "Utils" -Query "EXEC mcp.GetDatabases"

# Парсинг JSON
$mcpResponse = $result.result | ConvertFrom-Json
$databases = $mcpResponse.content[0].text | ConvertFrom-Json

# Вивід інформації
$databases | Format-Table name, databaseId, stateDesc, recoveryModelDesc
```

### Обробка результату в Python

```python
import pyodbc
import json

# Підключення до SQL Server
conn = pyodbc.connect('DRIVER={SQL Server};SERVER=localhost;DATABASE=Utils;Trusted_Connection=yes')
cursor = conn.cursor()

# Виконання процедури
cursor.execute("EXEC mcp.GetDatabases")
result = cursor.fetchone()[0]

# Парсинг JSON
mcp_response = json.loads(result)
databases = json.loads(mcp_response['content'][0]['text'])

# Обробка даних
for db in databases:
    print(f"{db['name']} - {db['stateDesc']} - {db['recoveryModelDesc']}")
```

## Примітки

1. **Права доступу**: Користувач повинен мати права VIEW ANY DATABASE або бути членом ролі sysadmin
2. **Системні бази даних**: Результат включає системні бази даних (master, model, msdb, tempdb)
3. **Сортування**: Бази даних відсортовані за назвою (ORDER BY name)
4. **Формат дати**: Дати повертаються в ISO 8601 форматі (YYYY-MM-DDTHH:MM:SS)

## Використання в MCP серверах

Процедура автоматично реєструється як MCP tool в наступних серверах:
- **PureSqlsMcp** - консольний MCP сервер
- **PureSqlsMcpWeb** - веб-базований MCP сервер

### Tool Definition

```json
{
  "name": "GetDatabases",
  "description": "Процедура для отримання списку баз даних через MCP протокол",
  "inputSchema": {
    "type": "object",
    "properties": {},
    "required": []
  }
}
```

## Пов'язані об'єкти

- `mcp.GetTables` - отримання списку таблиць в базі даних
- `mcp.GetViews` - отримання списку представлень
- `mcp.GetFunctions` - отримання списку функцій
- `mcp.GetProcedures` - отримання списку процедур

## Вихідний код

Розташування: `/mcp/Procedures/GetDatabases.sql`

```sql
CREATE OR ALTER PROCEDURE mcp.GetDatabases
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @databases NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);

    -- Формуємо JSON з інформацією про бази даних
    SELECT @databases = (
        SELECT
            name,
            database_id AS databaseId,
            CONVERT(VARCHAR(23), create_date, 126) AS createDate,
            compatibility_level AS compatibilityLevel,
            is_read_only AS isReadOnly,
            state_desc AS stateDesc,
            snapshot_isolation_state_desc AS snapshotIsolationStateDesc,
            is_read_committed_snapshot_on AS isReadCommittedSnapshotOn,
            is_broker_enabled AS isBrokerEnabled,
            recovery_model_desc AS recoveryModelDesc,
            is_published AS isPublished,
            is_trustworthy_on AS isTrustworthyOn
        FROM sys.databases
        ORDER BY name
        FOR JSON PATH
    );

    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (
        SELECT
            'text' AS [type],
            @databases AS [text]
        FOR JSON PATH
    );

    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');

    SELECT @result AS result;
END;
```

## Див. також

- [Огляд схеми mcp](../README.md)
- [Список всіх MCP об'єктів](../objects-list.md)
- [mcp.GetTables](GetTables.md)
- [Інструкції по розгортанню](../../deploy.md)

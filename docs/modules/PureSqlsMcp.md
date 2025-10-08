# PureSqlsMcp - Сервер метаданих для AI-інтеграції

## Огляд

**PureSqlsMcp** — це .NET 8 консольна програма, яка реалізує Model Context Protocol (MCP) сервер для динамічної роботи з метаданими SQL Server через AI-асистентів.

## Основні можливості

- **Динамічна генерація MCP tools** з процедур схеми mcp
- **Автоматичне витягування параметрів** та типів з SQL Server
- **Підтримка JSON-RPC 2.0** через stdio
- **Інтеграція з Claude Desktop, GitHub Copilot** та іншими MCP клієнтами
- **Self-contained deployment** - не потребує встановленого .NET Runtime

## Архітектура

```
┌─────────────────────────────────────────┐
│   AI-асистент (Copilot)                 │
└──────────────┬──────────────────────────┘
               │ stdio (JSON-RPC 2.0)
               ▼
┌─────────────────────────────────────────┐
│   PureSqlsMcp.exe                       │
│   ┌─────────────────────────────────┐   │
│   │  MCP Server Handler             │   │
│   │  - tools/list                   │   │
│   │  - tools/call                   │   │
│   └─────────────────────────────────┘   │
│               │                         │
│               ▼                         │
│   ┌─────────────────────────────────┐   │
│   │  SQL Dynamic Tool Generator     │   │
│   │  - Сканує mcp.* процедури       │   │
│   │  - Витягує параметри            │   │
│   │  - Генерує JSON schema          │   │
│   └─────────────────────────────────┘   │
└──────────────┬──────────────────────────┘
               │ ADO.NET (SqlClient)
               ▼
┌─────────────────────────────────────────┐
│   SQL Server Database                   │
│   ┌─────────────────────────────────┐   │
│   │  Схема mcp                      │   │
│   │  - GetDatabases                 │   │
│   │  - GetTables                    │   │
│   │  - GetTableInfo                 │   │
│   │  - ScriptObjectAndReferences    │   │
│   │  - etc.                         │   │
│   └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

## Встановлення

### Вимоги

- **.NET SDK 8.0** (для компіляції)
- **SQL Server** з розгорнутою схемою mcp
- **Права доступу** до SQL Server (Windows Authentication або SQL Authentication)

### Компіляція

Використовуйте PowerShell скрипт `build.ps1`:

```powershell
cd PureSqlsMcp
.\build.ps1
```

Скрипт:
1. Перевіряє наявність .NET SDK 8.0
2. Виконує `dotnet publish` з self-contained конфігурацією
3. Створює виконуваний файл у `bin\Release\net8.0\win-x64\publish\PureSqlsMcp.exe`

### Ручна компіляція

```bash
dotnet publish -c Release -r win-x64 --self-contained true `
    -p:PublishSingleFile=true -p:PublishTrimmed=false
```

**Параметри**:
- `-r win-x64` - платформа Windows x64
- `--self-contained true` - включає .NET runtime
- `-p:PublishSingleFile=true` - один виконуваний файл
- `-p:PublishTrimmed=false` - без trimming (для сумісності)

## Конфігурація

### Параметри командного рядка

```bash
PureSqlsMcp.exe --server <server> --database <database> [options]
```

**Обов'язкові параметри**:
- `--server` - ім'я SQL Server (наприклад, `localhost`, `.\SQLEXPRESS`, `server.domain.com`)
- `--database` - ім'я бази даних з розгорнутою схемою mcp

**Опціональні параметри**:
- `--integrated-security` - використовувати Windows Authentication (за замовчуванням `true`)
- `--user-id` - SQL Server login (для SQL Authentication)
- `--password` - пароль (для SQL Authentication)

### Приклади запуску

**Windows Authentication**:
```bash
PureSqlsMcp.exe --server localhost --database master
```

**SQL Authentication**:
```bash
PureSqlsMcp.exe --server localhost --database master `
    --integrated-security false --user-id sa --password MyPassword123
```

**Віддалений сервер**:
```bash
PureSqlsMcp.exe --server sql-server.company.com --database Production
```

## Інтеграція
Claude Desktop, GitHub Copilot (VS, VSCode)

### Конфігурація .mcp

**Розташування файлу**:
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`

**Приклад конфігурації**:
```json
{
  "mcpServers": {
    "puresqls": {
      "command": "C:\\path\\to\\PureSqlsMcp.exe",
      "args": [
        "--server", "localhost",
        "--database", "master"
      ]
    }
  }
}
```

**З SQL Authentication**:
```json
{
  "mcpServers": {
    "puresqls": {
      "command": "C:\\tools\\PureSqlsMcp.exe",
      "args": [
        "--server", "sql-server.company.com",
        "--database", "Production",
        "--integrated-security", "false",
        "--user-id", "app_user",
        "--password", "SecurePassword123"
      ]
    }
  }
}
```

### Перевірка підключення

Після налаштування Claude Desktop:
1. Перезапустіть Claude Desktop
2. У діалозі запитайте: "Які бази даних доступні?"
3. Claude повинен викликати tool `GetDatabases` та показати результат

## Як працює динамічна генерація tools

### 1. Ініціалізація сервера

При старті PureSqlsMcp:
1. Підключається до SQL Server
2. Виконує запит для отримання всіх процедур схеми mcp:
```sql
SELECT 
    p.name,
    p.object_id
FROM sys.procedures p
    JOIN sys.schemas s ON p.schema_id = s.schema_id
WHERE s.name = 'mcp'
```

### 2. Витягування параметрів

Для кожної процедури викликає `util.mcpGetObjectParameters`:
```sql
SELECT * FROM util.mcpGetObjectParameters(@objectId);
```

Повертає:
- ParameterName
- DataType
- IsNullable
- DefaultValue

### 3. Генерація JSON schema

Викликає `util.mcpBuildToolJson` для генерації MCP tool metadata:
```sql
SELECT * FROM util.mcpBuildToolJson(@objectId);
```

Повертає JSON:
```json
{
  "name": "GetTableInfo",
  "description": "Детальна інформація про структуру таблиці",
  "inputSchema": {
    "type": "object",
    "properties": {
      "database": {
        "type": "string",
        "description": "Назва бази даних"
      },
      "schema": {
        "type": "string",
        "description": "Назва схеми"
      },
      "table": {
        "type": "string",
        "description": "Назва таблиці"
      }
    },
    "required": ["table"]
  }
}
```

### 4. Реєстрація tools

Кожна процедура реєструється як MCP tool і доступна для AI-асистента.

### 5. Виконання tool call

При виклику tool від AI:
1. PureSqlsMcp отримує JSON-RPC запит
2. Парсить назву процедури та параметри
3. Викликає відповідну процедуру mcp:
```sql
EXEC mcp.GetTableInfo @database = 'master', @schema = 'sys', @table = 'tables';
```
4. Отримує JSON відповідь
5. Повертає результат AI-асистенту

## Структура коду

### Program.cs

**Призначення**: Entry point програми

```csharp
// Парсинг аргументів командного рядка
var server = args.GetValue("--server");
var database = args.GetValue("--database");

// Створення та запуск MCP сервера
var mcpServer = new PureMcpServer(server, database);
await mcpServer.RunAsync();
```

### PureSqlsMcpServer.cs

**Клас PureMcpServer**

**Основні методи**:

#### `RunAsync()`
Головний цикл обробки JSON-RPC повідомлень

#### `HandleRequest(JsonRpcRequest request)`
Маршрутизація запитів до відповідних обробників

#### `HandleToolsList()`
Повертає список всіх доступних tools

**Алгоритм**:
1. Запит до SQL Server для отримання процедур mcp
2. Для кожної процедури генерація JSON schema
3. Формування JSON-RPC відповіді

#### `HandleToolCall(string toolName, JsonElement arguments)`
Виконання виклику конкретного tool

**Алгоритм**:
1. Парсинг параметрів з JSON
2. Формування SQL команди `EXEC mcp.[toolName] @param1 = value1, ...`
3. Виконання через `SqlCommand`
4. Читання JSON результату
5. Формування MCP відповіді

#### `LoadToolsFromDatabase()`
Завантаження metadata про tools

```csharp
private async Task LoadToolsFromDatabase()
{
    var tools = new List<ToolMetadata>();
    
    using var connection = new SqlConnection(_connectionString);
    await connection.OpenAsync();
    
    // Отримати всі процедури mcp
    var proceduresQuery = @"
        SELECT p.name, p.object_id
        FROM sys.procedures p
        JOIN sys.schemas s ON p.schema_id = s.schema_id
        WHERE s.name = 'mcp'";
    
    using var cmd = new SqlCommand(proceduresQuery, connection);
    using var reader = await cmd.ExecuteReaderAsync();
    
    while (await reader.ReadAsync())
    {
        var toolName = reader.GetString(0);
        var objectId = reader.GetInt32(1);
        
        // Генерувати JSON schema для tool
        var toolJson = await GetToolJsonSchema(objectId);
        tools.Add(toolJson);
    }
    
    return tools;
}
```

## Логування та діагностика

### Debug mode

Для увімкнення детального логування використовуйте змінну середовища:

```bash
set DEBUG=true
PureSqlsMcp.exe --server localhost --database master
```

### Логи

Логи записуються у `stderr`:
- Запити JSON-RPC
- Виклики SQL процедур
- Помилки підключення
- Результати виконання

### Типові помилки

**Помилка підключення до SQL Server**:
```
Error: Cannot connect to SQL Server 'localhost'
```
**Рішення**: Перевірте ім'я сервера, права доступу, firewall

**Процедура mcp не знайдена**:
```
Error: Procedure 'mcp.GetTables' not found
```
**Рішення**: Розгорніть схему mcp через `deployUtil.ps1`

**Помилка парсингу JSON**:
```
Error: Invalid JSON in response from 'mcp.GetTableInfo'
```
**Рішення**: Перевірте, що процедура повертає валідний JSON

## Розширення функціональності

### Додавання нового tool

1. Створіть процедуру у схемі mcp:
```sql
CREATE PROCEDURE mcp.MyNewTool
    @param1 NVARCHAR(128),
    @param2 INT = NULL
AS
BEGIN
    -- Ваша логіка
    
    -- Поверніть JSON у форматі MCP
    DECLARE @result NVARCHAR(MAX);
    SET @result = (SELECT 'text' AS [type], 'data' AS [text] FOR JSON PATH);
    SELECT @result AS content FOR JSON PATH, INCLUDE_NULL_VALUES;
END;
```

2. Додайте структуровані коментарі:
```sql
/*
# Description
Опис того що робить процедура

# Parameters
@param1 NVARCHAR(128) - опис параметра
@param2 INT - опис параметра (опціональний)
*/
```

3. Перезапустіть PureSqlsMcp - tool з'явиться автоматично

### Кастомна обробка помилок

Модифікуйте `PureSqlsMcpServer.cs`:

```csharp
private async Task<JsonRpcResponse> HandleToolCall(...)
{
    try
    {
        // Виконання SQL
        var result = await ExecuteSqlProcedure(...);
        return CreateSuccessResponse(result);
    }
    catch (SqlException ex)
    {
        // Логування помилки
        LogError(ex);
        
        // Повернення помилки у форматі MCP
        return CreateErrorResponse(ex.Message);
    }
}
```

## Продуктивність

### Кешування metadata

Tools metadata кешується при старті:
- Завантажується один раз при ініціалізації
- Зберігається у пам'яті
- Не потребує повторних запитів до SQL

### Connection pooling

ADO.NET автоматично керує connection pool:
- Мінімум: 0 з'єднань
- Максимум: 100 з'єднань
- Timeout: 15 секунд

### Оптимізація запитів

- Використовуйте prepared statements
- Обмежуйте розмір результатів
- Уникайте довгих транзакцій

## Безпека

### Рекомендації

1. **Використовуйте Windows Authentication** де можливо
2. **Створіть окремого SQL користувача** з мінімальними правами:
```sql
CREATE LOGIN mcp_reader WITH PASSWORD = 'SecurePassword123';
CREATE USER mcp_reader FOR LOGIN mcp_reader;
GRANT EXECUTE ON SCHEMA::mcp TO mcp_reader;
GRANT SELECT ON SCHEMA::util TO mcp_reader;
```

3. **Не зберігайте паролі** у відкритому вигляді в конфігурації


## Best Practices

1. **Тестуйте процедури mcp** окремо через T-SQL перед використанням з AI
2. **Додавайте детальні коментарі** для кращого розуміння AI
3. **Обмежуйте розмір результатів** для швидшої відповіді

## Troubleshooting

### Tool не з'являється у списку

1. Перевірте, що процедура у схемі mcp
2. Перезапустіть PureSqlsMcp
3. Перевірте логи на помилки

### JSON відповідь некоректна

1. Протестуйте процедуру через SSMS
2. Перевірте формат JSON (має бути валідний)
3. Переконайтеся, що повертається `content` array

### Повільна робота

1. Перевірте навантаження на SQL Server
2. Оптимізуйте util функції
3. Додайте індекси на таблиці util
4. Обмежте розмір результатів

## Наступні кроки

- [PlanSqlsMcp сервер](PlanSqlsMcp.md)
- [MCP процедури](mcp.md)
- [Конфігурація](../config.md)
- [Приклади використання](../examples.md)

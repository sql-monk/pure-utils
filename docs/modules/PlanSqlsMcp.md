# PlanSqlsMcp - Сервер аналізу планів виконання

## Огляд

**PlanSqlsMcp** — це .NET 8 консольна програма, яка реалізує Model Context Protocol (MCP) сервер для отримання та аналізу estimated execution plans SQL запитів через AI-асистентів.

## Основні можливості

- **Отримання estimated execution plans** у форматі XML
- **Автоматичне очищення** запитів від службових команд SHOWPLAN
- **Підтримка батчів** та складних запитів
- **Інтеграція з Claude Desktop** через MCP
- **Безпечне виконання** без зміни даних (тільки estimated plans)

## Архітектура

```
┌─────────────────────────────────────────┐
│   AI-асистент (Claude Desktop)          │
└──────────────┬──────────────────────────┘
               │ stdio (JSON-RPC 2.0)
               ▼
┌─────────────────────────────────────────┐
│   PlanSqlsMcp.exe                       │
│   ┌─────────────────────────────────┐   │
│   │  MCP Server Handler             │   │
│   │  - Tool: GetEstimatedPlan       │   │
│   └─────────────────────────────────┘   │
│               │                          │
│               ▼                          │
│   ┌─────────────────────────────────┐   │
│   │  Query Processor                │   │
│   │  - Видалення SET SHOWPLAN_*     │   │
│   │  - Розбиття на батчі           │   │
│   │  - Збір планів для кожного     │   │
│   └─────────────────────────────────┘   │
└──────────────┬──────────────────────────┘
               │ ADO.NET (SqlClient)
               │ SET SHOWPLAN_XML ON
               ▼
┌─────────────────────────────────────────┐
│   SQL Server                            │
│   - Генерація estimated plans          │
│   - Повернення XML                     │
└─────────────────────────────────────────┘
```

## Встановлення

### Вимоги

- **.NET SDK 8.0** (для компіляції)
- **SQL Server** з доступом до цільової бази даних
- **Права VIEW DEFINITION** на об'єкти

### Компіляція

Використовуйте PowerShell скрипт `build.ps1`:

```powershell
cd PlanSqlsMcp
.\build.ps1
```

Скрипт виконує:
1. Перевірку .NET SDK 8.0
2. `dotnet publish` з self-contained конфігурацією
3. Створення `bin\Release\net8.0\win-x64\publish\PlanSqlsMcp.exe`

### Ручна компіляція

```bash
dotnet publish -c Release -r win-x64 --self-contained true `
    -p:PublishSingleFile=true -p:PublishTrimmed=false
```

## Конфігурація

### Параметри командного рядка

```bash
PlanSqlsMcp.exe --server <server> --database <database> [options]
```

**Обов'язкові параметри**:
- `--server` - ім'я SQL Server
- `--database` - ім'я бази даних

**Опціональні параметри**:
- `--integrated-security` - Windows Authentication (за замовчуванням `true`)
- `--user-id` - SQL Server login
- `--password` - пароль

### Приклади запуску

**Windows Authentication**:
```bash
PlanSqlsMcp.exe --server localhost --database AdventureWorks
```

**SQL Authentication**:
```bash
PlanSqlsMcp.exe --server localhost --database AdventureWorks `
    --integrated-security false --user-id app_user --password Pass123
```

## Інтеграція 
`Claude Desktop, GitHub Copilot (VS, VSCode)`

### Конфігурація .mcp

```json
{
  "mcpServers": {
    "showplan": {
      "command": "C:\\path\\to\\PlanSqlsMcp.exe",
      "args": [
        "--server", "localhost",
        "--database", "master"
      ]
    }
  }
}
```

### Приклад використання

**Користувач**: "Отримай execution plan для запиту SELECT * FROM sys.tables"

**Claude викликає**:
```
GetEstimatedPlan(query="SELECT * FROM sys.tables")
```

**Відповідь**: XML з estimated execution plan

## MCP Tool: GetEstimatedPlan

### Опис

Отримує estimated execution plan для SQL запиту без його виконання.

### Сигнатура

```json
{
  "name": "GetEstimatedPlan",
  "description": "Get estimated execution plan for SQL query in XML format",
  "inputSchema": {
    "type": "object",
    "properties": {
      "query": {
        "type": "string",
        "description": "SQL query to get execution plan for"
      }
    },
    "required": ["query"]
  }
}
```


## Алгоритм роботи

### 1. Прийом запиту

Отримання JSON-RPC запиту від MCP клієнта:
```json
{
  "method": "tools/call",
  "params": {
    "name": "GetEstimatedPlan",
    "arguments": {
      "query": "SELECT * FROM sys.tables"
    }
  }
}
```

### 2. Очищення запиту

Видалення службових команд:
```csharp
private string CleanQuery(string query)
{
    var cleaned = query;
    
    // Видалити SET SHOWPLAN_XML ON/OFF
    cleaned = Regex.Replace(cleaned, 
        @"SET\s+SHOWPLAN_XML\s+(ON|OFF)", 
        "", 
        RegexOptions.IgnoreCase);
    
    // Видалити SET SHOWPLAN_ALL ON/OFF
    cleaned = Regex.Replace(cleaned, 
        @"SET\s+SHOWPLAN_ALL\s+(ON|OFF)", 
        "", 
        RegexOptions.IgnoreCase);
    
    // Видалити SET STATISTICS XML ON/OFF
    cleaned = Regex.Replace(cleaned, 
        @"SET\s+STATISTICS\s+XML\s+(ON|OFF)", 
        "", 
        RegexOptions.IgnoreCase);
    
    return cleaned.Trim();
}
```

### 3. Розбиття на батчі

SQL запити можуть містити кілька батчів (розділених `GO`):
```csharp
private List<string> SplitIntoBatches(string query)
{
    var batches = new List<string>();
    var lines = query.Split('\n');
    var currentBatch = new StringBuilder();
    
    foreach (var line in lines)
    {
        if (line.Trim().Equals("GO", StringComparison.OrdinalIgnoreCase))
        {
            if (currentBatch.Length > 0)
            {
                batches.Add(currentBatch.ToString());
                currentBatch.Clear();
            }
        }
        else
        {
            currentBatch.AppendLine(line);
        }
    }
    
    if (currentBatch.Length > 0)
    {
        batches.Add(currentBatch.ToString());
    }
    
    return batches;
}
```

### 4. Отримання планів

Для кожного батчу:
```csharp
private async Task<string> GetEstimatedPlan(string batch)
{
    using var connection = new SqlConnection(_connectionString);
    await connection.OpenAsync();
    
    // Увімкнути SHOWPLAN_XML
    using (var cmd = new SqlCommand("SET SHOWPLAN_XML ON", connection))
    {
        await cmd.ExecuteNonQueryAsync();
    }
    
    // Виконати запит (отримаємо план, не результат)
    using (var cmd = new SqlCommand(batch, connection))
    {
        using var reader = await cmd.ExecuteReaderAsync();
        
        if (await reader.ReadAsync())
        {
            var planXml = reader.GetString(0);
            return planXml;
        }
    }
    
    return null;
}
```

### 5. Формування відповіді

Збір усіх планів у JSON:
```csharp
var response = new
{
    content = new[]
    {
        new
        {
            type = "text",
            text = JsonSerializer.Serialize(new
            {
                query = originalQuery,
                batches = plans.Select((plan, index) => new
                {
                    batchNumber = index + 1,
                    planXml = plan
                })
            })
        }
    }
};
```

## Структура коду

### Program.cs

Entry point програми:
```csharp
public static async Task Main(string[] args)
{
    var server = ParseArg(args, "--server");
    var database = ParseArg(args, "--database");
    
    var mcpServer = new PlanMcpServer(server, database);
    await mcpServer.RunAsync();
}
```

### PlanSqlsMcpServer.cs

**Клас PlanMcpServer**

#### Основні методи

**`RunAsync()`** - головний цикл обробки JSON-RPC

**`HandleToolsList()`** - повертає опис tool GetEstimatedPlan

**`HandleGetEstimatedPlan(string query)`** - обробка запиту плану:
1. Очищення запиту
2. Розбиття на батчі
3. Отримання планів
4. Формування відповіді

## Обмеження

### SQL Server обмеження

- **Тільки estimated plans** - запити не виконуються
- **Потребує VIEW DEFINITION** на об'єкти
- **Не підтримує динамічний SQL** у повному обсязі
- **Обмеження на розмір плану** (XML може бути великим)

### MCP обмеження

- **Максимальний розмір відповіді** обмежений stdio buffer
- **Timeout** на довгі запити (можна налаштувати)

## Безпека

### Рекомендації

1. **Використовуйте read-only користувача**:
```sql
CREATE LOGIN plan_reader WITH PASSWORD = 'SecurePass123';
CREATE USER plan_reader FOR LOGIN plan_reader;
GRANT VIEW DEFINITION TO plan_reader;
GRANT VIEW SERVER STATE TO plan_reader;
```

2. **Обмежуйте доступ** до виконуваних файлів
3. **Не зберігайте паролі** у відкритому вигляді
4. **Аудитуйте запити** через Extended Events

### Безпечне виконання

PlanSqlsMcp **НЕ** виконує запити:
- Використовує `SET SHOWPLAN_XML ON`
- SQL Server генерує тільки план
- **Дані не змінюються**
- **Результати не повертаються**

## Troubleshooting

### Помилка: "Could not get execution plan"

**Причини**:
- Синтаксична помилка у запиті
- Відсутні права VIEW DEFINITION
- Об'єкт не існує

**Рішення**: Перевірте запит через SSMS з `SET SHOWPLAN_XML ON`

### Помилка: "Access denied"

**Рішення**: Надайте права VIEW DEFINITION та VIEW SERVER STATE

### План занадто великий

**Рішення**: 
- Спростіть запит
- Розбийте на менші частини
- Збільште timeout

## Best Practices

1. **Тестуйте запити** окремо перед отриманням плану
2. **Аналізуйте плани** для оптимізації


## Приклади аналізу планів

### Пошук Table Scans

AI може допомогти знайти неоптимальні операції:

**Запит**: "Покажи мені план для SELECT * FROM LargeTable WHERE Status = 'Active'"

**Аналіз плану**: 
- Table Scan (погано)
- Рекомендація: CREATE INDEX IX_LargeTable_Status

### Аналіз JOIN стратегій

**Запит**: "Отримай план для JOIN двох великих таблиць"

**Аналіз плану**:
- Hash Join vs Nested Loops
- Спіл у tempdb
- Рекомендації з оптимізації

### Виявлення missing indexes

З плану можна витягти рекомендації:
```xml
<MissingIndexes>
  <MissingIndexGroup Impact="95.5">
    <MissingIndex>
      <Column Name="Status" />
      <Include>
        <Column Name="OrderDate" />
      </Include>
    </MissingIndex>
  </MissingIndexGroup>
</MissingIndexes>
```

## Інтеграція з util функціями

Можна комбінувати з PureSqlsMcp:

1. Отримати список таблиць через `GetTables`
2. Згенерувати SELECT запити
3. Отримати плани через `GetEstimatedPlan`
4. Проаналізувати та оптимізувати

## Розширення функціональності

### Додавання actual execution plans

**Увага**: Потребує виконання запиту!

```csharp
// SET STATISTICS XML ON замість SHOWPLAN_XML
using (var cmd = new SqlCommand("SET STATISTICS XML ON", connection))
{
    await cmd.ExecuteNonQueryAsync();
}

using (var cmd = new SqlCommand(query, connection))
{
    await cmd.ExecuteNonQueryAsync(); // Виконується!
    
    // Читання результатів та планів
}
```

### Кешування планів

Для часто запитуваних планів:
```csharp
private Dictionary<string, string> _planCache = new();

private async Task<string> GetPlanWithCache(string query)
{
    var hash = GetQueryHash(query);
    
    if (_planCache.TryGetValue(hash, out var cachedPlan))
    {
        return cachedPlan;
    }
    
    var plan = await GetEstimatedPlan(query);
    _planCache[hash] = plan;
    
    return plan;
}
```

## Логування

### Debug mode

```bash
set DEBUG=true
PlanSqlsMcp.exe --server localhost --database master
```

Логує:
- Отримані запити
- Очищені запити
- Батчі
- Розмір планів
- Помилки

## Наступні кроки

- [PureSqlsMcp сервер](PureSqlsMcp.md)
- [Конфігурація MCP](../config.md)
- [Приклади оптимізації](../examples.md)
- [FAQ](../faq.md)

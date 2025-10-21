# PureSqlsApi

**PureSqlsApi** — тонкий REST API адаптер між HTTP-запитами та SQL-об'єктами (процедурами, функціями, представленнями) у схемі `api` бази даних SQL Server.

## Опис

Мікро-сервіс надає HTTP доступ до SQL-об'єктів зі схеми `api`, дозволяючи отримувати дані у форматі JSON для використання в d3.js та інших JavaScript фреймворках. Вся бізнес-логіка залишається в базі даних, C# шар лише маршрутизує запити та серіалізує відповіді.

## Архітектура

```
HTTP Client (Browser/d3.js)
    ↓
PureSqlsApi (ASP.NET Core Minimal API)
    ↓
SQL Server (схема api)
    - api.{resource}List() - table-valued functions
    - api.{resource}Get() - scalar functions
    - api.{procedure} - stored procedures
```

## Встановлення

### Вимоги

- .NET 8.0 SDK
- SQL Server з базою даних, що містить схему `api`
- Windows Authentication або SQL Server Authentication

### Збірка

```powershell
# Debug build
.\build.ps1

# Release build
.\build.ps1 -Release

# Publish self-contained executable
.\build.ps1 -Release -Publish
```

## Запуск

### Windows Authentication

```powershell
dotnet run -- --server localhost --database utils
```

### SQL Authentication

```powershell
dotnet run -- --server localhost --database utils --user sa
# Пароль буде запитано інтерактивно
```

### Кастомний порт

```powershell
dotnet run -- --server localhost --database utils --port 8080
```

### Запуск скомпільованого exe

```powershell
.\bin\Release\net8.0\win-x64\publish\PureSqlsApi.exe --server localhost --database utils
```

## CLI Параметри

| Параметр | Коротка форма | Опис | За замовчуванням |
|----------|---------------|------|------------------|
| `--server` | `-s` | SQL Server instance | (обов'язковий) |
| `--database` | `-d` | Ім'я бази даних | `msdb` |
| `--user` | `-u` | SQL користувач (якщо не вказано - Windows Auth) | - |
| `--port` | `-p` | HTTP порт | `51433` |
| `--help` | `-h` | Показати довідку | - |

## API Endpoints

### 1. GET `/{resource}/list`

Викликає table-valued function `api.{resource}List()` та повертає масив JSON-об'єктів.

**Приклади:**

```bash
# Всі бази даних
curl http://localhost:51433/databases/list

# Об'єкти конкретної схеми
curl "http://localhost:51433/objects/list?schema=dbo"

# Об'єкти конкретного типу
curl "http://localhost:51433/objects/list?type=U"
```

**Відповідь:**

```json
{
  "data": [
    {
      "databaseId": 1,
      "databaseName": "master",
      "stateDesc": "ONLINE",
      "recoveryModelDesc": "SIMPLE",
      "createDate": "2023-01-01T00:00:00"
    }
  ],
  "count": 1
}
```

### 2. GET `/{resource}/get`

Викликає scalar function `api.{resource}Get()` та повертає JSON-об'єкт.

**Приклади:**

```bash
# Детальна інформація про базу
curl "http://localhost:51433/databases/get?name=master"

# Детальна інформація про об'єкт
curl "http://localhost:51433/objects/get?id=123456"
```

**Відповідь:**

```json
{
  "databaseId": 1,
  "databaseName": "master",
  "stateDesc": "ONLINE",
  "recoveryModelDesc": "SIMPLE",
  "createDate": "2023-01-01T00:00:00",
  "compatibilityLevel": 160,
  "collationName": "SQL_Latin1_General_CP1_CI_AS",
  "sizeMB": 10.25
}
```

### 3. GET `/exec/{procedureName}`

Викликає stored procedure `api.{procedureName}` з OUTPUT параметром `@response`.

**Приклади:**

```bash
# Виконання процедури з параметрами
curl "http://localhost:51433/exec/doSomething?param1=value1&param2=value2"
```

**Відповідь:**

```json
{
  "status": "success",
  "message": "Operation completed"
}
```

## SQL Objects у схемі api

### Table-Valued Functions (для /list)

```sql
CREATE OR ALTER FUNCTION api.{resource}List(
    @param1 TYPE = NULL,
    @param2 TYPE = NULL
)
RETURNS TABLE
AS
RETURN(
    SELECT 
        column1,
        column2,
        column3
    FROM some_table
    WHERE (@param1 IS NULL OR column1 = @param1)
);
GO
```

### Scalar Functions (для /get)

```sql
CREATE OR ALTER FUNCTION api.{resource}Get(@id INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (
        SELECT 
            column1,
            column2,
            column3
        FROM some_table
        WHERE id = @id
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
END;
GO
```

### Stored Procedures (для /exec)

```sql
CREATE OR ALTER PROCEDURE api.{procedureName}
    @param1 TYPE,
    @param2 TYPE,
    @response NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Business logic here
    
    SET @response = (
        SELECT 
            'success' status,
            'Operation completed' message
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
END;
GO
```

## Інтеграція з d3.js

```javascript
// Завантаження списку баз даних
d3.json('http://localhost:51433/databases/list')
  .then(response => {
    console.log(`Loaded ${response.count} databases`);
    
    // Візуалізація даних
    d3.select('#chart')
      .selectAll('div')
      .data(response.data)
      .enter()
      .append('div')
      .text(d => d.databaseName);
  });

// Завантаження деталей конкретної бази
d3.json('http://localhost:51433/databases/get?name=master')
  .then(database => {
    console.log('Database size:', database.sizeMB, 'MB');
  });
```

## Обробка помилок

У разі помилки сервіс повертає HTTP 500 з JSON:

```json
{
  "error": "Invalid object name 'api.nonexistent'.",
  "type": "SqlException"
}
```

## Безпека

⚠️ **ВАЖЛИВО**: Цей сервіс призначений для локального використання та розробки. 

На production середовищі рекомендується:
- Додати автентифікацію (JWT, API Keys)
- Обмежити CORS
- Використовувати HTTPS
- Валідувати вхідні параметри
- Додати rate limiting

## Приклади використання

### Створення візуалізації бази даних

```html
<!DOCTYPE html>
<html>
<head>
    <script src="https://d3js.org/d3.v7.min.js"></script>
</head>
<body>
    <div id="databases"></div>
    
    <script>
        d3.json('http://localhost:51433/databases/list')
          .then(response => {
            d3.select('#databases')
              .selectAll('p')
              .data(response.data)
              .enter()
              .append('p')
              .text(d => `${d.databaseName} (${d.stateDesc})`);
          });
    </script>
</body>
</html>
```

## Структура проекту

```
PureSqlsApi/
├── Program.cs              # Entry point + API endpoints
├── SqlExecutor.cs          # SQL execution helper
├── PureSqlsApi.csproj     # Project file
├── build.ps1              # Build script
└── README.md              # Ця документація
```

## Troubleshooting

### Помилка підключення до SQL Server

```
ERROR: Cannot connect to SQL Server
```

**Рішення:**
- Перевірте, що SQL Server запущено
- Перевірте правильність імені сервера
- Перевірте credentials (user/password)
- Переконайтесь, що TCP/IP протокол увімкнено в SQL Server Configuration Manager

### Помилка "Invalid object name"

```json
{
  "error": "Invalid object name 'api.databasesList'.",
  "type": "SqlException"
}
```

**Рішення:**
- Перевірте, що схема `api` існує в базі даних
- Перевірте, що функція/процедура існує
- Перевірте правильність назви ресурсу в URL

## Ліцензія

Частина проекту pure-utils від sql-monk

## Автори

- SQL Monk Team
- Базується на архітектурі PureSqlsMcp та PlanSqlsMcp

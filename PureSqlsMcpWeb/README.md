
## �🚀 Запуск

### Швидкий старт
```powershell
# Запустити скрипт
.\start.ps1

# Або просто
dotnet run
```

Після запуску відкрийте: **http://localhost:5000/swagger**

### Розробка
```powershell
dotnet run
```API

Web API для роботи з SQL Server через MCP протокол, оптимізований для використання з GPT та іншими чат-сервісами.

## � Документація

- **[Швидкий старт](QUICK_START.md)** - Як швидко розпочати
- **[Налаштування порту](PORT_CONFIGURATION.md)** - Всі способи зміни порту
- **[Приклади конфігурацій](CONFIGURATION_EXAMPLES.md)** - Детальні приклади налаштувань
- **[Інтеграція з GPT](GPT_INTEGRATION.md)** - OpenAPI schema та інструкції
- **[Підсумок проекту](PROJECT_SUMMARY.md)** - Повний опис створеного проекту

## �🚀 Запуск

### Розробка
```powershell
dotnet run
```

### Продакшн
```powershell
dotnet publish -c Release
cd bin/Release/net8.0/publish
dotnet PureSqlsMcpWeb.dll
```

## ⚙️ Налаштування

Відредагуйте `appsettings.json` для налаштування підключення до SQL Server:

```json
{
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://localhost:5000"
      }
    }
  },
  "SqlConnection": {
    "Server": "localhost",
    "Database": "master",
    "IntegratedSecurity": true,
    "UserId": null,
    "Password": null,
    "TrustServerCertificate": true,
    "Encrypt": true,
    "CommandTimeout": 180
  }
}
```

### Зміна порту

Змініть порт в `appsettings.json`:
```json
{
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://localhost:8080"
      }
    }
  }
}
```

Або через змінну середовища:
```powershell
$env:ASPNETCORE_URLS="http://localhost:8080"
dotnet run
```

### Для SQL Server Authentication:
```json
{
  "SqlConnection": {
    "Server": "localhost",
    "Database": "master",
    "IntegratedSecurity": false,
    "UserId": "sa",
    "Password": "YourPassword",
    "TrustServerCertificate": true,
    "Encrypt": true,
    "CommandTimeout": 180
  }
}
```

## 📡 API Endpoints

### Базові endpoints

- **GET** `/health` - Перевірка стану API
- **GET** `/api/tools/connection-test` - Перевірка підключення до БД

### Робота з інструментами

- **GET** `/api/tools/list` - Отримати список доступних інструментів
- **POST** `/api/tools/call` - Викликати інструмент з параметрами
- **GET** `/api/tools/call/{toolName}` - Викликати інструмент через GET (для простих запитів)

### Swagger UI

Після запуску відкрийте в браузері:
- http://localhost:5000/swagger - інтерактивна документація API

## 📝 Приклади використання

### 1. Отримати список таблиць (POST)

```bash
curl -X POST "http://localhost:5000/api/tools/call" \
  -H "Content-Type: application/json" \
  -d '{
    "toolName": "GetTables",
    "arguments": {
      "schemaName": "dbo"
    }
  }'
```

### 2. Отримати список таблиць (GET)

```bash
curl "http://localhost:5000/api/tools/call/GetTables?schemaName=dbo"
```

### 3. Отримати список баз даних

```bash
curl -X POST "http://localhost:5000/api/tools/call" \
  -H "Content-Type: application/json" \
  -d '{
    "toolName": "GetDatabases"
  }'
```

### 4. Отримати DDL історію

```bash
curl -X POST "http://localhost:5000/api/tools/call" \
  -H "Content-Type: application/json" \
  -d '{
    "toolName": "GetDdlHistory",
    "arguments": {
      "objectName": "MyTable",
      "top": 10
    }
  }'
```

## 🤖 Інтеграція з GPT

### Приклад для GPT Actions

```json
{
  "openapi": "3.0.0",
  "info": {
    "title": "SQL Server MCP API",
    "version": "1.0.0"
  },
  "servers": [
    {
      "url": "http://your-server:5000"
    }
  ],
  "paths": {
    "/api/tools/list": {
      "get": {
        "operationId": "getToolsList",
        "summary": "Get available SQL tools"
      }
    },
    "/api/tools/call": {
      "post": {
        "operationId": "callTool",
        "summary": "Execute SQL tool",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "toolName": {"type": "string"},
                  "arguments": {"type": "object"}
                }
              }
            }
          }
        }
      }
    }
  }
}
```

## 🔒 Безпека

- CORS налаштований для роботи з будь-якими джерелами (для продакшну рекомендується обмежити)
- Використовуйте HTTPS в продакшн середовищі
- Налаштуйте аутентифікацію для публічного доступу

## 📦 Залежності

- .NET 8.0
- Microsoft.Data.SqlClient 5.2.2
- Swashbuckle.AspNetCore 6.9.0

## 🛠️ Розробка

### Структура проекту
```
PureSqlsMcpWeb/
├── Controllers/          # API контролери
│   └── ToolsController.cs
├── Models/              # Моделі даних
│   ├── SqlConnectionOptions.cs
│   ├── ToolCallRequest.cs
│   ├── ToolCallResponse.cs
│   └── ToolsListResponse.cs
├── Services/            # Бізнес-логіка
│   └── SqlToolsService.cs
├── Program.cs           # Точка входу
├── appsettings.json     # Конфігурація
└── PureSqlsMcpWeb.csproj
```

## 📄 Ліцензія

Відповідає ліцензії основного проекту PureSqlsMcp.

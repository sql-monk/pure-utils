
##  Запуск

### Швидкий старт
```powershell
# Запустити скрипт
.\start.ps1

# Або просто
dotnet run
```

Після запуску відкрийте: **http://localhost:5000/swagger**


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


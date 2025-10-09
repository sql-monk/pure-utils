# Конфігурація

## Огляд

Цей розділ описує файли конфігурації для pure-utils, зокрема для MCP серверів та інтеграції з AI-асистентами.

## config.mcp.json

### Призначення

Конфігураційний файл для MCP клієнтів (наприклад, Claude Desktop) для підключення до PureSqlsMcp та PlanSqlsMcp серверів.

### Розташування файлу

Файл може бути розташований у різних місцях залежно від MCP клієнта:

**Claude Desktop**:
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`

**Інші MCP клієнти**:
Зверніться до документації вашого MCP клієнта.

### Базова структура

```json
{
  "mcpServers": {
    "server_name": {
      "command": "path/to/executable",
      "args": ["arg1", "arg2", ...]
    }
  }
}
```

### Приклад конфігурації для Windows

```json
{
  "mcpServers": {
    "puresqls": {
      "command": "C:\\tools\\pure-utils\\PureSqlsMcp\\bin\\Release\\net8.0\\win-x64\\publish\\PureSqlsMcp.exe",
      "args": [
        "--server", "localhost",
        "--database", "master"
      ]
    },
    "showplan": {
      "command": "C:\\tools\\pure-utils\\PlanSqlsMcp\\bin\\Release\\net8.0\\win-x64\\publish\\PlanSqlsMcp.exe",
      "args": [
        "--server", "localhost",
        "--database", "master"
      ]
    }
  }
}
```

### Приклад для віддаленого SQL Server

```json
{
  "mcpServers": {
    "puresqls-prod": {
      "command": "C:\\tools\\PureSqlsMcp.exe",
      "args": [
        "--server", "sql-prod.company.com",
        "--database", "Production"
      ]
    },
    "puresqls-dev": {
      "command": "C:\\tools\\PureSqlsMcp.exe",
      "args": [
        "--server", "sql-dev.company.local",
        "--database", "Development"
      ]
    }
  }
}
```

### SQL Authentication

```json
{
  "mcpServers": {
    "puresqls": {
      "command": "C:\\tools\\PureSqlsMcp.exe",
      "args": [
        "--server", "sql-server.company.com",
        "--database", "Production",
        "--integrated-security", "false",
        "--user-id", "mcp_service",
        "--password", "SecurePassword123"
      ]
    }
  }
}
```

**Увага**: Не рекомендується зберігати паролі у відкритому вигляді у конфігурації. Розгляньте використання:
- Windows Authentication (--integrated-security true)
- Azure AD Authentication
- Key Vault для зберігання credentials

### Кілька баз даних

```json
{
  "mcpServers": {
    "dwh-metadata": {
      "command": "C:\\tools\\PureSqlsMcp.exe",
      "args": [
        "--server", "dwh-server",
        "--database", "DWH"
      ]
    },
    "oltp-metadata": {
      "command": "C:\\tools\\PureSqlsMcp.exe",
      "args": [
        "--server", "oltp-server",
        "--database", "OLTP"
      ]
    },
    "plans-analyzer": {
      "command": "C:\\tools\\PlanSqlsMcp.exe",
      "args": [
        "--server", "dwh-server",
        "--database", "DWH"
      ]
    }
  }
}
```

## Параметри командного рядка

### PureSqlsMcp та PlanSqlsMcp

Обидва сервери підтримують однакові параметри:

#### --server (обов'язковий)
Ім'я або адреса SQL Server

**Приклади**:
- `"localhost"`
- `".\\SQLEXPRESS"`
- `"sql-server.domain.com"`
- `"sql-server.domain.com,1433"` (з портом)
- `"tcp:sql-server.database.windows.net"` (Azure SQL)

#### --database (обов'язковий)
Ім'я бази даних

**Приклади**:
- `"master"`
- `"Production"`
- `"DWH"`

#### --integrated-security (опціональний)
Використовувати Windows Authentication

**Значення**:
- `"true"` (за замовчуванням) - Windows Authentication
- `"false"` - SQL Server Authentication

#### --user-id (опціональний)
SQL Server login (тільки з --integrated-security false)

**Приклад**: `"app_user"`

#### --password (опціональний)
Пароль (тільки з --integrated-security false)

**Приклад**: `"SecurePassword123"`

## Connection String параметри

MCP сервери формують connection string з наданих параметрів:

### Windows Authentication
```
Server=localhost;Database=master;Integrated Security=true;TrustServerCertificate=true;Encrypt=true
```

### SQL Authentication
```
Server=localhost;Database=master;User Id=app_user;Password=SecurePassword123;TrustServerCertificate=true;Encrypt=true
```

### Azure SQL Database
```json
{
  "mcpServers": {
    "azure-sql": {
      "command": "C:\\tools\\PureSqlsMcp.exe",
      "args": [
        "--server", "tcp:myserver.database.windows.net",
        "--database", "mydatabase",
        "--integrated-security", "false",
        "--user-id", "azureuser@myserver",
        "--password", "AzurePassword123!"
      ]
    }
  }
}
```

## Додаткові налаштування

### Timeout

За замовчуванням connection timeout = 15 секунд. Для зміни потрібно модифікувати код:

```csharp
// У PureSqlsMcpServer.cs або PlanSqlsMcpServer.cs
var builder = new SqlConnectionStringBuilder
{
    DataSource = server,
    InitialCatalog = database,
    ConnectTimeout = 30,  // 30 секунд замість 15
    // ...
};
```

### Max Pool Size

За замовчуванням Max Pool Size = 100. Для зміни:

```csharp
var builder = new SqlConnectionStringBuilder
{
    // ...
    MaxPoolSize = 200,
    MinPoolSize = 10
};
```

### Application Name

Для ідентифікації з'єднань у SQL Server:

```csharp
var builder = new SqlConnectionStringBuilder
{
    // ...
    ApplicationName = "PureSqlsMcp v1.0"
};
```

## Перевірка конфігурації

### Тестування підключення

```powershell
# Запустити сервер вручну для тестування
C:\tools\PureSqlsMcp.exe --server localhost --database master

# Сервер повинен запуститися та очікувати JSON-RPC команд
# Натисніть Ctrl+C для виходу
```

### Перевірка у Claude Desktop

1. Відредагуйте `claude_desktop_config.json`
2. Перезапустіть Claude Desktop
3. У діалозі запитайте: "Які MCP tools доступні?"
4. Claude повинен показати список tools (GetDatabases, GetTables, тощо)

### Діагностика помилок

Якщо MCP сервер не запускається, перевірте:

1. **Шлях до executable** - має бути абсолютний
2. **Правильність параметрів** - server, database
3. **Доступність SQL Server** - чи можна підключитися через SSMS
4. **Права доступу** - чи має service account необхідні права
5. **Firewall** - чи дозволено підключення до SQL Server

### Логи

Для увімкнення debug логів встановіть змінну середовища:

```powershell
$env:DEBUG = "true"
C:\tools\PureSqlsMcp.exe --server localhost --database master
```

Логи будуть виводитись у stderr і доступні у Claude Desktop developer console.

## Конфігурація для production

### Рекомендації

1. **Використовуйте Windows Authentication** де можливо
2. **Створіть окремого service account** з мінімальними правами
3. **Не зберігайте паролі** у конфігурації
4. **Обмежуйте доступ** до конфігураційних файлів
5. **Використовуйте read-only користувачів** для PureSqlsMcp
6. **Регулярно ротуйте паролі** для service accounts

### Приклад production конфігурації

```json
{
  "mcpServers": {
    "production-metadata": {
      "command": "C:\\Program Files\\PureUtils\\PureSqlsMcp.exe",
      "args": [
        "--server", "prod-sql.company.internal",
        "--database", "Production"
      ]
    }
  }
}
```

З налаштованим service account у Windows:
```powershell
# Запустити під конкретним обліковим записом
runas /user:DOMAIN\mcp_service "C:\Program Files\PureUtils\PureSqlsMcp.exe ..."
```

## Конфігурація для різних середовищ

### Development

```json
{
  "mcpServers": {
    "dev-utils": {
      "command": "C:\\dev\\pure-utils\\PureSqlsMcp\\bin\\Debug\\net8.0\\PureSqlsMcp.exe",
      "args": [
        "--server", "localhost",
        "--database", "Dev"
      ]
    }
  }
}
```

### Testing

```json
{
  "mcpServers": {
    "test-utils": {
      "command": "C:\\test\\PureSqlsMcp.exe",
      "args": [
        "--server", "test-sql.company.local",
        "--database", "Test"
      ]
    }
  }
}
```

### Production

```json
{
  "mcpServers": {
    "prod-utils": {
      "command": "C:\\Program Files\\PureUtils\\PureSqlsMcp.exe",
      "args": [
        "--server", "prod-sql.company.com",
        "--database", "Production"
      ]
    }
  }
}
```

## Альтернативні конфігурації

### Використання .env файлів

Створіть `.env` файл:
```
SQL_SERVER=localhost
SQL_DATABASE=master
SQL_USER=app_user
SQL_PASSWORD=SecurePassword123
```

Модифікуйте код для читання з .env:
```csharp
// Використовуючи DotNetEnv NuGet package
DotNetEnv.Env.Load();
var server = Environment.GetEnvironmentVariable("SQL_SERVER");
var database = Environment.GetEnvironmentVariable("SQL_DATABASE");
```

### Використання Azure Key Vault

```csharp
// Використовуючи Azure.Security.KeyVault.Secrets
var client = new SecretClient(new Uri(keyVaultUrl), new DefaultAzureCredential());
var password = await client.GetSecretAsync("sql-password");
```

## Troubleshooting

### MCP сервер не з'являється у Claude

1. Перевірте формат JSON (валідність)
2. Перевірте шлях до executable
3. Перезапустіть Claude Desktop
4. Перевірте developer console у Claude

### Помилка підключення до SQL Server

1. Перевірте ім'я сервера
2. Перевірте права користувача
3. Перевірте firewall
4. Тестуйте через SSMS з тими ж credentials

### Паролі не працюють

1. Перевірте спецсимволи (екрануйте у JSON)
2. Використовуйте Windows Authentication
3. Перевірте SQL Server Authentication mode

## Наступні кроки

- [PureSqlsMcp документація](modules/PureSqlsMcp.md)
- [PlanSqlsMcp документація](modules/PlanSqlsMcp.md)
- [Приклади використання](examples.md)
- [FAQ](faq.md)

# Початок роботи з pure-utils

Цей посібник допоможе вам швидко почати використовувати pure-utils у вашому середовищі SQL Server.

## Мінімальні вимоги

### Системні вимоги

- **Microsoft SQL Server**: версія 2022 або новіша
- **PowerShell**: версія 5.1 або новіша
- **dbatools**: PowerShell модуль (буде встановлено автоматично при першому запуску)
- **.NET SDK 8.0**: для компіляції MCP серверів (якщо потрібна інтеграція з AI-асистентами)

## Встановлення

### Крок 1: Клонування репозиторію

```bash
git clone https://github.com/sql-monk/pure-utils.git
cd pure-utils
```

### Крок 2: Встановлення основної бібліотеки util

Використовуйте PowerShell скрипт `deployUtil.ps1` для розгортання об'єктів схеми util:

```powershell
# Встановлення всіх об'єктів у базу даних
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "util" -Objects @("*")
```

#### Параметри deployUtil.ps1

- **Server** (обов'язковий): Ім'я SQL Server
- **Database** (обов'язковий): Ім'я бази даних для розгортання
- **Schema** (опціональний): Схема для розгортання (`util` або `mcp`), за замовчуванням `util`
- **Objects** (обов'язковий): Масив імен об'єктів для розгортання або `@("*")` для всіх

#### Приклади розгортання

```powershell
# Розгортання окремих об'єктів
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "util" `
    -Objects @("indexesGetConventionNames", "metadataGetAnyId")

# Розгортання схеми mcp
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "mcp" -Objects @("*")
```

### Крок 3: Встановлення Extended Events сесій (опціонально)

Extended Events сесії надають моніторинг виконання модулів та помилок:

```sql
-- Встановлення сесії для моніторингу помилок
-- Відкрийте XESessions/utilsErrors.sql та виконайте у SSMS

-- Встановлення сесії для моніторингу виконання модулів користувачами
-- Відкрийте XESessions/utilsModulesUsers.sql та виконайте у SSMS

-- Запуск сесій
ALTER EVENT SESSION [utilsErrors] ON SERVER STATE = START;
ALTER EVENT SESSION [utilsModulesUsers] ON SERVER STATE = START;
```

### Крок 4: Налаштування безпеки (опціонально)

Створіть окремі схеми з обмеженими правами:

```sql
-- Створення схем
CREATE SCHEMA util AUTHORIZATION dbo;
CREATE SCHEMA mcp AUTHORIZATION dbo;

-- Надання прав на виконання для ролі
GRANT EXECUTE ON SCHEMA::util TO [YourDatabaseRole];
GRANT EXECUTE ON SCHEMA::mcp TO [YourDatabaseRole];
```

## Перевірка встановлення

### Тестування базових функцій

```sql
-- Перевірка версії та доступності util
SELECT * FROM util.metadataGetAnyName(OBJECT_ID('sys.tables'), DEFAULT);

-- Отримання списку всіх функцій util
SELECT 
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS ObjectName,
    type_desc AS ObjectType
FROM sys.objects
WHERE schema_id = SCHEMA_ID('util')
ORDER BY type_desc, name;

-- Тестування генерації назв індексів
SELECT TOP 10 * 
FROM util.indexesGetConventionNames(NULL, NULL)
WHERE IndexName <> NewIndexName;
```

### Тестування MCP процедур

```sql
-- Отримання списку баз даних
EXEC mcp.GetDatabases;

-- Отримання інформації про таблицю
EXEC mcp.GetTableInfo @database = 'master', @schema = 'sys', @table = 'tables';
```

## Простий приклад використання

### Приклад 1: Пошук та створення відсутніх індексів

```sql
-- Знайти відсутні індекси
SELECT TOP 10
    DatabaseName,
    SchemaName,
    TableName,
    EqualityColumns,
    InequalityColumns,
    IncludedColumns,
    UniqueCompiles,
    UserSeeks,
    UserScans,
    AvgTotalUserCost,
    ImprovementMeasure
FROM util.indexesGetMissing(NULL)
ORDER BY ImprovementMeasure DESC;
```

### Приклад 2: Генерація DDL для таблиці

```sql
-- Отримати повний DDL скрипт для таблиці
DECLARE @ddl NVARCHAR(MAX);

SELECT @ddl = DDLScript
FROM util.tablesGetScript('YourTableName', NULL);

PRINT @ddl;
```

### Приклад 3: Автоматичне перейменування індексів

```sql
-- Отримати рекомендації щодо перейменування індексів
SELECT 
    SchemaName,
    TableName,
    IndexName,
    NewIndexName,
    'EXEC sp_rename ''[' + SchemaName + '].[' + TableName + '].[' + IndexName + ']'', ''' + NewIndexName + ''', ''INDEX'';' AS RenameScript
FROM util.indexesGetConventionNames(NULL, NULL)
WHERE IndexName <> NewIndexName;
```

### Приклад 4: Моніторинг виконання модулів

```sql
-- Переглянути останні виконання модулів (вимагає активної XE сесії)
SELECT TOP 100
    EventName,
    EventTime,
    ObjectName,
    Duration,
    DatabaseName,
    ClientAppName,
    ServerPrincipalName
FROM util.xeGetModules('Users', DEFAULT)
ORDER BY EventTime DESC;
```

## Налаштування MCP серверів (опціонально)

### Компіляція MCP серверів

Якщо ви хочете використовувати інтеграцію з AI-асистентами:

```powershell
# Компіляція PureSqlsMcp
cd PureSqlsMcp
.\build.ps1

# Компіляція PlanSqlsMcp
cd ..\PlanSqlsMcp
.\build.ps1
```

### Конфігурація для Claude Desktop / інших MCP клієнтів

Відредагуйте `config.mcp.json` у вашому MCP клієнті:

```json
{
  "servers": {
    "puresqls": {
      "command": "C:\\path\\to\\PureSqlsMcp.exe",
      "args": [
        "--server", "your-server-name",
        "--database", "your-database"
      ]
    },
    "showplan": {
      "command": "C:\\path\\to\\PlanSqlsMcp.exe",
      "args": [
        "--server", "your-server-name",
        "--database", "your-database"
      ]
    }
  }
}
```

Детальніше про конфігурацію MCP серверів у розділі [Конфігурація](config.md).

## Наступні кроки

Тепер, коли pure-utils встановлено, ви можете:

1. Ознайомитись з [Архітектурою](architecture.md) для розуміння внутрішньої структури
2. Вивчити документацію [Модулів](modules/util.md) для детального опису функцій
3. Переглянути [Приклади](examples.md) для практичних сценаріїв використання
4. Налаштувати [Стиль коду](coding-style.md) для вашої команди

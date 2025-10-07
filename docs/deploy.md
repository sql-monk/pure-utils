# Інструкції по розгортанню Pure Utils

Цей документ описує процес розгортання об'єктів схем `util` та `mcp` в SQL Server базі даних.

## Огляд

Pure Utils використовує PowerShell скрипт `deployUtil.ps1` для автоматичного розгортання SQL об'єктів з вирішенням залежностей. Скрипт аналізує залежності між об'єктами та розгортає їх у правильному порядку.

## Вимоги

### Програмне забезпечення
- **PowerShell** 5.1 або вище
- **SQL Server** 2016 або вище
- **dbatools** PowerShell модуль

### Встановлення dbatools

```powershell
# Встановлення dbatools
Install-Module -Name dbatools -Scope CurrentUser

# Перевірка встановлення
Get-Module -ListAvailable -Name dbatools
```

## Структура проекту

```
pure-utils/
├── deployUtil.ps1          # Головний скрипт розгортання
├── util/                   # Схема util
│   ├── Functions/          # Функції
│   ├── Procedures/         # Процедури
│   ├── Tables/             # Таблиці
│   └── Views/              # Представлення
├── mcp/                    # Схема mcp
│   ├── Functions/          # Функції
│   └── Procedures/         # Процедури
├── Security/               # Скрипти безпеки
│   ├── util.sql           # Створення схеми util
│   └── mcp.sql            # Створення схеми mcp
└── docs/                   # Документація
```

## Основний скрипт: deployUtil.ps1

### Синтаксис

```powershell
.\deployUtil.ps1 -Server <server> -Database <database> -Schema <schema> -Objects <objects>
```

### Параметри

| Параметр | Тип | Обов'язковий | Опис |
|----------|-----|--------------|------|
| `-Server` | String | Так | Ім'я SQL Server інстансу |
| `-Database` | String | Так | Ім'я бази даних |
| `-Schema` | String | Ні | Схема для розгортання: 'util' або 'mcp' (за замовчуванням 'util') |
| `-Objects` | String/Array | Так | Ім'я об'єкту, маска пошуку або масив імен |

### Можливості

1. **Автоматичне вирішення залежностей** - аналізує залежності між об'єктами
2. **Підтримка масок** - використання wildcards для вибору кількох об'єктів
3. **Підтримка масивів** - розгортання кількох конкретних об'єктів
4. **Захист від циклічних залежностей** - кешування оброблених об'єктів
5. **Детальне логування** - вивід інформації про процес розгортання

## Приклади використання

### 1. Розгортання одного об'єкта

```powershell
# Розгорнути функцію в схемі util
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "util" -Objects "mcpBuildParameterJson"

# Розгорнути процедуру в схемі mcp
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "mcp" -Objects "GetTables"
```

### 2. Розгортання за маскою

```powershell
# Розгорнути всі об'єкти що починаються з "mcp"
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "util" -Objects "mcp*"

# Розгорнути всі об'єкти що містять "index"
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "util" -Objects "*index*"

# Розгорнути всі процедури Get*
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "mcp" -Objects "Get*"
```

### 3. Розгортання масиву об'єктів

```powershell
# Розгорнути кілька конкретних об'єктів
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "util" -Objects @("mcpBuildParameterJson", "mcpMapSqlTypeToJsonType")

# Розгорнути кілька MCP процедур
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "mcp" -Objects @("GetTables", "GetDatabases", "GetViews")
```

### 4. Розгортання всіх об'єктів схеми

```powershell
# Розгорнути всі об'єкти util
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "util" -Objects "*"

# Розгорнути всі об'єкти mcp
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "mcp" -Objects "*"
```

## Покрокова інструкція: Повне розгортання

### Крок 1: Підготовка бази даних

```sql
-- Створіть базу даних (якщо потрібно)
CREATE DATABASE [Utils];
GO

USE [Utils];
GO
```

### Крок 2: Створення схем

```powershell
# Перейдіть у директорію проекту
cd C:\path\to\pure-utils

# Виконайте скрипти створення схем
sqlcmd -S localhost -d Utils -i Security\util.sql
sqlcmd -S localhost -d Utils -i Security\mcp.sql
```

Або через SQL Server Management Studio:
```sql
-- Створення схеми util
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'util')
BEGIN
    EXEC('CREATE SCHEMA util');
END;
GO

-- Створення схеми mcp
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'mcp')
BEGIN
    EXEC('CREATE SCHEMA mcp');
END;
GO
```

### Крок 3: Розгортання схеми util

```powershell
# Розгорнути всі об'єкти util
.\deployUtil.ps1 -Server "localhost" -Database "Utils" -Schema "util" -Objects "*"
```

### Крок 4: Розгортання схеми mcp

```powershell
# Розгорнути всі об'єкти mcp
.\deployUtil.ps1 -Server "localhost" -Database "Utils" -Schema "mcp" -Objects "*"
```

### Крок 5: Перевірка розгортання

```sql
-- Перевірка об'єктів util
SELECT 
    OBJECT_SCHEMA_NAME(object_id) AS SchemaName,
    name AS ObjectName,
    type_desc AS ObjectType,
    create_date AS CreateDate
FROM sys.objects
WHERE OBJECT_SCHEMA_NAME(object_id) = 'util'
ORDER BY type_desc, name;

-- Перевірка об'єктів mcp
SELECT 
    OBJECT_SCHEMA_NAME(object_id) AS SchemaName,
    name AS ObjectName,
    type_desc AS ObjectType,
    create_date AS CreateDate
FROM sys.objects
WHERE OBJECT_SCHEMA_NAME(object_id) = 'mcp'
ORDER BY type_desc, name;

-- Тестування базових функцій
SELECT util.metadataGetObjectName(OBJECT_ID('util.errorHandler'));
EXEC mcp.GetDatabases;
```

## Вирішення залежностей

Скрипт `deployUtil.ps1` автоматично аналізує залежності між об'єктами:

1. **Парсинг залежностей** - читає коментарі та аналізує код SQL
2. **Побудова графа залежностей** - створює дерево залежностей
3. **Топологічне сортування** - визначає правильний порядок розгортання
4. **Розгортання в порядку** - спочатку залежності, потім об'єкт

### Приклад роботи з залежностями

Якщо ви розгортаєте процедуру `mcp.GetTableInfo`, яка використовує `util.metadataGetObjectName`, скрипт автоматично:
1. Знайде залежність від `util.metadataGetObjectName`
2. Спочатку розгорне `util.metadataGetObjectName`
3. Потім розгорне `mcp.GetTableInfo`

## Оновлення існуючих об'єктів

Всі SQL файли використовують `CREATE OR ALTER`, тому:
- Якщо об'єкт не існує - він буде створений
- Якщо об'єкт існує - він буде оновлений
- Дані в таблицях при оновленні функцій/процедур не втрачаються

## Права доступу

### Мінімальні права для розгортання

```sql
-- Створення користувача для розгортання
CREATE LOGIN [DeployUser] WITH PASSWORD = 'StrongPassword123!';
CREATE USER [DeployUser] FOR LOGIN [DeployUser];

-- Надання прав
ALTER ROLE db_ddladmin ADD MEMBER [DeployUser];
GRANT CREATE SCHEMA TO [DeployUser];
GRANT ALTER ON SCHEMA::util TO [DeployUser];
GRANT ALTER ON SCHEMA::mcp TO [DeployUser];
```

### Права для користувачів

```sql
-- Read-only доступ до util
GRANT SELECT ON SCHEMA::util TO [ReadOnlyUser];
GRANT EXECUTE ON SCHEMA::util TO [ReadOnlyUser];

-- Read-only доступ до mcp
GRANT SELECT ON SCHEMA::mcp TO [ReadOnlyUser];
GRANT EXECUTE ON SCHEMA::mcp TO [ReadOnlyUser];
```

## Логування та діагностика

### Увімкнення детального логування

```powershell
# Використовуйте -Verbose для детального виводу
.\deployUtil.ps1 -Server "localhost" -Database "Utils" -Schema "util" -Objects "*" -Verbose
```

### Перевірка помилок

Якщо виникають помилки:
1. Перевірте, чи встановлено dbatools
2. Перевірте підключення до SQL Server
3. Перевірте права доступу користувача
4. Перегляньте повідомлення про помилки в консолі

## CI/CD Integration

### Azure DevOps Pipeline

```yaml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - util/*
      - mcp/*

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  displayName: 'Install dbatools'
  inputs:
    targetType: 'inline'
    script: |
      Install-Module -Name dbatools -Force -Scope CurrentUser

- task: PowerShell@2
  displayName: 'Deploy util schema'
  inputs:
    targetType: 'filePath'
    filePath: '$(Build.SourcesDirectory)/deployUtil.ps1'
    arguments: '-Server $(SqlServer) -Database $(SqlDatabase) -Schema util -Objects "*"'

- task: PowerShell@2
  displayName: 'Deploy mcp schema'
  inputs:
    targetType: 'filePath'
    filePath: '$(Build.SourcesDirectory)/deployUtil.ps1'
    arguments: '-Server $(SqlServer) -Database $(SqlDatabase) -Schema mcp -Objects "*"'
```

### GitHub Actions

```yaml
name: Deploy Pure Utils

on:
  push:
    branches: [ main ]
    paths:
      - 'util/**'
      - 'mcp/**'

jobs:
  deploy:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Install dbatools
      run: Install-Module -Name dbatools -Force -Scope CurrentUser
      shell: powershell
    
    - name: Deploy util schema
      run: |
        .\deployUtil.ps1 -Server $env:SQL_SERVER -Database $env:SQL_DATABASE -Schema util -Objects "*"
      shell: powershell
      env:
        SQL_SERVER: ${{ secrets.SQL_SERVER }}
        SQL_DATABASE: ${{ secrets.SQL_DATABASE }}
    
    - name: Deploy mcp schema
      run: |
        .\deployUtil.ps1 -Server $env:SQL_SERVER -Database $env:SQL_DATABASE -Schema mcp -Objects "*"
      shell: powershell
      env:
        SQL_SERVER: ${{ secrets.SQL_SERVER }}
        SQL_DATABASE: ${{ secrets.SQL_DATABASE }}
```

## Відкат змін

Якщо потрібно відкотити зміни:

```sql
-- Видалення схеми mcp
DROP SCHEMA IF EXISTS mcp;

-- Видалення схеми util
DROP SCHEMA IF EXISTS util;

-- Видалення конкретного об'єкта
DROP FUNCTION IF EXISTS util.mcpBuildParameterJson;
DROP PROCEDURE IF EXISTS mcp.GetTables;
```

## Часті питання (FAQ)

### Q: Чи можна розгорнути в production базу даних?
**A:** Так, але рекомендується:
1. Спочатку протестувати в dev/test середовищі
2. Створити backup бази даних перед розгортанням
3. Розгортати в maintenance window
4. Використовувати транзакції (якщо можливо)

### Q: Що робити якщо об'єкт використовується?
**A:** CREATE OR ALTER чекає на завершення виконання об'єкта. Рекомендується розгортати в період низького навантаження.

### Q: Чи можна розгортати частково?
**A:** Так, можна розгортати окремі об'єкти або групи об'єктів за масками.

### Q: Чи зберігаються дані в таблицях?
**A:** Так, оновлення функцій та процедур не впливає на дані в таблицях. Однак будьте обережні з оновленням структури таблиць.

## Додаткові ресурси

- [Документація dbatools](https://dbatools.io/)
- [SQL Server Documentation](https://docs.microsoft.com/en-us/sql/sql-server/)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)

## Див. також

- [Огляд можливостей util](util/README.md)
- [Огляд можливостей mcp](mcp/README.md)
- [Список об'єктів util](util/objects-list.md)
- [Список об'єктів mcp](mcp/objects-list.md)

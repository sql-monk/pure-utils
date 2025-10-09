# Часті питання (FAQ)

## Загальні питання

### Що таке pure-utils?

pure-utils — це комплексна бібліотека утиліт для Microsoft SQL Server, призначена для автоматизації рутинних задач адміністрування, моніторингу та оптимізації. Вона включає понад 100 функцій та процедур для роботи з метаданими, аналізу індексів, генерації DDL скриптів, моніторингу через Extended Events та інтеграції з AI-асистентами.

### Навіщо мені pure-utils?

pure-utils корисний якщо ви:
- Адмініструєте великі Data Warehouse системи
- Потребуєте автоматизації рутинних DBA задач
- Хочете оптимізувати продуктивність SQL Server
- Плануєте інтегрувати базу даних з AI-асистентами
- Потребуєте стандартизованих інструментів для команди

### Які вимоги для використання?

- SQL Server 2022
- PowerShell 5.1+ для розгортання
- Права `db_owner` або `sysadmin` для встановлення
- Опціонально: .NET 8.0 для MCP серверів

### Чи підтримується Azure SQL Database?

Частково. Більшість функцій util працюють, але:
- Extended Events мають обмеження в Azure SQL DB
- Деякі системні представлення недоступні
- Cross-database запити обмежені в Azure SQL DB
- SQL Managed Instance має кращу підтримку

## Встановлення та налаштування

### Як встановити pure-utils?

```powershell
# 1. Клонувати репозиторій
git clone https://github.com/sql-monk/pure-utils.git
cd pure-utils

# 2. Встановити dbatools (якщо ще немає)
Install-Module -Name dbatools -Scope CurrentUser -Force

# 3. Розгорнути схему util
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "util" -Objects @("*")

# 4. Розгорнути схему mcp (опціонально)
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "mcp" -Objects @("*")
```

Детальніше: [Початок роботи](getting-started.md)

### Помилка: "Модуль dbatools не встановлено"

```powershell
# Встановити dbatools
Install-Module -Name dbatools -Scope CurrentUser -Force

# Якщо помилка прав доступу
Install-Module -Name dbatools -Scope CurrentUser -Force -SkipPublisherCheck
```

### Як оновити pure-utils до нової версії?

```powershell
# 1. Pull останні зміни
git pull origin main

# 2. Перерозгорнути об'єкти
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "util" -Objects @("*")
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "mcp" -Objects @("*")
```

### Чи можу я встановити в іншу базу даних окрім master?

Так, pure-utils можна встановити в будь-яку базу даних:

```powershell
.\deployUtil.ps1 -Server "localhost" -Database "YourDatabase" -Schema "util" -Objects @("*")
```

Рекомендується встановлювати в окрему utility БД або у вашу головну DWH базу.

## Використання функцій

### Як знайти відсутні індекси?

```sql
-- Топ-10 відсутніх індексів
SELECT TOP 10 *
FROM util.indexesGetMissing(NULL)
ORDER BY ImprovementMeasure DESC;
```

### Як знайти невикористовувані індекси?

```sql
-- Невикористовувані індекси > 100 MB
SELECT *
FROM util.indexesGetUnused(NULL)
WHERE SizeKB > 102400
ORDER BY SizeKB DESC;
```

### Як отримати DDL таблиці?

```sql
DECLARE @ddl NVARCHAR(MAX);
SELECT @ddl = DDLScript
FROM util.tablesGetScript('YourTable', 'dbo');
PRINT @ddl;
```

### Як перейменувати індекси згідно конвенцій?

```sql
-- 1. Переглянути рекомендації
SELECT * 
FROM util.indexesGetConventionNames('YourTable', NULL)
WHERE IndexName <> NewIndexName;

-- 2. Згенерувати скрипти
SELECT 
    'EXEC sp_rename ''' + SchemaName + '.' + TableName + '.' + IndexName + 
    ''', ''' + NewIndexName + ''', ''INDEX'';'
FROM util.indexesGetConventionNames('YourTable', NULL)
WHERE IndexName <> NewIndexName;

-- 3. Виконати скрипти
```

### Як додати опис до таблиці або колонки?

```sql
-- Для таблиці
EXEC util.metadataSetTableDescription 
    @table = 'dbo.Orders',
    @description = 'Таблиця замовлень';

-- Для колонки
EXEC util.metadataSetColumnDescription 
    @table = 'dbo.Orders',
    @column = 'OrderId',
    @description = 'Унікальний ідентифікатор замовлення';
```

## Extended Events

### Як налаштувати Extended Events моніторинг?

```sql
-- 1. Створити сесію для помилок
-- Виконайте XESessions/utilsErrors.sql

-- 2. Запустити сесію
ALTER EVENT SESSION [utilsErrors] ON SERVER STATE = START;

-- 3. Читати дані
SELECT TOP 100 *
FROM util.xeGetErrors(DEFAULT)
ORDER BY EventTime DESC;
```

### Як автоматизувати копіювання XE даних?

Створіть SQL Agent Job:

```sql
USE msdb;
EXEC sp_add_job @job_name = 'Copy XE Errors';

EXEC sp_add_jobstep 
    @job_name = 'Copy XE Errors',
    @step_name = 'Copy',
    @subsystem = 'TSQL',
    @command = 'EXEC util.xeCopyErrorsToTable;';

EXEC sp_add_schedule
    @schedule_name = 'Every 15 minutes',
    @freq_type = 4,
    @freq_interval = 1,
    @freq_subday_type = 4,
    @freq_subday_interval = 15;

EXEC sp_attach_schedule 
    @job_name = 'Copy XE Errors',
    @schedule_name = 'Every 15 minutes';
```

### XE файли занадто великі, що робити?

```sql
-- 1. Зменшити max_file_size
ALTER EVENT SESSION [utilsErrors] ON SERVER
DROP TARGET package0.event_file;

ALTER EVENT SESSION [utilsErrors] ON SERVER
ADD TARGET package0.event_file(
    SET filename=N'utilsErrors.xel',
    max_file_size=(4),  -- 4 MB замість 8
    max_rollover_files=(8)  -- більше файлів
);

-- 2. Додати більше фільтрів
ALTER EVENT SESSION [utilsErrors] ON SERVER
DROP EVENT sqlserver.error_reported;

ALTER EVENT SESSION [utilsErrors] ON SERVER
ADD EVENT sqlserver.error_reported(
    WHERE severity >= 16  -- тільки серйозні помилки
);

-- 3. Регулярно копіювати та очищати
```

## MCP інтеграція

### Як налаштувати MCP сервери?

```powershell
# 1. Скомпілювати MCP сервери
cd PureSqlsMcp
.\build.ps1

cd ..\PlanSqlsMcp
.\build.ps1

# 2. Відредагувати Claude Desktop config
# %APPDATA%\Claude\claude_desktop_config.json
```

```json
{
  "mcpServers": {
    "puresqls": {
      "command": "C:\\path\\to\\PureSqlsMcp.exe",
      "args": ["--server", "localhost", "--database", "master"]
    }
  }
}
```

Детальніше: [Конфігурація MCP](config.md)

### MCP сервер не з'являється в Claude

1. Перевірте формат JSON конфігурації
2. Перевірте шлях до executable (має бути абсолютний)
3. Перезапустіть Claude Desktop
4. Перевірте developer console у Claude на помилки

### Помилка підключення MCP до SQL Server

1. Перевірте ім'я сервера та назву БД
2. Перевірте права доступу користувача
3. Тестуйте підключення через SSMS
4. Перевірте firewall налаштування
5. Для SQL Authentication перевірте credentials

### Як додати новий MCP tool?

```sql
-- 1. Створити процедуру в схемі mcp
CREATE OR ALTER PROCEDURE mcp.MyNewTool
    @param1 NVARCHAR(128),
    @param2 INT = NULL
AS
BEGIN
    -- Ваша логіка
    
    -- Повернути JSON у форматі MCP
    DECLARE @result NVARCHAR(MAX);
    -- ... формування результату
    SELECT @result FOR JSON PATH, INCLUDE_NULL_VALUES;
END;

-- 2. Додати коментарі
/*
# Description
Опис функціональності

# Parameters
@param1 NVARCHAR(128) - опис
@param2 INT - опис (опціональний)
*/

-- 3. Перезапустити PureSqlsMcp - tool з'явиться автоматично
```

## Продуктивність

### Чи впливає pure-utils на продуктивність SQL Server?

Вплив мінімальний:
- Функції util виконуються тільки на запит
- Extended Events мають дуже низький overhead (<1%)
- Запити до sys каталогів використовують NOLOCK
- Всі об'єкти оптимізовані для продуктивності

### Як оптимізувати запити до util функцій?

```sql
-- Погано (повільно на великих БД):
SELECT * FROM util.indexesGetMissing(NULL);  -- всі таблиці

-- Добре (швидко):
SELECT * FROM util.indexesGetMissing('YourTable');  -- конкретна таблиця

-- Погано:
SELECT * FROM util.indexesGetSpaceUsed(NULL);

-- Добре:
SELECT * FROM util.indexesGetSpaceUsed(NULL)
WHERE TotalSpaceMB > 100;  -- фільтрувати результати
```

### XE сесії уповільнюють SQL Server?

Ні, якщо правильно налаштовані:
- Використовуйте фільтри для зменшення кількості подій
- Встановіть розумні розміри файлів
- Уникайте збору зайвих actions
- Моніторьте розмір XE файлів

## Безпека

### Які права потрібні для використання pure-utils?

**Мінімальні права для читання**:
```sql
GRANT EXECUTE ON SCHEMA::util TO [YourUser];
GRANT VIEW DEFINITION TO [YourUser];
```

**Для Extended Events**:
```sql
GRANT VIEW SERVER STATE TO [YourUser];
GRANT ALTER ANY EVENT SESSION TO [YourUser];
```

**Для cross-database запитів**:
```sql
-- На кожній БД
GRANT VIEW DEFINITION TO [YourUser];
```

Детальніше: [Безпека](modules/Security.md)

### Як обмежити доступ для production?

```sql
-- Створити read-only роль
CREATE ROLE db_util_readonly;
GRANT SELECT ON SCHEMA::util TO db_util_readonly;
DENY INSERT, UPDATE, DELETE ON SCHEMA::util TO db_util_readonly;
DENY EXECUTE ON util.metadataSetTableDescription TO db_util_readonly;
DENY EXECUTE ON util.metadataSetColumnDescription TO db_util_readonly;

ALTER ROLE db_util_readonly ADD MEMBER [ProductionUser];
```

### Чи безпечно використовувати PlanSqlsMcp?

Так, PlanSqlsMcp:
- Отримує тільки estimated plans (запити не виконуються)
- Не змінює дані
- Використовує `SET SHOWPLAN_XML ON` (безпечний режим)
- Рекомендується використовувати read-only користувача

## Troubleshooting

### Помилка: "Invalid object name 'util.functionName'"

Перевірте:
1. Чи розгорнута схема util у поточній БД
2. Чи правильна назва функції
3. Чи має користувач права EXECUTE

```sql
-- Перевірити наявність об'єктів util
SELECT name, type_desc
FROM sys.objects
WHERE schema_id = SCHEMA_ID('util')
ORDER BY name;
```

### Помилка: "Cannot find the object because it does not exist"

Можливі причини:
1. Об'єкт не існує в БД
2. Немає прав VIEW DEFINITION
3. Cross-database запит без прав

```sql
-- Перевірити права
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');
```

### Функція повертає NULL замість результату

Перевірте:
1. Чи існує об'єкт з такою назвою/ID
2. Чи правильні параметри
3. Чи є дані для повернення

```sql
-- Debug приклад
DECLARE @objectId INT = OBJECT_ID('dbo.MyTable');
SELECT @objectId;  -- має бути не NULL

SELECT * FROM util.metadataGetColumns(NULL, @objectId);
```

### deployUtil.ps1 не знаходить файли

Перевірте:
1. Поточна директорія (має бути корінь репозиторію)
2. Структура папок: `util/Functions/`, `util/Procedures/` тощо
3. Назва файлу співпадає з назвою об'єкта

```powershell
# Перевірити поточну директорію
Get-Location

# Перевірити наявність файлів
Get-ChildItem -Path ".\util\Functions\" -Filter "*.sql"
```

## Розробка та внесення змін

### Як додати нову функцію до util?

1. Створіть SQL файл у відповідній папці:
   - `util/Functions/yourFunction.sql`
   - `util/Procedures/yourProcedure.sql`

2. Дотримуйтесь конвенцій найменування:
   - `{category}{Action}{Entity}` для функцій
   - `{entity}Set{Property}` для процедур

3. Додайте структуровані коментарі:
```sql
/*
# Description
Опис

# Parameters
@param - опис

# Returns
Опис результату

# Usage
-- Приклад
*/
```

4. Розгорніть:
```powershell
.\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "util" -Objects "yourFunction"
```

Детальніше: [Стиль коду](coding-style.md)

### Де знайти приклади коду?

- [Приклади використання](examples.md)
- [Існуючі функції](modules/util.md)
- Файли у `util/Functions/` та `util/Procedures/`

### Як тестувати зміни?

1. Тестуйте на dev середовищі
2. Створіть test cases з різними параметрами
3. Перевірте NULL handling
4. Тестуйте на великих обсягах даних
5. Перевірте продуктивність

```sql
-- Приклад тестування
-- NULL parameters
SELECT * FROM util.yourFunction(NULL);

-- Конкретні значення
SELECT * FROM util.yourFunction('test');

-- Неіснуючі об'єкти
SELECT * FROM util.yourFunction('NonExistent');
```

## Підтримка та спільнота

### Де отримати допомогу?

1. Документація: [docs/](index.md)
2. GitHub Issues: створіть issue з питанням
3. Приклади коду: [examples.md](examples.md)

### Як повідомити про помилку?

Створіть GitHub Issue з наступною інформацією:
- Версія SQL Server
- Кроки для відтворення
- Повідомлення про помилку
- Очікувана поведінка
- Фактична поведінка

### Як запропонувати нову функцію?

Створіть GitHub Issue або Pull Request:
1. Опишіть use case
2. Запропонуйте реалізацію
3. Додайте приклади використання
4. Дотримуйтесь стилю коду проєкту

## Наступні кроки

- [Початок роботи](getting-started.md) - Встановлення
- [Архітектура](architecture.md) - Розуміння системи
- [Приклади](examples.md) - Практичні сценарії
- [Модулі](modules/util.md) - Детальна документація

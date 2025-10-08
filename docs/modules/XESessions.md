# Extended Events Sessions - Моніторинг та аудит

## Огляд

Директорія `XESessions` містить готові конфігурації Extended Events (XE) сесій для моніторингу виконання модулів, помилок та debug подій у SQL Server.

## Переваги Extended Events

- **Низький overhead** порівняно з SQL Profiler
- **Гнучка фільтрація** подій на рівні сервера
- **Асинхронна обробка** без блокування запитів
- **Інкрементальне завантаження** через util функції
- **Довгострокове зберігання** у таблицях util

## Доступні сесії

### utilsErrors.sql

**Призначення**: Моніторинг помилок у SQL Server

**Події**:
- `sqlserver.error_reported` - всі помилки з severity >= 11

**Actions** (додаткова інформація):
- `sqlserver.database_name` - назва БД
- `sqlserver.client_app_name` - додаток
- `sqlserver.server_principal_name` - користувач
- `sqlserver.sql_text` - SQL запит
- `sqlserver.session_id` - ID сесії

**Конфігурація**:
```sql
CREATE EVENT SESSION [utilsErrors] ON SERVER 
ADD EVENT sqlserver.error_reported(
    WHERE ([severity]>=(11))
)
ADD TARGET package0.event_file(
    SET filename=N'utilsErrors.xel',
    max_file_size=(8),      -- 8 MB на файл
    max_rollover_files=(4)  -- максимум 4 файли (32 MB загалом)
)
WITH (
    MAX_MEMORY=4096 KB,
    EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY=5 SECONDS,
    MAX_EVENT_SIZE=0 KB,
    MEMORY_PARTITION_MODE=NONE,
    TRACK_CAUSALITY=ON,
    STARTUP_STATE=OFF
);
```

**Встановлення та запуск**:
```sql
-- Створити сесію
-- Виконайте XESessions/utilsErrors.sql

-- Запустити
ALTER EVENT SESSION [utilsErrors] ON SERVER STATE = START;

-- Автозапуск при старті SQL Server
ALTER EVENT SESSION [utilsErrors] ON SERVER WITH (STARTUP_STATE = ON);
```

**Читання даних**:
```sql
-- Останні 100 помилок
SELECT TOP 100
    EventTime,
    Severity,
    State,
    ErrorNumber,
    Message,
    DatabaseName,
    UserName,
    ClientAppName,
    SqlText
FROM util.xeGetErrors(DEFAULT)
ORDER BY EventTime DESC;

-- Критичні помилки за останню добу
SELECT *
FROM util.xeGetErrors(NULL)
WHERE EventTime > DATEADD(DAY, -1, GETDATE())
  AND Severity >= 16
ORDER BY Severity DESC, EventTime DESC;
```

**Копіювання у таблиці**:
```sql
-- Ручне копіювання
EXEC util.xeCopyErrorsToTable;

-- Автоматизація через SQL Agent Job
EXEC msdb.dbo.sp_add_job @job_name = 'Util - Copy XE Errors';

EXEC msdb.dbo.sp_add_jobstep 
    @job_name = 'Util - Copy XE Errors',
    @step_name = 'Copy Errors',
    @subsystem = 'TSQL',
    @command = 'EXEC util.xeCopyErrorsToTable;';

EXEC msdb.dbo.sp_add_schedule
    @schedule_name = 'Every 15 minutes',
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @freq_subday_type = 4,  -- Minutes
    @freq_subday_interval = 15;

EXEC msdb.dbo.sp_attach_schedule 
    @job_name = 'Util - Copy XE Errors',
    @schedule_name = 'Every 15 minutes';
```

---

### utilsModulesUsers.sql

**Призначення**: Відстеження виконання модулів (процедур, функцій) користувачами

**Події**:
- `sqlserver.module_start` - початок виконання модуля
- `sqlserver.module_end` - завершення виконання модуля
- `sqlserver.rpc_starting` - виклик віддаленої процедури

**Фільтри**:
```sql
WHERE [sqlserver].[like_i_sql_unicode_string](
    [sqlserver].[server_principal_name],
    N'%\_[.A-z]%[^$]'  -- тільки користувачі домену
) 
AND [object_name] <> N'xp_instance_regread'  -- виключити системні виклики
```

**Actions**:
- `sqlos.task_time` - час виконання
- `sqlserver.database_name`, `sqlserver.database_id`
- `sqlserver.client_app_name`, `sqlserver.client_hostname`
- `sqlserver.plan_handle` - plan handle
- `sqlserver.sql_text` - повний SQL текст
- `sqlserver.session_id`, `sqlserver.server_principal_name`

**Конфігурація**:
```sql
CREATE EVENT SESSION [utilsModulesUsers] ON SERVER 
ADD EVENT sqlserver.module_end(SET collect_statement=(1)
    ACTION(sqlos.task_time, sqlserver.client_app_name, ...)
    WHERE ([sqlserver].[like_i_sql_unicode_string](...))
),
ADD EVENT sqlserver.module_start(SET collect_statement=(1) ...),
ADD EVENT sqlserver.rpc_starting(SET collect_statement=(1) ...)
ADD TARGET package0.event_file(
    SET filename=N'utilsModulesUsers.xel',
    max_file_size=(8),
    max_rollover_files=(4)
)
WITH (...);
```

**Встановлення**:
```sql
-- Створити сесію
-- Виконайте XESessions/utilsModulesUsers.sql

-- Запустити
ALTER EVENT SESSION [utilsModulesUsers] ON SERVER STATE = START;
```

**Читання даних**:
```sql
-- Останні виконання модулів
SELECT TOP 100
    EventTime,
    EventName,
    ObjectName,
    Duration / 1000000.0 AS DurationSeconds,
    DatabaseName,
    ServerPrincipalName,
    ClientAppName,
    ClientHostname
FROM util.xeGetModules('Users', DEFAULT)
ORDER BY EventTime DESC;

-- Найдовші виконання за сьогодні
SELECT TOP 20
    ObjectName,
    AVG(Duration) / 1000000.0 AS AvgDurationSeconds,
    MAX(Duration) / 1000000.0 AS MaxDurationSeconds,
    COUNT(*) AS ExecutionCount
FROM util.xeGetModules('Users', CAST(GETDATE() AS DATE))
GROUP BY ObjectName
ORDER BY AVG(Duration) DESC;

-- Активність по користувачах
SELECT 
    ServerPrincipalName,
    COUNT(DISTINCT ObjectName) AS UniqueModules,
    COUNT(*) AS TotalExecutions,
    SUM(Duration) / 1000000.0 AS TotalSeconds
FROM util.xeGetModules('Users', DATEADD(DAY, -7, GETDATE()))
GROUP BY ServerPrincipalName
ORDER BY TotalExecutions DESC;
```

**Копіювання у таблиці**:
```sql
-- Інкрементальне копіювання
EXEC util.xeCopyModulesToTable @scope = 'Users';

-- SQL Agent Job для регулярного копіювання
EXEC msdb.dbo.sp_add_job @job_name = 'Util - Copy XE Modules Users';

EXEC msdb.dbo.sp_add_jobstep 
    @job_name = 'Util - Copy XE Modules Users',
    @step_name = 'Copy Modules',
    @subsystem = 'TSQL',
    @command = 'EXEC util.xeCopyModulesToTable @scope = ''Users'';';

-- Щогодини
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = 'Hourly',
    @freq_type = 4,
    @freq_interval = 1,
    @freq_subday_type = 8,  -- Hours
    @freq_subday_interval = 1;

EXEC msdb.dbo.sp_attach_schedule 
    @job_name = 'Util - Copy XE Modules Users',
    @schedule_name = 'Hourly';
```

---

### utilsDebug.sql

**Призначення**: Детальний debug для розробки та тестування

**Події**:
- `sqlserver.module_start`, `sqlserver.module_end`
- `sqlserver.sql_statement_starting`, `sqlserver.sql_statement_completed`
- `sqlserver.sp_statement_starting`, `sqlserver.sp_statement_completed`

**Особливості**:
- Збирає детальну інформацію про виконання statements всередині модулів
- Має більший overhead
- Рекомендується для тимчасового увімкнення під час debug

**Фільтри**:
```sql
WHERE [sqlserver].[database_name] = N'YourDatabase'  -- тільки ваша БД
  AND [sqlserver].[like_i_sql_unicode_string]([object_name], N'util.%')  -- тільки util модулі
```

**Конфігурація**:
```sql
CREATE EVENT SESSION [utilsDebug] ON SERVER 
ADD EVENT sqlserver.module_end(...),
ADD EVENT sqlserver.module_start(...),
ADD EVENT sqlserver.sp_statement_completed(...),
ADD EVENT sqlserver.sp_statement_starting(...),
ADD EVENT sqlserver.sql_statement_completed(...),
ADD EVENT sqlserver.sql_statement_starting(...)
ADD TARGET package0.event_file(
    SET filename=N'utilsDebug.xel',
    max_file_size=(16),      -- більший розмір для детальних даних
    max_rollover_files=(2)
)
WITH (...);
```

**Встановлення** (тимчасово для debug):
```sql
-- Створити та запустити
-- Виконайте XESessions/utilsDebug.sql
ALTER EVENT SESSION [utilsDebug] ON SERVER STATE = START;

-- Після debug - зупинити та видалити
ALTER EVENT SESSION [utilsDebug] ON SERVER STATE = STOP;
DROP EVENT SESSION [utilsDebug] ON SERVER;
```

**Читання даних**:
```sql
-- Детальне виконання statements у процедурі
SELECT 
    EventTime,
    EventName,
    ObjectName,
    Statement,
    LineNumber,
    Duration / 1000.0 AS DurationMs
FROM util.xeGetDebug(DEFAULT)
WHERE ObjectName = 'util.indexesGetMissing'
ORDER BY EventTime;
```

---

## Управління XE сесіями

### Перегляд активних сесій

```sql
-- Всі XE сесії
SELECT 
    name,
    CASE WHEN xes.create_time > DATEADD(MINUTE, -5, GETDATE()) 
        THEN 'Recently Created' 
        ELSE 'Active' 
    END AS Status,
    create_time,
    MAX(xet.target_name) AS target_name
FROM sys.dm_xe_sessions xes
    LEFT JOIN sys.dm_xe_session_targets xet ON xes.address = xet.event_session_address
WHERE name LIKE 'utils%'
GROUP BY name, create_time;

-- Статистика подій
SELECT 
    s.name AS session_name,
    e.event_name,
    e.count
FROM sys.dm_xe_sessions s
    JOIN sys.dm_xe_session_events e ON s.address = e.event_session_address
WHERE s.name LIKE 'utils%'
ORDER BY s.name, e.count DESC;
```

### Зупинка та запуск

```sql
-- Зупинити
ALTER EVENT SESSION [utilsErrors] ON SERVER STATE = STOP;
ALTER EVENT SESSION [utilsModulesUsers] ON SERVER STATE = STOP;

-- Запустити
ALTER EVENT SESSION [utilsErrors] ON SERVER STATE = START;
ALTER EVENT SESSION [utilsModulesUsers] ON SERVER STATE = START;

-- Видалити
DROP EVENT SESSION [utilsErrors] ON SERVER;
```

### Зміна конфігурації

```sql
-- Збільшити розмір файлів
ALTER EVENT SESSION [utilsModulesUsers] ON SERVER
DROP TARGET package0.event_file;

ALTER EVENT SESSION [utilsModulesUsers] ON SERVER
ADD TARGET package0.event_file(
    SET filename=N'utilsModulesUsers.xel',
    max_file_size=(16),      -- 16 MB замість 8
    max_rollover_files=(10)  -- 10 файлів замість 4
);
```

## Аналіз даних XE

### Розмір XE файлів

```sql
-- Перевірити розмір файлів
EXEC xp_cmdshell 'dir C:\Path\To\XE\Files\*.xel';

-- Або через util функцію
SELECT * FROM util.xeGetLogsPath();
```

### Очищення старих файлів

```sql
-- Видалити файли старші 30 днів (PowerShell)
$path = "C:\Path\To\XE\Files"
Get-ChildItem -Path $path -Filter "*.xel" | 
    Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | 
    Remove-Item -Force
```

### Топ помилок

```sql
-- Найчастіші помилки
SELECT 
    ErrorNumber,
    Message,
    COUNT(*) AS ErrorCount,
    MAX(EventTime) AS LastOccurrence
FROM util.executionErrors  -- якщо копіюєте у таблицю
GROUP BY ErrorNumber, Message
ORDER BY ErrorCount DESC;
```

### Профілювання продуктивності

```sql
-- Процедури з найдовшим виконанням
SELECT 
    ObjectName,
    COUNT(*) AS Executions,
    AVG(Duration) / 1000000.0 AS AvgSeconds,
    MAX(Duration) / 1000000.0 AS MaxSeconds,
    MIN(Duration) / 1000000.0 AS MinSeconds,
    STDEV(Duration) / 1000000.0 AS StdDevSeconds
FROM util.executionModulesUsers
WHERE EventTime > DATEADD(DAY, -7, GETDATE())
GROUP BY ObjectName
HAVING COUNT(*) > 100
ORDER BY AVG(Duration) DESC;
```

## Кастомізація XE сесій

### Додавання власних подій

```sql
-- Приклад: відстеження lock timeouts
ALTER EVENT SESSION [utilsErrors] ON SERVER
ADD EVENT sqlserver.lock_timeout(
    ACTION(
        sqlserver.database_name,
        sqlserver.sql_text,
        sqlserver.session_id
    )
);
```

### Додавання фільтрів

```sql
-- Фільтр по конкретній БД
ALTER EVENT SESSION [utilsModulesUsers] ON SERVER
DROP EVENT sqlserver.module_end;

ALTER EVENT SESSION [utilsModulesUsers] ON SERVER
ADD EVENT sqlserver.module_end(
    SET collect_statement=(1)
    ACTION(...)
    WHERE [sqlserver].[database_name] = N'Production'  -- додано фільтр
      AND [sqlserver].[like_i_sql_unicode_string](...)
);
```

## Best Practices

1. **Обмежуйте розмір файлів** для уникнення великих накопичень
2. **Регулярно копіюйте** дані у таблиці для довгострокового зберігання
3. **Налаштуйте ротацію** старих XE файлів
4. **Використовуйте фільтри** для зменшення обсягу даних
5. **Моніторьте overhead** XE сесій на продуктивність
6. **Тестуйте на dev** перед увімкненням на production
7. **Документуйте зміни** у конфігурації XE сесій

## Troubleshooting

### XE сесія не запускається

```sql
-- Перевірити помилки
SELECT * FROM sys.dm_xe_sessions;
SELECT * FROM sys.event_log WHERE name LIKE '%utils%';
```

### Файли не створюються

```sql
-- Перевірити шлях
SELECT * FROM util.xeGetLogsPath();

-- Перевірити права SQL Server service account
EXEC xp_cmdshell 'whoami';
```

### Дані не читаються

```sql
-- Перевірити наявність файлів
EXEC xp_cmdshell 'dir C:\Path\To\XE\Files\utilsErrors*.xel';

-- Перевірити структуру подій
SELECT 
    event_data
FROM sys.fn_xe_file_target_read_file('C:\Path\utilsErrors*.xel', NULL, NULL, NULL);
```

## Наступні кроки

- [Модуль util](util.md) - Функції для читання XE
- [Приклади аналізу](../examples.md)
- [FAQ](../faq.md)

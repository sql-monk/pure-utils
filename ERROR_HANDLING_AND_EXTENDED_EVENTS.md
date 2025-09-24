# ERROR HANDLING - Детальний огляд системи обробки помилок

## Архітектура системи

Система ERROR HANDLING в Pure Utils - це комплексне рішення для централізованого збору, логування та аналізу помилок в SQL Server середовищі. Система забезпечує повний життєвий цикл управління помилками: від виникнення до аналізу та звітності.

### Основні компоненти системи (3 об'єкти)

#### 1. **Процедура `util.errorHandler`** - Універсальний обробник помилок
- **Призначення**: Центральна точка обробки всіх помилок в системі
- **Функціональність**: Збирає контекстну інформацію, логує в базу даних
- **Параметри**: `@attachment NVARCHAR(MAX)` - додатковий контекст помилки
- **Технології**: Використовує системні функції ERROR_*(), DMV, XML для сесійної інформації

#### 2. **Таблиця `util.errorLog`** - Централізований журнал помилок
- **Призначення**: Зберігання всіх помилок з повним контекстом
- **Структура**: 17 колонок з детальною інформацією про помилку та сесію
- **Оптимізація**: Індексування по часу, номеру помилки та процедурі
- **Ретенція**: Автоматичне архівування старих записів

#### 3. **Функція `util.help`** - Довідкова система
- **Призначення**: Інтерактивна довідка по всій системі Pure Utils
- **Параметри**: `@keyword SYSNAME` - фільтрація по ключовим словам
- **Джерела**: Витягує інформацію з Extended Properties та коментарів

## Детальна структура таблиці `util.errorLog`

```sql
-- Ідентифікація помилки
ErrorId BIGINT IDENTITY(1,1) PRIMARY KEY    -- Унікальний ідентифікатор
ErrorDateTime DATETIME2(3) DEFAULT GETDATE() -- Точний час виникнення

-- Інформація про помилку SQL Server
ErrorNumber INT NOT NULL                     -- Номер помилки (наприклад, 2, 8134, 50000)
ErrorSeverity INT NOT NULL                   -- Рівень критичності (1-25)
ErrorState INT NOT NULL                      -- Внутрішній стан помилки
ErrorMessage NVARCHAR(4000) NOT NULL         -- Текст повідомлення

-- Контекст виконання
ErrorProcedure NVARCHAR(128) NULL            -- Процедура/функція де сталася помилка
ErrorLine INT NULL                           -- Номер рядка в коді
ErrorLineText NVARCHAR(MAX) NULL             -- Точний текст рядка коду

-- Сесійна інформація
OriginalLogin NVARCHAR(128) NULL             -- Оригінальний логін користувача
SessionId SMALLINT NULL                      -- ID сесії SQL Server
HostName NVARCHAR(128) NULL                  -- Ім'я комп'ютера клієнта
ProgramName NVARCHAR(128) NULL               -- Програма що підключилася
DatabaseName NVARCHAR(128) NULL             -- База даних де сталася помилка
UserName NVARCHAR(128) NULL                  -- Користувач бази даних

-- Додаткова інформація
Attachment NVARCHAR(MAX) NULL                -- Користувацький контекст
SessionInfo XML NULL                         -- Детальна інформація про сесію (DMV дані)
```

## Принцип роботи системи

### 1. **Механізм перехоплення помилок**
```sql
BEGIN TRY
    -- Ризикована операція
    EXEC dbo.BusinessLogicProcedure @param = 'value';
    INSERT INTO dbo.CriticalTable VALUES (...);
    UPDATE dbo.ImportantData SET Status = 'Processed';
END TRY
BEGIN CATCH
    -- Автоматичне логування з контекстом
    EXEC util.errorHandler @attachment = 'Бізнес-процес: Обробка замовлення #12345';
    
    -- Опціонально - повторне викидання
    IF ERROR_SEVERITY() >= 16
        THROW;
END CATCH
```

### 2. **Збір контекстної інформації**
Процедура `errorHandler` автоматично збирає:
- **Системну інформацію**: ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE()
- **Контекст виконання**: ERROR_PROCEDURE(), ERROR_LINE()
- **Код рядка**: Через `util.modulesSplitToLines()` знаходить точний текст
- **Сесійні дані**: HOST_NAME(), PROGRAM_NAME(), USER_NAME()
- **Детальну DMV інформацію**: sys.dm_exec_sessions, sys.dm_exec_requests

### 3. **Структурування SessionInfo XML**
```xml
<session>
  <session_id>52</session_id>
  <login_time>2024-01-15T09:30:00</login_time>
  <host_name>WORKSTATION01</host_name>
  <program_name>Microsoft SQL Server Management Studio</program_name>
  <cpu_time>1250</cpu_time>
  <memory_usage>8</memory_usage>
  <reads>15420</reads>
  <writes>890</writes>
  <current_request>
    <request_id>0</request_id>
    <command>INSERT</command>
    <wait_type>PAGEIOLATCH_SH</wait_type>
    <blocking_session_id>0</blocking_session_id>
    <open_transaction_count>1</open_transaction_count>
  </current_request>
</session>
```

## Практичні приклади використання

### Базове логування помилок
```sql
-- Простий приклад з мінімальним контекстом
BEGIN TRY
    DECLARE @result INT = 10 / 0;  -- Помилка ділення на нуль
END TRY
BEGIN CATCH
    EXEC util.errorHandler;  -- Логування без додаткового контексту
END CATCH
```

### Розширене логування з контекстом
```sql
-- ETL процес з детальним контекстом
DECLARE @BatchId INT = 12345;
DECLARE @ProcessingStep NVARCHAR(100);

BEGIN TRY
    SET @ProcessingStep = 'Завантаження даних з джерела';
    EXEC dbo.LoadSourceData @BatchId;
    
    SET @ProcessingStep = 'Трансформація даних';
    EXEC dbo.TransformData @BatchId;
    
    SET @ProcessingStep = 'Запис в цільову систему';
    EXEC dbo.WriteToTarget @BatchId;
    
END TRY
BEGIN CATCH
    DECLARE @ErrorContext NVARCHAR(MAX) = CONCAT(
        'ETL Batch: ', @BatchId, 
        ', Step: ', @ProcessingStep,
        ', Parameters: BatchId=', @BatchId,
        ', Timestamp: ', GETDATE()
    );
    
    EXEC util.errorHandler @attachment = @ErrorContext;
    
    -- Відкат транзакції якщо потрібно
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
        
    -- Критичні помилки прокидуємо далі
    IF ERROR_SEVERITY() >= 20
        THROW;
END CATCH
```

### Використання в циклічних операціях
```sql
-- Обробка великих обсягів даних з логуванням проблемних записів
DECLARE @UserId INT;
DECLARE user_cursor CURSOR FOR 
    SELECT UserId FROM dbo.UsersToProcess WHERE ProcessedDate IS NULL;

OPEN user_cursor;
FETCH NEXT FROM user_cursor INTO @UserId;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC dbo.ProcessUser @UserId;
        UPDATE dbo.UsersToProcess SET ProcessedDate = GETDATE() WHERE UserId = @UserId;
    END TRY
    BEGIN CATCH
        -- Логуємо помилку з конкретним користувачем
        EXEC util.errorHandler @attachment = CONCAT('Failed to process UserId: ', @UserId);
        
        -- Позначаємо як проблемний, але продовжуємо обробку
        UPDATE dbo.UsersToProcess 
        SET ErrorDate = GETDATE(), ErrorMessage = ERROR_MESSAGE() 
        WHERE UserId = @UserId;
    END CATCH
    
    FETCH NEXT FROM user_cursor INTO @UserId;
END

CLOSE user_cursor;
DEALLOCATE user_cursor;
```

## Аналітичні запити для моніторингу

### Топ помилок за частотою
```sql
-- Найчастіші помилки за останню добу
SELECT 
    ErrorNumber,
    COUNT(*) as ErrorCount,
    ErrorMessage,
    MAX(ErrorDateTime) as LastOccurrence,
    COUNT(DISTINCT SessionId) as AffectedSessions,
    COUNT(DISTINCT HostName) as AffectedHosts
FROM util.errorLog 
WHERE ErrorDateTime > DATEADD(DAY, -1, GETDATE())
GROUP BY ErrorNumber, ErrorMessage
HAVING COUNT(*) > 1
ORDER BY ErrorCount DESC;
```

### Аналіз помилок по процедурах
```sql
-- Процедури з найбільшою кількістю помилок
SELECT 
    ISNULL(ErrorProcedure, 'Ad-hoc SQL') as ProcedureName,
    COUNT(*) as ErrorCount,
    COUNT(DISTINCT ErrorNumber) as UniqueErrors,
    AVG(ErrorSeverity) as AvgSeverity,
    MAX(ErrorDateTime) as LastError,
    STRING_AGG(DISTINCT CAST(ErrorNumber as VARCHAR(10)), ', ') as ErrorNumbers
FROM util.errorLog
WHERE ErrorDateTime > DATEADD(WEEK, -1, GETDATE())
GROUP BY ErrorProcedure
ORDER BY ErrorCount DESC;
```

### Трендовий аналіз помилок
```sql
-- Тренд помилок по годинах за тиждень
SELECT 
    DATEPART(HOUR, ErrorDateTime) as HourOfDay,
    DATENAME(WEEKDAY, ErrorDateTime) as DayName,
    COUNT(*) as ErrorCount,
    AVG(CAST(ErrorSeverity as FLOAT)) as AvgSeverity
FROM util.errorLog
WHERE ErrorDateTime > DATEADD(WEEK, -1, GETDATE())
GROUP BY DATEPART(HOUR, ErrorDateTime), DATENAME(WEEKDAY, ErrorDateTime)
ORDER BY HourOfDay, DayName;
```

### Аналіз користувацької активності
```sql
-- Користувачі з найбільшою кількістю помилок
SELECT 
    OriginalLogin,
    HostName,
    ProgramName,
    COUNT(*) as ErrorCount,
    COUNT(DISTINCT ErrorNumber) as UniqueErrorTypes,
    MIN(ErrorDateTime) as FirstError,
    MAX(ErrorDateTime) as LastError
FROM util.errorLog
WHERE ErrorDateTime > DATEADD(MONTH, -1, GETDATE())
    AND OriginalLogin IS NOT NULL
GROUP BY OriginalLogin, HostName, ProgramName
HAVING COUNT(*) > 5
ORDER BY ErrorCount DESC;
```

---

# EXTENDED EVENTS (XE) - Детальний огляд системи моніторингу

## Архітектура системи Extended Events

Pure Utils включає повну екосистему для роботи з Extended Events SQL Server, що забезпечує:
- **Збір подій** через спеціалізовані XE сесії
- **Обробку та зберігання** в структурованих таблицях  
- **Аналіз та звітність** через зручні представлення та функції

### Компоненти системи (15 об'єктів)

#### **XE Сесії (4 об'єкти)**
1. **`utilsErrors`** - Збір критичних помилок системи
2. **`utilsModulesUsers`** - Моніторинг виконання модулів звичайними користувачами
3. **`utilsModulesFaust`** - Спеціальний моніторинг для Faust користувачів
4. **`utilsModulesSSIS`** - Відстеження виконання SSIS пакетів

#### **Функції для читання XE (3 об'єкти)**
1. **`util.xeGetErrors`** - Читання помилок з XE файлів
2. **`util.xeGetTargetFile`** - Інформація про поточні файли сесій
3. **`util.xeGetLogsPath`** - Генерація шляхів до директорій логів

#### **Процедури для обробки (1 об'єкт)**
1. **`util.xeCopyModulesToTable`** - Копіювання даних з XE у таблиці

#### **Таблиці для зберігання (6 об'єктів)**
1. **`util.executionModulesUsers`** - Дані виконання модулів користувачами
2. **`util.executionModulesFaust`** - Дані виконання модулів Faust
3. **`util.executionModulesSSIS`** - Дані виконання SSIS пакетів
4. **`util.executionSqlText`** - Кеш унікальних SQL текстів
5. **`util.xeOffsets`** - Позиції читання XE файлів
6. **`util.errorLog`** - Журнал помилок (спільний з ERROR HANDLING)

#### **Представлення для аналізу (3 об'єкти)**
1. **`util.viewExecutionModulesUsers`** - Аналіз виконання модулів користувачами
2. **`util.viewExecutionModulesFaust`** - Аналіз виконання модулів Faust
3. **`util.viewExecutionModulesSSIS`** - Аналіз виконання SSIS пакетів

## Детальний опис XE сесій

### 1. **utilsErrors** - Моніторинг помилок
```sql
-- Події що відстежуються:
- error_reported          -- Всі помилки системи
- user_error_message      -- Користувацькі помилки (RAISERROR, THROW)

-- Дії (Actions) що збираються:
- client_app_name         -- Назва програми клієнта
- client_hostname         -- Ім'я хоста клієнта  
- database_name           -- База даних де сталася помилка
- server_principal_name   -- Користувач що викликав помилку
- sql_text               -- SQL текст що призвів до помилки
- tsql_frame             -- T-SQL фрейм виконання
- tsql_stack             -- Повний стек T-SQL викликів

-- Фільтри:
- severity >= 11         -- Тільки серйозні помилки
- Виключає системні помилки типу "Login failed"
```

### 2. **utilsModulesUsers** - Моніторинг модулів користувачів
```sql
-- Події що відстежуються:
- module_start           -- Початок виконання процедури/функції
- module_end             -- Завершення виконання
- rpc_starting           -- Виклик remote procedure call

-- Дії що збираються:
- task_time              -- Системний час задачі
- client_app_name        -- Програма клієнта
- client_hostname        -- Хост клієнта
- database_id/name       -- Ідентифікатор та назва БД
- plan_handle            -- Дескриптор плану виконання
- server_principal_name  -- Користувач сервера
- session_id             -- Ідентифікатор сесії
- sql_text              -- Повний SQL текст

-- Фільтри:
- Тільки користувачі з паттерном '%_[.A-z]%[^$]' (виключає службові акаунти)
- Виключає системні процедури типу sp_reset_connection
```

### 3. **utilsModulesFaust** - Спеціальний моніторинг Faust
```sql
-- Аналогічна структура з utilsModulesUsers але з фільтрами для:
- Faust користувачів (спеціальний паттерн імен)
- Специфічні програми та підключення
- Окремі файли для ізоляції даних
```

### 4. **utilsModulesSSIS** - Моніторинг SSIS пакетів
```sql
-- Фокус на відстеженні:
- SSIS package execution  -- Виконання пакетів
- Data Flow components    -- Компоненти потоків даних
- Connection managers     -- Менеджери підключень

-- Спеціальні фільтри для:
- SQL Server Integration Services
- DTS packages
- SSIS Runtime processes
```

## Детальна структура таблиць зберігання

### `util.executionModulesUsers` (та аналогічні Faust/SSIS)
```sql
-- Ідентифікація події
xeId INT IDENTITY(1,1) PRIMARY KEY          -- Унікальний ідентифікатор
EventName NVARCHAR(50) NOT NULL             -- module_start/end, rpc_starting
EventTime DATETIME2(7) NOT NULL             -- Точний час події
hb VARBINARY(32) NOT NULL                   -- Hash bucket для групування

-- Інформація про об'єкт
ObjectName NVARCHAR(128) NOT NULL           -- Назва процедури/функції
ObjectId BIGINT NULL                        -- Ідентифікатор об'єкта в sys.objects
ObjectType NVARCHAR(10) NULL                -- Тип об'єкта (P, FN, IF, тощо)
LineNumber INT NULL                         -- Номер рядка в модулі
ModuleRowCount BIGINT NULL                  -- Загальна кількість рядків модуля

-- SQL тексти та хеші
StatementHash VARBINARY(32) NULL            -- Хеш конкретної інструкції
SqlTextHash VARBINARY(32) NULL              -- Хеш повного SQL тексту
Offset INT NULL                             -- Позиція початку інструкції
OffsetEnd INT NULL                          -- Позиція кінця інструкції

-- Контекст виконання
DatabaseName NVARCHAR(128) NULL             -- Назва бази даних
DatabaseId SMALLINT NULL                    -- Ідентифікатор БД
SessionId INT NULL                          -- Ідентифікатор сесії
SourceDatabaseId INT NULL                   -- БД де розташований об'єкт

-- Інформація про клієнта
ClientHostname NVARCHAR(128) NULL           -- Ім'я комп'ютера клієнта
ClientAppName NVARCHAR(256) NULL            -- Програма що підключилася
ServerPrincipalName NVARCHAR(128) NULL      -- Користувач сервера

-- Продуктивність
Duration BIGINT NULL                        -- Тривалість виконання (мікросекунди)
TaskTime BIGINT NULL                        -- Системний час задачі
PlanHandle VARBINARY(64) NULL               -- Дескриптор плану виконання
```

### `util.executionSqlText` - Кеш SQL текстів
```sql
-- Структура оптимізована для зберігання унікальних SQL команд
sqlHash VARBINARY(32) NOT NULL PRIMARY KEY  -- SHA2_256 хеш SQL тексту
sqlText NVARCHAR(MAX) NOT NULL               -- Повний текст SQL команди

-- Індексування:
-- - Кластерний індекс по sqlHash для швидкого пошуку
-- - Компресія PAGE для економії простору
-- - Автоматичне дедуплікування через хеші
```

### `util.xeOffsets` - Позиції читання файлів
```sql
sessionName NVARCHAR(128) PRIMARY KEY       -- Назва XE сесії
LastEventTime DATETIME2 NOT NULL            -- Час останньої обробленої події  
LastFileName NVARCHAR(260) NOT NULL         -- Шлях до останнього файлу
LastOffset BIGINT NOT NULL DEFAULT(0)       -- Позиція в файлі (bytes)

-- Призначення: Забезпечення інкрементального читання XE файлів
-- без дублювання подій при перезапуску обробки
```

## Функції для роботи з XE

### `util.xeGetErrors(@minEventTime)` - Читання помилок
```sql
-- Повертає структуровані дані про помилки з XE файлів
SELECT 
    EventTime,              -- Час події
    ErrorNumber,            -- Номер помилки SQL Server
    Severity,               -- Рівень критичності
    State,                  -- Стан помилки
    Message,                -- Текст повідомлення
    DatabaseName,           -- База даних
    ClientHostname,         -- Хост клієнта
    ClientAppName,          -- Програма клієнта
    ServerPrincipalName,    -- Користувач
    SqlText,                -- SQL код що призвів до помилки
    TsqlFrame,              -- T-SQL фрейм
    TsqlStack,              -- Стек викликів
    FileName,               -- XE файл джерело
    FileOffset              -- Позиція у файлі
FROM util.xeGetErrors(DATEADD(HOUR, -1, GETDATE()));
```

### `util.xeGetLogsPath(@sessionName)` - Шляхи до логів
```sql
-- Автоматично генерує стандартизовані шляхи для XE файлів
SELECT util.xeGetLogsPath('utilsErrors');
-- Результат: C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Log\util\Errors\

-- Базується на розташуванні SQL Server Error Log
-- Створює структуру папок util\{SessionType}\
```

### `util.xeGetTargetFile(@xeSession)` - Інформація про файли
```sql
-- Повертає інформацію для продовження читання XE файлів
SELECT 
    lastEventTime,          -- Час останньої обробленої події
    lastOffset,             -- Позиція для продовження читання
    currentFile             -- Поточний активний файл сесії
FROM util.xeGetTargetFile('utilsErrors');
```

## Процедура `util.xeCopyModulesToTable(@scope)`

### Алгоритм роботи
1. **Читання XE даних** через util.xeReadFileModules()
2. **Дедуплікація SQL текстів** через хешування SHA2_256
3. **Збереження в executionSqlText** унікальних команд
4. **Запис подій** в відповідну таблицю (Users/Faust/SSIS)
5. **Оновлення позицій** в util.xeOffsets для наступного читання

### Приклади використання
```sql
-- Обробка модулів користувачів
EXEC util.xeCopyModulesToTable 'Users';

-- Обробка Faust модулів  
EXEC util.xeCopyModulesToTable 'Faust';

-- Обробка SSIS пакетів
EXEC util.xeCopyModulesToTable 'SSIS';
```

## Представлення для аналізу

Всі представлення автоматично:
- **Конвертують час** з UTC в локальний часовий пояс
- **Приєднують SQL тексти** з util.executionSqlText
- **Забезпечують READ UNCOMMITTED** для мінімального блокування

### `util.viewExecutionModulesUsers`
```sql
-- Основні колонки для аналізу користувацької активності
SELECT 
    EventTime,                  -- Локальний час
    ObjectName,                 -- Процедура/функція
    Duration,                   -- Тривалість (мікросекунди)
    ClientHostname,             -- Хост користувача
    ServerPrincipalName,        -- Користувач
    statmentText,               -- SQL інструкція
    sqlText,                    -- Повний SQL код
    DatabaseName,               -- База даних
    SessionId                   -- Сесія
FROM util.viewExecutionModulesUsers
WHERE EventTime > DATEADD(HOUR, -1, GETDATE());
```

## Практичні сценарії використання

### 1. Моніторинг критичних помилок
```sql
-- Критичні помилки за останню добу з контекстом
SELECT 
    xe.EventTime,
    xe.ErrorNumber,
    xe.Severity,
    xe.Message,
    xe.DatabaseName,
    xe.ServerPrincipalName,
    xe.ClientHostname,
    xe.SqlText,
    -- Корреляція з журналом помилок
    el.ErrorProcedure,
    el.ErrorLine,
    el.Attachment
FROM util.xeGetErrors(DATEADD(DAY, -1, GETDATE())) xe
LEFT JOIN util.errorLog el ON 
    xe.ErrorNumber = el.ErrorNumber 
    AND ABS(DATEDIFF(SECOND, xe.EventTime, el.ErrorDateTime)) < 5
WHERE xe.Severity >= 16
ORDER BY xe.EventTime DESC;
```

### 2. Аналіз продуктивності процедур
```sql
-- Топ повільних процедур з детальною статистикою
WITH ProcStats AS (
    SELECT 
        ObjectName,
        COUNT(*) as ExecutionCount,
        AVG(Duration) as AvgDurationMicroseconds,
        MAX(Duration) as MaxDurationMicroseconds,
        MIN(Duration) as MinDurationMicroseconds,
        STDEV(Duration) as StdDevDuration,
        COUNT(DISTINCT ServerPrincipalName) as UniqueUsers,
        COUNT(DISTINCT ClientHostname) as UniqueHosts,
        MAX(EventTime) as LastExecution
    FROM util.viewExecutionModulesUsers
    WHERE EventTime > DATEADD(DAY, -1, GETDATE())
        AND Duration IS NOT NULL
        AND EventName = 'module_end'  -- Тільки завершені виконання
    GROUP BY ObjectName
)
SELECT 
    ObjectName,
    ExecutionCount,
    AvgDurationMicroseconds / 1000.0 as AvgDurationMs,
    MaxDurationMicroseconds / 1000.0 as MaxDurationMs,
    StdDevDuration / 1000.0 as StdDevMs,
    UniqueUsers,
    UniqueHosts,
    LastExecution,
    -- Індекс варіабельності продуктивності
    CASE 
        WHEN AvgDurationMicroseconds > 0 
        THEN StdDevDuration / AvgDurationMicroseconds 
        ELSE 0 
    END as PerformanceVariabilityIndex
FROM ProcStats
WHERE ExecutionCount >= 10  -- Тільки з достатньою статистикою
ORDER BY AvgDurationMicroseconds DESC;
```

### 3. Аналіз користувацької активності
```sql
-- Детальний аналіз активності користувачів
SELECT 
    ServerPrincipalName,
    ClientHostname,
    ClientAppName,
    COUNT(*) as TotalExecutions,
    COUNT(DISTINCT ObjectName) as UniqueObjectsUsed,
    COUNT(DISTINCT DatabaseName) as DatabasesAccessed,
    AVG(Duration) / 1000.0 as AvgDurationMs,
    SUM(Duration) / 1000.0 as TotalDurationMs,
    MIN(EventTime) as FirstActivity,
    MAX(EventTime) as LastActivity,
    DATEDIFF(MINUTE, MIN(EventTime), MAX(EventTime)) as SessionDurationMinutes
FROM util.viewExecutionModulesUsers
WHERE EventTime > DATEADD(DAY, -1, GETDATE())
    AND Duration IS NOT NULL
GROUP BY ServerPrincipalName, ClientHostname, ClientAppName
HAVING COUNT(*) > 50  -- Активні користувачі
ORDER BY TotalExecutions DESC;
```

### 4. Аналіз SSIS пакетів
```sql
-- Моніторинг виконання SSIS пакетів
SELECT 
    ObjectName as PackageName,
    COUNT(*) as ExecutionCount,
    AVG(Duration) / 1000000.0 as AvgDurationSeconds,
    MAX(Duration) / 1000000.0 as MaxDurationSeconds,
    COUNT(CASE WHEN Duration > 300000000 THEN 1 END) as LongRunsCount, -- >30 сек
    MAX(EventTime) as LastRun,
    COUNT(DISTINCT ClientHostname) as ExecutionHosts,
    -- Аналіз трендів виконання
    AVG(CASE WHEN EventTime > DATEADD(DAY, -1, GETDATE()) THEN Duration END) / 1000000.0 as Recent24hAvgSec,
    AVG(CASE WHEN EventTime BETWEEN DATEADD(DAY, -7, GETDATE()) AND DATEADD(DAY, -1, GETDATE()) THEN Duration END) / 1000000.0 as Previous6dAvgSec
FROM util.viewExecutionModulesSSIS
WHERE EventTime > DATEADD(DAY, -7, GETDATE())
    AND EventName = 'module_end'
    AND Duration IS NOT NULL
GROUP BY ObjectName
HAVING COUNT(*) >= 5
ORDER BY AvgDurationSeconds DESC;
```

### 5. Корелляційний аналіз помилок та виконання
```sql
-- Аналіз взаємозв'язку між помилками та навантаженням
WITH HourlyStats AS (
    SELECT 
        DATEPART(HOUR, EventTime) as HourOfDay,
        COUNT(*) as ExecutionCount,
        AVG(Duration) as AvgDuration,
        COUNT(DISTINCT ServerPrincipalName) as ActiveUsers
    FROM util.viewExecutionModulesUsers
    WHERE EventTime > DATEADD(DAY, -7, GETDATE())
    GROUP BY DATEPART(HOUR, EventTime)
),
HourlyErrors AS (
    SELECT 
        DATEPART(HOUR, EventTime) as HourOfDay,
        COUNT(*) as ErrorCount,
        AVG(Severity) as AvgSeverity
    FROM util.xeGetErrors(DATEADD(DAY, -7, GETDATE()))
    GROUP BY DATEPART(HOUR, EventTime)
)
SELECT 
    hs.HourOfDay,
    hs.ExecutionCount,
    hs.AvgDuration / 1000.0 as AvgDurationMs,
    hs.ActiveUsers,
    ISNULL(he.ErrorCount, 0) as ErrorCount,
    ISNULL(he.AvgSeverity, 0) as AvgErrorSeverity,
    -- Індекс навантаження системи
    (hs.ExecutionCount * hs.AvgDuration / 1000000.0) as LoadIndex,
    -- Коефіцієнт помилок
    CASE 
        WHEN hs.ExecutionCount > 0 
        THEN (ISNULL(he.ErrorCount, 0) * 100.0) / hs.ExecutionCount 
        ELSE 0 
    END as ErrorRate
FROM HourlyStats hs
LEFT JOIN HourlyErrors he ON hs.HourOfDay = he.HourOfDay
ORDER BY hs.HourOfDay;
```

## Автоматизація та планове обслуговування

### 1. SQL Server Agent Jobs для обробки XE
```sql
-- Job для щоденної обробки XE даних
EXEC msdb.dbo.sp_add_job 
    @job_name = 'Pure Utils - Process XE Data',
    @description = 'Daily processing of Extended Events data into util tables';

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'Pure Utils - Process XE Data',
    @step_name = 'Process User Modules',
    @command = 'EXEC util.xeCopyModulesToTable ''Users'';';

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'Pure Utils - Process XE Data', 
    @step_name = 'Process Faust Modules',
    @command = 'EXEC util.xeCopyModulesToTable ''Faust'';';

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'Pure Utils - Process XE Data',
    @step_name = 'Process SSIS Modules', 
    @command = 'EXEC util.xeCopyModulesToTable ''SSIS'';';
```

### 2. Очистка старих даних
```sql
-- Архівування та очистка старих XE даних
CREATE PROCEDURE util.ArchiveOldXEData
    @RetentionDays INT = 90
AS
BEGIN
    DECLARE @CutoffDate DATETIME2 = DATEADD(DAY, -@RetentionDays, GETDATE());
    
    -- Архівація в історичні таблиці (опціонально)
    -- INSERT INTO util.executionModulesUsersArchive SELECT * FROM util.executionModulesUsers WHERE EventTime < @CutoffDate;
    
    -- Очистка старих даних
    DELETE FROM util.executionModulesUsers WHERE EventTime < @CutoffDate;
    DELETE FROM util.executionModulesFaust WHERE EventTime < @CutoffDate;
    DELETE FROM util.executionModulesSSIS WHERE EventTime < @CutoffDate;
    DELETE FROM util.errorLog WHERE ErrorDateTime < @CutoffDate;
    
    -- Очистка неіспользуемых SQL текстів
    DELETE st FROM util.executionSqlText st
    WHERE NOT EXISTS (
        SELECT 1 FROM util.executionModulesUsers u WHERE u.SqlTextHash = st.sqlHash OR u.StatementHash = st.sqlHash
        UNION ALL
        SELECT 1 FROM util.executionModulesFaust f WHERE f.SqlTextHash = st.sqlHash OR f.StatementHash = st.sqlHash
        UNION ALL  
        SELECT 1 FROM util.executionModulesSSIS s WHERE s.SqlTextHash = st.sqlHash OR s.StatementHash = st.sqlHash
    );
END;
```

Ця комплексна система ERROR HANDLING та EXTENDED EVENTS забезпечує повний контроль над станом SQL Server середовища, дозволяючи швидко виявляти проблеми, аналізувати продуктивність та оптимізувати роботу системи.
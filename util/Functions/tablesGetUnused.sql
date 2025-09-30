/*
# Description
Знаходить невикористовувані таблиці в базі даних на основі статистики використання індексів.
Функція аналізує DMV sys.dm_db_index_usage_stats для визначення таблиць, з яких не було читань
і опціонально таблиць, в які не було записів (якщо @WriteOnly = 0).

# Parameters
@WriteOnly BIT = 0 - режим пошуку:
  0 - шукати таблиці без читань і без записів (повністю невикористовувані)
  1 - шукати таблиці без читань (тільки таблиці для запису)

# Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- ObjectId INT - Ідентифікатор об'єкта таблиці
- TotalUserReads BIGINT - Загальна кількість операцій читання
- TotalUserWrites BIGINT - Загальна кількість операцій запису
- LastUserRead DATETIME - Час останнього читання (з усіх індексів)
- LastUserWrite DATETIME - Час останнього запису (з усіх індексів)
- IndexCount INT - Кількість індексів на таблиці
- UnusedReason NVARCHAR(200) - Причина віднесення до невикористовуваних

# Usage
-- Знайти таблиці без читань і без записів (повністю невикористовувані)
SELECT * FROM util.tablesGetUnused(0);

-- Знайти таблиці без читань (тільки для запису)
SELECT * FROM util.tablesGetUnused(1);

-- Аналіз з додатковими деталями
SELECT 
    SchemaName,
    TableName,
    UnusedReason,
    IndexCount,
    TotalUserWrites,
    LastUserWrite
FROM util.tablesGetUnused(0)
ORDER BY SchemaName, TableName;
*/
CREATE OR ALTER FUNCTION util.tablesGetUnused(@WriteOnly BIT = 0)
RETURNS TABLE
AS
RETURN(
    WITH TableUsageStats AS (
        SELECT
            t.object_id,
            s.name AS SchemaName,
            t.name AS TableName,
            -- Агрегуємо статистику по всіх індексах таблиці
            SUM(ISNULL(ius.user_seeks, 0) + ISNULL(ius.user_scans, 0) + ISNULL(ius.user_lookups, 0)) AS TotalUserReads,
            SUM(ISNULL(ius.user_updates, 0)) AS TotalUserWrites,
            MAX(ius.last_user_seek) AS LastUserSeek,
            MAX(ius.last_user_scan) AS LastUserScan, 
            MAX(ius.last_user_lookup) AS LastUserLookup,
            MAX(ius.last_user_update) AS LastUserWrite,
            COUNT(i.index_id) AS IndexCount
        FROM sys.tables t (NOLOCK)
            INNER JOIN sys.schemas s (NOLOCK) ON t.schema_id = s.schema_id
            LEFT JOIN sys.indexes i (NOLOCK) ON t.object_id = i.object_id AND i.type > 0 -- Виключаємо HEAP (type = 0)
            LEFT JOIN sys.dm_db_index_usage_stats ius (NOLOCK) ON i.object_id = ius.object_id 
                AND i.index_id = ius.index_id 
                AND ius.database_id = DB_ID()
        WHERE
            t.is_ms_shipped = 0 -- Виключаємо системні таблиці
            AND t.type = 'U' -- Тільки користувацькі таблиці
        GROUP BY t.object_id, s.name, t.name
    )
    SELECT
        tus.SchemaName,
        tus.TableName,
        tus.object_id AS ObjectId,
        tus.TotalUserReads,
        tus.TotalUserWrites,
        -- Визначаємо останнє читання з усіх типів
        CASE 
            WHEN tus.LastUserSeek >= ISNULL(tus.LastUserScan, '1900-01-01') 
                AND tus.LastUserSeek >= ISNULL(tus.LastUserLookup, '1900-01-01')
            THEN tus.LastUserSeek
            WHEN tus.LastUserScan >= ISNULL(tus.LastUserLookup, '1900-01-01')
            THEN tus.LastUserScan
            ELSE tus.LastUserLookup
        END AS LastUserRead,
        tus.LastUserWrite,
        tus.IndexCount,
        CASE
            WHEN @WriteOnly = 1 AND tus.TotalUserReads = 0 THEN
                N'Таблиця використовується тільки для запису (без читань)'
            WHEN @WriteOnly = 0 AND tus.TotalUserReads = 0 AND tus.TotalUserWrites = 0 THEN
                N'Таблиця не використовувалася зовсім (без читань і записів)'
            WHEN @WriteOnly = 0 AND tus.TotalUserReads = 0 AND tus.TotalUserWrites > 0 THEN
                N'Таблиця використовується тільки для запису (без читань)'
        END AS UnusedReason
    FROM TableUsageStats tus
    WHERE
        -- Фільтрація залежно від режиму @WriteOnly
        CASE @WriteOnly
            WHEN 1 THEN 
                -- Режим @WriteOnly = 1: тільки таблиці без читань
                CASE WHEN tus.TotalUserReads = 0 THEN 1 ELSE 0 END
            ELSE 
                -- Режим @WriteOnly = 0: таблиці без читань і без записів
                CASE WHEN tus.TotalUserReads = 0 AND tus.TotalUserWrites = 0 THEN 1 ELSE 0 END
        END = 1
);
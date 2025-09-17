/*
# Description
Знаходить відсутні індекси, які рекомендує SQL Server для покращення продуктивності запитів.
Функція аналізує DMV sys.dm_db_missing_index_* для визначення потенційно корисних індексів.

# Parameters
@object NVARCHAR(128) = NULL - Назва таблиці для аналізу відсутніх індексів (NULL = усі таблиці)

# Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- MissingIndexId INT - ID відсутнього індексу
- IndexAdvantage FLOAT - Оцінка переваги створення індексу (чим більше, тим краще)
- UserSeeks BIGINT - Кількість пошуків, які б скористалися цим індексом
- UserScans BIGINT - Кількість сканувань, які б скористалися цим індексом
- LastUserSeek DATETIME - Час останнього пошуку
- LastUserScan DATETIME - Час останнього сканування
- AvgTotalUserCost FLOAT - Середня вартість користувацьких запитів
- AvgUserImpact FLOAT - Середній відсоток покращення продуктивності
- SystemSeeks BIGINT - Кількість системних пошуків
- SystemScans BIGINT - Кількість системних сканувань
- EqualityColumns NVARCHAR(4000) - Колонки для умов рівності (WHERE col = value)
- InequalityColumns NVARCHAR(4000) - Колонки для умов нерівності (WHERE col > value)
- IncludedColumns NVARCHAR(4000) - Колонки для включення в індекс (INCLUDE)
- CreateIndexStatement NVARCHAR(MAX) - Готовий DDL для створення індексу

# Usage
-- Знайти всі відсутні індекси в базі даних
SELECT * FROM util.indexesGetMissing(NULL)
ORDER BY IndexAdvantage DESC;

-- Знайти відсутні індекси для конкретної таблиці
SELECT * FROM util.indexesGetMissing('MyTable')
ORDER BY IndexAdvantage DESC;

-- Топ-10 найбільш корисних відсутніх індексів
SELECT TOP 10 SchemaName, TableName, IndexAdvantage, CreateIndexStatement
FROM util.indexesGetMissing(NULL)
ORDER BY IndexAdvantage DESC;

-- Відсутні індекси з високим впливом на продуктивність
SELECT * FROM util.indexesGetMissing(NULL)
WHERE AvgUserImpact > 80
ORDER BY IndexAdvantage DESC;
*/
CREATE OR ALTER FUNCTION util.indexesGetMissing(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
    WITH MissingIndexes AS (
        SELECT
            OBJECT_SCHEMA_NAME(mid.object_id) AS SchemaName,
            OBJECT_NAME(mid.object_id) AS TableName,
            mid.index_handle AS MissingIndexId,
            migs.user_seeks,
            migs.user_scans,
            migs.last_user_seek,
            migs.last_user_scan,
            migs.avg_total_user_cost,
            migs.avg_user_impact,
            migs.system_seeks,
            migs.system_scans,
            mid.equality_columns,
            mid.inequality_columns,
            mid.included_columns,
            mid.object_id,
            -- Розрахунок переваги індексу
            (migs.avg_total_user_cost * migs.avg_user_impact) * (migs.user_seeks + migs.user_scans) AS IndexAdvantage
        FROM sys.dm_db_missing_index_details mid
            INNER JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
            INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
        WHERE 
            mid.database_id = DB_ID()
            AND (@object IS NULL 
                OR OBJECT_NAME(mid.object_id) = @object 
                OR mid.object_id = TRY_CONVERT(INT, @object)
                OR OBJECT_ID(@object) = mid.object_id)
    )
    SELECT
        object_id objectId,
        SchemaName,
        TableName,
        MissingIndexId,
        CAST(IndexAdvantage AS FLOAT) AS IndexAdvantage,
        user_seeks AS UserSeeks,
        user_scans AS UserScans,
        last_user_seek AS LastUserSeek,
        last_user_scan AS LastUserScan,
        avg_total_user_cost AS AvgTotalUserCost,
        avg_user_impact AS AvgUserImpact,
        system_seeks AS SystemSeeks,
        system_scans AS SystemScans,
        equality_columns AS EqualityColumns,
        inequality_columns AS InequalityColumns,
        included_columns AS IncludedColumns,
        -- Генерація DDL для створення індексу
        CONCAT(
            'CREATE NONCLUSTERED INDEX [IX_', TableName, '_Missing_', 
            CAST(MissingIndexId AS NVARCHAR), '] ON [', SchemaName, '].[', TableName, '] (',
            CASE 
                WHEN equality_columns IS NOT NULL AND inequality_columns IS NOT NULL 
                THEN equality_columns + ', ' + inequality_columns
                WHEN equality_columns IS NOT NULL 
                THEN equality_columns
                WHEN inequality_columns IS NOT NULL 
                THEN inequality_columns
                ELSE ''
            END,
            ')',
            CASE 
                WHEN included_columns IS NOT NULL 
                THEN ' INCLUDE (' + included_columns + ')'
                ELSE ''
            END,
            ';'
        ) AS CreateIndexStatement
    FROM MissingIndexes
    WHERE IndexAdvantage > 0  -- Показуємо тільки індекси з позитивною перевагою
);
/*
# Description
Отримує детальну інформацію про сторінку бази даних на основі lock hash з KEY блокування.
Процедура працює з недокументованими колонками %%lockres%% та %%physloc%% для знаходження
фізичного розташування запису, який викликав блокування типу KEY.

Використовується для аналізу KEY блокувань (hash-based locks) на відміну від PAGE блокувань.

# Parameters
@keyString NVARCHAR(200) - Рядок з KEY блокування у форматі "dbid:hobt_id (lock_hash)"
                           Наприклад: "5:72057594044284928 (abc123def456)"
@object NVARCHAR(128) - Назва об'єкта (таблиці) в якому шукати lock hash

# Returns
Результат з sys.dm_db_page_info:
- database_id - ID бази даних
- file_id - ID файлу даних
- page_id - ID сторінки
- page_type_desc - Опис типу сторінки (DATA_PAGE, INDEX_PAGE, тощо)
- object_id - ID об'єкта (таблиці)
- schemaName - Назва схеми об'єкта
- objectName - Назва об'єкта
- index_id - ID індексу
- is_allocated - Чи виділена сторінка
- та інші колонки детальної інформації про сторінку

# Usage
-- Аналіз KEY блокування
EXEC util.pageGetInfoByLockHash 
    @keyString = '5:72057594044284928 (abc123def456)',
    @object = 'cfg.sql_databases';

-- Аналіз з sys.dm_tran_locks
DECLARE @lockKey NVARCHAR(200);
SELECT TOP 1 @lockKey = CONCAT(resource_database_id, ':', resource_associated_entity_id, ' (', resource_description, ')')
FROM sys.dm_tran_locks
WHERE resource_type = 'KEY';

EXEC util.pageGetInfoByLockHash 
    @keyString = @lockKey,
    @object = 'dbo.MyTable';
*/
CREATE OR ALTER PROCEDURE util.pageGetInfoByLockHash
    @keyString NVARCHAR(200), 
    @object NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @dbId INT = TRY_CAST(LEFT(@keyString, CHARINDEX(':', @keyString) - 1) AS INT);
    DECLARE @lockHash NVARCHAR(50) = SUBSTRING(@keyString, CHARINDEX('(', @keyString) + 1, CHARINDEX(')', @keyString) - CHARINDEX('(', @keyString) - 1);
    DECLARE @fileId INT;
    DECLARE @pageId BIGINT;
    DECLARE @sql NVARCHAR(MAX);

    -- Крок 1: Знайти file_id та page_id через %%lockres%% та %%physloc%%
    SET @sql = CONCAT(
        'USE ', QUOTENAME(DB_NAME(@dbId)), ';
        WITH cte AS (
            SELECT %%lockres%% lockRes, sys.fn_PhysLocFormatter(%%physloc%%) physLoc
            FROM ', @object, '
            WHERE %%lockres%% = @LockHash
        )
        SELECT 
            @FileId = CAST(SUBSTRING(physLoc, 2, CHARINDEX('':'', physLoc) - 2) AS INT),
            @PageId = CAST(SUBSTRING(physLoc,
                CHARINDEX('':'', physLoc) + 1,
                CHARINDEX('':'', physLoc, CHARINDEX('':'', physLoc) + 1) - CHARINDEX('':'', physLoc) - 1) AS BIGINT)
        FROM cte;'
    );
    
    EXEC sp_executesql 
        @sql, 
        N'@LockHash NVARCHAR(50), @FileId INT OUTPUT, @PageId BIGINT OUTPUT', 
        @lockHash, 
        @fileId OUTPUT, 
        @pageId OUTPUT;

    -- Крок 2: Отримати детальну інформацію про сторінку
    -- ВАЖЛИВО: sys.dm_db_page_info працює тільки в контексті поточної БД
    SET @sql = CONCAT(
        'USE ', QUOTENAME(DB_NAME(@dbId)), ';
        SELECT 
            DB_ID() database_id,
            file_id,
            page_id,
            page_type,
            page_type_desc,
            page_level,
            object_id,
            OBJECT_SCHEMA_NAME(object_id) schemaName,
            OBJECT_NAME(object_id) objectName,
            index_id,
            partition_id,
            allocation_unit_id,
            allocation_unit_type_desc,
            is_allocated,
            is_iam_page,
            is_mixed_page_allocation,
            page_free_space_percent,
            page_lsn,
            modify_lsn
        FROM sys.dm_db_page_info(@FileId, @PageId, ''DETAILED'');'
    );

    EXEC sp_executesql 
        @sql,
        N'@FileId INT, @PageId BIGINT',
        @fileId,
        @pageId;
END;
GO
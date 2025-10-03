/*
# Description
Процедура для отримання детальної інформації про таблицю через MCP протокол.
Повертає валідний JSON для MCP відповіді з повною інформацією про таблицю,
включаючи назву, опис, дату створення, кількість рядків, колонки та індекси.

# Parameters
@database NVARCHAR(128) - Назва бази даних
@table NVARCHAR(128) - Назва таблиці (може бути у форматі schema.table або просто table)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить детальну інформацію про таблицю

# Usage
-- Отримати інформацію про таблицю
EXEC mcp.GetTableInfo @database = 'utils', @table = 'dbo.events_notifications';

-- Або без схеми (буде використано dbo)
EXEC mcp.GetTableInfo @database = 'utils', @table = 'events_notifications';
*/
CREATE OR ALTER PROCEDURE mcp.GetTableInfo
    @database NVARCHAR(128),
    @table NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tableInfo NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);

    -- Парсинг схеми та таблиці
    DECLARE @schemaName NVARCHAR(128) = PARSENAME(@table, 2);
    DECLARE @tableName NVARCHAR(128) = PARSENAME(@table, 1);
    
    -- Якщо схема не вказана, використовуємо dbo
    IF @schemaName IS NULL
    BEGIN
        SET @schemaName = 'dbo';
        SET @tableName = @table;
    END;

    -- Формуємо динамічний SQL для отримання інформації про таблицю
    SET @sql = CONCAT(N'
    USE ', QUOTENAME(@database), N';
    
    DECLARE @tableInfo NVARCHAR(MAX);
    
    -- Перевірка існування таблиці
    IF NOT EXISTS (
        SELECT 1 
        FROM sys.tables t
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = @schemaName AND t.name = @tableName
    )
    BEGIN
        SET @tableInfo = (
            SELECT ''Table not found'' AS error
            FOR JSON PATH
        );
        SELECT @tableInfo AS tableInfo;
        RETURN;
    END;

    DECLARE @objectId INT;
    SELECT @objectId = t.object_id
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = @schemaName AND t.name = @tableName;

    -- Основна інформація про таблицю
    DECLARE @name NVARCHAR(256);
    DECLARE @description NVARCHAR(MAX);
    DECLARE @createDate NVARCHAR(30);
    DECLARE @rowCount BIGINT;

    SELECT 
        @name = CONCAT(s.name, ''.'', t.name),
        @createDate = CONVERT(VARCHAR(23), t.create_date, 126),
        @rowCount = SUM(p.rows)
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    LEFT JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
    WHERE t.object_id = @objectId
    GROUP BY s.name, t.name, t.create_date;

    -- Отримання опису через util функцію
    DECLARE @descSql NVARCHAR(MAX) = CONCAT(
        ''SELECT @desc = '', 
        QUOTENAME(@database), 
        ''.util.metadataGetObjectName('', 
        @objectId, 
        '')''
    );
    EXEC sp_executesql @descSql, N''@desc NVARCHAR(MAX) OUTPUT'', @desc = @description OUTPUT;

    -- Колонки таблиці
    DECLARE @columns NVARCHAR(MAX);
    SELECT @columns = (
        SELECT 
            c.name,
            CASE
                WHEN tp.name IN (''varchar'', ''char'', ''varbinary'', ''binary'', ''text'') THEN 
                    CONCAT(tp.name, ''('', CASE WHEN c.max_length = -1 THEN ''MAX'' ELSE CAST(c.max_length AS NVARCHAR(10)) END, '')'')
                WHEN tp.name IN (''nvarchar'', ''nchar'', ''ntext'') THEN 
                    CONCAT(tp.name, ''('', CASE WHEN c.max_length = -1 THEN ''MAX'' ELSE CAST(c.max_length / 2 AS NVARCHAR(10)) END, '')'')
                WHEN tp.name IN (''decimal'', ''numeric'') THEN 
                    CONCAT(tp.name, ''('', CAST(c.precision AS NVARCHAR(10)), '','', CAST(c.scale AS NVARCHAR(10)), '')'')
                WHEN tp.name IN (''datetime2'', ''time'', ''datetimeoffset'') THEN 
                    CONCAT(tp.name, ''('', CAST(c.scale AS NVARCHAR(10)), '')'')
                ELSE tp.name
            END AS [type]
        FROM sys.columns c
        INNER JOIN sys.types tp ON c.user_type_id = tp.user_type_id
        WHERE c.object_id = @objectId
        ORDER BY c.column_id
        FOR JSON PATH
    );

    -- Індекси таблиці з детальною інформацією
    DECLARE @indexes NVARCHAR(MAX);
    SELECT @indexes = (
        SELECT 
            i.name,
            (
                SELECT DISTINCT p.partition_number
                FROM sys.partitions p
                WHERE p.object_id = i.object_id AND p.index_id = i.index_id
                FOR JSON PATH
            ) AS partitions,
            (
                SELECT TOP 1 
                    CAST(SUM(a.total_pages) * 8 / 1024.0 AS DECIMAL(10, 2)) AS totalSpaceMB,
                    CAST(SUM(a.used_pages) * 8 / 1024.0 AS DECIMAL(10, 2)) AS usedSpaceMB,
                    CAST(SUM(a.data_pages) * 8 / 1024.0 AS DECIMAL(10, 2)) AS dataSpaceMB
                FROM sys.partitions p
                INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
                WHERE p.object_id = i.object_id AND p.index_id = i.index_id
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            ) AS spaceUsed,
            (
                SELECT 
                    c.name
                FROM sys.index_columns ic
                INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                WHERE ic.object_id = i.object_id 
                    AND ic.index_id = i.index_id 
                    AND ic.is_included_column = 0
                ORDER BY ic.key_ordinal
                FOR JSON PATH
            ) AS keyColumns,
            (
                SELECT 
                    c.name
                FROM sys.index_columns ic
                INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                WHERE ic.object_id = i.object_id 
                    AND ic.index_id = i.index_id 
                    AND ic.is_included_column = 1
                ORDER BY ic.index_column_id
                FOR JSON PATH
            ) AS includeColumns
        FROM sys.indexes i
        WHERE i.object_id = @objectId AND i.name IS NOT NULL
        ORDER BY i.index_id
        FOR JSON PATH
    );

    -- Формуємо фінальний JSON
    SET @tableInfo = (
        SELECT 
            @name AS name,
            @description AS description,
            @createDate AS createDate,
            @rowCount AS rowCount,
            JSON_QUERY(@columns) AS [columns],
            JSON_QUERY(@indexes) AS indexes
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    SELECT @tableInfo AS tableInfo;
    ');

    -- Виконуємо динамічний SQL
    EXEC sp_executesql @sql, 
        N'@schemaName NVARCHAR(128), @tableName NVARCHAR(128), @database NVARCHAR(128), @tableInfo NVARCHAR(MAX) OUTPUT', 
        @schemaName = @schemaName, 
        @tableName = @tableName,
        @database = @database,
        @tableInfo = @tableInfo OUTPUT;

    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (
        SELECT
            'text' AS [type],
            ISNULL(@tableInfo, '{"error":"Unable to retrieve table information"}') AS [text]
        FOR JSON PATH
    );

    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');

    SELECT @result AS result;
END;
GO

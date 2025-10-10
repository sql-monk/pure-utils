/*
# Description
Процедура для отримання відсутніх індексів через MCP протокол.
Повертає валідний JSON для MCP відповіді з інформацією про індекси, які рекомендує SQL Server
для покращення продуктивності запитів в зазначеній базі даних.

# Parameters
@database NVARCHAR(128) - Назва бази даних для аналізу відсутніх індексів
@object NVARCHAR(128) = NULL - Назва таблиці для аналізу відсутніх індексів (NULL = усі таблиці)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить інформацію про відсутні індекси

# Usage
-- Отримати всі відсутні індекси в базі даних
EXEC mcp.GetIndexesMissing @database = 'utils';

-- Отримати відсутні індекси конкретної таблиці
EXEC mcp.GetIndexesMissing @database = 'utils', @object = 'myTable';
*/
CREATE OR ALTER PROCEDURE mcp.GetIndexesMissing
    @database NVARCHAR(128),
    @object NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @missingIndexes NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);

    -- Формуємо динамічний SQL для отримання missing indexes з вказаної бази даних
    SET @sql = N'
    USE ' + QUOTENAME(@database) + N';
    
    SELECT @missingIndexes = (
        SELECT
            objectId,
            SchemaName,
            TableName,
            MissingIndexId,
            IndexAdvantage,
            UserSeeks,
            UserScans,
            CONVERT(VARCHAR(23), LastUserSeek, 126) LastUserSeek,
            CONVERT(VARCHAR(23), LastUserScan, 126) LastUserScan,
            AvgTotalUserCost,
            AvgUserImpact,
            SystemSeeks,
            SystemScans,
            EqualityColumns,
            InequalityColumns,
            IncludedColumns,
            CreateIndexStatement
        FROM util.indexesGetMissing(@object)
        ORDER BY
            IndexAdvantage DESC
        FOR JSON PATH
    );';

    -- Виконуємо динамічний SQL
    EXEC sys.sp_executesql 
        @sql, 
        N'@missingIndexes NVARCHAR(MAX) OUTPUT, @object NVARCHAR(128)', 
        @missingIndexes = @missingIndexes OUTPUT, 
        @object = @object;

    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (SELECT 'text' type, ISNULL(@missingIndexes, '[]') text FOR JSON PATH);

    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');

    SELECT @result result;
END;
GO

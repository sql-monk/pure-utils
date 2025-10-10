/*
# Description
Процедура для отримання невикористовуваних індексів через MCP протокол.
Повертає валідний JSON для MCP відповіді з інформацією про індекси, які не використовувались
для операцій читання в зазначеній базі даних.

# Parameters
@database NVARCHAR(128) - Назва бази даних для аналізу індексів
@object NVARCHAR(128) = NULL - Назва таблиці для аналізу індексів (NULL = усі таблиці)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить інформацію про невикористовувані індекси

# Usage
-- Отримати всі невикористовувані індекси в базі даних
EXEC mcp.GetIndexesUnused @database = 'utils';

-- Отримати невикористовувані індекси конкретної таблиці
EXEC mcp.GetIndexesUnused @database = 'utils', @object = 'myTable';
*/
CREATE OR ALTER PROCEDURE mcp.GetIndexesUnused
    @database NVARCHAR(128),
    @object NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @unusedIndexes NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);

    -- Формуємо динамічний SQL для отримання unused indexes з вказаної бази даних
    SET @sql = N'
    USE ' + QUOTENAME(@database) + N';
    
    SELECT @unusedIndexes = (
        SELECT
            objectId,
            indexId,
            SchemaName,
            TableName,
            IndexName,
            IndexType,
            UnusedReason
        FROM util.indexesGetUnused(@object)
        ORDER BY
            SchemaName,
            TableName,
            IndexName
        FOR JSON PATH
    );';

    -- Виконуємо динамічний SQL
    EXEC sys.sp_executesql 
        @sql, 
        N'@unusedIndexes NVARCHAR(MAX) OUTPUT, @object NVARCHAR(128)', 
        @unusedIndexes = @unusedIndexes OUTPUT, 
        @object = @object;

    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (SELECT 'text' type, ISNULL(@unusedIndexes, '[]') text FOR JSON PATH);

    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');

    SELECT @result result;
END;
GO

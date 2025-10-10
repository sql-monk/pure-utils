/*
# Description
Процедура для отримання DDL скриптів індексів через MCP протокол.
Повертає валідний JSON для MCP відповіді з готовими CREATE INDEX скриптами
для існуючих індексів таблиць в зазначеній базі даних.

# Parameters
@database NVARCHAR(128) - Назва бази даних для генерації скриптів індексів
@table NVARCHAR(128) = NULL - Назва таблиці для генерації скриптів індексів (NULL = усі таблиці)
@index NVARCHAR(128) = NULL - Назва конкретного індексу (NULL = усі індекси)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить DDL скрипти індексів

# Usage
-- Згенерувати скрипти для всіх індексів в базі даних
EXEC mcp.GetIndexesScript @database = 'utils';

-- Згенерувати скрипти для всіх індексів конкретної таблиці
EXEC mcp.GetIndexesScript @database = 'utils', @table = 'myTable';

-- Згенерувати скрипт для конкретного індексу
EXEC mcp.GetIndexesScript @database = 'utils', @table = 'myTable', @index = 'myIndex';
*/
CREATE OR ALTER PROCEDURE mcp.GetIndexesScript
    @database NVARCHAR(128),
    @table NVARCHAR(128) = NULL,
    @index NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @indexScripts NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);

    -- Формуємо динамічний SQL для отримання index scripts з вказаної бази даних
    SET @sql = N'
    USE ' + QUOTENAME(@database) + N';
    
    SELECT @indexScripts = (
        SELECT
            tableName,
            statement
        FROM util.indexesGetScript(@table, @index)
        ORDER BY
            tableName
        FOR JSON PATH
    );';

    -- Виконуємо динамічний SQL
    EXEC sys.sp_executesql 
        @sql, 
        N'@indexScripts NVARCHAR(MAX) OUTPUT, @table NVARCHAR(128), @index NVARCHAR(128)', 
        @indexScripts = @indexScripts OUTPUT, 
        @table = @table,
        @index = @index;

    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (SELECT 'text' type, ISNULL(@indexScripts, '[]') text FOR JSON PATH);

    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');

    SELECT @result result;
END;
GO

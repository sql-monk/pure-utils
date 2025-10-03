/*
# Description
Процедура для отримання списку представлень (views) через MCP протокол.
Повертає валідний JSON для MCP відповіді з інформацією про представлення в зазначеній базі даних,
включаючи назву схеми, представлення, дату створення та дату модифікації.

# Parameters
@database NVARCHAR(128) - Назва бази даних для отримання списку представлень
@filter NVARCHAR(128) = NULL - Фільтр за назвою представлення (підтримує LIKE Pattern)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить інформацію про представлення

# Usage
-- Отримати всі представлення в базі даних
EXEC mcp.GetViews @database = 'utils';

-- Отримати представлення з фільтром
EXEC mcp.GetViews @database = 'utils', @filter = 'v%';
*/
CREATE OR ALTER PROCEDURE mcp.GetViews
    @database NVARCHAR(128),
    @filter NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @views NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);

    -- Формуємо динамічний SQL для отримання представлень з вказаної бази даних
    SET @sql = N'
    USE ' + QUOTENAME(@database) + N';
    
    SELECT @views = (
        SELECT
            SCHEMA_NAME(v.schema_id) AS schemaName,
            v.name AS viewName,
            v.object_id AS objectId,
            CONVERT(VARCHAR(23), v.create_date, 126) AS createDate,
            CONVERT(VARCHAR(23), v.modify_date, 126) AS modifyDate,
            v.type_desc AS typeDesc
        FROM sys.views v
        WHERE v.is_ms_shipped = 0
            AND (v.name LIKE ISNULL(@filter, ''%''))
        ORDER BY
            SCHEMA_NAME(v.schema_id),
            v.name
        FOR JSON PATH
    );';

    -- Виконуємо динамічний SQL
    EXEC sp_executesql @sql, N'@views NVARCHAR(MAX) OUTPUT, @filter NVARCHAR(128)', @views = @views OUTPUT, @filter = @filter;

    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (
        SELECT
            'text' AS [type],
            ISNULL(@views, '[]') AS [text]
        FOR JSON PATH
    );

    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');

    SELECT @result AS result;
END;
GO

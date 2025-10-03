/*
# Description
Процедура для отримання списку процедур через MCP протокол.
Повертає валідний JSON для MCP відповіді з інформацією про збережені процедури в зазначеній базі даних,
включаючи назву схеми, процедури, дату створення та дату модифікації.

# Parameters
@database NVARCHAR(128) - Назва бази даних для отримання списку процедур
@filter NVARCHAR(128) = NULL - Фільтр за назвою процедури (підтримує LIKEPattern)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить інформацію про процедури

# Usage
-- Отримати всі процедури в базі даних
EXEC mcp.GetProcedures @database = 'utils';

-- Отримати процедури з фільтром
EXEC mcp.GetProcedures @database = 'utils', @filter = 'Get%';
*/
CREATE OR ALTER PROCEDURE mcp.GetProcedures
	@database NVARCHAR(128),
	@filter NVARCHAR(128) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	IF(LEN(TRIM(@filter)) = 0)
	BEGIN
		SET @filter = NULL;
	END;
	DECLARE @procedures NVARCHAR(MAX);
	DECLARE @content NVARCHAR(MAX);
	DECLARE @result NVARCHAR(MAX);
	DECLARE @sql NVARCHAR(MAX);

	-- Формуємо динамічний SQL для отримання процедур з вказаної бази даних
	SET @sql
		= N'
    USE ' + QUOTENAME(@database)
			+ N';
    
    SELECT @procedures = (
        SELECT
            SCHEMA_NAME(p.schema_id) AS schemaName,
            p.name AS procedureName,
            p.object_id AS objectId,
            CONVERT(VARCHAR(23), p.create_date, 126) AS createDate,
            CONVERT(VARCHAR(23), p.modify_date, 126) AS modifyDate,
            p.type_desc AS typeDesc
        FROM sys.procedures p
        WHERE p.is_ms_shipped = 0
            AND (p.name LIKE ISNULL(@filter, ''%''))
        ORDER BY
            SCHEMA_NAME(p.schema_id),
            p.name
        FOR JSON PATH
    );';

	-- Виконуємо динамічний SQL
	EXEC sys.sp_executesql @sql, N'@procedures NVARCHAR(MAX) OUTPUT, @filter NVARCHAR(128)', @procedures = @procedures OUTPUT, @filter = @filter;

	-- Формуємо масив content з одним елементом типу text
	SELECT @content = (SELECT 'text' type, ISNULL(@procedures, '[]') text FOR JSON PATH);

	-- Обгортаємо у фінальну структуру MCP відповіді
	SET @result = CONCAT('{"content":', @content, '}');

	SELECT @result result;
END;
GO

/*
# Description
Процедура для отримання списку таблиць через MCP протокол.
Повертає валідний JSON для MCP відповіді з інформацією про таблиці в зазначеній базі даних,
включаючи назву схеми, таблиці, дату створення, дату модифікації та кількість рядків.

# Parameters
@database NVARCHAR(128) - Назва бази даних для отримання списку таблиць
@filter NVARCHAR(128) = NULL - Фільтр за назвою таблиці (підтримує LIKE Pattern)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить інформацію про таблиці

# Usage
-- Отримати всі таблиці в базі даних
EXEC mcp.GetTables @database = 'utils';

-- Отримати таблиці з фільтром
EXEC mcp.GetTables @database = 'utils', @filter = 'events%';
*/
CREATE OR ALTER PROCEDURE mcp.GetTables
	@database NVARCHAR(128),
	@filter NVARCHAR(128) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	IF(LEN(TRIM(@filter)) = 0)
	BEGIN
		SET @filter = NULL;
	END;
	DECLARE @tables NVARCHAR(MAX);
	DECLARE @content NVARCHAR(MAX);
	DECLARE @result NVARCHAR(MAX);
	DECLARE @sql NVARCHAR(MAX);

	-- Формуємо динамічний SQL для отримання таблиць з вказаної бази даних
	SET @sql
		= N'
    USE ' + QUOTENAME(@database)
			+ N';
    
    SELECT @tables = (
        SELECT
            SCHEMA_NAME(t.schema_id) schemaName,
            t.name tableName,
            t.object_id objectId,
            CONVERT(VARCHAR(23), t.create_date, 126) createDate,
            CONVERT(VARCHAR(23), t.modify_date, 126) modifyDate,
            t.type_desc typeDesc,
            SUM(p.rows) rowsCount
        FROM sys.tables t
            LEFT JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
        WHERE t.is_ms_shipped = 0
            AND (t.name LIKE ISNULL(@filter, ''%''))
        GROUP BY
            t.schema_id,
            t.name,
            t.object_id,
            t.create_date,
            t.modify_date,
            t.type_desc
        ORDER BY
            SCHEMA_NAME(t.schema_id),
            t.name
        FOR JSON PATH
    );';

	-- Виконуємо динамічний SQL
	EXEC sys.sp_executesql @sql, N'@tables NVARCHAR(MAX) OUTPUT, @filter NVARCHAR(128)', @tables = @tables OUTPUT, @filter = @filter;

	-- Формуємо масив content з одним елементом типу text
	SELECT @content = (SELECT 'text' type, ISNULL(@tables, '[]') text FOR JSON PATH);

	-- Обгортаємо у фінальну структуру MCP відповіді
	SET @result = CONCAT('{"content":', @content, '}');

	SELECT @result result;
END;
GO

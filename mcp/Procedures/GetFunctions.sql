/*
# Description
Процедура для отримання списку функцій через MCP протокол.
Повертає валідний JSON для MCP відповіді з інформацією про функції в зазначеній базі даних,
включаючи назву схеми, функції, тип функції, дату створення та дату модифікації.

# Parameters
@database NVARCHAR(128) - Назва бази даних для отримання списку функцій

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить інформацію про функції

# Usage
-- Отримати всі функції в базі даних
EXEC mcp.GetFunctions @database = 'utils';
*/
CREATE OR ALTER PROCEDURE mcp.GetFunctions
	@database NVARCHAR(128),
	@filter NVARCHAR(128) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	IF(LEN(TRIM(@filter)) = 0)
	BEGIN
		SET @filter = NULL;
	END;

	DECLARE @functions NVARCHAR(MAX);
	DECLARE @content NVARCHAR(MAX);
	DECLARE @result NVARCHAR(MAX);
	DECLARE @sql NVARCHAR(MAX);

	-- Формуємо динамічний SQL для отримання функцій з вказаної бази даних
	SET @sql
		= N'
    USE ' + QUOTENAME(@database)
			+ N';
    
    SELECT @functions = (
        SELECT
            SCHEMA_NAME(o.schema_id) AS schemaName,
            o.name AS functionName,
            o.object_id AS objectId,
            CONVERT(VARCHAR(23), o.create_date, 126) AS createDate,
            CONVERT(VARCHAR(23), o.modify_date, 126) AS modifyDate,
            o.type_desc AS typeDesc,
            CASE o.type
                WHEN ''FN'' THEN ''SCALAR_FUNCTION''
                WHEN ''IF'' THEN ''INLINE_TABLE_VALUED_FUNCTION''
                WHEN ''TF'' THEN ''TABLE_VALUED_FUNCTION''
                WHEN ''FS'' THEN ''CLR_SCALAR_FUNCTION''
                WHEN ''FT'' THEN ''CLR_TABLE_VALUED_FUNCTION''
                ELSE o.type_desc
            END AS functionType
        FROM sys.objects o
        WHERE 
            o.type IN (''FN'', ''IF'', ''TF'', ''FS'', ''FT'')
            AND o.is_ms_shipped = 0
            AND (o.name LIKE ISNULL(@filter, ''%''))
        ORDER BY
            SCHEMA_NAME(o.schema_id),
            o.name
        FOR JSON PATH
    );';

	-- Виконуємо динамічний SQL
	EXEC sys.sp_executesql @sql, N'@filter nvarchar(128), @functions NVARCHAR(MAX) OUTPUT', @filter = @filter, @functions = @functions OUTPUT;

	-- Формуємо масив content з одним елементом типу text
	SELECT @content = (SELECT 'text' type, ISNULL(@functions, '[]') text FOR JSON PATH);

	-- Обгортаємо у фінальну структуру MCP відповіді
	SET @result = CONCAT('{"content":', @content, '}');

	SELECT @result result;
END;
GO

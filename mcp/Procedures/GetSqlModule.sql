/*
# Description
Процедура для отримання інформації про SQL модуль (процедура, функція, представлення тощо) через MCP протокол.
Повертає валідний JSON для MCP відповіді з детальною інформацією про модуль,
включаючи дату створення, тип, визначення, опис та інші властивості.

# Parameters
@name NVARCHAR(128) - Назва SQL модуля (може бути з схемою, наприклад 'mcp.GetTables')

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить інформацію про SQL модуль

# Usage
-- Отримати інформацію про процедуру
EXEC mcp.GetSqlModule @name = 'mcp.GetTables';

-- Отримати інформацію про функцію
EXEC mcp.GetSqlModule @name = 'util.metadataGetDescriptions';

-- Отримати інформацію про представлення
EXEC mcp.GetSqlModule @name = 'dbo.vwCustomers';
*/
CREATE OR ALTER PROCEDURE mcp.GetSqlModule
	@name NVARCHAR(128)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @moduleInfo NVARCHAR(MAX);
	DECLARE @content NVARCHAR(MAX);
	DECLARE @result NVARCHAR(MAX);
	DECLARE @errorMessage NVARCHAR(MAX);

	BEGIN TRY
		-- Перевіряємо чи існує об'єкт
		IF OBJECT_ID(@name) IS NULL
		BEGIN
			SET @errorMessage = CONCAT('SQL модуль не знайдено: ', @name);
			
			-- Формуємо error response для MCP
			SELECT @content = (
				SELECT 
					'text' [type], 
					STRING_ESCAPE(@errorMessage, 'json') [text] 
				FOR JSON PATH
			);
			
			SET @result = CONCAT('{"content":', @content, ',"isError":true}');
			SELECT @result result;
			RETURN;
		END

		-- Отримуємо інформацію про SQL модуль
		SELECT @moduleInfo = (
			SELECT
				OBJECT_SCHEMA_NAME(o.object_id) schemaName,
				OBJECT_NAME(o.object_id) objectName,
				o.type objectType,
				o.type_desc typeDesc,
				CONVERT(VARCHAR(23), o.create_date, 126) createDate,
				CONVERT(VARCHAR(23), o.modify_date, 126) modifyDate,
				sm.uses_ansi_nulls usesAnsiNulls,
				sm.uses_quoted_identifier usesQuotedIdentifier,
				sm.is_schema_bound isSchemaBound,
				sm.null_on_null_input nullOnNullInput,
				CASE 
					WHEN sm.inline_type = 0 THEN 'Not inline'
					WHEN sm.inline_type = 1 THEN 'Inline'
					WHEN sm.inline_type = 2 THEN 'Multi-statement'
					ELSE 'Unknown'
				END inlineType,
				USER_NAME(sm.execute_as_principal_id) executeAs,
				sm.definition definition,
				(
					SELECT TOP 1 d.description
					FROM util.metadataGetDescriptions(o.object_id, DEFAULT) d
				) description
			FROM sys.objects o
				JOIN sys.sql_modules sm ON sm.object_id = o.object_id
			WHERE o.object_id = OBJECT_ID(@name)
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
		);

		-- Перевіряємо чи отримали дані
		IF @moduleInfo IS NULL OR LEN(@moduleInfo) = 0
		BEGIN
			SET @errorMessage = CONCAT('Не вдалося отримати інформацію про модуль: ', @name);
			
			SELECT @content = (
				SELECT 
					'text' [type], 
					STRING_ESCAPE(@errorMessage, 'json') [text] 
				FOR JSON PATH
			);
		END
		ELSE
		BEGIN
			-- Формуємо масив content з одним елементом типу text
			SELECT @content = (
				SELECT 
					'text' [type], 
					@moduleInfo [text] 
				FOR JSON PATH
			);
		END

		-- Обгортаємо у фінальну структуру MCP відповіді
		SET @result = CONCAT('{"content":', @content, '}');

		SELECT @result result;
	END TRY
	BEGIN CATCH
		-- Обробка помилок
		SET @errorMessage = CONCAT(
			'Помилка при отриманні інформації про модуль "', 
			@name, 
			'": ', 
			ERROR_MESSAGE(),
			' (Error ', 
			ERROR_NUMBER(), 
			', Line ', 
			ERROR_LINE(), 
			')'
		);

		-- Екрануємо повідомлення про помилку для JSON
		DECLARE @escapedError NVARCHAR(MAX) = STRING_ESCAPE(@errorMessage, 'json');

		-- Формуємо error response для MCP
		SELECT @content = (
			SELECT 
				'text' [type], 
				@escapedError [text] 
			FOR JSON PATH
		);

		SET @result = CONCAT('{"content":', @content, ',"isError":true}');

		SELECT @result result;
	END CATCH
END;
GO

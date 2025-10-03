/*
# Description
Процедура для отримання SQL скрипту об'єкта разом з усіма його залежностями через MCP протокол.
Повертає валідний JSON для MCP відповіді з SQL скриптом, який включає всі необхідні залежності
в правильному порядку (спочатку залежності, потім сам об'єкт).

# Parameters
@objectFullName NVARCHAR(128) - Повне ім'я об'єкта у форматі 'database.schema.object'

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить SQL скрипт

# Usage
-- Отримати скрипт таблиці з усіма залежностями
EXEC mcp.ScriptObjectAndReferences @objectFullName = 'DataWareHouse.dbo.[Faust.DFM.CardOpers]';

-- Отримати скрипт процедури з залежностями
EXEC mcp.ScriptObjectAndReferences @objectFullName = 'utils.util.metadataGetDescriptions';

-- Отримати скрипт view з залежностями
EXEC mcp.ScriptObjectAndReferences @objectFullName = 'dwh.solar.vwCustomers';
*/
CREATE OR ALTER PROCEDURE mcp.ScriptObjectAndReferences
	@objectFullName NVARCHAR(128)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @outputScript NVARCHAR(MAX);
	DECLARE @content NVARCHAR(MAX);
	DECLARE @result NVARCHAR(MAX);
	DECLARE @errorMessage NVARCHAR(MAX);

	BEGIN TRY
		-- Викликаємо процедуру для генерації скрипту з залежностями
		EXEC util.objectScriptWithDependencies
			@objectFullName = @objectFullName,
			@outputScript = @outputScript OUTPUT;

		-- Перевіряємо чи отримали скрипт
		IF @outputScript IS NULL OR LEN(@outputScript) = 0
		BEGIN
			SET @errorMessage = CONCAT('Не вдалося згенерувати скрипт для об''єкта: ', @objectFullName);
			
			-- Формуємо error response для MCP
			SELECT @content = (
				SELECT 
					'text' [type], 
					@errorMessage [text] 
				FOR JSON PATH
			);
		END
		ELSE
		BEGIN
			-- Екрануємо SQL скрипт для JSON
			DECLARE @escapedScript NVARCHAR(MAX) = STRING_ESCAPE(@outputScript, 'json');
			
			-- Формуємо масив content з одним елементом типу text
			SELECT @content = (
				SELECT 
					'text' [type], 
					@escapedScript [text] 
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
			'Помилка при генерації скрипту для об''єкта "', 
			@objectFullName, 
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

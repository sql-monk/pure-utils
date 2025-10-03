/*
# Description
Процедура для пошуку останнього плану виконання модуля через MCP протокол.
Повертає валідний JSON для MCP відповіді з планом виконання.

# Parameters
@object NVARCHAR(128) - Повне ім'я об'єкта (може включати database.schema.object)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить план виконання

# Usage
EXEC mcp.FindLastModulePlan @object = 'utils.dbo.myProcedure';
*/
CREATE OR ALTER PROCEDURE mcp.FindLastModulePlan @object NVARCHAR(128)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @plan NVARCHAR(MAX);
	DECLARE @result NVARCHAR(MAX);

	-- Викликаємо util процедуру для отримання плану
	BEGIN TRY
		EXEC util.executionSearchPlanByObjectName @fullObjectName = @object, @plan = @plan OUTPUT;
	END TRY
	BEGIN CATCH
		-- Обробка помилок
		SET @plan = (
			SELECT ERROR_NUMBER() errorNumber, ERROR_MESSAGE() errorMessage FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
		);
	END CATCH;

	-- Формуємо валідну MCP відповідь
	IF @plan IS NULL OR @plan = ''
	BEGIN
		-- План не знайдено
		SET @result = (
			SELECT 'text' type, 'Execution plan not found for object: ' + @object text FOR JSON PATH
		);
	END;
	ELSE IF @plan LIKE '%"errorNumber"%'
	BEGIN
		-- Помилка виконання
		SET @result = (
			SELECT 'text' type, JSON_QUERY(@plan) text FOR JSON PATH
		);
	END;
	ELSE
	BEGIN
		-- План знайдено - повертаємо як текст
		SET @result = (SELECT 'text' type, @plan text FOR JSON PATH);
	END;

	-- Обгортаємо в MCP формат
	SET @result = CONCAT('{"content":', @result, '}');

	SELECT @result result;
END;
GO

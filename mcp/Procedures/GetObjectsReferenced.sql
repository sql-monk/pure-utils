/*
# Description
Процедура для отримання зворотних залежностей об'єкта через MCP протокол.
Повертає валідний JSON для MCP відповіді з рекурсивною структурою всіх об'єктів,
які посилаються на вказаний об'єкт (зворотні залежності).

# Parameters
@object NVARCHAR(256) - Повне 3-х рівневе ім'я об'єкта у форматі 'database.schema.object'
@maxDepth INT = 5 - Максимальна глибина рекурсії (за замовчуванням 5 рівнів)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить рекурсивну структуру зворотних залежностей

# Usage
-- Отримати зворотні залежності для таблиці
EXEC mcp.GetObjectsReferenced @object = 'utils.dbo.events_notifications';

-- Отримати зворотні залежності з обмеженням глибини
EXEC mcp.GetObjectsReferenced @object = 'utils.util.metadataGetAnyId', @maxDepth = 3;
*/
CREATE OR ALTER PROCEDURE mcp.GetObjectsReferenced
    @object NVARCHAR(256),
    @maxDepth INT = 5
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @referenced NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);
    
    -- Викликаємо основну процедуру для отримання зворотних залежностей
    EXEC util.objectsGetReferenced 
        @object = @object,
        @maxDepth = @maxDepth,
        @referenced = @referenced OUTPUT;
    
    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (SELECT 'text' type, ISNULL(@referenced, '{}') text FOR JSON PATH);
    
    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');
    
    SELECT @result result;
END;
GO

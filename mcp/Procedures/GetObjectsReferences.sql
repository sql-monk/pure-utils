/*
# Description
Процедура для отримання залежностей об'єкта через MCP протокол.
Повертає валідний JSON для MCP відповіді з рекурсивною структурою всіх об'єктів,
від яких залежить вказаний об'єкт (прямі залежності).

# Parameters
@object NVARCHAR(256) - Повне 3-х рівневе ім'я об'єкта у форматі 'database.schema.object'
@maxDepth INT = 5 - Максимальна глибина рекурсії (за замовчуванням 5 рівнів)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить рекурсивну структуру залежностей

# Usage
-- Отримати залежності для процедури
EXEC mcp.GetObjectsReferences @object = 'utils.util.metadataGetDescriptions';

-- Отримати залежності з обмеженням глибини
EXEC mcp.GetObjectsReferences @object = 'utils.util.indexesGetConventionNames', @maxDepth = 3;
*/
CREATE OR ALTER PROCEDURE mcp.GetObjectsReferences
    @object NVARCHAR(256),
    @maxDepth INT = 5
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @references NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);
    
    -- Викликаємо основну процедуру для отримання залежностей
    EXEC util.objectsGetReferences 
        @object = @object,
        @maxDepth = @maxDepth,
        @references = @references OUTPUT;
    
    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (SELECT 'text' type, ISNULL(@references, '{}') text FOR JSON PATH);
    
    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');
    
    SELECT @result result;
END;
GO

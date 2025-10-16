/*
# Description
Процедура для отримання помилок виконання SSIS пакетів через MCP протокол.
Повертає валідний JSON для MCP відповіді з детальною інформацією про помилки,
включаючи повідомлення, джерело, час виникнення та код помилки.

# Parameters
@executionId BIGINT = NULL - ID виконання для фільтрації (NULL = всі виконання)
@folder NVARCHAR(128) = NULL - Назва папки SSISDB (NULL = всі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = всі проекти)
@package NVARCHAR(128) = NULL - Назва пакету (NULL = всі пакети)
@daysBack INT = 7 - Кількість днів назад для фільтрації (за замовчуванням 7)
@topN INT = 100 - Кількість останніх помилок (за замовчуванням 100)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить інформацію про помилки SSIS

# Usage
-- Отримати останні 100 помилок за останній тиждень
EXEC mcp.GetSsisErrors;

-- Отримати помилки за останню добу
EXEC mcp.GetSsisErrors @daysBack = 1;

-- Отримати помилки конкретного виконання
EXEC mcp.GetSsisErrors @executionId = 12345;

-- Отримати помилки конкретного пакету за місяць
EXEC mcp.GetSsisErrors @package = 'LoadDimensions.dtsx', @daysBack = 30, @topN = 200;
*/
CREATE OR ALTER PROCEDURE mcp.GetSsisErrors
    @executionId BIGINT = NULL,
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL,
    @daysBack INT = 7,
    @topN INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    
    IF(LEN(TRIM(ISNULL(@folder, ''))) = 0)
    BEGIN
        SET @folder = NULL;
    END;
    
    IF(LEN(TRIM(ISNULL(@project, ''))) = 0)
    BEGIN
        SET @project = NULL;
    END;
    
    IF(LEN(TRIM(ISNULL(@package, ''))) = 0)
    BEGIN
        SET @package = NULL;
    END;
    
    DECLARE @errors NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);
    DECLARE @startTime DATETIME = DATEADD(DAY, -ABS(@daysBack), GETDATE());
    
    SELECT @errors = (
        SELECT
            EventMessageId,
            OperationId,
            ExecutionId,
            FolderName,
            ProjectName,
            PackageName,
            EventName,
            MessageSourceName,
            PackagePath,
            CONVERT(VARCHAR(23), MessageTime, 126) AS MessageTime,
            MessageType,
            MessageTypeDesc,
            MessageSourceType,
            Message,
            ExtendedInfoId,
            ErrorCode,
            ExecutionPath
        FROM util.ssisGetErrors(@executionId, @folder, @project, @package, @startTime, @topN)
        ORDER BY MessageTime DESC
        FOR JSON PATH
    );
    
    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (SELECT 'text' type, ISNULL(@errors, '[]') text FOR JSON PATH);
    
    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');
    
    SELECT @result result;
END;
GO

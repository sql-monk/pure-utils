/*
# Description
Процедура для отримання інформації про виконання SSIS пакетів через MCP протокол.
Повертає валідний JSON для MCP відповіді з детальною інформацією про запуски пакетів,
включаючи статус, тривалість, результати та статистику використання ресурсів.

# Parameters
@folder NVARCHAR(128) = NULL - Назва папки SSISDB (NULL = всі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = всі проекти)
@package NVARCHAR(128) = NULL - Назва пакету (NULL = всі пакети)
@status INT = NULL - Статус виконання (1=Created, 2=Running, 3=Canceled, 4=Failed, 5=Pending, 6=Ended unexpectedly, 7=Succeeded, 8=Stopping, 9=Completed)
@daysBack INT = 7 - Кількість днів назад для фільтрації (за замовчуванням 7)
@topN INT = 100 - Кількість останніх виконань (за замовчуванням 100)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить інформацію про виконання SSIS пакетів

# Usage
-- Отримати останні 100 виконань за останній тиждень
EXEC mcp.GetSsisExecutions;

-- Отримати невдалі виконання за останню добу
EXEC mcp.GetSsisExecutions @status = 4, @daysBack = 1;

-- Отримати виконання конкретного пакету
EXEC mcp.GetSsisExecutions @package = 'LoadDimensions.dtsx', @daysBack = 30, @topN = 50;

-- Отримати всі виконання конкретного проекту
EXEC mcp.GetSsisExecutions @project = 'ETL_Project', @daysBack = 7;
*/
CREATE OR ALTER PROCEDURE mcp.GetSsisExecutions
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL,
    @status INT = NULL,
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
    
    DECLARE @executions NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);
    DECLARE @startTime DATETIME = DATEADD(DAY, -ABS(@daysBack), GETDATE());
    
    SELECT @executions = (
        SELECT
            ExecutionId,
            FolderName,
            ProjectName,
            PackageName,
            Status,
            StatusDesc,
            CONVERT(VARCHAR(23), StartTime, 126) AS StartTime,
            CONVERT(VARCHAR(23), EndTime, 126) AS EndTime,
            DurationSeconds,
            DurationFormatted,
            ExecutedAsName,
            Use32BitRuntime,
            ServerName,
            MachineName,
            TotalPhysicalMemoryKB,
            AvailablePhysicalMemoryKB
        FROM util.ssisGetExecutions(@folder, @project, @package, @status, @startTime, @topN)
        ORDER BY StartTime DESC
        FOR JSON PATH
    );
    
    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (SELECT 'text' type, ISNULL(@executions, '[]') text FOR JSON PATH);
    
    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');
    
    SELECT @result result;
END;
GO

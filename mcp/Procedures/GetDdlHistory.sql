/*
# Description
Процедура для отримання історії DDL подій через MCP протокол.
Повертає валідний JSON для MCP відповіді з інформацією про DDL події (CREATE, ALTER, DROP тощо),
включаючи тип події, час виконання, користувача, базу даних, об'єкт та TSQL команду.
Підтримує фільтрацію за типом події, часом, користувачем, базою даних, схемою та ім'ям об'єкта.

# Parameters
@eventType NVARCHAR(36) - Тип DDL події (CREATE_TABLE, ALTER_PROCEDURE, DROP_VIEW тощо). NULL = всі події
@postTime DATETIME - Мінімальна дата/час події. NULL = всі дати
@loginName NVARCHAR(128) - Ім'я користувача, який виконав подію. NULL = всі користувачі
@databaseName NVARCHAR(128) - Назва бази даних. NULL = всі бази
@schemaName NVARCHAR(128) - Назва схеми об'єкта. NULL = всі схеми
@objectName NVARCHAR(128) - Назва об'єкта, над яким виконана операція. NULL = всі об'єкти

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить топ 1000 DDL подій

# Usage
-- Отримати всі події за останній тиждень
EXEC mcp.GetDdlHistory @postTime = '2025-09-26';

-- Отримати всі події CREATE_TABLE
EXEC mcp.GetDdlHistory @eventType = 'CREATE_TABLE';

-- Отримати події для конкретної бази даних
EXEC mcp.GetDdlHistory @databaseName = 'utils';

-- Отримати події конкретного користувача
EXEC mcp.GetDdlHistory @loginName = 'DOMAIN\username';

-- Комбінована фільтрація
EXEC mcp.GetDdlHistory 
    @eventType = 'ALTER_PROCEDURE',
    @databaseName = 'utils',
    @schemaName = 'mcp';
*/
CREATE OR ALTER PROCEDURE mcp.GetDdlHistory
    @eventType NVARCHAR(36) = NULL,
    @postTime DATETIME = NULL,
    @loginName NVARCHAR(128) = NULL,
    @databaseName NVARCHAR(128) = NULL,
    @schemaName NVARCHAR(128) = NULL,
    @objectName NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @events NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);

    -- Формуємо JSON з інформацією про DDL події
    SELECT @events = (
        SELECT TOP (1000)
            eventType,
            CONVERT(VARCHAR(23), postTime, 126) AS postTime,
            spid,
            serverName,
            loginName,
            userName,
            roleName,
            databaseName,
            schemaName,
            objectName,
            objectType,
            loginType,
            targetObjectName,
            targetObjectType,
            propertyName,
            propertyValue,
            parameters,
            tsqlCommand
        FROM util.eventsNotifications
        WHERE
            (@eventType IS NULL OR eventType = @eventType) AND
            (@postTime IS NULL OR postTime >= @postTime) AND
            (@loginName IS NULL OR loginName = @loginName) AND
            (@databaseName IS NULL OR databaseName = @databaseName) AND
            (@schemaName IS NULL OR schemaName = @schemaName) AND
            (@objectName IS NULL OR objectName = @objectName)
        ORDER BY postTime DESC
        FOR JSON PATH
    );

    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (
        SELECT
            'text' AS [type],
            @events AS [text]
        FOR JSON PATH
    );

    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');

    SELECT @result AS result;
END;

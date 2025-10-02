/*
# Description
Процедура для отримання списку баз даних через MCP протокол.
Повертає валідний JSON для MCP відповіді з інформацією про всі бази даних на сервері,
включаючи назву, ID, дату створення, рівень сумісності, статус та налаштування безпеки.

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить інформацію про всі бази даних

# Usage
EXEC mcp.GetDatabases;
*/
CREATE OR ALTER PROCEDURE mcp.GetDatabases
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @databases NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);

    -- Формуємо JSON з інформацією про бази даних
    SELECT @databases = (
        SELECT
            name,
            database_id AS databaseId,
            CONVERT(VARCHAR(23), create_date, 126) AS createDate,
            compatibility_level AS compatibilityLevel,
            is_read_only AS isReadOnly,
            state_desc AS stateDesc,
            snapshot_isolation_state_desc AS snapshotIsolationStateDesc,
            is_read_committed_snapshot_on AS isReadCommittedSnapshotOn,
            is_broker_enabled AS isBrokerEnabled,
            recovery_model_desc AS recoveryModelDesc,
            is_published AS isPublished,
            is_trustworthy_on AS isTrustworthyOn
        FROM sys.databases
        ORDER BY name
        FOR JSON PATH
    );

    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (
        SELECT
            'text' AS [type],
            @databases AS [text]
        FOR JSON PATH
    );

    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');

    SELECT @result AS result;
END;

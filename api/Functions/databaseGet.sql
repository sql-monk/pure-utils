/*
# Description
Приклад скалярної функції для pureAPI.
Повертає детальну інформацію про одну базу даних у форматі JSON.

# Parameters
@databaseId INT - ID бази даних

# Returns
NVARCHAR(MAX) - JSON-об'єкт з детальною інформацією про базу даних

# Usage
-- Отримати інформацію про базу з ID = 1
SELECT api.databaseGet(1);

-- Через pureAPI
-- GET http://localhost:51433/database/get?databaseId=1
*/
CREATE OR ALTER FUNCTION api.databaseGet(@databaseId INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    
    SELECT @result = (
        SELECT 
            d.database_id AS databaseId,
            d.name AS databaseName,
            d.state_desc AS stateDesc,
            d.compatibility_level AS compatibilityLevel,
            d.recovery_model_desc AS recoveryModelDesc,
            d.collation_name AS collationName,
            CONVERT(VARCHAR(23), d.create_date, 126) AS createDate,
            d.is_read_only AS isReadOnly,
            d.is_auto_close_on AS isAutoCloseOn,
            d.is_auto_shrink_on AS isAutoShrinkOn,
            d.page_verify_option_desc AS pageVerifyOptionDesc,
            d.is_read_committed_snapshot_on AS isReadCommittedSnapshotOn,
            d.snapshot_isolation_state_desc AS snapshotIsolationStateDesc,
            d.is_broker_enabled AS isBrokerEnabled,
            d.is_trustworthy_on AS isTrustworthyOn,
            d.is_encrypted AS isEncrypted
        FROM sys.databases d
        WHERE d.database_id = @databaseId
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
    
    RETURN @result;
END;
GO

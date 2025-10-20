/*
# Description
Scalar function для отримання детальної інформації про конкретну базу даних.
Повертає валідний JSON з повною інформацією про базу даних.

# Parameters
@databaseName NVARCHAR(128) - назва бази даних

# Returns
NVARCHAR(MAX) - валідний JSON з детальною інформацією про базу даних

# Usage
-- Отримати інформацію про базу msdb
SELECT pupy.databasesGet('msdb');

-- Використання в HTTP запиті
-- GET /databases/get?databaseName=msdb
*/
CREATE OR ALTER FUNCTION pupy.databasesGet(@databaseName NVARCHAR(128))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    
    SELECT @result = (
        SELECT
            d.name,
            d.database_id databaseId,
            CONVERT(VARCHAR(23), d.create_date, 126) createDate,
            d.compatibility_level compatibilityLevel,
            d.collation_name collationName,
            d.is_read_only isReadOnly,
            d.state_desc stateDesc,
            d.recovery_model_desc recoveryModelDesc,
            d.is_published isPublished,
            d.is_subscribed isSubscribed,
            d.is_merge_published isMergePublished,
            d.is_distributor isDistributor,
            d.is_trustworthy_on isTrustworthyOn,
            d.snapshot_isolation_state_desc snapshotIsolationStateDesc,
            d.is_read_committed_snapshot_on isReadCommittedSnapshotOn,
            d.is_broker_enabled isBrokerEnabled,
            d.is_encrypted isEncrypted,
            d.is_query_store_on isQueryStoreOn,
            d.containment_desc containmentDesc,
            d.page_verify_option_desc pageVerifyOptionDesc,
            d.user_access_desc userAccessDesc,
            SUSER_SNAME(d.owner_sid) ownerName
        FROM sys.databases d
        WHERE d.name = @databaseName
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
    
    RETURN ISNULL(@result, '{}');
END;
GO

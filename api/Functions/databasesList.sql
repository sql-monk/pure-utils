/*
# Description
Приклад табличної функції для pureAPI.
Повертає список баз даних на сервері у форматі JSON.
Кожен рядок містить один JSON-об'єкт у колонці jsondata.

# Parameters
@stateDesc NVARCHAR(60) = NULL - Фільтр за станом бази даних (ONLINE, OFFLINE тощо)

# Returns
TABLE з колонкою jsondata NVARCHAR(MAX) - кожен рядок містить JSON-об'єкт

# Usage
-- Всі бази даних
SELECT * FROM api.databasesList(NULL);

-- Тільки онлайн бази
SELECT * FROM api.databasesList('ONLINE');

-- Через pureAPI
-- GET http://localhost:51433/databases/list
-- GET http://localhost:51433/databases/list?stateDesc=ONLINE
*/
CREATE OR ALTER FUNCTION api.databasesList(@stateDesc NVARCHAR(60) = NULL)
RETURNS TABLE
AS
RETURN(
    SELECT 
        (
            SELECT 
                d.database_id AS databaseId,
                d.name AS databaseName,
                d.state_desc AS stateDesc,
                d.compatibility_level AS compatibilityLevel,
                d.recovery_model_desc AS recoveryModelDesc,
                CONVERT(VARCHAR(23), d.create_date, 126) AS createDate,
                d.is_read_only AS isReadOnly
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS jsondata
    FROM sys.databases d
    WHERE @stateDesc IS NULL OR d.state_desc = @stateDesc
);
GO

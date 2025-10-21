/*
# Description
Повертає детальну інформацію про базу даних у форматі JSON.
Використовується для endpoint GET /api/databases/details?name={name}

# Parameters
@name NVARCHAR(128) - ім'я бази даних

# Returns  
JSON string з детальною інформацією про базу даних:
- databaseId: ID бази даних
- databaseName: Ім'я бази даних
- stateDesc: Стан бази
- recoveryModelDesc: Модель відновлення
- createDate: Дата створення
- compatibilityLevel: Рівень сумісності
- collationName: Collation бази
- sizeMB: Розмір бази в мегабайтах

# Usage
SELECT api.databasesDetails('master');
SELECT api.databasesDetails('utils');
*/
CREATE OR ALTER FUNCTION api.databasesGet(@name NVARCHAR(128))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (
        SELECT 
            d.database_id databaseId,
            d.name databaseName,
            d.state_desc stateDesc,
            d.recovery_model_desc recoveryModelDesc,
            d.create_date createDate,
            d.compatibility_level compatibilityLevel,
            d.collation_name collationName,
            CAST(SUM(mf.size) * 8.0 / 1024 AS DECIMAL(10,2)) sizeMB
        FROM sys.databases d
            LEFT JOIN sys.master_files mf ON d.database_id = mf.database_id
        WHERE d.name = @name
        GROUP BY 
            d.database_id,
            d.name,
            d.state_desc,
            d.recovery_model_desc,
            d.create_date,
            d.compatibility_level,
            d.collation_name
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
END;
GO

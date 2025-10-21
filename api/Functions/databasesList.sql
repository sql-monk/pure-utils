/*
# Description
Повертає список всіх баз даних на SQL Server з основними характеристиками.
Використовується для endpoint GET /api/databases/list

# Returns  
Таблиця з колонками:
- databaseId: ID бази даних
- databaseName: Ім'я бази даних
- stateDesc: Стан бази (ONLINE, OFFLINE, тощо)
- recoveryModelDesc: Модель відновлення (SIMPLE, FULL, BULK_LOGGED)
- createDate: Дата створення бази

# Usage
SELECT * FROM api.databasesList();
*/
CREATE OR ALTER FUNCTION api.databasesList()
RETURNS TABLE
AS
RETURN(
    SELECT 
        database_id databaseId,
        name databaseName,
        state_desc stateDesc,
        recovery_model_desc recoveryModelDesc,
        create_date createDate
    FROM sys.databases
    WHERE state = 0  -- Тільки ONLINE бази
);
GO

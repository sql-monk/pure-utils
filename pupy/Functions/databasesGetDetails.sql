/*
# Description
Функція для отримання детальної інформації про конкретну базу даних через REST API.
Приймає назву бази даних як параметр та повертає повну інформацію про неї,
включаючи назву, ID, дату створення, рівень сумісності, стан та модель відновлення.

# Parameters
@databaseName NVARCHAR(256) - назва бази даних для пошуку

# Returns
Таблиця з детальною інформацією про базу даних

# Usage
SELECT * FROM pupy.databasesGetDetails('AdventureWorks');
*/
CREATE OR ALTER FUNCTION pupy.databasesGetDetails(@databaseName NVARCHAR(256))
RETURNS TABLE
AS
RETURN
(
    SELECT
        name,
        database_id,
        create_date,
        compatibility_level,
        state_desc,
        recovery_model_desc
    FROM sys.databases (NOLOCK)
    WHERE name = @databaseName
);
GO

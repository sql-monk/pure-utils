/*
# Description
Scalar функція-обгортка для генерації DDL скрипту на основі аналізу SQL запиту.
Викликає inline функцію util.stringGetCreateTempScriptInline і повертає результат як скалярне значення.
Підтримує параметризовані запити через декларацію @params.

# Parameters
@query NVARCHAR(MAX) - SQL запит для аналізу структури результуючого набору
@tablename NVARCHAR(128) = NULL - ім'я створюваної таблиці (default: #temp)  
@params NVARCHAR(MAX) = NULL - декларація параметрів запиту у форматі sp_executesql

# Returns
NVARCHAR(MAX) - готовий до виконання CREATE TABLE скрипт

# Usage
SELECT util.stringGetCreateTempScript('SELECT * FROM util.indexesGetMissing(DEFAULT)',DEFAULT,DEFAULT)
*/
CREATE OR ALTER FUNCTION [util].[stringGetCreateTempScript](
    @query NVARCHAR(MAX), 
    @tablename NVARCHAR(128) = NULL,
    @params NVARCHAR(MAX) = NULL
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    
    SELECT @result = createScript 
    FROM util.stringGetCreateTempScriptInline(@query, @tablename, @params);
    
    RETURN @result;
END;
GO
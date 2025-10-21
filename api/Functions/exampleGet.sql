/*
# Description
Приклад скалярної функції для отримання одного об'єкта за ID
Повертає JSON з деталями об'єкта

# Parameters
@id INT - ідентифікатор об'єкта

# Returns  
NVARCHAR(MAX) з JSON об'єктом або NULL якщо не знайдено

# Usage
-- Отримати об'єкт
SELECT api.exampleGet(2);
*/

CREATE OR ALTER FUNCTION api.exampleGet(@id INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    
    WITH cteData AS (
        SELECT 1 AS id, 'Example 1' AS name, 'demo' AS type, 100 AS value, 'First example item' AS description
        UNION ALL
        SELECT 2, 'Example 2', 'test', 200, 'Second example item'
        UNION ALL
        SELECT 3, 'Example 3', 'demo', 300, 'Third example item'
        UNION ALL
        SELECT 4, 'Example 4', 'prod', 400, 'Fourth example item'
    )
    SELECT @result = (
        SELECT 
            d.id,
            d.name,
            d.type,
            d.value,
            d.description
        FROM cteData d
        WHERE d.id = @id
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
    
    RETURN @result;
END;
GO

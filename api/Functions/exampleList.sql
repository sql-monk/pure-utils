/*
# Description
Приклад таблично функції для отримання списку об'єктів
Повертає демонстраційні дані у форматі JSON

# Parameters
@type NVARCHAR(50) = NULL - опціональний фільтр по типу

# Returns  
Таблиця з колонкою jsondata, де кожен рядок - JSON об'єкт

# Usage
-- Всі об'єкти
SELECT * FROM api.exampleList(DEFAULT);

-- З фільтром
SELECT * FROM api.exampleList('demo');
*/

CREATE OR ALTER FUNCTION api.exampleList(@type NVARCHAR(50) = NULL)
RETURNS TABLE
AS
RETURN(
    WITH cteData AS (
        SELECT 1 AS id, 'Example 1' AS name, 'demo' AS type, 100 AS value
        UNION ALL
        SELECT 2, 'Example 2', 'test', 200
        UNION ALL
        SELECT 3, 'Example 3', 'demo', 300
        UNION ALL
        SELECT 4, 'Example 4', 'prod', 400
    )
    SELECT 
        (
            SELECT 
                d.id,
                d.name,
                d.type,
                d.value
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS jsondata
    FROM cteData d
    WHERE @type IS NULL OR d.type = @type
);
GO

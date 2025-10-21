/*
# Description
Приклад процедури для виконання операції
Демонструє використання OUTPUT параметру @response для повернення JSON

# Parameters
@name NVARCHAR(100) - назва об'єкта
@value INT = 0 - значення об'єкта
@response NVARCHAR(MAX) OUTPUT - JSON відповідь

# Usage
DECLARE @result NVARCHAR(MAX);
EXEC api.ExampleCreate @name = 'Test Item', @value = 500, @response = @result OUTPUT;
SELECT @result;
*/

CREATE OR ALTER PROCEDURE api.ExampleCreate
    @name NVARCHAR(100),
    @value INT = 0,
    @response NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @newId INT = ABS(CHECKSUM(NEWID())) % 10000;
    DECLARE @timestamp DATETIME2 = SYSDATETIME();
    
    BEGIN TRY
        -- Симуляція створення об'єкта
        -- В реальному сценарії тут був би INSERT INTO ...
        
        SET @response = (
            SELECT 
                'true' AS success,
                'Object created successfully' AS message,
                (
                    SELECT 
                        @newId AS id,
                        @name AS name,
                        @value AS value,
                        @timestamp AS createdAt
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ) AS data
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END TRY
    BEGIN CATCH
        SET @response = (
            SELECT 
                'false' AS success,
                ERROR_MESSAGE() AS message,
                ERROR_NUMBER() AS errorCode
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END CATCH
END;
GO

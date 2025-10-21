/*
# Description
Приклад процедури для pureAPI з OUTPUT параметром @response.
Виконує тестову операцію і повертає результат у JSON форматі.

# Parameters
@testValue NVARCHAR(100) = NULL - Тестове значення для обробки
@response NVARCHAR(MAX) OUTPUT - JSON відповідь з результатом виконання

# Returns
Через OUTPUT параметр @response повертається JSON-об'єкт:
{
    "status": "success" | "error",
    "message": "...",
    "data": {...}
}

# Usage
-- SQL виклик
DECLARE @response NVARCHAR(MAX);
EXEC api.testOperation @testValue = 'test', @response = @response OUTPUT;
SELECT @response;

-- Через pureAPI
-- GET http://localhost:51433/exec/testOperation?testValue=test
*/
CREATE OR ALTER PROCEDURE api.testOperation
    @testValue NVARCHAR(100) = NULL,
    @response NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Тестова логіка
        DECLARE @resultData NVARCHAR(MAX);
        
        SELECT @resultData = (
            SELECT 
                @testValue AS inputValue,
                UPPER(@testValue) AS upperValue,
                LEN(@testValue) AS valueLength,
                GETDATE() AS processedAt
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
        
        -- Формуємо успішну відповідь
        SELECT @response = (
            SELECT 
                'success' AS status,
                'Operation completed successfully' AS message,
                JSON_QUERY(@resultData) AS data
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END TRY
    BEGIN CATCH
        -- Формуємо відповідь з помилкою
        SELECT @response = (
            SELECT 
                'error' AS status,
                ERROR_MESSAGE() AS message,
                ERROR_NUMBER() AS errorNumber,
                ERROR_LINE() AS errorLine
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END CATCH
END;
GO

/*
# Description
Stored procedure для генерації DDL скрипту таблиці.
Повертає валідний JSON через OUTPUT параметр @response з SQL скриптом створення таблиці.

# Parameters
@name NVARCHAR(128) - назва таблиці (може бути schema.table або просто table)
@response NVARCHAR(MAX) OUTPUT - валідний JSON з DDL скриптом

# Returns
Через @response OUTPUT параметр повертається JSON з DDL скриптом таблиці

# Usage
-- Виклик процедури
DECLARE @response NVARCHAR(MAX);
EXEC pupy.scriptTable @name = 'dbo.MyTable', @response = @response OUTPUT;
SELECT @response;

-- Використання в HTTP запиті
-- POST /pupy/scriptTable?name=dbo.MyTable
*/
CREATE OR ALTER PROCEDURE pupy.scriptTable
    @name NVARCHAR(128),
    @response NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    DECLARE @objectId INT;
    DECLARE @script NVARCHAR(MAX);
    
    -- Отримання object_id
    SET @objectId = ISNULL(TRY_CONVERT(INT, @name), OBJECT_ID(@name));
    
    IF @objectId IS NULL
    BEGIN
        SET @response = JSON_MODIFY('{}', '$.error', 'Table not found');
        RETURN;
    END
    
    BEGIN TRY
        -- Використовуємо функцію tablesGetScript якщо вона існує
        IF OBJECT_ID('util.tablesGetScript') IS NOT NULL
        BEGIN
            SELECT @script = (SELECT util.tablesGetScript(@objectId, DEFAULT, DEFAULT, DEFAULT, DEFAULT));
        END
        ELSE
        BEGIN
            -- Простий fallback скрипт
            SET @script = CONCAT(
                '-- DDL script for table ', 
                OBJECT_SCHEMA_NAME(@objectId), 
                '.', 
                OBJECT_NAME(@objectId),
                CHAR(13), CHAR(10),
                '-- Use util.tablesGetScript for complete DDL generation'
            );
        END
        
        -- Формуємо JSON відповідь
        SELECT @response = (
            SELECT 
                OBJECT_SCHEMA_NAME(@objectId) schemaName,
                OBJECT_NAME(@objectId) tableName,
                @script script
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
        
    END TRY
    BEGIN CATCH
        -- Обробка помилок
        DECLARE @errorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
        SET @response = (
            SELECT 
                'error' [type],
                @errorMessage [message],
                ERROR_NUMBER() errorNumber
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END CATCH
END;
GO

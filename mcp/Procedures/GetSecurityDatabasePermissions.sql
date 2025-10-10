/*
# Description
Процедура для отримання дозволів на рівні бази даних через MCP протокол.
Повертає валідний JSON для MCP відповіді з інформацією про permissions для конкретної бази даних,
включаючи principal, тип дозволу, об'єкт та готовий скрипт для відтворення.

# Parameters
@database NVARCHAR(128) - Назва бази даних для отримання дозволів
@granteePrincipal NVARCHAR(128) = NULL - Ім'я principal (користувача/ролі) для якого генерувати скрипти (NULL = всі principals)
@filter NVARCHAR(128) = NULL - Фільтр для назви дозволів за патерном LIKE (NULL або '' = '%')
@includeInherited BIT = 0 - Включати дозволи успадковані через членство в ролях (0 = тільки явні дозволи, 1 = включаючи успадковані)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить інформацію про database permissions

# Usage
-- Отримати всі дозволи в базі даних
EXEC mcp.GetSecurityDatabasePermissions @database = 'utils';

-- Отримати дозволи для конкретного користувача
EXEC mcp.GetSecurityDatabasePermissions @database = 'utils', @granteePrincipal = 'myUser';

-- Отримати тільки SELECT дозволи
EXEC mcp.GetSecurityDatabasePermissions @database = 'utils', @filter = 'SELECT';
*/
CREATE OR ALTER PROCEDURE mcp.GetSecurityDatabasePermissions
    @database NVARCHAR(128),
    @granteePrincipal NVARCHAR(128) = NULL,
    @filter NVARCHAR(128) = NULL,
    @includeInherited BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    IF(LEN(TRIM(ISNULL(@filter, ''))) = 0)
    BEGIN
        SET @filter = '%';
    END;
    
    DECLARE @permissions NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);

    -- Формуємо динамічний SQL для отримання permissions з вказаної бази даних
    SET @sql = N'
    USE ' + QUOTENAME(@database) + N';
    
    SELECT @permissions = (
        SELECT
            principalName,
            principalType,
            permissionState,
            permissionName,
            objectSchema,
            objectName,
            objectType,
            columnName,
            permissionScript
        FROM util.securityGetDatabasePermissions(@granteePrincipal, @filter, @includeInherited)
        ORDER BY
            principalName,
            objectSchema,
            objectName,
            permissionName
        FOR JSON PATH
    );';

    -- Виконуємо динамічний SQL
    EXEC sys.sp_executesql 
        @sql, 
        N'@permissions NVARCHAR(MAX) OUTPUT, @granteePrincipal NVARCHAR(128), @filter NVARCHAR(128), @includeInherited BIT', 
        @permissions = @permissions OUTPUT, 
        @granteePrincipal = @granteePrincipal,
        @filter = @filter,
        @includeInherited = @includeInherited;

    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (SELECT 'text' type, ISNULL(@permissions, '[]') text FOR JSON PATH);

    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');

    SELECT @result result;
END;
GO

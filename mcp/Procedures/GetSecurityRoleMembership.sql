/*
# Description
Процедура для отримання членства в ролях бази даних через MCP протокол.
Повертає валідний JSON для MCP відповіді з інформацією про role membership для конкретної бази даних,
включаючи назву ролі, члена та готовий скрипт для відтворення.

# Parameters
@database NVARCHAR(128) - Назва бази даних для отримання членства в ролях
@principal NVARCHAR(128) = NULL - Ім'я або ID principal (користувача/ролі) для якого генерувати скрипти (NULL = всі members)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить інформацію про role membership

# Usage
-- Отримати всі членства в ролях в базі даних
EXEC mcp.GetSecurityRoleMembership @database = 'utils';

-- Отримати членства для конкретного користувача
EXEC mcp.GetSecurityRoleMembership @database = 'utils', @principal = 'myUser';
*/
CREATE OR ALTER PROCEDURE mcp.GetSecurityRoleMembership
    @database NVARCHAR(128),
    @principal NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @roleMembership NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);

    -- Формуємо динамічний SQL для отримання role membership з вказаної бази даних
    SET @sql = N'
    USE ' + QUOTENAME(@database) + N';
    
    SELECT @roleMembership = (
        SELECT
            roleName,
            roleType,
            memberName,
            memberType,
            roleMembershipScript
        FROM util.securityGetRoleMembership(@principal)
        ORDER BY
            roleName,
            memberName
        FOR JSON PATH
    );';

    -- Виконуємо динамічний SQL
    EXEC sys.sp_executesql 
        @sql, 
        N'@roleMembership NVARCHAR(MAX) OUTPUT, @principal NVARCHAR(128)', 
        @roleMembership = @roleMembership OUTPUT, 
        @principal = @principal;

    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (SELECT 'text' type, ISNULL(@roleMembership, '[]') text FOR JSON PATH);

    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');

    SELECT @result result;
END;
GO

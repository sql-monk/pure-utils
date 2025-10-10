/*
# Description
Генерує T-SQL скрипти для відтворення членства в ролях бази даних.
Функція аналізує членство користувачів та ролей у database roles і створює ALTER ROLE ... ADD MEMBER команди
для копіювання налаштувань між середовищами.

# Parameters
@principal NVARCHAR(128) = NULL - Ім'я або ID principal (користувача/ролі) для якого генерувати скрипти.
                                   NULL = всі members. Може бути як role (той, хто надає членство), 
                                   так і member (той, хто отримує членство)

# Returns
TABLE - Повертає таблицю з колонками:
- roleName NVARCHAR(128) - Назва ролі
- roleType NVARCHAR(60) - Тип ролі
- memberName NVARCHAR(128) - Назва члена ролі (користувача або іншої ролі)
- memberType NVARCHAR(60) - Тип члена
- roleMembershipScript NVARCHAR(MAX) - Готовий T-SQL скрипт для відтворення членства (ALTER ROLE ... ADD MEMBER)

# Usage
-- Отримати всі членства в ролях в поточній базі даних
SELECT * FROM util.securityScriptRoleMembership(NULL);

-- Отримати членства для конкретного користувача (як члена)
SELECT * FROM util.securityScriptRoleMembership('myUser');

-- Отримати членства для конкретної ролі (хто є членом цієї ролі)
SELECT * FROM util.securityScriptRoleMembership('db_datareader');

-- Отримати скрипти тільки для конкретного principal за ID
SELECT * FROM util.securityScriptRoleMembership('5');
*/
CREATE OR ALTER FUNCTION util.securityScriptRoleMembership(
    @principal NVARCHAR(128) = NULL
)
RETURNS TABLE
AS
RETURN(
    SELECT
        dpRole.name roleName,
        dpRole.type_desc roleType,
        dpMember.name memberName,
        dpMember.type_desc memberType,
        CONCAT(
            N'ALTER ROLE ',
            QUOTENAME(dpRole.name),
            N' ADD MEMBER ',
            QUOTENAME(dpMember.name),
            N';'
        ) roleMembershipScript
    FROM sys.database_role_members drm (NOLOCK)
        INNER JOIN sys.database_principals dpRole (NOLOCK)
            ON drm.role_principal_id = dpRole.principal_id
        INNER JOIN sys.database_principals dpMember (NOLOCK)
            ON drm.member_principal_id = dpMember.principal_id
    WHERE (
        @principal IS NULL 
        OR drm.role_principal_id = ISNULL(TRY_CONVERT(INT, @principal), USER_ID(@principal))
        OR drm.member_principal_id = ISNULL(TRY_CONVERT(INT, @principal), USER_ID(@principal))
    )
);
GO

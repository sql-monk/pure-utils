/*
# Description
Визначає об'єкти, для яких потрібні додаткові права при виконанні заданого об'єкта (процедури, функції).
Аналізує залежності через sys.sql_expression_dependencies та виявляє:
1. Об'єкти з інших баз даних (завжди потребують прав)
2. Об'єкти з різними власниками схем (можуть потребувати додаткових прав)

# Parameters
@object NVARCHAR(128) - повне ім'я об'єкта у форматі [схема].[ім'я] або просто ім'я

# Returns
TABLE - Повертає таблицю з колонками:
- ObjectName NVARCHAR(MAX) - повне ім'я об'єкта, який потребує додаткових прав
- PermissionReason NVARCHAR(200) - причина, чому потрібні додаткові права
- DatabaseName NVARCHAR(128) - назва бази даних об'єкта
- SchemaName NVARCHAR(128) - назва схеми об'єкта
- EntityName NVARCHAR(128) - назва об'єкта
- SchemaOwner NVARCHAR(128) - власник схеми об'єкта

# Usage
-- Перевірити права для конкретної процедури
SELECT * FROM util.metadataGetRequiredPermission('util.myselfGetHistory');

-- Аналіз прав для процедури з повним іменем
SELECT * FROM util.metadataGetRequiredPermission('[util].[errorHandler]');

-- Групування по причинах
SELECT PermissionReason, COUNT(*) AS ObjectCount
FROM util.metadataGetRequiredPermission('util.myselfGetHistory')
GROUP BY PermissionReason;
*/
CREATE FUNCTION util.metadataGetRequiredPermission(@object NVARCHAR(128))
RETURNS TABLE
AS
RETURN(
    SELECT
        CONCAT(
            CASE WHEN d.referenced_database_name IS NOT NULL 
                 THEN QUOTENAME(d.referenced_database_name) + '.' 
                 ELSE '' END,
            QUOTENAME(d.referenced_schema_name), '.',
            QUOTENAME(d.referenced_entity_name)
        ) AS ObjectName,
        CASE 
            WHEN d.referenced_database_name <> DB_NAME() AND d.referenced_database_name IS NOT NULL
                THEN N'Об''єкт з іншої бази даних'
            WHEN ISNULL(d.referenced_database_name, DB_NAME()) = DB_NAME()
                 AND USER_NAME(rs.principal_id) <> USER_NAME(source_schema.principal_id)
                 AND USER_NAME(source_schema.principal_id) IS NOT NULL
                THEN N'Різні власники схем (' + USER_NAME(source_schema.principal_id) + ' vs ' + USER_NAME(rs.principal_id) + ')'
            ELSE NULL
        END AS PermissionReason,
        ISNULL(d.referenced_database_name, DB_NAME()) AS DatabaseName,
        d.referenced_schema_name AS SchemaName,
        d.referenced_entity_name AS EntityName,
        USER_NAME(rs.principal_id) AS SchemaOwner
    FROM sys.sql_expression_dependencies d
        LEFT JOIN sys.schemas rs ON rs.name = d.referenced_schema_name
        LEFT JOIN sys.schemas source_schema ON source_schema.name = CASE 
            WHEN PARSENAME(@object, 2) IS NOT NULL THEN PARSENAME(@object, 2)
            ELSE OBJECT_SCHEMA_NAME(ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
        END
    WHERE d.referencing_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object))
        AND ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)) IS NOT NULL
        AND (
            -- Об'єкти з інших баз даних
            (d.referenced_database_name <> DB_NAME() AND d.referenced_database_name IS NOT NULL)
            OR 
            -- Об'єкти з різними власниками схем в тій же БД
            (ISNULL(d.referenced_database_name, DB_NAME()) = DB_NAME()
             AND USER_NAME(rs.principal_id) <> USER_NAME(source_schema.principal_id)
             AND USER_NAME(source_schema.principal_id) IS NOT NULL)
        )
);
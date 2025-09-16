/*
# Description
Отримує детальну інформацію про всі стовпці таблиці або представлення.

# Parameters
@object NVARCHAR(128) = NULL - назва об'єкта або NULL для всіх таблиць

# Returns
Таблиця з колонками: column_id, name, system_type_name, max_length, precision, scale, is_nullable, is_identity

# Usage
SELECT * FROM util.metadataGetColumns('dbo.MyTable');
-- Отримати інформацію про всі стовпці таблиці
*/
CREATE FUNCTION util.metadataGetColumns(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT 
        c.object_id objectId,
        OBJECT_SCHEMA_NAME(c.object_id) schemaName,
        OBJECT_NAME(c.object_id) objectName,
        c.column_id columnId,
        c.name columnName
	FROM sys.columns c
	WHERE (@object IS NULL OR c.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
);

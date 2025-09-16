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

CREATE FUNCTION util.metadataGetParameters(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT
    p.object_id objectId,
    OBJECT_SCHEMA_NAME(p.object_id) schemaName,
    OBJECT_NAME(p.object_id) objectName,
    p.parameter_id parameterId,
    p.name parameterName
	FROM sys.parameters p
	WHERE p.name IS NOT NULL -- Виключаємо системні параметри без імені
		AND (@object IS NULL OR p.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
);

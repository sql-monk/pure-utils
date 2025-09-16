CREATE FUNCTION util.metadataGetIndexes(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT
        i.object_id objectId,
        OBJECT_SCHEMA_NAME(i.object_id) schemaName,
        OBJECT_NAME(i.object_id) objectName,
        i.index_id indexId,
        i.name indexName
	FROM sys.indexes i
	WHERE i.name IS NOT NULL -- Виключаємо HEAP індекси
		AND i.is_hypothetical = 0 -- Виключаємо гіпотетичні індекси
		AND (@object IS NULL OR i.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
);

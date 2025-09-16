CREATE FUNCTION util.metadataGetIndexesName(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT DISTINCT 
		i.name indexName
	FROM sys.indexes i
		INNER JOIN sys.objects o ON i.object_id = o.object_id
	WHERE i.name IS NOT NULL -- Виключаємо HEAP індекси
		AND i.is_hypothetical = 0 -- Виключаємо гіпотетичні індекси
		AND (@object IS NULL OR o.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
);

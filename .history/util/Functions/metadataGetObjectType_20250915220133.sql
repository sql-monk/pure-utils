CREATE OR ALTER FUNCTION util.metadataGetObjectsType(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	WITH cteSplit AS (
		SELECT
			o.object_id objectId,
			LOWER(s.value) objectType,
			ROW_NUMBER() OVER (PARTITION BY o.object_id ORDER BY s.ordinal DESC) rn
		FROM sys.objects o
			CROSS APPLY STRING_SPLIT(o.type_desc, '_', 1) s
		WHERE(@object IS NULL OR o.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
	)
	SELECT DISTINCT cteSplit.objectType FROM cteSplit WHERE cteSplit.rn = 1
);

GO
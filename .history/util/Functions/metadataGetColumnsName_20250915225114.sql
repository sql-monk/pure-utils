CREATE FUNCTION util.metadataGetColumnsName(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT DISTINCT 
		c.name columnName
	FROM sys.columns c
		INNER JOIN sys.objects o ON c.object_id = o.object_id
	WHERE (@object IS NULL OR o.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
);

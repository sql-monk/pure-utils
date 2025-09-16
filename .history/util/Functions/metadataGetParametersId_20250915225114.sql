CREATE FUNCTION util.metadataGetParametersId(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT DISTINCT 
		p.parameter_id parameterId
	FROM sys.parameters p
		INNER JOIN sys.objects o ON p.object_id = o.object_id
	WHERE p.name IS NOT NULL -- Виключаємо системні параметри без імені
		AND (@object IS NULL OR o.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
);

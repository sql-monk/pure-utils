CREATE FUNCTION util.metadataGetDescriptions(@major NVARCHAR(128), @minor NVARCHAR(128))
RETURNS TABLE
AS
RETURN(
	WITH cte AS (SELECT
		Id,
		name,
		propertyValue,
		typeDesc
	FROM util.metadataGetExtendedProperiesValues(@major, @minor, 'MS_Description')
	UNION ALL
	SELECT
		Id,
		name,
		propertyValue,
		typeDesc
	FROM util.metadataGetExtendedProperiesValues(@major, @minor, 'Description')
	)
	SELECT Id, name, propertyValue description, typeDesc FROM cte
);


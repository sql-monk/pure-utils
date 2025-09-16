CREATE FUNCTION util.metadataGetDescriptions(@majorId INT = NULL, @minorId SMALLINT = NULL)
RETURNS TABLE
AS
RETURN(
	with cte as (SELECT
		Id,
		name,
		propertyValue,
		typeDesc
	FROM util.metadataGetExtendedProperiesValues(@majorId, @minorId, 'MS_Description')
	UNION ALL
	SELECT
		Id,
		name,
		propertyValue,
		typeDesc
	FROM util.metadataGetExtendedProperiesValues(@majorId, @minorId, 'Description')
	)
	SELECT Id, name, propertyValue description, typeDesc FROM cte
);
GO


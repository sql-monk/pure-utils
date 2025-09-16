USE model;
GO
CREATE OR ALTER FUNCTION util.metadataGetDescriptions(@majorId INT = NULL, @minorId SMALLINT = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT
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
);
GO


USE model;
GO
CREATE OR ALTER FUNCTION util.metadataGetParameterName(@majorId INT, @minorId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (
		SELECT CONCAT(QUOTENAME(SCHEMA_NAME(o.schema_id)), '.', QUOTENAME(o.name), ' (', p.name, ')')
		FROM sys.parameters p(NOLOCK)
			INNER JOIN sys.objects o(NOLOCK)ON p.object_id = o.object_id
		WHERE
			p.object_id = @majorId AND p.parameter_id = @minorId
	);
END;
GO


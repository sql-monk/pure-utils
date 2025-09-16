USE model; 
GO
CREATE OR ALTER     FUNCTION [util].[metadataGetObjectName](@majorId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT CONCAT (QUOTENAME (SCHEMA_NAME (o.schema_id)), '.', QUOTENAME (o.name)) name FROM sys.objects o (NOLOCK) WHERE @majorId = o.object_id);
END;
GO


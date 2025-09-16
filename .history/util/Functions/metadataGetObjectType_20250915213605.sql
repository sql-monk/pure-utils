CREATE OR ALTER     FUNCTION [util].[metadataGetObjectType](@majorId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT LOWER(REPLACE(REPLACE(REPLACE(o.type_desc,'USER_',''),'SQL_',''),'_', '')) typeDesc FROM sys.objects o (NOLOCK) WHERE @majorId = o.object_id);
END;
GO


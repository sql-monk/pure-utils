-- Column name function  
USE model; 
GO
USE model; 
GO
CREATE OR ALTER     FUNCTION [util].[metadataGetColumnName](@majorId INT, @minorId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT QUOTENAME (c.name) name FROM sys.columns c (NOLOCK) WHERE c.object_id = @majorId AND c.column_id = @minorId);
END;
GO


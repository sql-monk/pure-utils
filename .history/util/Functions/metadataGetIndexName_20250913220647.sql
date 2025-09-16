-- Index name function
USE model;
GO
CREATE OR ALTER     FUNCTION [util].[metadataGetIndexName](@majorId INT, @minorId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT QUOTENAME (ix.name) name FROM sys.indexes ix (NOLOCK) WHERE ix.object_id = @majorId AND ix.index_id = @minorId);
END;
GO


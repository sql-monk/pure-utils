-- Dataspace name function
USE model;
GO
CREATE OR ALTER FUNCTION util.metadataGetDataspaceName(@majorId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT QUOTENAME(name) name FROM sys.data_spaces(NOLOCK)WHERE data_space_id = @majorId);
END;
GO


USE model;
GO
CREATE OR ALTER FUNCTION util.metadataGetIndexId(@majorId INT, @minor NVARCHAR(128))
RETURNS INT
AS
BEGIN
	RETURN (SELECT ix.index_id FROM sys.indexes ix(NOLOCK)WHERE ix.object_id = @majorId AND ix.name = @minor);
END;
GO


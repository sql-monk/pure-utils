USE model;
GO
CREATE OR ALTER FUNCTION util.metadataGetColumnId(@majorId INT, @minor NVARCHAR(128))
RETURNS INT
AS
BEGIN
	RETURN (SELECT c.column_id FROM sys.columns c(NOLOCK)WHERE c.object_id = @majorId AND c.name = @minor);
END;
GO


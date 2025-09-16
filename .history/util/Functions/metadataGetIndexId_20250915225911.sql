USE model;
GO
CREATE OR ALTER FUNCTION util.metadataGetIndexId(@major NVARCHAR(128), @minor NVARCHAR(128))
RETURNS INT
AS
BEGIN
	RETURN (SELECT ix.index_id FROM sys.indexes ix(NOLOCK)WHERE ix.object_id = ISNULL(TRY_CONVERT(INT, @major), OBJECT_ID(@major)) AND ix.name = @minor);
END;
GO


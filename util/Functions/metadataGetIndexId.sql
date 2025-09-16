CREATE FUNCTION util.metadataGetIndexId(@object NVARCHAR(128), @indexName NVARCHAR(128))
RETURNS INT
AS
BEGIN
	RETURN (SELECT ix.index_id FROM sys.indexes ix(NOLOCK)WHERE ix.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)) AND ix.name = @indexName);
END;
GO


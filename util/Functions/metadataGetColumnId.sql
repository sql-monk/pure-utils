CREATE FUNCTION util.metadataGetColumnId(@major NVARCHAR(128), @column NVARCHAR(128))
RETURNS INT
AS
BEGIN
	RETURN (SELECT c.column_id FROM sys.columns c(NOLOCK)WHERE c.object_id = ISNULL(TRY_CONVERT(INT, @major), OBJECT_ID(@major)) AND c.name = @column);
END;
GO


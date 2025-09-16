CREATE FUNCTION util.metadataGetDataspaceId(@dataSpace INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT data_space_id name FROM sys.data_spaces(NOLOCK)WHERE name = @dataSpace);
END;
GO


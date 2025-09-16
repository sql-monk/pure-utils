CREATE FUNCTION util.metadataGetDataspaceName(@dataSpaceId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT QUOTENAME(name) name FROM sys.data_spaces(NOLOCK)WHERE data_space_id = @dataSpaceId);
END;
GO


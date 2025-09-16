USE model; 
GO
CREATE OR ALTER PROCEDURE [util].[metadataSetDataspaceDescription]
	@dataspace NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	EXEC util.metadataSetExtendedProperty 
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'PARTITION SCHEME',
		@level0name = @dataspace;
END;
GO
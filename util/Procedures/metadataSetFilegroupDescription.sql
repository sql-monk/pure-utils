USE model; 
GO
CREATE OR ALTER PROCEDURE [util].[metadataSetFilegroupDescription]
	@filegroup NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	EXEC util.metadataSetExtendedProperty 
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'FILEGROUP',
		@level0name = @filegroup;
END;
GO
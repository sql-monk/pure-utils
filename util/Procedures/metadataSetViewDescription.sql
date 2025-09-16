USE model; 
GO
CREATE OR ALTER PROCEDURE [util].[metadataSetViewDescription]
	@view NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	DECLARE @schema_name NVARCHAR(128);
	DECLARE @view_name NVARCHAR(128);
	
	SELECT @schema_name = SCHEMA_NAME(o.schema_id), @view_name = o.name
	FROM sys.objects o (NOLOCK)
	WHERE o.object_id = OBJECT_ID(@view);

	EXEC util.metadataSetExtendedProperty 
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'SCHEMA',
		@level0name = @schema_name,
		@level1type = 'VIEW',
		@level1name = @view_name;
END;
GO
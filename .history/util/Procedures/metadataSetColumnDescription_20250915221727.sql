USE model; 
GO
CREATE OR ALTER PROCEDURE [util].[metadataSetColumnDescription]
	@major NVARCHAR(128),
	@column NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	DECLARE @schema_name NVARCHAR(128);
	DECLARE @table_name NVARCHAR(128);
	
	SELECT @schema_name = SCHEMA_NAME(o.schema_id), @table_name = o.name
	FROM sys.objects o (NOLOCK)
	WHERE o.object_id = OBJECT_ID(@major);

	EXEC util.metadataSetExtendedProperty 
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'SCHEMA',
		@level0name = @schema_name,
		@level1type = 'OBJECT_OR_COLUMN',
		@level1name = @table_name,
		@level2type = 'COLUMN',
		@level2name = @column;
END;
GO
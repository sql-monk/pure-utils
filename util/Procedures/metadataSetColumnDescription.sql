CREATE PROCEDURE util.metadataSetColumnDescription 
	@object NVARCHAR(128),
	@column NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	DECLARE @schName NVARCHAR(128);
	DECLARE @objName NVARCHAR(128);
	DECLARE @objType NVARCHAR(128);

	SELECT
		@schName = SCHEMA_NAME(o.schema_id),
		@objName = o.name,
		@objType = t.objectType
	FROM sys.objects o(NOLOCK)
		OUTER APPLY util.metadataGetObjectsType(o.object_id) t
	WHERE o.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object));
	
	EXEC util.metadataSetExtendedProperty
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'SCHEMA',
		@level0name = @schName,
		@level1type = @objType,
		@level1name = @objName,
		@level2type = 'COLUMN',
		@level2name = @column;
END;
GO


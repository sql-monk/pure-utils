USE model; 
GO
CREATE OR ALTER PROCEDURE [util].[metadataSetProcedureDescription]
	@procedure NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	DECLARE @schema_name NVARCHAR(128);
	DECLARE @procedure_name NVARCHAR(128);
	
	SELECT @schema_name = SCHEMA_NAME(o.schema_id), @procedure_name = o.name
	FROM sys.objects o (NOLOCK)
	WHERE o.object_id = OBJECT_ID(@procedure);

	EXEC util.metadataSetExtendedProperty 
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'SCHEMA',
		@level0name = @schema_name,
		@level1type = 'PROCEDURE',
		@level1name = @procedure_name;
END;
GO
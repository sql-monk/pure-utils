USE model; 
GO
CREATE OR ALTER PROCEDURE [util].[metadataSetParameterDescription]
	@major NVARCHAR(128),
	@parameter NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	DECLARE @schema_name NVARCHAR(128);
	DECLARE @object_name NVARCHAR(128);
	DECLARE @object_type NVARCHAR(128);
	
	SELECT 
		@schema_name = SCHEMA_NAME(o.schema_id), 
		@object_name = o.name,
		@object_type = CASE o.type
			WHEN 'P' THEN 'PROCEDURE'
			WHEN 'FN' THEN 'FUNCTION'
			WHEN 'IF' THEN 'FUNCTION'
			WHEN 'TF' THEN 'FUNCTION'
			ELSE 'PROCEDURE'
		END
	FROM sys.objects o (NOLOCK)
	WHERE o.object_id = OBJECT_ID(@major);

	EXEC util.metadataSetExtendedProperty 
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'SCHEMA',
		@level0name = @schema_name,
		@level1type = @object_type,
		@level1name = @object_name,
		@level2type = 'PARAMETER',
		@level2name = @parameter;
END;
GO
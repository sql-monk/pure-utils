USE model; 
GO
CREATE OR ALTER PROCEDURE [util].[metadataSetSchemaDescription]
	@schema NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	EXEC util.metadataSetExtendedProperty 
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'SCHEMA',
		@level0name = @schema;
END;
GO
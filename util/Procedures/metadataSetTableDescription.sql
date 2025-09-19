/*
# Description
Встановлює опис для таблиці через розширені властивості MS_Description.

# Parameters
@table NVARCHAR(128) - назва таблиці
@description NVARCHAR(MAX) - текст опису для таблиці

# Usage
-- Встановити опис для користувацької таблиці
EXEC util.metadataSetTableDescription @table = 'dbo.Customers', @description = 'Таблиця інформації про клієнтів';

-- Встановити опис для системної таблиці
EXEC util.metadataSetTableDescription @table = 'util.ErrorLog', @description = 'Журнал помилок системи';
*/
CREATE OR ALTER PROCEDURE [util].[metadataSetTableDescription]
	@table NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	DECLARE @schema_name NVARCHAR(128);
	DECLARE @table_name NVARCHAR(128);
	
	SELECT @schema_name = SCHEMA_NAME(o.schema_id), @table_name = o.name
	FROM sys.objects o (NOLOCK)
	WHERE o.object_id = OBJECT_ID(@table);

	EXEC util.metadataSetExtendedProperty 
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'SCHEMA',
		@level0name = @schema_name,
		@level1type = 'TABLE',
		@level1name = @table_name;
END;
GO
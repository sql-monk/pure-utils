/*
# Description
Встановлює опис для індексу через розширені властивості MS_Description.

# Parameters
@major NVARCHAR(128) - назва таблиці або object_id
@index NVARCHAR(128) - назва індексу
@description NVARCHAR(MAX) - текст опису для індексу

# Usage
-- Встановити опис для індексу
EXEC util.metadataSetIndexDescription @major = 'dbo.myTable', @index = 'IX_myTable_Column1', @description = 'Індекс для швидкого пошуку по Column1';

-- Встановити опис для первинного ключа
EXEC util.metadataSetIndexDescription @major = 'dbo.myTable', @index = 'PK_myTable', @description = 'Первинний ключ таблиці';
*/
CREATE OR ALTER PROCEDURE [util].[metadataSetIndexDescription]
	@major NVARCHAR(128),
	@index NVARCHAR(128),
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
		@level1type = 'TABLE',
		@level1name = @table_name,
		@level2type = 'INDEX',
		@level2name = @index;
END;
GO
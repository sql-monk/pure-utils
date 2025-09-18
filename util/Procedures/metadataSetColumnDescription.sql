
/*
# Description
Встановлює опис для колонки таблиці чи представлення через розширені властивості MS_Description.

# Parameters
@object NVARCHAR(128) - назва таблиці або представлення
@column NVARCHAR(128) - назва колонки
@description NVARCHAR(MAX) - текст опису для колонки

# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для колонки

# Usage
-- Встановити опис для колонки таблиці
EXEC util.metadataSetColumnDescription @object = 'myTable', @column = 'myColumn', @description = 'Опис колонки';

-- Встановити опис для колонки представлення
EXEC util.metadataSetColumnDescription @object = 'myView', @column = 'calculatedColumn', @description = 'Розрахункова колонка';
*/
CREATE OR ALTER PROCEDURE util.metadataSetColumnDescription 
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


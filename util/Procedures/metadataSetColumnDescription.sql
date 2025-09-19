/*
# Description
Встановлює опис для колонки таблиці або представлення через розширені властивості MS_Description.
Процедура автоматично визначає схему та тип об'єкта, а потім встановлює опис для вказаної колонки.

# Parameters
- @object NVARCHAR(128) - Назва або ID об'єкта (таблиці/представлення)
- @column NVARCHAR(128) - Назва колонки для встановлення опису
- @description NVARCHAR(MAX) - Текст опису колонки

# Usage
```sql
EXEC util.metadataSetColumnDescription 'myTable', 'myColumn', 'Опис колонки';
EXEC util.metadataSetColumnDescription 'dbo.users', 'user_id', 'Унікальний ідентифікатор користувача';
```
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



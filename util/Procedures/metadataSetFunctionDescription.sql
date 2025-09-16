
/*
# Description
Встановлює опис для функції через розширені властивості MS_Description.

# Parameters
@function NVARCHAR(128) - назва функції
@description NVARCHAR(MAX) - текст опису для функції

# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для функції

# Usage
-- Встановити опис для скалярної функції
EXEC util.metadataSetFunctionDescription @function = 'dbo.MyScalarFunction', @description = 'Функція розрахунку значення';

-- Встановити опис для табличної функції
EXEC util.metadataSetFunctionDescription @function = 'dbo.MyTableFunction', @description = 'Функція повертає набір рядків';
*/
CREATE PROCEDURE [util].[metadataSetFunctionDescription]
	@function NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	DECLARE @schema_name NVARCHAR(128);
	DECLARE @function_name NVARCHAR(128);
	
	SELECT @schema_name = SCHEMA_NAME(o.schema_id), @function_name = o.name
	FROM sys.objects o (NOLOCK)
	WHERE o.object_id = ISNULL(TRY_CONVERT(INT, @function), OBJECT_ID(@function));

	EXEC util.metadataSetExtendedProperty 
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'SCHEMA',
		@level0name = @schema_name,
		@level1type = 'FUNCTION',
		@level1name = @function_name;
END;
GO
/*
# Description
Встановлює опис для схеми бази даних через розширені властивості MS_Description.

# Parameters
@schema NVARCHAR(128) - назва схеми
@description NVARCHAR(MAX) - текст опису для схеми

# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для схеми

# Usage
-- Встановити опис для користувацької схеми
EXEC util.metadataSetSchemaDescription @schema = 'sales', @description = 'Схема даних продажів';

-- Встановити опис для службової схеми
EXEC util.metadataSetSchemaDescription @schema = 'util', @description = 'Схема утилітарних функцій та процедур';
*/
CREATE PROCEDURE [util].[metadataSetSchemaDescription]
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
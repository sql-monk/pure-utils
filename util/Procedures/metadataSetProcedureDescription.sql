/*
# Description
Встановлює опис для збереженої процедури через розширені властивості MS_Description.

# Parameters
@procedure NVARCHAR(128) - назва процедури
@description NVARCHAR(MAX) - текст опису для процедури

# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для процедури

# Usage
-- Встановити опис для процедури
EXEC util.metadataSetProcedureDescription @procedure = 'dbo.myProcedure', @description = 'Процедура для обробки користувацьких даних';

-- Встановити опис для системної процедури
EXEC util.metadataSetProcedureDescription @procedure = 'util.errorHandler', @description = 'Універсальний обробник помилок';
*/
CREATE OR ALTER PROCEDURE util.metadataSetProcedureDescription @procedure NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	DECLARE @schema_name NVARCHAR(128);
	DECLARE @procedure_name NVARCHAR(128);

	SELECT
		@schema_name = SCHEMA_NAME(o.schema_id),
		@procedure_name = o.name
	FROM sys.objects o(NOLOCK)
	WHERE o.object_id = ISNULL(TRY_CONVERT(INT, @procedure), OBJECT_ID(@procedure));

	EXEC util.metadataSetExtendedProperty
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'SCHEMA',
		@level0name = @schema_name,
		@level1type = 'PROCEDURE',
		@level1name = @procedure_name;
END;
GO
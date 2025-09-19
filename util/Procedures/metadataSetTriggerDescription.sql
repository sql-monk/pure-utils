/*
# Description
Встановлює опис для тригера через розширені властивості MS_Description.

# Parameters
@trigger NVARCHAR(128) - назва тригера
@description NVARCHAR(MAX) - текст опису для тригера

# Usage
-- Встановити опис для тригера INSERT
EXEC util.metadataSetTriggerDescription @trigger = 'dbo.tr_Customers_Insert', @description = 'Тригер для логування додавання нових клієнтів';

-- Встановити опис для тригера UPDATE
EXEC util.metadataSetTriggerDescription @trigger = 'dbo.tr_Orders_Update', @description = 'Тригер для перевірки бізнес-правил при оновленні замовлень';
*/
CREATE OR ALTER PROCEDURE [util].[metadataSetTriggerDescription]
	@trigger NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	DECLARE @schema_name NVARCHAR(128);
	DECLARE @table_name NVARCHAR(128);
	DECLARE @trigger_name NVARCHAR(128);
	
	SELECT 
		@schema_name = SCHEMA_NAME(parent_obj.schema_id), 
		@table_name = parent_obj.name,
		@trigger_name = trigger_obj.name
	FROM sys.objects trigger_obj (NOLOCK)
	INNER JOIN sys.objects parent_obj (NOLOCK) ON trigger_obj.parent_object_id = parent_obj.object_id
	WHERE trigger_obj.object_id = OBJECT_ID(@trigger);

	EXEC util.metadataSetExtendedProperty 
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'SCHEMA',
		@level0name = @schema_name,
		@level1type = 'TABLE',
		@level1name = @table_name,
		@level2type = 'TRIGGER',
		@level2name = @trigger_name;
END;
GO
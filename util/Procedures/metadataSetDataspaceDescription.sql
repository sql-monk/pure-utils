/*
# Description
Встановлює опис для простору даних (файлової групи або схеми розділення) через розширені властивості MS_Description.

# Parameters
@dataspace NVARCHAR(128) - назва простору даних
@description NVARCHAR(MAX) - текст опису для простору даних

# Usage
-- Встановити опис для файлової групи
EXEC util.metadataSetDataspaceDescription @dataspace = 'PRIMARY', @description = 'Основна файлова група';

-- Встановити опис для схеми розділення
EXEC util.metadataSetDataspaceDescription @dataspace = 'MyPartitionScheme', @description = 'Схема розділення по датах';
*/
CREATE OR ALTER PROCEDURE [util].[metadataSetDataspaceDescription]
	@dataspace NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	EXEC util.metadataSetExtendedProperty 
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'PARTITION SCHEME',
		@level0name = @dataspace;
END;
GO
/*
# Description
Встановлює опис для файлової групи через розширені властивості MS_Description.

# Parameters
@filegroup NVARCHAR(128) - назва файлової групи
@description NVARCHAR(MAX) - текст опису для файлової групи

# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для файлової групи

# Usage
-- Встановити опис для файлової групи
EXEC util.metadataSetFilegroupDescription @filegroup = 'PRIMARY', @description = 'Основна файлова група системи';

-- Встановити опис для додаткової файлової групи
EXEC util.metadataSetFilegroupDescription @filegroup = 'DATA_FG', @description = 'Файлова група для користувацьких даних';
*/
CREATE OR ALTER PROCEDURE [util].[metadataSetFilegroupDescription]
	@filegroup NVARCHAR(128),
	@description NVARCHAR(MAX)
AS
BEGIN
	EXEC util.metadataSetExtendedProperty 
		@name = 'MS_Description',
		@value = @description,
		@level0type = 'FILEGROUP',
		@level0name = @filegroup;
END;
GO
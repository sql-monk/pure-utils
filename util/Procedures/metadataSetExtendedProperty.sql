/*
# Description
Універсальна процедура для встановлення розширених властивостей на різних рівнях ієрархії об'єктів бази даних.
Підтримує встановлення властивостей для об'єктів на рівні схеми, таблиці, колонки тощо.

# Parameters
@name NVARCHAR(128) - назва розширеної властивості
@value NVARCHAR(MAX) - значення властивості
@level0type NVARCHAR(128) = NULL - тип об'єкта рівня 0 (наприклад, 'SCHEMA')
@level0name NVARCHAR(128) = NULL - назва об'єкта рівня 0
@level1type NVARCHAR(128) = NULL - тип об'єкта рівня 1 (наприклад, 'TABLE')
@level1name NVARCHAR(128) = NULL - назва об'єкта рівня 1
@level2type NVARCHAR(128) = NULL - тип об'єкта рівня 2 (наприклад, 'COLUMN')
@level2name NVARCHAR(128) = NULL - назва об'єкта рівня 2

# Returns
Нічого не повертає. Встановлює або оновлює розширену властивість

# Usage
-- Встановити властивість для таблиці
EXEC util.metadataSetExtendedProperty @name = 'MS_Description', @value = 'Опис таблиці',
    @level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'myTable';

-- Встановити властивість для колонки
EXEC util.metadataSetExtendedProperty @name = 'MS_Description', @value = 'Опис колонки',
    @level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'myTable',
    @level2type = 'COLUMN', @level2name = 'myColumn';
*/
CREATE OR ALTER PROCEDURE [util].[metadataSetExtendedProperty]
	@name NVARCHAR(128),
	@value NVARCHAR(MAX),
	@level0type NVARCHAR(128) = NULL,
	@level0name NVARCHAR(128) = NULL,
	@level1type NVARCHAR(128) = NULL,
	@level1name NVARCHAR(128) = NULL,
	@level2type NVARCHAR(128) = NULL,
	@level2name NVARCHAR(128) = NULL
AS
BEGIN
	-- Check if property already exists
	IF EXISTS (
		SELECT 1 FROM sys.extended_properties 
		WHERE name = @name
		AND major_id = ISNULL(OBJECT_ID(QUOTENAME(ISNULL(@level0name, '')) + '.' + QUOTENAME(ISNULL(@level1name, ''))), 0)
		AND minor_id = ISNULL((
			SELECT column_id 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID(QUOTENAME(ISNULL(@level0name, '')) + '.' + QUOTENAME(ISNULL(@level1name, '')))
			AND name = @level2name
		), 0)
	)
	BEGIN
		-- Update existing property
		EXEC sys.sp_updateextendedproperty 
			@name = @name,
			@value = @value,
			@level0type = @level0type,
			@level0name = @level0name,
			@level1type = @level1type,
			@level1name = @level1name,
			@level2type = @level2type,
			@level2name = @level2name;
	END
	ELSE
	BEGIN
		-- Add new property
		EXEC sys.sp_addextendedproperty 
			@name = @name,
			@value = @value,
			@level0type = @level0type,
			@level0name = @level0name,
			@level1type = @level1type,
			@level1name = @level1name,
			@level2type = @level2type,
			@level2name = @level2name;
	END
END;
GO
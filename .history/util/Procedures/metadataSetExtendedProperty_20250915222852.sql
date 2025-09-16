USE model; 
GO
CREATE OR ALTER PROCEDURE [util].[metadataSetExtendedProperty]
	@name NVARCHAR(128),
	@value sql_variant = NULL,
	@level0type VARCHAR(128) = NULL,
	@level0name NVARCHAR(128) = NULL,
	@level1type VARCHAR(128) = NULL,
	@level1name NVARCHAR(128) = NULL,
	@level2type VARCHAR(128) = NULL,
	@level2name NVARCHAR(128) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	-- Перевірка на існування extended property
	IF NOT EXISTS (
		SELECT * 
		FROM sys.extended_properties
		WHERE name = @name 
			AND ISNULL(@level0type, 'DATABASE') = 'DATABASE'
			AND ISNULL(@level1type, '') = ISNULL(@level1type, '')
			AND ISNULL(@level1name, '') = ISNULL(@level1name, '')
			AND ISNULL(@level2type, '') = ISNULL(@level2type, '')
			AND ISNULL(@level2name, '') = ISNULL(@level2name, '')
	)
	BEGIN
		-- Додавання нового extended property
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
	ELSE
	BEGIN
		-- Оновлення існуючого extended property
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
END;
GO
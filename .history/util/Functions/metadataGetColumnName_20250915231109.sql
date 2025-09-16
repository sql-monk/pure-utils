CREATE FUNCTION [util].[metadataGetColumnName](@major NVARCHAR(128), @columnId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	return(
		SELECT QUOTENAME (c.name)
		FROM sys.columns c (NOLOCK)
		WHERE c.object_id = ISNULL(TRY_CONVERT(INT, @major), OBJECT_ID(@major)) AND c.column_id = @columnId
	)
END;
GO


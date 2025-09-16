CREATE FUNCTION [util].[metadataGetIndexName](@major NVARCHAR(128), @indexId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (
		SELECT QUOTENAME (ix.name)
		FROM sys.indexes ix (NOLOCK) 
		WHERE ix.object_id = ISNULL(TRY_CONVERT(INT, @major), OBJECT_ID(@major)) AND ix.index_id = @indexId);
END;
GO


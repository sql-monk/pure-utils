CREATE FUNCTION util.metadataGetPartitionFunctionName(@functionId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT QUOTENAME(name) name FROM sys.partition_functions(NOLOCK)WHERE function_id = @functionId);
END;
GO


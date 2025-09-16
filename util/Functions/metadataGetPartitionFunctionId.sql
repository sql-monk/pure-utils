CREATE FUNCTION util.metadataGetPartitionFunctionName(@function NVARCHAR(128))
RETURNS int
AS
BEGIN
	RETURN (SELECT function_id FROM sys.partition_functions(NOLOCK)WHERE name = @function);
END;
GO


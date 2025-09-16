CREATE FUNCTION util.metadataGetParameterId(@object INT, @parameterName NVARCHAR(128))
RETURNS INT
AS
BEGIN
	RETURN (SELECT p.parameter_id FROM sys.parameters p(NOLOCK)WHERE p.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)) AND p.name = @parameterName);
END;
GO


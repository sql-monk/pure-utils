CREATE FUNCTION util.metadataGetObjectType(@object NVARCHAR(128))
RETURNS NVARCHAR(60)
AS
BEGIN
    RETURN (SELECT objectType FROM util.metadataGetObjectsType(@object)) ;
END
  
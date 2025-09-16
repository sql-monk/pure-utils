CREATE OR ALTER FUNCTION util.metadataGetCertificateName(@majorId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT QUOTENAME(name) name FROM sys.certificates(NOLOCK)WHERE certificate_id = @majorId);
END;
GO


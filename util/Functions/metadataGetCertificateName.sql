/*
# Description
Отримує ім'я сертифіката за його ідентифікатором з системного каталогу.

# Parameters
@majorId INT - ідентифікатор сертифіката (certificate_id)

# Returns
NVARCHAR(128) - ім'я сертифіката в квадратних дужках або NULL якщо не знайдено

# Usage
-- Отримати ім'я сертифіката за ID
SELECT util.metadataGetCertificateName(1);
*/
CREATE OR ALTER FUNCTION util.metadataGetCertificateName(@majorId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT QUOTENAME(name) name FROM sys.certificates(NOLOCK)WHERE certificate_id = @majorId);
END;
GO


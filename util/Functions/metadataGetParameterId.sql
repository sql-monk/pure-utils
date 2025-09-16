/*
# Description
Отримує ідентифікатор параметра для вказаного об'єкта бази даних.

# Parameters
@object NVARCHAR(128) - назва або ID об'єкта бази даних
@parameterName NVARCHAR(128) - назва параметра

# Returns
INT - ідентифікатор параметра або NULL якщо параметр не знайдено

# Usage
-- Отримати ID параметра процедури
SELECT util.metadataGetParameterId('myProcedure', '@param1');

-- Використовуючи object_id
SELECT util.metadataGetParameterId('1234567890', '@param1');
*/
CREATE FUNCTION util.metadataGetParameterId(@object NVARCHAR(128), @parameterName NVARCHAR(128))
RETURNS INT
AS
BEGIN
	RETURN (SELECT p.parameter_id FROM sys.parameters p(NOLOCK)WHERE p.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)) AND p.name = @parameterName);
END;
GO


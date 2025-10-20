/*
# Description
Отримує повну назву параметра об'єкта за його ідентифікаторами.

# Parameters
@majorId INT - ідентифікатор об'єкта (object_id)
@minorId INT - ідентифікатор параметра (parameter_id)

# Returns
NVARCHAR(128) - повна назва у форматі "схема.об'єкт (параметр)" або NULL якщо не знайдено

# Usage
-- Отримати назву параметра за ID
SELECT util.metadataGetParameterName(OBJECT_ID('myProc'), 1);
*/
CREATE OR ALTER FUNCTION util.metadataGetParameterName(@majorId INT, @minorId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (
		SELECT CONCAT(QUOTENAME(SCHEMA_NAME(o.schema_id)), '.', QUOTENAME(o.name), ' (', p.name, ')')
		FROM sys.parameters p(NOLOCK)
			INNER JOIN sys.objects o(NOLOCK)ON p.object_id = o.object_id
		WHERE
			p.object_id = @majorId AND p.parameter_id = @minorId
	);
END;
GO


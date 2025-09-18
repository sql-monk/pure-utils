/*
# Description
Отримує повну назву об'єкта бази даних за його ідентифікатором.
Повертає назву у форматі "схема.об'єкт" в квадратних дужках.

# Parameters
@majorId INT - ідентифікатор об'єкта (object_id)

# Returns
NVARCHAR(128) - повну назву об'єкта у форматі "[схема].[об'єкт]" або NULL якщо не знайдено

# Usage
-- Отримати назву об'єкта за його ID
SELECT util.metadataGetObjectName(OBJECT_ID('dbo.myTable'));

-- Використовуючи числовий ID
SELECT util.metadataGetObjectName(1234567890);
*/
CREATE OR ALTER FUNCTION [util].[metadataGetObjectName](@majorId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT CONCAT (QUOTENAME (SCHEMA_NAME (o.schema_id)), '.', QUOTENAME (o.name)) name FROM sys.objects o (NOLOCK) WHERE @majorId = o.object_id);
END;
GO




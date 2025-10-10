/*
# Description
Отримує повну назву об'єкта бази даних за його ідентифікатором.
Повертає назву у форматі "схема.об'єкт" в квадратних дужках.

# Parameters
@objectId INT - ідентифікатор об'єкта (object_id)

# Returns
NVARCHAR(128) - повну назву об'єкта у форматі "[схема].[об'єкт]" або NULL якщо не знайдено

# Usage
-- Отримати назву об'єкта за його ID
SELECT util.metadataGetObjectName(OBJECT_ID('dbo.myTable'), DEFAULT);

-- Використовуючи числовий ID
SELECT util.metadataGetObjectName(1234567890, DEFAULT);
*/
CREATE OR ALTER FUNCTION [util].[metadataGetObjectName](@objectId INT, @dbId INT = NULL)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN CONCAT(QUOTENAME(DB_NAME(@dbId)), N'.', QUOTENAME(OBJECT_SCHEMA_NAME(@objectId)), N'.', QUOTENAME(OBJECT_NAME(@objectId)));
END;
GO




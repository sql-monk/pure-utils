/*
# Description
Отримує назву індексу за ідентифікатором таблиці та ідентифікатором індексу.

# Parameters
@major NVARCHAR(128) - назва таблиці або object_id
@indexId INT - ідентифікатор індексу

# Returns
NVARCHAR(128) - повна назва індексу у форматі "схема.таблиця (індекс)" або NULL якщо не знайдено

# Usage
-- Отримати назву індексу за ID
SELECT util.metadataGetIndexName('myTable', 2);

-- Використовуючи object_id таблиці
SELECT util.metadataGetIndexName('1234567890', 2);
*/
CREATE OR ALTER FUNCTION [util].[metadataGetIndexName](@major NVARCHAR(128), @indexId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (
		SELECT QUOTENAME (ix.name)
		FROM sys.indexes ix (NOLOCK) 
		WHERE ix.object_id = ISNULL(TRY_CONVERT(INT, @major), OBJECT_ID(@major)) AND ix.index_id = @indexId);
END;
GO


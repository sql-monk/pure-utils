/*
# Description
Отримує ім'я стовпця за ідентифікатором таблиці та ідентифікатором стовпця.

# Parameters
@major NVARCHAR(128) - назва таблиці або object_id
@columnId INT - ідентифікатор стовпця (column_id)

# Returns
NVARCHAR(128) - ім'я стовпця в квадратних дужках або NULL якщо не знайдено

# Usage
SELECT util.metadataGetColumnName('dbo.MyTable', 1);
-- Отримати ім'я стовпця за його column_id
*/
CREATE OR ALTER FUNCTION [util].[metadataGetColumnName](@major NVARCHAR(128), @columnId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	return(
		SELECT QUOTENAME (c.name)
		FROM sys.columns c (NOLOCK)
		WHERE c.object_id = ISNULL(TRY_CONVERT(INT, @major), OBJECT_ID(@major)) AND c.column_id = @columnId
	)
END;
GO


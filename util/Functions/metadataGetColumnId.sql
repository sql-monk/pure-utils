/*
# Description
Отримує column_id для заданого стовпця в таблиці або представленні. 
Підтримує передачу як назви об'єкта, так і числового ідентифікатора таблиці.

# Parameters
@major NVARCHAR(128) - назва об'єкта (таблиця/представлення) або object_id
@column NVARCHAR(128) - назва стовпця для якого шукати ідентифікатор

# Returns
INT - ідентифікатор стовпця (column_id) або NULL якщо стовпець не знайдено

# Usage
SELECT util.metadataGetColumnId('dbo.MyTable', 'MyColumn');
-- Отримати column_id для стовпця MyColumn в таблиці dbo.MyTable
*/
CREATE FUNCTION util.metadataGetColumnId(@major NVARCHAR(128), @column NVARCHAR(128))
RETURNS INT
AS
BEGIN
	RETURN (SELECT c.column_id FROM sys.columns c(NOLOCK)WHERE c.object_id = ISNULL(TRY_CONVERT(INT, @major), OBJECT_ID(@major)) AND c.name = @column);
END;
GO


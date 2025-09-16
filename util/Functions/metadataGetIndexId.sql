/*
# Description
Отримує ідентифікатор індексу за назвою табліці та назвою індексу.

# Parameters
@object NVARCHAR(128) - назва таблиці або object_id
@indexName NVARCHAR(128) - назва індексу

# Returns
INT - ідентифікатор індексу або NULL якщо не знайдено

# Usage
-- Отримати ID індексу за назвами
SELECT util.metadataGetIndexId('myTable', 'IX_myTable_Column1');

-- Використовуючи object_id таблиці
SELECT util.metadataGetIndexId('1234567890', 'IX_myTable_Column1');
*/
CREATE FUNCTION util.metadataGetIndexId(@object NVARCHAR(128), @indexName NVARCHAR(128))
RETURNS INT
AS
BEGIN
	RETURN (SELECT ix.index_id FROM sys.indexes ix(NOLOCK)WHERE ix.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)) AND ix.name = @indexName);
END;
GO


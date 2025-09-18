/*
# Description
Повертає текстову назву класу об'єкта за його числовим кодом.
Зворотна функція до metadataGetClassByName.

# Parameters
@class TINYINT - числовий код класу об'єкта

# Returns
NVARCHAR(128) - текстова назва класу або NULL для невідомого коду

# Usage
-- Отримати назву класу за кодом
SELECT util.metadataGetClassName(1); -- OBJECT_OR_COLUMN
SELECT util.metadataGetClassName(3); -- SCHEMA
*/
CREATE OR ALTER FUNCTION util.metadataGetClassName(@class TINYINT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN CASE @class
		WHEN 0 THEN 'DATABASE'
		WHEN 1 THEN 'OBJECT_OR_COLUMN'
		WHEN 2 THEN 'PARAMETER'
		WHEN 3 THEN 'SCHEMA'
		WHEN 4 THEN 'DATABASE_PRINCIPAL'
		WHEN 7 THEN 'INDEX'
		WHEN 20 THEN 'DATASPACE'
		WHEN 21 THEN 'PARTITION_FUNCTION'
		WHEN 22 THEN 'DATABASE_FILE'
		WHEN 25 THEN 'CERTIFICATE'
		ELSE NULL
	END;
END;
GO
/*
# Description
Отримує тип об'єкта бази даних за його назвою.
Спрощена версія metadataGetObjectsType для отримання одного значення.

# Parameters
@object NVARCHAR(128) - назва об'єкта бази даних

# Returns
NVARCHAR(60) - тип об'єкта (наприклад, 'U' для таблиці, 'P' для процедури, 'FN' для функції)

# Usage
-- Отримати тип об'єкта
SELECT util.metadataGetObjectType('myTable');

-- Перевірити чи є об'єкт таблицею
SELECT CASE WHEN util.metadataGetObjectType('myTable') = 'U' THEN 'Table' ELSE 'Not Table' END;
*/
CREATE FUNCTION util.metadataGetObjectType(@object NVARCHAR(128))
RETURNS NVARCHAR(60)
AS
BEGIN
    RETURN (SELECT objectType FROM util.metadataGetObjectsType(@object)) ;
END
  
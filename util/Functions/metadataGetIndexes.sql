/*
# Description
Отримує детальну інформацію про індекси для заданих таблиць.
Включає основні характеристики індексів та їх стан.

# Parameters
@object NVARCHAR(128) = NULL - назва таблиці для отримання індексів (NULL = всі таблиці)

# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор таблиці
- index_id INT - ідентифікатор індексу
- name NVARCHAR(128) - назва індексу
- type_desc NVARCHAR(60) - тип індексу
- is_unique BIT - чи унікальний індекс
- is_primary_key BIT - чи первинний ключ

# Usage
-- Отримати всі індекси конкретної таблиці
SELECT * FROM util.metadataGetIndexes('myTable');

-- Отримати індекси всіх таблиць
SELECT * FROM util.metadataGetIndexes(NULL);
*/
CREATE OR ALTER FUNCTION util.metadataGetIndexes(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT
        i.object_id objectId,
        OBJECT_SCHEMA_NAME(i.object_id) schemaName,
        OBJECT_NAME(i.object_id) objectName,
        i.index_id indexId,
        i.name indexName
    FROM sys.indexes i
	WHERE i.name IS NOT NULL -- Виключаємо HEAP індекси
		AND i.is_hypothetical = 0 -- Виключаємо гіпотетичні індекси
		AND (@object IS NULL OR i.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
);

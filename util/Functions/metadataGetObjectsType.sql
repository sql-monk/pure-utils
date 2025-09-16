/*
# Description
Отримує інформацію про тип об'єктів бази даних з можливістю фільтрації.
Підтримує як окремі об'єкти, так і список через кому.

# Parameters
@object NVARCHAR(128) = NULL - назва об'єкта або список назв через кому (NULL = всі об'єкти)

# Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - ідентифікатор об'єкта
- objectName NVARCHAR(128) - назва об'єкта
- objectType NVARCHAR(60) - тип об'єкта

# Usage
-- Отримати тип конкретного об'єкта
SELECT * FROM util.metadataGetObjectsType('myTable');

-- Отримати типи кількох об'єктів
SELECT * FROM util.metadataGetObjectsType('myTable,myView,myProcedure');
*/
CREATE FUNCTION util.metadataGetObjectsType(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	WITH cteSplit AS (
		SELECT
			o.object_id objectId,
			LOWER(s.value) objectType,
			ROW_NUMBER() OVER (PARTITION BY o.object_id ORDER BY s.ordinal DESC) rn
		FROM sys.objects o
			CROSS APPLY STRING_SPLIT(o.type_desc, '_', 1) s
		WHERE(@object IS NULL OR o.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
	)
	SELECT cteSplit.objectType FROM cteSplit WHERE cteSplit.rn = 1
);
/*
# Description
Отримує значення розширених властивостей (extended properties) для об'єктів бази даних.
Дозволяє фільтрувати по об'єктах та типах властивостей.

# Parameters
@major NVARCHAR(128) = NULL - основний об'єкт для пошуку (NULL = всі)
@minor NVARCHAR(128) = NULL - додатковий об'єкт (NULL = всі)
@property NVARCHAR(128) = NULL - назва властивості (NULL = всі властивості)

# Returns
TABLE - Повертає таблицю з колонками:
- majorName NVARCHAR(128) - назва основного об'єкта
- minorName NVARCHAR(128) - назва додаткового об'єкта
- propertyName NVARCHAR(128) - назва властивості
- propertyValue NVARCHAR(MAX) - значення властивості
- class TINYINT - клас об'єкта

# Usage
-- Отримати всі розширені властивості для таблиці
SELECT * FROM util.metadataGetExtendedProperiesValues('myTable', NULL, NULL);

-- Отримати значення конкретної властивості
SELECT * FROM util.metadataGetExtendedProperiesValues('myTable', 'myColumn', 'MS_Description');
*/
CREATE OR ALTER FUNCTION util.metadataGetExtendedProperiesValues(@major NVARCHAR(128) = NULL, @minor NVARCHAR(128) = NULL, @property NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT
		ep.major_id Id,
		ep.class,
		util.metadataGetAnyName(ep.major_id, ep.minor_id, ep.class) name,
		ep.name propertyName,
		CONVERT(NVARCHAR(MAX), ep.value) propertyValue,
		CASE
			WHEN ep.class = 1 AND ep.minor_id = 0 THEN util.metadataGetObjectType(ep.major_id)
			WHEN ep.class = 1 AND ep.minor_id > 0 THEN 'COLUMN'
			ELSE util.metadataGetClassName(ep.class)
		END typeDesc
	FROM sys.extended_properties ep(NOLOCK)
	WHERE
		(@property IS NULL OR ep.name = @property)
		AND (@major IS NULL OR ep.major_id = ISNULL(TRY_CONVERT(INT, @major), OBJECT_ID(@major)))
		AND (
			@minor IS NULL OR ep.minor_id = ISNULL(TRY_CONVERT(INT, @minor),
																				CASE ep.class
																					WHEN 1 THEN util.metadataGetColumnId(ep.major_id, @minor)
																					WHEN 2 THEN util.metadataGetIndexId(ep.major_id, @minor)
																					WHEN 7 THEN util.metadataGetParameterId(ep.major_id, @minor)
																				END
																			)
		)
);
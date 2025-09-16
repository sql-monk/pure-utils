/*
# Description
Отримує описи (extended properties) для об'єктів бази даних за заданими критеріями.
Працює з розширеними властивостями типу MS_Description.

# Parameters
@major NVARCHAR(128) - основний об'єкт для пошуку описів
@minor NVARCHAR(128) - додатковий об'єкт (колонка, параметр тощо)

# Returns
TABLE - Повертає таблицю з колонками:
- majorId INT - ідентифікатор основного об'єкта
- minorId INT - ідентифікатор додаткового об'єкта
- class TINYINT - клас об'єкта
- description NVARCHAR(MAX) - текст опису

# Usage
-- Отримати описи для конкретної таблиці та її колонок
SELECT * FROM util.metadataGetDescriptions('myTable', 'myColumn');
*/
CREATE FUNCTION util.metadataGetDescriptions(@major NVARCHAR(128), @minor NVARCHAR(128))
RETURNS TABLE
AS
RETURN(
	WITH cte AS (SELECT
		Id,
		name,
		propertyValue,
		typeDesc
	FROM util.metadataGetExtendedProperiesValues(@major, @minor, 'MS_Description')
	UNION ALL
	SELECT
		Id,
		name,
		propertyValue,
		typeDesc
	FROM util.metadataGetExtendedProperiesValues(@major, @minor, 'Description')
	)
	SELECT Id, name, propertyValue description, typeDesc FROM cte
);


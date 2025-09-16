/*
# Description
Розбиває визначення модулів на окремі рядки з нумерацією для подальшого аналізу.

# Parameters
@object NVARCHAR(128) = NULL - назва об'єкта для розбиття на рядки (NULL = усі об'єкти)
@additionalParameter NVARCHAR(128) = NULL - додатковий параметр (зарезервовано)

# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- ordinal INT - номер рядка
- line NVARCHAR(MAX) - текст рядка

# Usage
-- Розбити модуль на рядки
SELECT * FROM util.modulesSplitToLines('myProc', NULL);

-- Розбити всі модулі на рядки
SELECT * FROM util.modulesSplitToLines(NULL, NULL);
*/
CREATE FUNCTION util.modulesSplitToLines(@object NVARCHAR(128) = NULL, @additionalParameter NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT 
		m.object_id,
		ROW_NUMBER() OVER (PARTITION BY m.object_id ORDER BY v.number) AS ordinal,
		LTRIM(RTRIM(SUBSTRING(m.definition, v.number, CHARINDEX(CHAR(10), m.definition + CHAR(10), v.number) - v.number))) AS line
	FROM sys.sql_modules m (NOLOCK)
	CROSS APPLY (
		SELECT number 
		FROM master..spt_values 
		WHERE type = 'P' 
		AND number <= LEN(m.definition)
		AND (number = 1 OR SUBSTRING(m.definition, number - 1, 1) = CHAR(10))
	) v
	WHERE (@object IS NULL OR m.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
);

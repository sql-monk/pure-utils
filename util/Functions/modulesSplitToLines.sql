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
CREATE OR ALTER FUNCTION util.modulesSplitToLines(@object NVARCHAR(128), @skipEmpty BIT = 1)
RETURNS TABLE
AS
RETURN(
	WITH cteLines AS (
		SELECT
			sm.object_id objectId,
			TRIM(REPLACE(line.value, CHAR(9), ' ')) line,
			line.ordinal
		FROM sys.sql_modules sm
			CROSS APPLY STRING_SPLIT(REPLACE(sm.definition, CHAR(13), CHAR(10)), CHAR(10), 1) line
		WHERE(@object IS NULL OR sm.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
	)
	SELECT
		cteLines.objectId,
		cteLines.line,
		cteLines.ordinal lineNumber
	FROM cteLines
	WHERE(@skipEmpty = 0 OR LEN(cteLines.line) > 0)
);


/*
# Description
Розбиває визначення модулів (процедур, функцій, тригерів) на окремі рядки з нумерацією для подальшого аналізу.
Функція обробляє текст з sys.sql_modules, замінює табуляції на пробіли та може пропускати порожні рядки.

# Parameters
@object NVARCHAR(128) - назва або ID об'єкта для розбиття на рядки (NULL = усі об'єкти)
@skipEmpty BIT = 1 - пропускати порожні рядки (1 = так, 0 = включати порожні рядки)

# Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - ідентифікатор об'єкта модуля
- line NVARCHAR(MAX) - текст рядка (з обрізаними пробілами та заміненими табуляціями)
- lineNumber INT - номер рядка в модулі (порядковий номер)

# Usage
-- Розбити конкретний модуль на рядки (без порожніх)
SELECT * FROM util.modulesSplitToLines('util.errorHandler', 1);

-- Розбити модуль включаючи порожні рядки
SELECT * FROM util.modulesSplitToLines('util.errorHandler', 0);

-- Розбити всі модулі в базі даних
SELECT * FROM util.modulesSplitToLines(NULL, 1);

-- Знайти рядки з CREATE в модулі
SELECT * FROM util.modulesSplitToLines('util.errorHandler', 1)
WHERE line LIKE 'CREATE%';
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


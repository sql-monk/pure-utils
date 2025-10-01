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
	SELECT
		m.object_id objectId,
		l.line,
		l.lineNumber
	FROM sys.sql_modules m
		CROSS APPLY util.stringSplitToLines(m.definition, @skipEmpty) l
	WHERE(
		@object IS NULL OR m.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object))
	)
);


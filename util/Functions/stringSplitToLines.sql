/*
# Description
Розбиває текстовий рядок на окремі рядки з нумерацією для подальшого аналізу.
Функція обробляє будь-який текст, замінює табуляції на пробіли та може пропускати порожні рядки.

# Parameters
@string NVARCHAR(MAX) - текстовий рядок для розбиття на рядки
@skipEmpty BIT = 1 - пропускати порожні рядки (1 = так, 0 = включати порожні рядки)

# Returns
TABLE - Повертає таблицю з колонками:
- line NVARCHAR(MAX) - текст рядка (з обрізаними пробілами та заміненими табуляціями)
- lineNumber INT - номер рядка (порядковий номер)

# Usage
-- Розбити текст на рядки (без порожніх)
SELECT * FROM util.stringSplitToLines('Рядок 1' + CHAR(13) + CHAR(10) + 'Рядок 2', 1);

-- Розбити текст включаючи порожні рядки
SELECT * FROM util.stringSplitToLines('Рядок 1' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 'Рядок 3', 0);

-- Розбити SQL скрипт на рядки
DECLARE @script NVARCHAR(MAX) = 'SELECT * FROM table1;
GO
SELECT * FROM table2;';
SELECT * FROM util.stringSplitToLines(@script, 1);

-- Знайти номери рядків з SELECT
DECLARE @sql NVARCHAR(MAX) = 'CREATE PROCEDURE test AS
SELECT * FROM users;
SELECT COUNT(*) FROM orders;';
SELECT * FROM util.stringSplitToLines(@sql, 1)
WHERE line LIKE '%SELECT%';
*/
CREATE OR ALTER FUNCTION util.stringSplitToLines(@string NVARCHAR(MAX), @skipEmpty BIT = 1)
RETURNS TABLE
AS
RETURN(
	WITH cteLines AS (SELECT TRIM(REPLACE(line.value, CHAR(9), ' ')) line, line.ordinal FROM STRING_SPLIT(REPLACE(@string, CHAR(13), CHAR(10)), CHAR(10), 1) line)
	SELECT cteLines.line, cteLines.ordinal lineNumber FROM cteLines WHERE(@skipEmpty = 0 OR LEN(cteLines.line) > 0)
);
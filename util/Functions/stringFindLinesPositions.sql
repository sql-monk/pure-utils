/*
# Description
Знаходить позиції всіх рядків у переданому тексті, включаючи перший рядок.
Нумерує рядки та визначає їх початкові та кінцеві позиції.

# Parameters
@string NVARCHAR(MAX) - текст для аналізу позицій рядків
@replaceCRwithLF BIT = 1 - замінювати CR на LF для нормалізації переносів рядків

# Returns
TABLE - Повертає таблицю з колонками:
- startPosition INT - позиція початку рядка
- endPosition INT - позиція кінця рядка
- lineNumber INT - номер рядка

# Usage Examples
-- Знайти позиції всіх рядків у тексті
DECLARE @text NVARCHAR(MAX) = 'Перший рядок
Другий рядок
Третій рядок'
SELECT * FROM util.stringFindLinesPositions(@text, 1);

-- Аналіз SQL коду з визначенням позицій рядків
DECLARE @sqlCode NVARCHAR(MAX) = 'CREATE PROCEDURE dbo.TestProc
AS
BEGIN
    SELECT * FROM Users;
    UPDATE Users SET Status = ''Active'';
END'
SELECT 
    lineNumber, 
    startPosition, 
    endPosition,
    endPosition - startPosition + 1 AS lineLength
FROM util.stringFindLinesPositions(@sqlCode, 1)
ORDER BY lineNumber;

-- Обробка тексту з різними типами переносів
DECLARE @mixedText NVARCHAR(MAX) = 'Line 1' + CHAR(13) + CHAR(10) + 'Line 2' + CHAR(10) + 'Line 3'
SELECT * FROM util.stringFindLinesPositions(@mixedText, 1);

# Performance Notes
- Функція використовує util.stringRecureSearchStartEndPositionsExtended для пошуку символів переносу рядків
- Автоматично обробляє перший рядок та нумерує всі рядки
- Підтримує нормалізацію переносів рядків для коректного аналізу
- Ефективно працює з великими текстовими блоками
*/
CREATE OR ALTER FUNCTION [util].[stringFindLinesPositions](@string NVARCHAR(MAX), @replaceCRwithLF BIT = 1)
RETURNS TABLE
AS
RETURN(
WITH cteLines
AS (SELECT startPosition, endPosition FROM util.stringRecureSearchStartEndPositionsExtended (@string, CHAR (10), CHAR (10), @replaceCRwithLF) ),
cteFirstLine
AS (SELECT 1 startPosition, MIN (l.startPosition) endPosition FROM cteLines l),
cteAllLines
AS (SELECT
			fl.startPosition,
			fl.endPosition
		FROM	cteFirstLine fl
		WHERE fl.startPosition <> fl.endPosition
		UNION ALL
		SELECT
			l.startPosition,
			l.endPosition
		FROM	cteLines l)
SELECT
	al.startPosition,
	al.endPosition,
	ROW_NUMBER () OVER (ORDER BY al.startPosition) lineNumber
FROM	cteAllLines al
);
GO
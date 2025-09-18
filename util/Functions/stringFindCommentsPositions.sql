/*
# Description
Знаходить позиції всіх коментарів (багаторядкових та однорядкових) у переданому тексті.
Об'єднує результати пошуку багаторядкових коментарів /* */ та однорядкових коментарів --.

# Parameters
@string NVARCHAR(MAX) - текст для аналізу коментарів
@replaceCRwithLF BIT = 1 - замінювати CR на LF для нормалізації переносів рядків

# Returns
TABLE - Повертає таблицю з колонками:
- startPosition INT - позиція початку коментаря
- endPosition INT - позиція кінця коментаря

# Usage
-- Знайти всі коментарі у SQL коді
DECLARE @code NVARCHAR(MAX) = 'SELECT * FROM table; -- коментар
/* багаторядковий коментар */';
SELECT * FROM util.stringFindCommentsPositions(@code, 1);
*/
CREATE OR ALTER FUNCTION util.stringFindCommentsPositions(@string NVARCHAR(MAX), @replaceCRwithLF BIT = 1)
RETURNS TABLE
AS
RETURN(
	SELECT startPosition, endPosition FROM util.stringFindMultilineCommentsPositions(@string, @replaceCRwithLF)
	UNION ALL
	SELECT
		ic.startPosition,
		ic.endPosition
	FROM util.stringFindInlineCommentsPositions(@string, @replaceCRwithLF) ic
		OUTER APPLY util.stringFindMultilineCommentsPositions(@string, @replaceCRwithLF) mc
	WHERE
		ic.startPosition NOT BETWEEN ISNULL(mc.startPosition, 0) AND ISNULL(mc.endPosition, 0)
);
GO
/*
# Description
Знаходить позиції всіх коментарів (багаторядкових та однорядкових) у модулях бази даних.
Об'єднує результати з функцій пошуку багаторядкових та однорядкових коментарів.

# Parameters
@objectId INT = NULL - ідентифікатор об'єкта для пошуку коментарів (NULL = усі об'єкти)

# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку коментаря
- endPosition INT - позиція кінця коментаря

# Usage
-- Знайти всі коментарі в конкретному об'єкті
SELECT * FROM util.modulesFindCommentsPositions(OBJECT_ID('myProc'));

-- Знайти всі коментарі в усіх об'єктах
SELECT * FROM util.modulesFindCommentsPositions(NULL);
*/
CREATE OR ALTER FUNCTION util.modulesFindCommentsPositions(@objectId INT = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT object_id, startPosition, endPosition FROM util.modulesFindMultilineCommentsPositions(@objectId)
	UNION ALL
	SELECT
		ic.object_id,
		ic.startPosition,
		ic.endPosition
	FROM util.modulesFindInlineCommentsPositions(@objectId) ic
		OUTER APPLY util.modulesFindMultilineCommentsPositions(@objectId) mc
	WHERE
		ic.startPosition NOT BETWEEN ISNULL(mc.startPosition, 0) AND ISNULL(mc.endPosition, 0)
);
GO


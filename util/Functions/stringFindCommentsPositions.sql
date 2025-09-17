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
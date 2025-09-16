USE model;
GO
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


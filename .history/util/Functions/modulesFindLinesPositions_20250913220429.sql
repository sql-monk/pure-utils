USE model; 
GO
CREATE OR ALTER     FUNCTION [util].[modulesFindLinesPositions](@objectId INT = NULL)
RETURNS TABLE
AS
RETURN(
WITH cteLines
AS (SELECT object_id, startPosition, endPosition FROM		util.modulesRecureSearchStartEndPositionsExtended (CHAR (10), CHAR (10), 1, @objectId) ),
cteFirstLine
AS (SELECT l.object_id, 1 startPosition, MIN (l.startPosition) endPosition FROM cteLines l GROUP BY l.object_id),
cteAllLines
AS (SELECT
			fl.object_id,
			fl.startPosition,
			fl.endPosition
		FROM	cteFirstLine fl
		WHERE fl.startPosition <> fl.endPosition
		UNION ALL
		SELECT
			l.object_id,
			l.startPosition,
			l.endPosition
		FROM	cteLines l)
SELECT
	al.object_id,
	al.startPosition,
	al.endPosition,
	ROW_NUMBER () OVER (PARTITION BY al.object_id ORDER BY al.startPosition) lineNumber
FROM	cteAllLines al
);
GO


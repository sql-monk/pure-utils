CREATE OR ALTER FUNCTION util.modulesGetDescriptionFromComments(@objectId INT = NULL)
RETURNS TABLE
AS
RETURN(
	WITH cteRn AS (
		SELECT
			mlcp.object_id objectId,
			mlcp.startPosition,
			mlcp.endPosition,
			ROW_NUMBER() OVER (PARTITION BY mlcp.object_id ORDER BY mlcp.startPosition) rn
		FROM util.modulesFindMultilineCommentsPositions(@objectId) mlcp
			CROSS APPLY util.modulesGetCreateLineNumber(@objectId) cln
			CROSS APPLY util.modulesFindLinesPositions(@objectId) lp
		WHERE lp.lineNumber = cln.lineNumber AND mlcp.startPosition < lp.startPosition
	),
	cteComment AS (
		SELECT
			cteRn.objectId,
			SUBSTRING(sm.definition, cteRn.startPosition, cteRn.endPosition - cteRn.startPosition) comment
		FROM cteRn
			JOIN sys.sql_modules sm ON cteRn.objectId = sm.object_id
		WHERE cteRn.rn = 1
	),
	cteDescription AS (
		SELECT
			c.objectId,
			util.metadataGetObjectType(c.objectId) objectType,
			mlc.minor,
			CONCAT(
				'''',
				REPLACE(
					CONCAT(
					mlc.description,
					CHAR(13) + CHAR(10) + '# Returns' + CHAR(13) + CHAR(10) + mlc.returns,
					CHAR(13) + CHAR(10) + '# Usage' + CHAR(13) + CHAR(10) + mlc.usage
					),
					'''',
					''''''
				),
				''''
			) description
		FROM cteComment c
			CROSS APPLY util.stringSplitMultiLineComment(c.comment) mlc
	)
	SELECT
		cteDescription.objectId,
		cteDescription.objectType,
		cteDescription.minor,
		cteDescription.description
	FROM cteDescription
);


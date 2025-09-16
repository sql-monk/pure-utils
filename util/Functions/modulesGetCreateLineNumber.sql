CREATE OR ALTER FUNCTION util.modulesGetCreateLineNumber(@objectId INT = NULL)
RETURNS TABLE
AS
RETURN(
	WITH cteRn AS (
		SELECT
			lnCreate.objectId,
			lnCreate.lineNumber,
			ROW_NUMBER() OVER (PARTITION BY lnCreate.objectId ORDER BY lnCreate.lineNumber) rn
		FROM util.modulesSplitToLines(DEFAULT, DEFAULT) lnCreate
		WHERE lnCreate.line LIKE 'CREATE%'
	)
	SELECT cteRn.objectId, cteRn.lineNumber FROM cteRn WHERE cteRn.rn = 1
);

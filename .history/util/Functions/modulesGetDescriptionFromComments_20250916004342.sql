CREATE FUNCTION util.modulesGetDescriptionFromComments(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
SELECT
	lnCreate.object_id objectId,
	TRIM(REPLACE(lnDescr.line, '-- Description:', '')) description,
	lnDescr.ordinal lineNumber
FROM util.modulesSplitToLines(DEFAULT, DEFAULT) lnDescr
	CROSS APPLY(
		SELECT lnCreate.object_id, lnCreate.ordinal 
		FROM util.modulesSplitToLines(lnDescr.object_id, DEFAULT) lnCreate 
		WHERE lnCreate.line LIKE 'CREATE%'
) lnCreate
WHERE
	lnDescr.line LIKE '%-- Description:%' AND lnCreate.ordinal > lnDescr.ordinal
);
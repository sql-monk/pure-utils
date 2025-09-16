ALTER FUNCTION util.modulesGetDescriptionFromComments(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	WITH cte AS (
		SELECT
			lnDescr.object_id objectId,
			TRIM(REPLACE(lnDescr.line, '-- Description:', '')) description,
			MIN(lnDescr.ordinal) ordinal
		FROM util.modulesSplitToLines(@object, DEFAULT) lnDescr
		GROUP BY
			lnDescr.object_id,
			TRIM(REPLACE(lnDescr.line, '-- Description:', ''))
	)
	SELECT
		cte.objectId,
		cte.description,
		cte.ordinal lineNumber
	FROM cte
		CROSS APPLY(SELECT lnCreate.object_id, lnCreate.ordinal FROM util.modulesSplitToLines(cte.objectId, DEFAULT) lnCreate WHERE lnCreate.line LIKE 'CREATE%') lnCreate
	WHERE
		cte.ordinal LIKE '%-- Description:%' AND lnCreate.ordinal > cte.ordinal
);
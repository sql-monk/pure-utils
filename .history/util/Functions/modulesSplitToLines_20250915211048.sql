CREATE FUNCTION util.modulesSplitToLines(@object NVARCHAR(128), @skipEmpty BIT = 1)
RETURNS TABLE
AS
RETURN(
	WITH cteLines AS (
		SELECT
			sm.object_id,
			TRIM(REPLACE(line.value, CHAR(9), ' ')) codeLine,
			line.ordinal
		FROM sys.sql_modules sm
			CROSS APPLY STRING_SPLIT(REPLACE(sm.definition, CHAR(13), CHAR(10)), CHAR(10), 1) line
		WHERE(@object IS NOT NULL AND @object IN (sm.object_id, OBJECT_NAME(sm.object_id)))
	)
	SELECT
		cteLines.object_id,
		cteLines.codeLine,
		ordinal
	FROM cteLines
	WHERE(@skipEmpty = 1 AND LEN(cteLines.codeLine) > 0)
);

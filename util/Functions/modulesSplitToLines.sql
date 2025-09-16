CREATE FUNCTION util.modulesSplitToLines(@object NVARCHAR(128), @skipEmpty BIT = 1)
RETURNS TABLE
AS
RETURN(
	WITH cteLines AS (
		SELECT
			sm.object_id,
			TRIM(REPLACE(line.value, CHAR(9), ' ')) line,
			line.ordinal
		FROM sys.sql_modules sm
			CROSS APPLY STRING_SPLIT(REPLACE(sm.definition, CHAR(13), CHAR(10)), CHAR(10), 1) line
		WHERE(@object IS NULL OR sm.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
	)
	SELECT
		cteLines.object_id,
		cteLines.line,
		cteLines.ordinal lineNumber
	FROM cteLines
	WHERE(@skipEmpty = 0 OR LEN(cteLines.line) > 0)
);

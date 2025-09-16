USE model; 
GO
CREATE FUNCTION util.modulesRecureSearchStartEndPositionsExtended(@startValue NVARCHAR(32), @endValue NVARCHAR(32), @replaceCRwithLF BIT = 0, @objectID INT = NULL)
RETURNS TABLE
AS
RETURN
		 (WITH	ctestartEndRaw AS (
				 SELECT
					 0 lvl,
					 m.object_id,
					 CHARINDEX(@startValue, IIF(@replaceCRwithLF = 1, REPLACE(m.definition, CHAR(13), CHAR(10)), m.definition)) startPosition,
					 CONVERT(BIGINT, 0) endPosition,
					 m.definition
				 FROM sys.sql_modules(NOLOCK) m
				 WHERE
					 IIF(@replaceCRwithLF = 1, REPLACE(m.definition, CHAR(13), CHAR(10)), m.definition) LIKE '%' + @startValue + '%' + @endValue + '%'
					 AND m.object_id = COALESCE(@objectID, m.object_id)
				 UNION ALL
				 SELECT
					 m.lvl + 1,
					 m.object_id,
					 CHARINDEX(@startValue, m.definition, CHARINDEX(@endValue, m.definition, m.startPosition) + 1) startPosition, --start of next one
					 CHARINDEX(@endValue, m.definition, m.startPosition + 1) endPosition, --end of prev!
					 m.definition
				 FROM ctestartEndRaw m
				 WHERE
					 m.startPosition <> 0 AND CHARINDEX(@endValue, m.definition, m.startPosition) <> 0
			 ),
			 ctestartEnd AS (SELECT ml.object_id, ml.startPosition, LEAD(ml.endPosition) OVER (PARTITION BY ml.object_id ORDER BY ml.lvl) endPosition FROM ctestartEndRaw ml)
			 SELECT
				 ctestartEnd.object_id, ctestartEnd.startPosition, ctestartEnd.endPosition
			 FROM ctestartEnd
			 WHERE
				 ctestartEnd.startPosition > 0 AND ctestartEnd.endPosition > 0);
GO


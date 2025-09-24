/* MS_Description
# Description
Розширена функція рекурсивного пошуку позицій початку та кінця блоків у текстовому рядку з додатковими опціями.
Підтримує обробку символів переносу рядків для довільного тексту.

# Parameters
@string NVARCHAR(MAX) - текстовий рядок для пошуку
@startValue NVARCHAR(32) - початкове значення для пошуку
@endValue NVARCHAR(32) - кінцеве значення для пошуку
@replaceCRwithLF BIT = 0 - замінити CR на LF (1) або залишити як є (0)

*/
CREATE OR ALTER FUNCTION util.stringRecureSearchStartEndPositionsExtended(@string NVARCHAR(MAX), @startValue NVARCHAR(32), @endValue NVARCHAR(32), @replaceCRwithLF BIT = 0)
RETURNS TABLE
AS
RETURN(
	WITH ctestartEndRaw AS (
		SELECT
			0 lvl,
			CHARINDEX(@startValue, IIF(@replaceCRwithLF = 1, REPLACE(@string, CHAR(13), CHAR(10)), @string)) startPosition,
			CONVERT(BIGINT, 0) endPosition,
			IIF(@replaceCRwithLF = 1, REPLACE(@string, CHAR(13), CHAR(10)), @string) definition
		WHERE IIF(@replaceCRwithLF = 1, REPLACE(@string, CHAR(13), CHAR(10)), @string) LIKE '%' + @startValue + '%' + @endValue + '%'
		UNION ALL
		SELECT
			m.lvl + 1,
			CHARINDEX(@startValue, m.definition, CHARINDEX(@endValue, m.definition, m.startPosition) + 1) startPosition, --start of next one
			CHARINDEX(@endValue, m.definition, m.startPosition + 1) endPosition, --end of prev!
			m.definition
		FROM ctestartEndRaw m
		WHERE
			m.startPosition <> 0 AND CHARINDEX(@endValue, m.definition, m.startPosition) <> 0
	),
	ctestartEnd AS (SELECT ml.startPosition, LEAD(ml.endPosition) OVER (ORDER BY ml.lvl) endPosition FROM ctestartEndRaw ml)
	SELECT
		ctestartEnd.startPosition,
		ctestartEnd.endPosition
	FROM ctestartEnd
	WHERE
		ctestartEnd.startPosition > 0 AND ctestartEnd.endPosition > 0
);
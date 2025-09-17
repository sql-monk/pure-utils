/*
# Description
Розбирає багаторядковий коментар і повертає структуровану інформацію по секціях.
Функція аналізує коментарі за стандартним форматом документації та виділяє основні секції.

# Parameters
@string NVARCHAR(MAX) - Багаторядковий коментар для розбору

# Returns
TABLE - Повертає таблицю з колонками:
- description NVARCHAR(MAX) - Весь рядок для параметра або опису
- minor NVARCHAR(128) - NULL для загального опису, перше слово для # Parameters/# Columns
- returns NVARCHAR(MAX) - NULL для процедур, опис повернення для функцій
- usage NVARCHAR(MAX) - Приклади використання

# Usage
-- Розібрати коментар функції
SELECT * FROM util.stringMultiLineComment(@commentString);

-- Отримати тільки опис параметрів
SELECT * FROM util.stringMultiLineComment(@commentString) WHERE minor IS NOT NULL;
*/
CREATE OR ALTER FUNCTION util.stringSplitMultiLineComment(@string NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN(
	WITH cteLines AS (
		SELECT
			CONVERT(NVARCHAR(256), value) lineText,
			ordinal lineNumber
		FROM STRING_SPLIT(REPLACE(REPLACE(REPLACE(@string, '/*', ''), '*/', ''), CHAR(13) + CHAR(10), CHAR(10)), CHAR(10), 1)
		WHERE LEN(TRIM(value)) > 0
	),
	cteLast AS (SELECT TOP(1)lineNumber FROM cteLines ORDER BY lineNumber DESC),
	cteSectionsNames AS (SELECT REPLACE(cteLines.lineText, '# ', '') sectionName, lineNumber FROM cteLines WHERE cteLines.lineText LIKE '#%'),
	cteSectionBounds AS (
		SELECT
			cteSectionsNames.sectionName,
			lineNumber + 1 sectionStart,
			ISNULL(LEAD(lineNumber) OVER (ORDER BY lineNumber) - 1, (SELECT lineNumber FROM cteLast)) sectionEnd
		FROM cteSectionsNames
	),
	cteSections AS (
		SELECT
			sb.sectionName,
			ln.sectionText
		FROM cteSectionBounds sb
			CROSS APPLY(SELECT STRING_AGG(ln.lineText, CHAR(13) + CHAR(10)) sectionText FROM cteLines ln WHERE
									ln.lineNumber BETWEEN sb.sectionStart AND sb.sectionEnd
		) ln
		WHERE
			sb.sectionName NOT IN ('Parameters', 'Columns')
	),
	cteMinor AS (
		SELECT
			minor.name,
			ln.lineText description
		FROM cteSectionBounds sb
			CROSS APPLY(SELECT cteLines.lineText FROM cteLines WHERE lineNumber BETWEEN sb.sectionStart AND sb.sectionEnd) ln
			CROSS APPLY(SELECT CONVERT(NVARCHAR(128), value) name FROM STRING_SPLIT(TRIM(REPLACE(ln.lineText, CHAR(9), CHAR(32))), CHAR(32), 1)WHERE ordinal = 1) minor
		WHERE
			sb.sectionName IN ('Parameters', 'Columns')
	)
	SELECT
		NULL minor,
		descr.sectionText description,
		ret.sectionText returns,
		usage.sectionText usage
	FROM cteSections descr
		OUTER APPLY(SELECT s.sectionText FROM cteSections s WHERE s.sectionName = 'Returns') ret
		OUTER APPLY(SELECT s.sectionText FROM cteSections s WHERE s.sectionName = 'Usage') usage
	WHERE descr.sectionName = 'Description'
	UNION ALL
	SELECT cteMinor.name minor, cteMinor.description, NULL, NULL FROM cteMinor
);
GO
EXEC util.modulesSetDescriptionFromComments @object = N'util.stringSplitMultiLineComment'; -- nvarchar(128)

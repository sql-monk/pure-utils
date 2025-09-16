/*
# Description
Рекурсивно шукає всі входження заданого рядка у визначеннях модулів бази даних.

# Parameters
@searchFor NVARCHAR(64) - рядок для пошуку
@options TINYINT - опції пошуку (зарезервовано для майбутнього використання)

# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- occurrencePosition INT - позиція входження

# Usage
-- Знайти всі входження слова 'SELECT' в модулях
SELECT * FROM util.modulesRecureSearchForOccurrences('SELECT', 0);

-- Пошук специфічного тексту
SELECT * FROM util.modulesRecureSearchForOccurrences('BEGIN TRANSACTION', 0);
*/
CREATE FUNCTION [util].[modulesRecureSearchForOccurrences](@searchFor NVARCHAR(64), @options TINYINT)
RETURNS TABLE
AS
RETURN(
WITH cteoccurrences
AS (SELECT
			m.object_id,
			CHARINDEX (@searchFor, m.definition) occurrencePosition,
			m.definition
		FROM	sys.sql_modules m (NOLOCK)
		WHERE m.definition IS NOT NULL
		UNION ALL
		SELECT
			m.object_id,
			CHARINDEX (@searchFor, m.definition, m.occurrencePosition + 1) occurrencePosition,
			m.definition
		FROM	cteoccurrences m
		WHERE m.occurrencePosition > 0),
cteoccurrencesNextChars
AS (SELECT
			o.object_id,
			o.occurrencePosition,
			SUBSTRING (o.definition, o.occurrencePosition - 1, 1) prevChar,
			SUBSTRING (o.definition, o.occurrencePosition + LEN (@searchFor), 1) nextChar,
			IIF(@options & 2 = 2, SUBSTRING (o.definition, o.occurrencePosition + LEN (@searchFor), 2), '') nextTwoChars
		FROM	cteoccurrences o
		WHERE o.occurrencePosition > 0)
SELECT
	c.object_id,
	c.occurrencePosition
FROM cteoccurrencesNextChars c
WHERE NOT(@options & 2 = 2 	AND (c.nextChar = '.' OR c.nextTwoChars = '].')) --skep before '.' option is set but next is '.' or two next = '].'
	AND NOT(@options & 4 = 4  AND (c.prevChar LIKE '[A-я]' OR c.nextChar LIKE '[A-я]')) --single word opion and prev or next char is a letter 
	AND NOT (@options & 8 = 8 AND  (c.prevChar = '[' OR c.nextChar= ']')) --skip quotename is set, but here we are
);
GO


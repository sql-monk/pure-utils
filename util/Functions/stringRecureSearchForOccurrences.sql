/*
# Description
Рекурсивно шукає всі входження заданого рядка у переданому тексті.
Використовує CTE для знаходження всіх позицій входження з можливістю фільтрації за опціями.

# Parameters
@string NVARCHAR(MAX) - текст для пошуку входжень
@searchFor NVARCHAR(64) - рядок для пошуку в тексті
@options TINYINT - бітові опції пошуку: (2): пропускати входження перед '.' або '].',  (4): шукати тільки цілі слова (не частини слів), (8): пропускати входження в quoted names ([...])

# Returns
TABLE - Повертає таблицю з колонками:
- occurrencePosition INT - позиція входження в тексті (1-based)

# Usage Examples
-- Знайти всі входження слова 'SELECT' без фільтрів
SELECT * FROM util.stringRecureSearchForOccurrences('SELECT * FROM table WHERE id = 1; SELECT COUNT(*) FROM users;', 'SELECT', 0);

-- Пошук цілих слів 'user' (не 'users', 'username' тощо)
SELECT * FROM util.stringRecureSearchForOccurrences('user table contains user_name and users data', 'user', 4);

-- Комбінація опцій: цілі слова + пропуск quoted names
SELECT * FROM util.stringRecureSearchForOccurrences('[name] column and name field', 'name', 12); -- 4 + 8

-- Пошук з опцією пропуску входжень перед крапкою
SELECT * FROM util.stringRecureSearchForOccurrences('schema.table and table.column', 'table', 2);

# Performance Notes
- Функція оптимізована для роботи з великими текстовими рядками
- Рекурсивний CTE ефективно обробляє множинні входження
- Бітові опції дозволяють гнучко налаштовувати критерії пошуку
*/
CREATE OR ALTER FUNCTION util.stringRecureSearchForOccurrences(@string NVARCHAR(MAX), @searchFor NVARCHAR(64), @options TINYINT)
RETURNS TABLE
AS
RETURN(
	WITH cteoccurrences AS (
		SELECT CHARINDEX(@searchFor, @string) occurrencePosition, @string definition WHERE @string IS NOT NULL
		UNION ALL
		SELECT
			CHARINDEX(@searchFor, m.definition, m.occurrencePosition + 1) occurrencePosition,
			m.definition
		FROM cteoccurrences m
		WHERE m.occurrencePosition > 0
	),
	cteoccurrencesNextChars AS (
		SELECT
			o.occurrencePosition,
			SUBSTRING(o.definition, o.occurrencePosition - 1, 1) prevChar,
			SUBSTRING(o.definition, o.occurrencePosition + LEN(@searchFor), 1) nextChar,
			IIF(@options & 2 = 2, SUBSTRING(o.definition, o.occurrencePosition + LEN(@searchFor), 2), '') nextTwoChars
		FROM cteoccurrences o
		WHERE o.occurrencePosition > 0
	)
	SELECT c.occurrencePosition
	FROM cteoccurrencesNextChars c
	WHERE
		NOT(@options & 2 = 2 AND (c.nextChar = '.' OR c.nextTwoChars = '].')) --skep before '.' option is set but next is '.' or two next = '].'
		AND NOT(@options & 4 = 4 AND (c.prevChar LIKE '[A-я]' OR c.nextChar LIKE '[A-я]')) --single word opion and prev or next char is a letter 
		AND NOT(@options & 8 = 8 AND (c.prevChar = '[' OR c.nextChar = ']')) --skip quotename is set, but here we are
);
GO
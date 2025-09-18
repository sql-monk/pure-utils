/*
# Description
Функція для роботи з рядками. Виконує обробку текстових даних.

# Parameters
@string NVARCHAR(MAX - параметр

# Returns
TABLE - результат функції

# Usage
-- Приклад використання
SELECT * FROM util.stringGetCreateLineNumber(параметри);
*/

CREATE OR ALTER FUNCTION util.stringGetCreateLineNumber(@string NVARCHAR(MAX), @skipEmpty BIT = 1)
RETURNS TABLE
AS
RETURN(
	WITH cteRn AS (
		SELECT
			lnCreate.lineNumber,
			ROW_NUMBER() OVER (ORDER BY lnCreate.lineNumber) rn
		FROM util.stringSplitToLines(@string, @skipEmpty) lnCreate
		WHERE lnCreate.line LIKE 'CREATE%'
	)
	SELECT cteRn.lineNumber FROM cteRn WHERE cteRn.rn = 1
);
GO
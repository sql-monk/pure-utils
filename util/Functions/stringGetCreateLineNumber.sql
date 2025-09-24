/* MS_Description
# Description
Знаходить номер рядка де розташована перша інструкція CREATE у переданому тексті.
Функція корисна для аналізу SQL скриптів та визначення початку створення об'єктів.

# Parameters
@string NVARCHAR(MAX) - текст для аналізу (SQL скрипт або код)
@skipEmpty BIT = 1 - пропускати порожні рядки при нумерації (1 = пропускати, 0 = не пропускати)

# Returns
TABLE - Повертає таблицю з колонкою:
- lineNumber INT - номер рядка де знайдена перша інструкція CREATE

# Usage
-- Знайти рядок з CREATE в SQL коді
DECLARE @sql NVARCHAR(MAX) = 'GO
-- Коментар
CREATE OR ALTER PROCEDURE dbo.Test
AS BEGIN
  SELECT 1
END'
SELECT * FROM util.stringGetCreateLineNumber(@sql, 1);

-- Результат: lineNumber = 3 (якщо пропускаємо порожні рядки)
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
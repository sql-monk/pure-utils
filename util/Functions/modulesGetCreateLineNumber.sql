/*
# Description
Повертає номер рядка, де знаходиться оператор CREATE для заданого об'єкта модуля.
Функція аналізує текст модуля та знаходить перший рядок що починається з "CREATE".

# Parameters
@objectId INT = NULL - ідентифікатор об'єкта модуля (функція, процедура, тригер)

# Returns
TABLE:
- objectId INT - ідентифікатор об'єкта
- lineNumber INT - номер рядка з оператором CREATE

# Usage
-- Знайти номер рядка з CREATE для всіх об'єктів
SELECT * FROM util.modulesGetCreateLineNumber(DEFAULT)

-- Знайти номер рядка з CREATE для конкретного об'єкта
SELECT * FROM util.modulesGetCreateLineNumber(OBJECT_ID('util.errorHandler'))
*/
CREATE OR ALTER FUNCTION util.modulesGetCreateLineNumber(@objectId INT = NULL)
RETURNS TABLE
AS
RETURN(
	WITH cteRn AS (
		SELECT
			lnCreate.objectId,
			lnCreate.lineNumber,
			ROW_NUMBER() OVER (PARTITION BY lnCreate.objectId ORDER BY lnCreate.lineNumber) rn
		FROM util.modulesSplitToLines(DEFAULT, DEFAULT) lnCreate
		WHERE lnCreate.line LIKE 'CREATE%'
	)
	SELECT cteRn.objectId, cteRn.lineNumber FROM cteRn WHERE cteRn.rn = 1
);

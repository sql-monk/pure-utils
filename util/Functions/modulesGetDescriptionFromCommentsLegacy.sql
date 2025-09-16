/*
# Description
Витягує описи об'єктів з коментарів у вихідному коді модулів, шукаючи рядки що починаються з '-- Description:'.

# Parameters
@object NVARCHAR(128) = NULL - назва об'єкта для пошуку описів (NULL = усі об'єкти)

# Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - ідентифікатор об'єкта
- schemaName NVARCHAR(128) - назва схеми
- objectName NVARCHAR(128) - назва об'єкта
- description NVARCHAR(MAX) - витягнутий опис з коментарів

# Usage
-- Витягти описи з коментарів для конкретного об'єкта
SELECT * FROM util.modulesGetDescriptionFromComments('myProc');

-- Витягти описи для всіх об'єктів
SELECT * FROM util.modulesGetDescriptionFromComments(NULL);
*/
CREATE OR ALTER FUNCTION util.modulesGetDescriptionFromCommentsLegacy(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT
		cte.objectId,
		TRIM(REPLACE(TRIM(REPLACE(cte.line, CHAR(9), CHAR(32))), '-- Description:', '')) description,
		cte.lineNumber lineNumber
	FROM util.modulesSplitToLines(DEFAULT, DEFAULT) cte
		CROSS APPLY(SELECT lnCreate.objectId, lnCreate.lineNumber FROM util.modulesSplitToLines(cte.objectId, DEFAULT) lnCreate WHERE lnCreate.line LIKE '%CREATE%') lnCreate
	WHERE
		cte.line LIKE '%-- Description:%' AND lnCreate.lineNumber > cte.lineNumber
);
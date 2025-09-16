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
CREATE FUNCTION util.modulesGetDescriptionFromComments(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	WITH cte AS (
		SELECT
			lnDescr.object_id objectId,
			TRIM(REPLACE(lnDescr.line, '-- Description:', '')) description,
			MIN(lnDescr.ordinal) ordinal
		FROM util.modulesSplitToLines(@object, DEFAULT) lnDescr
		GROUP BY
			lnDescr.object_id,
			TRIM(REPLACE(lnDescr.line, '-- Description:', ''))
	)
	SELECT
		cte.objectId,
		cte.description,
		cte.ordinal lineNumber
	FROM cte
		CROSS APPLY(SELECT lnCreate.object_id, lnCreate.ordinal FROM util.modulesSplitToLines(cte.objectId, DEFAULT) lnCreate WHERE lnCreate.line LIKE 'CREATE%') lnCreate
	WHERE
		cte.ordinal LIKE '%-- Description:%' AND lnCreate.ordinal > cte.ordinal
);
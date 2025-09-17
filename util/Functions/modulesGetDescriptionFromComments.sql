/*
# Description
Витягує опис з коментарів модулів (функцій, процедур, тригерів) та форматує його для встановлення 
як розширену властивість. Функція аналізує багаторядкові коментарі що знаходяться перед оператором CREATE
та витягує з них структурований опис.

# Parameters
@objectId INT = NULL - ідентифікатор об'єкта модуля (NULL для всіх об'єктів)

# Returns
TABLE:
- objectId INT - ідентифікатор об'єкта
- objectType NVARCHAR(128) - тип об'єкта (FUNCTION, PROCEDURE, TRIGGER)
- minor INT - мінорний ідентифікатор (завжди 0 для модулів)
- description NVARCHAR(MAX) - відформатований опис з коментарів

# Usage
-- Отримати опис для всіх модулів
SELECT * FROM util.modulesGetDescriptionFromComments(DEFAULT)

-- Отримати опис для конкретного модуля
SELECT * FROM util.modulesGetDescriptionFromComments(OBJECT_ID('util.errorHandler'))
*/
CREATE OR ALTER FUNCTION util.modulesGetDescriptionFromComments(@objectId INT = NULL)
RETURNS TABLE
AS
RETURN(
	WITH cteRn AS (
		SELECT
			mlcp.object_id objectId,
			mlcp.startPosition,
			mlcp.endPosition,
			ROW_NUMBER() OVER (PARTITION BY mlcp.object_id ORDER BY mlcp.startPosition) rn
		FROM util.modulesFindMultilineCommentsPositions(@objectId) mlcp
			CROSS APPLY util.modulesGetCreateLineNumber(@objectId) cln
			CROSS APPLY util.modulesFindLinesPositions(@objectId) lp
		WHERE lp.lineNumber = cln.lineNumber AND mlcp.startPosition < lp.startPosition
	),
	cteComment AS (
		SELECT
			cteRn.objectId,
			SUBSTRING(sm.definition, cteRn.startPosition, cteRn.endPosition - cteRn.startPosition) comment
		FROM cteRn
			JOIN sys.sql_modules sm ON cteRn.objectId = sm.object_id
		WHERE cteRn.rn = 1
	),
	cteDescription AS (
		SELECT
			c.objectId,
			util.metadataGetObjectType(c.objectId) objectType,
			mlc.minor,
			CONCAT(
				'''',
				REPLACE(
					CONCAT(
					mlc.description,
					CHAR(13) + CHAR(10) + '# Returns' + CHAR(13) + CHAR(10) + mlc.returns,
					CHAR(13) + CHAR(10) + '# Usage' + CHAR(13) + CHAR(10) + 
					 + CHAR(13) + CHAR(10) + '```sql' + CHAR(13) + CHAR(10) + mlc.usage + CHAR(13) + CHAR(10) + '```' + CHAR(13) + CHAR(10)
					),
					'''',
					''''''
				),
				''''
			) description
		FROM cteComment c
			CROSS APPLY util.stringSplitMultiLineComment(c.comment) mlc
	)
	SELECT
		cteDescription.objectId,
		cteDescription.objectType,
		cteDescription.minor,
		cteDescription.description
	FROM cteDescription
);


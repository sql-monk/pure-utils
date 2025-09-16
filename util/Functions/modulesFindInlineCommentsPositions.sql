/*
# Description
Знаходить позиції однорядкових коментарів (що починаються з '--') у модулях бази даних.

# Parameters
@objectId INT = NULL - ідентифікатор об'єкта для пошуку коментарів (NULL = усі об'єкти)

# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку коментаря
- endPosition INT - позиція кінця коментаря

# Usage
-- Знайти однорядкові коментарі в конкретному об'єкті
SELECT * FROM util.modulesFindInlineCommentsPositions(OBJECT_ID('myProc'));
*/
CREATE FUNCTION [util].[modulesFindInlineCommentsPositions](@objectId INT = NULL)
RETURNS TABLE
AS
RETURN(SELECT object_id, startPosition, endPosition FROM util.modulesRecureSearchStartEndPositionsExtended ('--', CHAR (10), 1, @objectId) );
GO




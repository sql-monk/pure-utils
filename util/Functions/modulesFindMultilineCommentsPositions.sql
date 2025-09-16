/*
# Description
Знаходить позиції багаторядкових коментарів (/* ... */) у модулях бази даних.

# Parameters
@objectId INT = NULL - ідентифікатор об'єкта для пошуку коментарів (NULL = усі об'єкти)

# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку коментаря
- endPosition INT - позиція кінця коментаря

# Usage
-- Знайти багаторядкові коментарі в конкретному об'єкті
SELECT * FROM util.modulesFindMultilineCommentsPositions(OBJECT_ID('myProc'));
*/
CREATE FUNCTION [util].[modulesFindMultilineCommentsPositions](@objectId INT = NULL)
RETURNS TABLE
AS
RETURN(SELECT object_id, startPosition, endPosition FROM util.modulesRecureSearchStartEndPositionsExtended ('/*', '*/', DEFAULT, @objectId) );
GO




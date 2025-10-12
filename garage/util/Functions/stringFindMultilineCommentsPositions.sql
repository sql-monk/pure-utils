/* MS_Description
# Description
Знаходить позиції багаторядкових коментарів (/* ... */) у переданому тексті.

# Parameters
@string NVARCHAR(MAX) - текст для аналізу коментарів
@replaceCRwithLF BIT = 1 - замінювати CR на LF для нормалізації переносів рядків

# Returns
TABLE - Повертає таблицю з колонками:
- startPosition INT - позиція початку коментаря
- endPosition INT - позиція кінця коментаря
 
*/
CREATE OR ALTER FUNCTION [util].[stringFindMultilineCommentsPositions](@string NVARCHAR(MAX), @replaceCRwithLF BIT = 1)
RETURNS TABLE
AS
RETURN(SELECT startPosition, endPosition FROM util.stringRecureSearchStartEndPositionsExtended (@string, '/*', '*/', @replaceCRwithLF) );
GO
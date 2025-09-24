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

# Usage Examples
-- Знайти багаторядкові коментарі у SQL коді
DECLARE @sqlCode NVARCHAR(MAX) = '
SELECT * FROM table1
/* Це багаторядковий
   коментар для пояснення */
WHERE id > 0
/* Ще один коментар */
AND status = ''active''
'
SELECT * FROM util.stringFindMultilineCommentsPositions(@sqlCode, 1);

-- Аналіз складного коду з вкладеними коментарями
DECLARE @complexCode NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE dbo.TestProc
AS
BEGIN
    /* Початок процедури
       Виконує важливі операції */
    
    SELECT COUNT(*) 
    /* Підрахунок записів */ 
    FROM Users;
    
    /* Кінець процедури
       Повертає результат */
END
'
SELECT 
    startPosition,
    endPosition,
    endPosition - startPosition + 1 AS commentLength
FROM util.stringFindMultilineCommentsPositions(@complexCode, 1)
ORDER BY startPosition;

# Performance Notes
- Функція використовує util.stringRecureSearchStartEndPositionsExtended для пошуку
- Ефективно обробляє множинні коментарі в тексті
- Підтримує нормалізацію переносів рядків для коректного аналізу
*/
CREATE OR ALTER FUNCTION [util].[stringFindMultilineCommentsPositions](@string NVARCHAR(MAX), @replaceCRwithLF BIT = 1)
RETURNS TABLE
AS
RETURN(SELECT startPosition, endPosition FROM util.stringRecureSearchStartEndPositionsExtended (@string, '/*', '*/', @replaceCRwithLF) );
GO
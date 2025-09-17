/*
# Description
Знаходить позиції однорядкових коментарів (що починаються з '--') у переданому тексті.

# Parameters
@string NVARCHAR(MAX) - текст для аналізу коментарів
@replaceCRwithLF BIT = 1 - замінювати CR на LF для нормалізації переносів рядків

# Returns
TABLE - Повертає таблицю з колонками:
- startPosition INT - позиція початку коментаря
- endPosition INT - позиція кінця коментаря

# Usage Examples
-- Знайти однорядкові коментарі у SQL коді
DECLARE @sqlCode NVARCHAR(MAX) = '
SELECT * FROM table1 -- Це коментар до запиту
WHERE id > 0
-- Повний рядковий коментар
AND status = ''active'' -- Ще один коментар
'
SELECT * FROM util.stringFindInlineCommentsPositions(@sqlCode, 1);

-- Аналіз коду з різними типами коментарів
DECLARE @codeWithComments NVARCHAR(MAX) = '
CREATE PROCEDURE dbo.TestProc -- Створення процедури
AS
BEGIN
    -- Початок логіки процедури
    SELECT COUNT(*) -- Підрахунок записів
    FROM Users u -- Таблиця користувачів
    WHERE u.IsActive = 1; -- Тільки активні користувачі
    
    -- Кінець процедури
END
'
SELECT 
    startPosition,
    endPosition,
    endPosition - startPosition + 1 AS commentLength
FROM util.stringFindInlineCommentsPositions(@codeWithComments, 1)
ORDER BY startPosition;

-- Витягнути текст коментарів
DECLARE @text NVARCHAR(MAX) = 'Line 1 -- Comment 1
Line 2 -- Comment 2
Line 3'
SELECT 
    startPosition,
    endPosition,
    SUBSTRING(@text, startPosition, endPosition - startPosition + 1) AS commentText
FROM util.stringFindInlineCommentsPositions(@text, 1);

# Performance Notes
- Функція використовує util.stringRecureSearchStartEndPositionsExtended для пошуку
- Шукає коментарі що починаються з '--' і закінчуються символом переносу рядка
- Ефективно обробляє множинні коментарі в тексті
- Підтримує нормалізацію переносів рядків для коректного аналізу
*/
CREATE OR ALTER FUNCTION [util].[stringFindInlineCommentsPositions](@string NVARCHAR(MAX), @replaceCRwithLF BIT = 1)
RETURNS TABLE
AS
RETURN(SELECT startPosition, endPosition FROM util.stringRecureSearchStartEndPositionsExtended (@string, '--', CHAR (10), @replaceCRwithLF) );
GO
/*
# Description
Рекурсивно шукає позиції початку та кінця блоків у модулях за заданими початковим та кінцевим значеннями.
Спрощена версія функції modulesRecureSearchStartEndPositionsExtended.

# Parameters
@startValue NVARCHAR(32) - початкове значення для пошуку
@endValue NVARCHAR(32) - кінцеве значення для пошуку

# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку блоку
- endPosition INT - позиція кінця блоку

# Usage
-- Знайти блоки BEGIN...END
SELECT * FROM util.modulesRecureSearchStartEndPositions('BEGIN', 'END');

-- Знайти блоки IF...END IF  
SELECT * FROM util.modulesRecureSearchStartEndPositions('IF', 'END IF');
*/
CREATE OR ALTER FUNCTION [util].[modulesRecureSearchStartEndPositions](@startValue NVARCHAR(32), @endValue NVARCHAR(32))
RETURNS TABLE
AS
RETURN(SELECT object_id, startPosition, endPosition FROM util.modulesRecureSearchStartEndPositionsExtended (@startValue, @endValue, DEFAULT, DEFAULT) );
GO


/*
# Description
Розбиває рядок на окремі символи та повертає їх як табличний результат.
Функція використовує рекурсивний CTE для ітерації по кожному символу вхідного рядка
та повертає позицію символу, сам символ та його ASCII код.

# Parameters
@string NVARCHAR(MAX) - Вхідний рядок для розбиття на символи

# Returns
Таблиця з колонками:
- pos INT - Позиція символу в рядку (починаючи з 1)
- chr NCHAR(1) - Символ
- asciiCode INT - ASCII код символу

# Usage
-- Розбити рядок на символи
SELECT * FROM util.stringSplitToChars('Hello');

-- Знайти всі символи з певним ASCII кодом
SELECT * FROM util.stringSplitToChars('Test String 123') WHERE asciiCode > 64 AND asciiCode < 91;

-- Підрахувати кількість символів різних типів
SELECT 
    CASE 
        WHEN asciiCode BETWEEN 48 AND 57 THEN 'Digit'
        WHEN asciiCode BETWEEN 65 AND 90 THEN 'Upper'
        WHEN asciiCode BETWEEN 97 AND 122 THEN 'Lower'
        ELSE 'Other'
    END charType,
    COUNT(*) count
FROM util.stringSplitToChars('Hello World 123!')
GROUP BY 
    CASE 
        WHEN asciiCode BETWEEN 48 AND 57 THEN 'Digit'
        WHEN asciiCode BETWEEN 65 AND 90 THEN 'Upper'
        WHEN asciiCode BETWEEN 97 AND 122 THEN 'Lower'
        ELSE 'Other'
    END;
*/
CREATE OR ALTER FUNCTION util.stringSplitToChars(@string NVARCHAR(MAX))
RETURNS TABLE 
AS RETURN (
    WITH cteChars AS (
        SELECT 
            1 pos, 
            SUBSTRING(@string, 1, 1) chr, 
            LEN(@string) totalLen
        UNION ALL
        SELECT 
            cteChars.pos + 1, 
            SUBSTRING(@string, cteChars.pos + 1, 1), 
            cteChars.totalLen 
        FROM cteChars 
        WHERE cteChars.pos < cteChars.totalLen
    )
    SELECT 
        chrs.pos, 
        chrs.chr, 
        ASCII(chrs.chr) asciiCode 
    FROM cteChars chrs
);
GO

/*
# Description
Конвертує бінарний Security Identifier (SID) у текстовий формат.
Функція розбирає структуру SID та формує стандартне текстове представлення
у форматі 'S-версія-authority-субавторитет1-субавторитет2-...'.

# Parameters
@sid VARBINARY(85) - Бінарне представлення Security Identifier (SID)

# Returns
VARCHAR(100) - Текстове представлення SID у форматі 'S-1-5-21-...' або NULL якщо SID невалідний

# Usage
-- Конвертувати SID користувача у текстовий формат
SELECT util.stringConvertFromSID(SUSER_SID('DOMAIN\User'));

-- Отримати текстові SID всіх користувачів бази даних
SELECT 
    name,
    util.stringConvertFromSID(sid) sidString
FROM sys.database_principals
WHERE sid IS NOT NULL;

-- Перевірка конвертації
DECLARE @binarySid VARBINARY(85) = SUSER_SID();
SELECT util.stringConvertFromSID(@binarySid) textSid;
*/
CREATE OR ALTER FUNCTION util.stringConvertFromSID(@sid VARBINARY(85))
RETURNS VARCHAR(100)
WITH SCHEMABINDING
AS
BEGIN
    -- Перевірка на NULL
    IF @sid IS NULL
        RETURN NULL;

    DECLARE @sidStr VARCHAR(100);
    DECLARE @len INT = DATALENGTH(@sid);
    DECLARE @loop INT;

    -- Валідація мінімальної довжини SID (мінімум 8 байт)
    IF @len < 8
        RETURN NULL;

    -- Формування початку SID: 'S-' + версія + '-' + authority
    SET @sidStr = CONCAT(
        'S-',
        CONVERT(INT, SUBSTRING(@sid, 1, 1)),
        '-',
        CONVERT(BIGINT, 
            CONVERT(INT, SUBSTRING(@sid, 3, 1)) * 1099511627776 +
            CONVERT(INT, SUBSTRING(@sid, 4, 1)) * 4294967296 +
            CONVERT(INT, SUBSTRING(@sid, 5, 1)) * 16777216 +
            CONVERT(INT, SUBSTRING(@sid, 6, 1)) * 65536 +
            CONVERT(INT, SUBSTRING(@sid, 7, 1)) * 256 +
            CONVERT(INT, SUBSTRING(@sid, 8, 1))
        )
    );

    -- Обробка sub-authorities (починаючи з 9-го байту)
    SET @loop = 9;
    WHILE @loop <= @len - 3
    BEGIN
        SET @sidStr = CONCAT(
            @sidStr,
            '-',
            CONVERT(BIGINT, 
                CONVERT(INT, SUBSTRING(@sid, @loop + 3, 1)) * 16777216 +
                CONVERT(INT, SUBSTRING(@sid, @loop + 2, 1)) * 65536 +
                CONVERT(INT, SUBSTRING(@sid, @loop + 1, 1)) * 256 +
                CONVERT(INT, SUBSTRING(@sid, @loop, 1))
            )
        );
        SET @loop = @loop + 4;
    END;

    RETURN @sidStr;
END;
GO

/*
# Description
Конвертує текстовий Security Identifier (SID) у бінарний формат.
Функція парсить текстове представлення SID та формує відповідну бінарну структуру,
яка використовується в системних таблицях SQL Server.

# Parameters
@string VARCHAR(100) - Текстове представлення SID у форматі 'S-1-5-21-...'

# Returns
VARBINARY(85) - Бінарне представлення SID або NULL якщо формат невалідний

# Usage
-- Конвертувати текстовий SID у бінарний формат
SELECT util.stringConvertToSID('S-1-5-21-3623811015-3361044348-30300820-1013');

-- Знайти користувача за текстовим SID
DECLARE @textSid VARCHAR(100) = 'S-1-5-21-1234567890-1234567890-1234567890-500';
SELECT * 
FROM sys.database_principals 
WHERE sid = util.stringConvertToSID(@textSid);

-- Перевірка двостороннього конвертування
DECLARE @originalText VARCHAR(100) = 'S-1-5-32-544';
DECLARE @binary VARBINARY(85) = util.stringConvertToSID(@originalText);
SELECT 
    @originalText originalSid,
    util.stringConvertFromSID(@binary) convertedBackSid;
*/
CREATE OR ALTER FUNCTION util.stringConvertToSID(@string VARCHAR(100))
RETURNS VARBINARY(85)
WITH SCHEMABINDING
AS
BEGIN
    -- Перевірка на NULL та формат
    IF @string IS NULL OR @string NOT LIKE 'S-[0-9]-%' RETURN NULL;

    DECLARE @sid VARBINARY(85) = 0x;
    DECLARE @pos INT = 3; -- Позиція після 'S-'
    DECLARE @nextPos INT;
    DECLARE @part VARCHAR(20);
    DECLARE @partCount INT = 0;
    DECLARE @authority BIGINT;
    DECLARE @version TINYINT;
    DECLARE @subAuthorities VARBINARY(256) = 0x;

    -- Парсинг версії (перше число після 'S-')
    SET @nextPos = CHARINDEX('-', @string, @pos);
    IF @nextPos = 0 RETURN NULL;

    SET @part = SUBSTRING(@string, @pos, @nextPos - @pos);
    SET @version = CONVERT(TINYINT, @part);

    SET @pos = @nextPos + 1;

    -- Парсинг identifier authority (друге число)
    SET @nextPos = CHARINDEX('-', @string, @pos);
    IF @nextPos = 0 RETURN NULL;

    SET @part = SUBSTRING(@string, @pos, @nextPos - @pos);
    SET @authority = CONVERT(BIGINT, @part);

    SET @pos = @nextPos + 1;

    -- Парсинг sub-authorities (решта чисел)
    WHILE @pos <= LEN(@string)
    BEGIN
        SET @nextPos = CHARINDEX('-', @string, @pos);

        IF @nextPos = 0 SET @nextPos = LEN(@string) + 1;

        SET @part = SUBSTRING(@string, @pos, @nextPos - @pos);

        IF LEN(@part) > 0
        BEGIN
            DECLARE @subVal BIGINT = CONVERT(BIGINT, @part);

            -- Sub-authorities зберігаються у little-endian (4 байти)
            SET @subAuthorities = @subAuthorities 
                + CONVERT(VARBINARY(1), @subVal % 256) 
                + CONVERT(VARBINARY(1), (@subVal / 256) % 256)
                + CONVERT(VARBINARY(1), (@subVal / 65536) % 256) 
                + CONVERT(VARBINARY(1), (@subVal / 16777216) % 256);

            SET @partCount = @partCount + 1;
        END;

        SET @pos = @nextPos + 1;
    END;

    -- Формування фінального SID
    -- Версія (1 байт)
    SET @sid = CONVERT(VARBINARY(1), @version);

    -- Кількість sub-authorities (1 байт)
    SET @sid = @sid + CONVERT(VARBINARY(1), @partCount);

    -- Authority у big-endian (6 байтів)
    SET @sid = @sid 
        + CONVERT(VARBINARY(1), (@authority / 1099511627776) % 256) 
        + CONVERT(VARBINARY(1), (@authority / 4294967296) % 256)
        + CONVERT(VARBINARY(1), (@authority / 16777216) % 256) 
        + CONVERT(VARBINARY(1), (@authority / 65536) % 256)
        + CONVERT(VARBINARY(1), (@authority / 256) % 256) 
        + CONVERT(VARBINARY(1), @authority % 256);

    -- Додаємо всі sub-authorities
    SET @sid = @sid + @subAuthorities;

    RETURN @sid;
END;
GO

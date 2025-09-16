/*
# Description
Перейменовує індекси відповідно до стандартних конвенцій найменування, генеруючи та виконуючи SQL скрипти.

# Parameters
@table NVARCHAR(128) = NULL - назва таблиці для перейменування індексів (NULL = усі таблиці)
@index NVARCHAR(128) = NULL - назва конкретного індексу (NULL = усі індекси)
@output TINYINT = 1 - виводити результати (1) або тільки виконувати (0)

# Returns
Виконує перейменування індексів і може виводити результати залежно від параметра @output

# Usage
-- Перейменувати всі індекси таблиці з виведенням результатів
EXEC util.indexesSetConventionNames @table = 'myTable', @output = 1;

-- Перейменувати конкретний індекс без виведення
EXEC util.indexesSetConventionNames @table = 'myTable', @index = 'oldIndexName', @output = 0;
*/
CREATE PROCEDURE util.indexesSetConventionNames
    @table NVARCHAR(128) = NULL,
    @index NVARCHAR(128) = NULL,
    @output TINYINT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX) = '';

    -- Build concatenated SQL from all rename scripts
    SELECT @sql = @sql + RenameScript + CHAR(13) + CHAR(10)
    FROM util.indexesGetScriptConventionRename(@table, @index);

 
        IF (@output & 2 = 2) PRINT @sql;
        IF (@output & 4 = 4) SELECT CONVERT(XML, @sql) AS RenameScriptsXML;
    END
     
    IF (@output & 8 = 8 AND  LEN(@sql) > 0) 
    BEGIN
        EXEC sp_executesql @sql;
    END
END;
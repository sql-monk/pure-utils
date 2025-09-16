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
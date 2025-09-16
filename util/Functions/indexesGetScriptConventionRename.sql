CREATE FUNCTION util.indexesGetScriptConventionRename(@table NVARCHAR(128) = NULL, @index NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
    SELECT
        CONCAT(
            'EXEC sp_rename N''',
            icn.currentName,
            ''', N''',
            icn.newName,
            ''', N''INDEX'';'
        ) AS statement
    FROM util.indexesGetConventionNames(@table, @index) icn
    WHERE icn.currentName <> icn.newName -- Only return indexes that need renaming
);
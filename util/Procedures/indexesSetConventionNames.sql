/*
# Description
Перейменовує індекси таблиць за стандартними конвенціями найменування, генеруючи та виконуючи SQL команди.

# Parameters
@table NVARCHAR(128) = NULL - назва таблиці для перейменування індексів (NULL = всі таблиці)
@index NVARCHAR(128) = NULL - назва конкретного індексу (NULL = всі індекси)
@output TINYINT = 1 - виводити генеровані SQL команди (1) або тільки виконувати (0)

# Usage
-- Перейменувати всі індекси таблиці з виводом команд
EXEC util.indexesSetConventionNames @table = 'myTable', @output = 1;

-- Перейменувати конкретний індекс без виводу
EXEC util.indexesSetConventionNames @table = 'myTable', @index = 'oldIndexName', @output = 0;
*/
CREATE OR ALTER PROCEDURE util.indexesSetConventionNames @table NVARCHAR(128) = NULL,
	@index NVARCHAR(128) = NULL,
	@output TINYINT = 1
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX) = N'';

	-- Build concatenated SQL from all rename scripts
	SELECT @sql = @sql + statement + CHAR(13) + CHAR(10)FROM util.indexesGetScriptConventionRename(@table, @index);


	IF(@output & 2 = 2)PRINT @sql;
	IF(@output & 4 = 4)SELECT CONVERT(XML, @sql) RenameScriptsXML;


	IF(@output & 8 = 8 AND LEN(@sql) > 0)
	BEGIN
		EXEC sys.sp_executesql @sql;
	END;
END;
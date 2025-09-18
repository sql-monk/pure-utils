/*
# Description
����������� ������� �������� �� ����������� ��������� ������������, ��������� �� ��������� SQL �������.

# Parameters
@table NVARCHAR(128) = NULL - ����� ������� ��� �������������� ������� (NULL = �� �������)
@index NVARCHAR(128) = NULL - ����� ����������� ������� (NULL = �� �������)
@output TINYINT = 1 - �������� ���������� (1) ��� ����� ���������� (0)

# Returns
������ �������������� ������� � ���� �������� ���������� ������� �� ��������� @output

# Usage
-- ������������� �� ������� ������� � ���������� ����������
EXEC util.indexesSetConventionNames @table = 'myTable', @output = 1;

-- ������������� ���������� ������ ��� ���������
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
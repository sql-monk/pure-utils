/*
# Description
Scalar �������-�������� ��� ��������� DDL ������� �� ����� ������ SQL ������.
������� inline ������� util.stringGetCreateTempScriptInline � ������� ��������� �� �������� ��������.
ϳ������ �������������� ������ ����� ���������� @params.

# Parameters
@query NVARCHAR(MAX) - SQL ����� ��� ������ ��������� ������������� ������
@tablename NVARCHAR(128) = NULL - ��'� ���������� ������� (default: #temp)  
@params NVARCHAR(MAX) = NULL - ���������� ��������� ������ � ������ sp_executesql

# Returns
NVARCHAR(MAX) - ������� �� ��������� CREATE TABLE ������

# Usage
SELECT util.stringGetCreateTempScript('SELECT * FROM util.indexesGetMissing(DEFAULT)',DEFAULT,DEFAULT)
*/
CREATE OR ALTER FUNCTION [util].[stringGetCreateTempScript](
    @query NVARCHAR(MAX), 
    @tablename NVARCHAR(128) = NULL,
    @params NVARCHAR(MAX) = NULL
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    
    SELECT @result = createScript 
    FROM util.stringGetCreateTempScriptInline(@query, @tablename, @params);
    
    RETURN @result;
END;
GO
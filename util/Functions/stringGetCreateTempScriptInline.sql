/*
# Description
Inline table-valued ������� ��� ������ SQL ������ �� ��������� ���������� CREATE TABLE DDL.
����������� sys.dm_exec_describe_first_result_set � ��������� ���������������� ������.
����������� ������� ���� �����, nullable constraints �� ������� ������������ ������.

# Parameters
@query NVARCHAR(MAX) - SQL ����� ��� ������ ��������� ������������� ������
@tablename NVARCHAR(128) = NULL - ����� ���������� ��������� ������� (default: #temp)
@params NVARCHAR(MAX) = NULL - ����� ���������� ��������� � ������ sp_executesql

# Returns
TABLE - ��������� ��������� � ������ ��������:
- createScript NVARCHAR(MAX) - ������������ CREATE TABLE ������ � ���������� �����

# Usage
SELECT * FROM util.stringGetCreateTempScriptInline('SELECT * FROM util.indexesGetMissing(DEFAULT)',DEFAULT,DEFAULT)
 
*/
CREATE OR ALTER FUNCTION [util].[stringGetCreateTempScriptInline](
    @query NVARCHAR(MAX), 
    @tablename NVARCHAR(128) = NULL,
    @params NVARCHAR(MAX) = NULL
)
RETURNS TABLE
AS
RETURN(
    WITH cteColumns AS (
        SELECT
            rs.column_ordinal,
            rs.name AS column_name,
            rs.system_type_name,
            rs.is_nullable
        FROM sys.dm_exec_describe_first_result_set(@query, @params, 1) rs
        WHERE rs.is_hidden = 0
    ),
    cteColumnDefinitions AS (
        SELECT 
            column_ordinal,
            CONCAT(
                QUOTENAME(column_name), ' ',
                system_type_name,
                CASE WHEN is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END
            ) AS column_definition
        FROM cteColumns
    )
    SELECT 
        CONCAT(
            'CREATE TABLE ', ISNULL(@tablename, '#temp'), ' (',
            CHAR(13) + CHAR(10) + CHAR(9),
            STRING_AGG(column_definition, ',' + CHAR(13) + CHAR(10) + CHAR(9)) 
                WITHIN GROUP (ORDER BY column_ordinal),
            CHAR(13) + CHAR(10) + ');'
        ) AS createScript
    FROM cteColumnDefinitions
);
GO
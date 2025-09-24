/*
�������� ������ ��� �������� ������� ��������� ������� ��������� ���������� �������
*/

-- ��������� �� ���� ����� util
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'util')
    CREATE SCHEMA [util] AUTHORIZATION [dbo];
GO

-- ���� 1: stringGetCreateTempScriptInline - ������� SELECT
PRINT '=== ���� 1: stringGetCreateTempScriptInline ===';
SELECT createScript 
FROM util.stringGetCreateTempScriptInline('SELECT 1 as ID, ''Test'' as Name, GETDATE() as CreateDate');
GO

-- ���� 2: stringGetCreateTempScript - �������� �����
PRINT '=== ���� 2: stringGetCreateTempScript ===';
DECLARE @script NVARCHAR(MAX);
SET @script = util.stringGetCreateTempScript('SELECT TOP 5 name, object_id, create_date FROM sys.objects WHERE type = ''U''');
PRINT @script;
GO

-- ���� 3: objectGetCreateTempScriptInline - ��� ���������� ��'����
PRINT '=== ���� 3: objectGetCreateTempScriptInline ===';
-- �������� ������� ��������� ��� ������������
CREATE OR ALTER PROCEDURE dbo.TestProc
AS
BEGIN
    SELECT 
        name,
        object_id,
        type,
        create_date
    FROM sys.objects 
    WHERE type IN ('U', 'V', 'P')
    ORDER BY create_date DESC;
END;
GO

SELECT createScript 
FROM util.objectGetCreateTempScriptInline('dbo.TestProc');
GO

-- ���� 4: objectGetCreateTempScript - ��� 򳺿 � ���������
PRINT '=== ���� 4: objectGetCreateTempScript ===';
DECLARE @objectScript NVARCHAR(MAX);
SET @objectScript = util.objectGetCreateTempScript('dbo.TestProc');
PRINT @objectScript;
GO

-- ���� 5: ������������ ������������� ������� ��� ��������� �������
PRINT '=== ���� 5: ������� ��������� ��������� ������� ===';
DECLARE @createSQL NVARCHAR(MAX);
SET @createSQL = util.stringGetCreateTempScript('SELECT ''Sample'' as TextColumn, 123 as NumberColumn, CAST(1 as BIT) as BoolColumn');

-- �������� ������������ ������
EXEC sp_executesql @createSQL;

-- ��������� ��������� �������� �������
IF OBJECT_ID('tempdb..#temp') IS NOT NULL
BEGIN
    PRINT '��������� ������� ������ ��������!';
    
    -- �������� ������� �������
    SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        IS_NULLABLE,
        CHARACTER_MAXIMUM_LENGTH
    FROM tempdb.INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME LIKE '#temp%'
    ORDER BY ORDINAL_POSITION;
    
    -- �������� ������ ���
    INSERT INTO #temp VALUES ('Test data', 456, 0);
    
    -- �������� ���
    SELECT * FROM #temp;
    
    DROP TABLE #temp;
    PRINT '��������� ������� ��������.';
END
ELSE
BEGIN
    PRINT '�������: ��������� ������� �� ���� ��������.';
END
GO

-- �������� ������� ���������
DROP PROCEDURE IF EXISTS dbo.TestProc;
GO

PRINT '=== ���������� ��������� ===';
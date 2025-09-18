/*
# Description
������� �������� ��� ����� ��'���� �� ���� ��������� ������.
��������������� ��� ������������ �������� ���� ����� � ������� ����.

# Parameters
@className NVARCHAR(128) - �������� ����� ����� ��'����

# Returns
TINYINT - �������� ��� ����� (0-���� �����, 1-��'���/�������, 2-��������, ����) ��� NULL ��� ��������� �����

# Usage
-- �������� ��� ����� �� ������
SELECT util.metadataGetClassByName('OBJECT_OR_COLUMN');
SELECT util.metadataGetClassByName('INDEX');
*/
CREATE OR ALTER FUNCTION util.metadataGetClassByName(@className NVARCHAR(128))
RETURNS TINYINT
AS
BEGIN
	RETURN CASE UPPER(LTRIM(RTRIM(@className)))
		WHEN 'DATABASE' THEN 0
		WHEN 'OBJECT_OR_COLUMN' THEN 1
		WHEN 'OBJECT' THEN 1
		WHEN 'TABLE' THEN 1
		WHEN 'PROCEDURE' THEN 1
		WHEN 'FUNCTION' THEN 1
		WHEN 'VIEW' THEN 1
		WHEN 'TRIGGER' THEN 1
		WHEN 'COLUMN' THEN 1
		WHEN 'PARAMETER' THEN 2
		WHEN 'SCHEMA' THEN 3
		WHEN 'DATABASE_PRINCIPAL' THEN 4
		WHEN 'USER' THEN 4
		WHEN 'ROLE' THEN 4
		WHEN 'INDEX' THEN 7
		WHEN 'DATASPACE' THEN 20
		WHEN 'FILEGROUP' THEN 20
		WHEN 'PARTITION_SCHEMA' THEN 20
		WHEN 'PARTITION SCHEMA' THEN 20
		WHEN 'PARTITION_FUNCTION' THEN 21
		WHEN 'PARTITION FUNCTION' THEN 21
		WHEN 'DATABASE_FILE' THEN 22
		WHEN 'DATABASE FILE' THEN 22
		WHEN 'FILE' THEN 22
		WHEN 'CERTIFICATE' THEN 25
		ELSE NULL
	END;
END;
GO
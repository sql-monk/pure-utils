/*
# Description
������ ������ ��� �� ��������� ��� ����������� ��'���� ���� �����.
������� ������� �� ��䳿, ���'���� � �������� ��'�����, ������� �������� ������������.

# Parameters
@object NVARCHAR(128) - ����� ��'���� ��� ��������� �����
@startTime DATETIME2 = NULL - ���������� ��� ��� ���������� ���� (NULL = �� ��䳿)

# Returns
TABLE - ���ert� ������� � ���������:
- eventType NVARCHAR - ��� ��䳿
- postTime DATETIME - ��� ��������� ��䳿
- SPID INT - ������������� ���
- serverName NVARCHAR - ����� �������
- loginName NVARCHAR - ��'� ����������� ��� �����
- userName NVARCHAR - ��'� �����������
- roleName NVARCHAR - ����� ���
- databaseName NVARCHAR - ����� ���� �����
- schemaName NVARCHAR - ����� �����
- objectName NVARCHAR - ����� ��'����
- objectType NVARCHAR - ��� ��'����
- loginType NVARCHAR - ��� �����
- targetObjectName NVARCHAR - ����� ��������� ��'����
- targetObjectType NVARCHAR - ��� ��������� ��'����
- propertyName NVARCHAR - ����� ����������
- propertyValue NVARCHAR - �������� ����������
- parameters NVARCHAR - ���������
- tsql_command NVARCHAR - T-SQL �������

# Usage
-- �������� ��� ������ ��� �������
SELECT * FROM util.objectGetHistory('myTable', NULL);

-- �������� ������ ��� �� ������� ����
SELECT * FROM util.objectGetHistory('myTable', DATEADD(day, -1, GETDATE()));
*/
CREATE OR ALTER FUNCTION util.objectGetHistory(@object NVARCHAR(128), @startTime DATETIME2 = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT
		event_type eventType,
		post_time postTime,
		spid SPID,
		server_name serverName,
		login_name loginName,
		user_name userName,
		role_name roleName,
		database_name databaseName,
		schema_name schemaName,
		object_name objectName,
		object_type objectType,
		login_type loginType,
		target_object_name targetObjectName,
		target_object_type targetObjectType,
		property_name propertyName,
		property_value propertyValue,
		parameters,
		tsql_command
	FROM msdb.dbo.events_notifications
	WHERE
		(@startTime IS NULL OR post_time >= @startTime)
        AND (object_name = @object OR target_object_name = @object)
);-- Write your own SQL object definition here, and it'll be included in your package.

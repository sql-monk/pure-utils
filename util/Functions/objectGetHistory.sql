/*
# Description
Отримує історію змін та активності для конкретного об'єкта бази даних.
Функція повертає всі події, пов'язані з вказаним об'єктом, виконані поточним користувачем.

# Parameters
@object NVARCHAR(128) - Назва об'єкта для отримання історії
@startTime DATETIME2 = NULL - Початковий час для фільтрації подій (NULL = всі події)

# Returns
TABLE - Повertає таблицю з колонками:
- eventType NVARCHAR - Тип події
- postTime DATETIME - Час публікації події
- SPID INT - Ідентифікатор сесії
- serverName NVARCHAR - Назва сервера
- loginName NVARCHAR - Ім'я користувача для входу
- userName NVARCHAR - Ім'я користувача
- roleName NVARCHAR - Назва ролі
- databaseName NVARCHAR - Назва бази даних
- schemaName NVARCHAR - Назва схеми
- objectName NVARCHAR - Назва об'єкта
- objectType NVARCHAR - Тип об'єкта
- loginType NVARCHAR - Тип входу
- targetObjectName NVARCHAR - Назва цільового об'єкта
- targetObjectType NVARCHAR - Тип цільового об'єкта
- propertyName NVARCHAR - Назва властивості
- propertyValue NVARCHAR - Значення властивості
- parameters NVARCHAR - Параметри
- tsql_command NVARCHAR - T-SQL команда

# Usage
-- Отримати всю історію змін таблиці
SELECT * FROM util.objectGetHistory('myTable', NULL);

-- Отримати історію змін за останню добу
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

/*
# Description
Отримує історію активності поточного користувача з системних подій.
Функція повертає всю історію дій, виконаних поточним користувачем в базі даних.

# Parameters
@startTime DATETIME = NULL - Початковий час для фільтрації подій (NULL = всі події)

# Returns
TABLE - Повертає таблицю з колонками:
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
-- Отримати всю історію активності поточного користувача
SELECT * FROM util.myselfGetHistory(NULL);

-- Отримати історію активності з певного часу
SELECT * FROM util.myselfGetHistory('2025-09-16 00:00:00');
*/
CREATE FUNCTION util.myselfGetHistory(@startTime DATETIME = NULL)
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
		login_name = ORIGINAL_LOGIN() AND (@startTime IS NULL OR post_time >= @startTime)
);-- Write your own SQL object definition here, and it'll be included in your package.

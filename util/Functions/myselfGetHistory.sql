/*
# Description
Отримує історію подій аудиту для поточного користувача (ORIGINAL_LOGIN()).
Функція фільтрує записи з таблиці подій за логіном користувача та опціонально за часом.

# Parameters
@startTime DATETIME - початковий час для фільтрації подій (NULL = всі події)

# Returns
TABLE - Повертає таблицю з колонками:
- eventType NVARCHAR - тип події аудиту
- postTime DATETIME - час події
- SPID INT - ідентифікатор процесу сервера
- serverName NVARCHAR - ім'я сервера
- loginName NVARCHAR - ім'я логіну
- userName NVARCHAR - ім'я користувача
- roleName NVARCHAR - ім'я ролі
- databaseName NVARCHAR - назва бази даних
- schemaName NVARCHAR - назва схеми
- objectName NVARCHAR - назва об'єкта
- objectType NVARCHAR - тип об'єкта
- loginType NVARCHAR - тип логіну
- targetObjectName NVARCHAR - назва цільового об'єкта
- targetObjectType NVARCHAR - тип цільового об'єкта
- propertyName NVARCHAR - назва властивості
- propertyValue NVARCHAR - значення властивості
- parameters NVARCHAR - параметри команди
- tsql_command NVARCHAR - текст T-SQL команди

# Usage Examples
-- Отримати всю історію поточного користувача
SELECT * FROM util.myselfGetHistory(NULL);

-- Отримати події за останню годину
SELECT * FROM util.myselfGetHistory(DATEADD(HOUR, -1, GETDATE()));

-- Аналіз активності за день з групуванням по типах подій
SELECT eventType, COUNT(*) as EventCount, MIN(postTime) as FirstEvent, MAX(postTime) as LastEvent
FROM util.myselfGetHistory(DATEADD(DAY, -1, GETDATE()))
GROUP BY eventType
ORDER BY EventCount DESC;

-- Пошук конкретних операцій над об'єктами
SELECT postTime, eventType, databaseName, objectName, tsql_command
FROM util.myselfGetHistory(DATEADD(DAY, -7, GETDATE()))
WHERE objectName IS NOT NULL
ORDER BY postTime DESC;
*/
CREATE OR ALTER FUNCTION util.myselfGetHistory(@startTime DATETIME = NULL)
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

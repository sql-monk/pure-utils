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
	FROM dbo.events_notifications
	WHERE
		login_name = ORIGINAL_LOGIN() AND (@startTime IS NULL OR post_time >= @startTime)
);-- Write your own SQL object definition here, and it'll be included in your package.

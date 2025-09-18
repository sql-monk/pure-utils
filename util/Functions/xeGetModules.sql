CREATE OR ALTER FUNCTION util.xeGetModules(@scope NVARCHAR(100), @minEventTime DATETIME2 = NULL)
RETURNS TABLE
AS
RETURN(
	WITH xeTarget AS (
		SELECT
			ISNULL(@minEventTime, lastEventTime) lastEventTime,
			NULLIF(lastOffset, 0) lastOffset,
			IIF(lastOffset = 0, NULL, currentFile) currentFile,
			CONCAT('utilsModules', @scope, '*.xel') defaultMask,
			util.xeGetLogsPath('utilsModules' + @scope) mdpath
		--CONCAT(util.xeGetLogsPath(@sessionName), REPLACE(@sessionName, ' utils', '')) mdpath
		FROM util.xeGetTargetFile('utilsModules' + @scope)
	),
	xe AS (
		SELECT
			CAST(xe.event_data AS XML) event_data,
			xe.file_name,
			xe.file_offset,
			t.lastEventTime,
			xe.timestamp_utc
		FROM xeTarget t
			CROSS APPLY sys.fn_xe_file_target_read_file(t.mdpath + t.defaultMask, NULL, t.currentFile, t.lastOffset) xe
		WHERE xe.timestamp_utc > t.lastEventTime
	),
	cteEvents AS (
		SELECT
			x.event_data.value('(event/@name)[1]', 'NVARCHAR(50)') EventName,
			x.event_data.value('(event/@timestamp)[1]', 'DATETIME2(7)') EventTime,
			x.event_data.value('(event/data[@name="object_name"]/value)[1]', 'NVARCHAR(128)') ObjectName,
			x.event_data.value('(event/data[@name="statement"]/value)[1]', 'NVARCHAR(MAX)') Statement,
			x.event_data.value('(event/data[@name="duration"]/value)[1]', 'BIGINT') Duration,
			x.event_data.value('(event/data[@name="source_database_id"]/value)[1]', 'INT') SourceDatabaseId,
			x.event_data.value('(event/data[@name="object_id"]/value)[1]', 'BIGINT') ObjectId,
			x.event_data.value('(event/data[@name="line_number"]/value)[1]', 'INT') LineNumber,
			x.event_data.value('(event/data[@name="offset"]/value)[1]', 'INT') Offset,
			x.event_data.value('(event/data[@name="offset_end"]/value)[1]', 'INT') OffsetEnd,
			x.event_data.value('(event/data[@name="object_type"]/value)[1]', 'NVARCHAR(10)') ObjectType,
			x.event_data.value('(event/data[@name="row_count"]/value)[1]', 'BIGINT') ModuleRowCount,
			x.event_data.value('(event/action[@name="database_name"]/value)[1]', 'NVARCHAR(128)') DatabaseName,
			x.event_data.value('(event/action[@name="database_id"]/value)[1]', 'SMALLINT') DatabaseId,
			x.event_data.value('(event/action[@name="session_id"]/value)[1]', 'INT') SessionId,
			x.event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'NVARCHAR(128)') ClientHostname,
			x.event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'NVARCHAR(256)') ClientAppName,
			x.event_data.value('(event/action[@name="server_principal_name"]/value)[1]', 'NVARCHAR(128)') ServerPrincipalName,
			x.event_data.value('(event/action[@name="sql_text"]/value)[1]', 'NVARCHAR(MAX)') SqlText,
			x.event_data.value('(event/action[@name="plan_handle"]/value)[1]', 'VARBINARY(64)') PlanHandle,
			x.event_data.value('(event/action[@name="task_time"]/value)[1]', 'BIGINT') TaskTime,
			x.file_name FileName,
			x.file_offset FileOffset
		FROM xe x
	)
	SELECT
		a.EventName,
		a.EventTime,
		HASHBYTES(
			'SHA2_256',
			CONCAT(
				a.EventName,
				a.EventTime,
				a.ObjectName,
				a.Statement,
				a.Duration,
				a.SourceDatabaseId,
				a.ObjectId,
				a.LineNumber,
				a.Offset,
				a.OffsetEnd,
				a.ObjectType,
				a.ModuleRowCount,
				a.DatabaseName,
				a.DatabaseId,
				a.SessionId,
				a.ClientHostname,
				a.ClientAppName,
				a.ServerPrincipalName,
				a.SqlText,
				a.PlanHandle,
				a.TaskTime,
				a.FileName,
				a.FileOffset
			)
		) hb,
		a.ObjectName,
		a.Statement,
		a.Duration,
		a.SourceDatabaseId,
		a.ObjectId,
		a.LineNumber,
		a.Offset,
		a.OffsetEnd,
		a.ObjectType,
		a.ModuleRowCount,
		a.DatabaseName,
		a.DatabaseId,
		a.SessionId,
		a.ClientHostname,
		a.ClientAppName,
		a.ServerPrincipalName,
		a.SqlText,
		a.PlanHandle,
		a.TaskTime,
		a.FileName,
		a.FileOffset
	FROM cteEvents a
);
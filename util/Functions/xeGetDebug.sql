/*
# Description
Таблично-значуща функція для отримання даних про debug події з Extended Events.
Читає дані з сесії utilsBatchesDebug та повертає їх у структурованому вигляді для аналізу та відладки.
Відстежує події sp_statement, sql_batch та sql_statement з маркером __#debug.

# Parameters
@minEventTime DATETIME2(7) - мінімальний час події для фільтрації (NULL = всі події)

# Returns
TABLE - Повертає таблицю з колонками:
- EventTime DATETIME2(7) - час події
- EventName NVARCHAR(128) - назва події (sp_statement_starting, sql_batch_completed тощо)
- DatabaseName NVARCHAR(128) - назва бази даних
- ObjectName NVARCHAR(128) - назва об'єкта (для sp_statement)
- Statement NVARCHAR(MAX) - текст оператора/батчу
- Duration BIGINT - тривалість виконання (мікросекунди)
- CpuTime BIGINT - час CPU (мікросекунди)
- LogicalReads BIGINT - кількість логічних читань
- PhysicalReads BIGINT - кількість фізичних читань
- Writes BIGINT - кількість записів
- AffectedRowsCount BIGINT - кількість рядків
- ClientHostname NVARCHAR(128) - ім'я хоста клієнта
- ClientAppName NVARCHAR(128) - назва додатку клієнта
- ServerPrincipalName NVARCHAR(128) - ім'я принципала сервера
- SessionId INT - ID сесії
- SqlText NVARCHAR(MAX) - повний SQL текст
- PlanHandle VARBINARY(64) - хендл плану виконання
- TaskTime BIGINT - час задачі
- FileName NVARCHAR(260) - ім'я файлу XE
- FileOffset BIGINT - зміщення у файлі

# Usage Examples
-- Отримати всі debug події
SELECT * FROM util.xeGetDebug(NULL);

-- Отримати debug події за останню годину
SELECT * FROM util.xeGetDebug(DATEADD(HOUR, -1, GETDATE()));

-- Отримати повільні запити з debug маркером
SELECT EventTime, DatabaseName, ObjectName, Duration/1000 as DurationMs, Statement
FROM util.xeGetDebug(DATEADD(HOUR, -1, GETDATE()))
WHERE Duration > 1000000 -- більше 1 секунди
ORDER BY Duration DESC;

-- Аналіз виконання по об'єктах
SELECT ObjectName, COUNT(*) as ExecutionCount, AVG(Duration)/1000 as AvgDurationMs
FROM util.xeGetDebug(DATEADD(DAY, -1, GETDATE()))
WHERE ObjectName IS NOT NULL
GROUP BY ObjectName
ORDER BY AvgDurationMs DESC;

-- Відстеження конкретної сесії
SELECT EventTime, EventName, Statement, Duration/1000 as DurationMs
FROM util.xeGetDebug(NULL)
WHERE SessionId = 123
ORDER BY EventTime;
*/
CREATE OR ALTER FUNCTION util.xeGetDebug(@minEventTime DATETIME2(7))
RETURNS TABLE
AS
RETURN(
	WITH xeTarget AS (
		SELECT
			ISNULL(@minEventTime, lastEventTime) lastEventTime,
			NULLIF(lastOffset, 0) lastOffset,
			IIF(lastOffset = 0, NULL, currentFile) currentFile,
			'utilsDebug*.xel' defaultMask,
			util.xeGetLogsPath('utilsDebug') mdpath
		FROM util.xeGetTargetFile('utilsDebug')
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
			x.event_data.value('(event/@timestamp)[1]', 'DATETIME2(7)') EventTime,
			x.event_data.value('(event/@name)[1]', 'NVARCHAR(128)') EventName,
			x.event_data.value('(event/action[@name="database_name"]/value)[1]', 'NVARCHAR(128)') DatabaseName,
			x.event_data.value('(event/data[@name="object_name"]/value)[1]', 'NVARCHAR(128)') ObjectName,
			COALESCE(
				x.event_data.value('(event/data[@name="statement"]/value)[1]', 'NVARCHAR(MAX)'),
				x.event_data.value('(event/data[@name="batch_text"]/value)[1]', 'NVARCHAR(MAX)')
			) Statement,
			x.event_data.value('(event/data[@name="line_number"]/value)[1]', 'INT') LineNumber,
			x.event_data.value('(event/data[@name="offset"]/value)[1]', 'INT') Offset,
			x.event_data.value('(event/data[@name="offset_end"]/value)[1]', 'INT') OffsetEnd,
			x.event_data.value('(event/data[@name="duration"]/value)[1]', 'BIGINT') Duration,
			x.event_data.value('(event/data[@name="cpu_time"]/value)[1]', 'BIGINT') CpuTime,
			x.event_data.value('(event/data[@name="logical_reads"]/value)[1]', 'BIGINT') LogicalReads,
			x.event_data.value('(event/data[@name="physical_reads"]/value)[1]', 'BIGINT') PhysicalReads,
			x.event_data.value('(event/data[@name="writes"]/value)[1]', 'BIGINT') Writes,
			x.event_data.value('(event/data[@name="row_count"]/value)[1]', 'BIGINT') AffectedRowsCount,
			x.event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'NVARCHAR(128)') ClientHostname,
			x.event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'NVARCHAR(128)') ClientAppName,
			x.event_data.value('(event/action[@name="server_principal_name"]/value)[1]', 'NVARCHAR(128)') ServerPrincipalName,
			x.event_data.value('(event/action[@name="session_id"]/value)[1]', 'INT') SessionId,
			x.event_data.value('(event/action[@name="sql_text"]/value)[1]', 'NVARCHAR(MAX)') SqlText,
			x.event_data.query('event/data[@name="showplan_xml"]/value/*')showPlanXML,
			CONVERT(VARBINARY(64), x.event_data.value('(event/action[@name="plan_handle"]/value)[1]', 'VARCHAR(MAX)'), 2) PlanHandle,
			x.event_data.value('(event/action[@name="task_time"]/value)[1]', 'BIGINT') TaskTime,
			x.file_name FileName,
			x.file_offset FileOffset
		FROM xe x
		WHERE(
			@minEventTime IS NULL OR x.event_data.value('(event/@timestamp)[1]', 'DATETIME2(7)') > @minEventTime
		)
	)
	SELECT
		cteEvents.EventTime,
		cteEvents.EventName,
		cteEvents.DatabaseName,
		cteEvents.ObjectName,
		cteEvents.Statement,
		cteEvents.LineNumber,
		cteEvents.Offset,
		cteEvents.OffsetEnd,
		cteEvents.Duration,
		cteEvents.CpuTime,
		cteEvents.LogicalReads,
		cteEvents.PhysicalReads,
		cteEvents.Writes,
		cteEvents.AffectedRowsCount,
		cteEvents.ClientHostname,
		cteEvents.ClientAppName,
		cteEvents.ServerPrincipalName,
		cteEvents.SessionId,
		cteEvents.SqlText,
		cteEvents.showPlanXML,
		cteEvents.PlanHandle,
		cteEvents.TaskTime,
		cteEvents.FileName,
		cteEvents.FileOffset
	FROM cteEvents
);




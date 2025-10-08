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
CREATE OR ALTER FUNCTION [util].[xeGetDebug](@minEventTime DATETIME2(7))
RETURNS TABLE
AS
RETURN (
	WITH xe_data AS (
		SELECT
			CAST(event_data AS XML) event_data,
			file_name,
			file_offset
		FROM sys.fn_xe_file_target_read_file('utilsBatchesDebug*.xel', NULL, NULL, NULL)
	)
	SELECT
		xe_data.event_data.value('(event/@timestamp)[1]', 'DATETIME2(7)') EventTime,
		xe_data.event_data.value('(event/@name)[1]', 'NVARCHAR(128)') EventName,
		xe_data.event_data.value('(event/action[@name="database_name"]/value)[1]', 'NVARCHAR(128)') DatabaseName,
		xe_data.event_data.value('(event/data[@name="object_name"]/value)[1]', 'NVARCHAR(128)') ObjectName,
		COALESCE(
			xe_data.event_data.value('(event/data[@name="statement"]/value)[1]', 'NVARCHAR(MAX)'),
			xe_data.event_data.value('(event/data[@name="batch_text"]/value)[1]', 'NVARCHAR(MAX)')
		) Statement,
		xe_data.event_data.value('(event/data[@name="duration"]/value)[1]', 'BIGINT') Duration,
		xe_data.event_data.value('(event/data[@name="cpu_time"]/value)[1]', 'BIGINT') CpuTime,
		xe_data.event_data.value('(event/data[@name="logical_reads"]/value)[1]', 'BIGINT') LogicalReads,
		xe_data.event_data.value('(event/data[@name="physical_reads"]/value)[1]', 'BIGINT') PhysicalReads,
		xe_data.event_data.value('(event/data[@name="writes"]/value)[1]', 'BIGINT') Writes,
		xe_data.event_data.value('(event/data[@name="row_count"]/value)[1]', 'BIGINT') AffectedRowsCount,
		xe_data.event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'NVARCHAR(128)') ClientHostname,
		xe_data.event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'NVARCHAR(128)') ClientAppName,
		xe_data.event_data.value('(event/action[@name="server_principal_name"]/value)[1]', 'NVARCHAR(128)') ServerPrincipalName,
		xe_data.event_data.value('(event/action[@name="session_id"]/value)[1]', 'INT') SessionId,
		xe_data.event_data.value('(event/action[@name="sql_text"]/value)[1]', 'NVARCHAR(MAX)') SqlText,
		xe_data.event_data.value('(event/action[@name="plan_handle"]/value)[1]', 'VARBINARY(64)') PlanHandle,
		xe_data.event_data.value('(event/action[@name="task_time"]/value)[1]', 'BIGINT') TaskTime,
		xe_data.file_name FileName,
		xe_data.file_offset FileOffset
	FROM xe_data
	WHERE (@minEventTime IS NULL OR xe_data.event_data.value('(event/@timestamp)[1]', 'DATETIME2(7)') > @minEventTime)
);
GO

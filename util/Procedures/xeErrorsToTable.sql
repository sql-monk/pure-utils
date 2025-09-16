/*
# Description
Процедура для перенесення даних про помилки з Extended Events до таблиці util.xeErrorLog.
Читає дані з системних сесій XE та зберігає їх у структурованому вигляді для подальшого аналізу.

# Parameters
Без параметрів

# Returns
Нічого не повертає. Вставляє записи про помилки в таблицю util.xeErrorLog

# Usage
-- Перенести нові помилки з XE до таблиці
EXEC util.xeErrorsToTable;

-- Можна викликати по розкладу для регулярного збору помилок
*/
CREATE PROCEDURE util.xeErrorsToTable
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	--DECLARE @LastProcessedFileName NVARCHAR(260) = NULL;
	--DECLARE @LastProcessedFileOffset BIGINT;
	DECLARE @LastProcessedTimestamp DATETIME2(7);

	-- Get the last processed position
	SELECT @LastProcessedTimestamp = MAX(EventTime)FROM util.xeErrorLog;



	BEGIN TRY;
		WITH xe_data AS (SELECT CAST(event_data AS XML) event_data, file_name, file_offset FROM sys.fn_xe_file_target_read_file(
																																														'utilsErrors*.xel', NULL, NULL, NULL
																																														)
		)
		INSERT INTO util.xeErrorLog(EventTime,
			ErrorNumber,
			Severity,
			State,
			Message,
			DatabaseName,
			ClientHostname,
			ClientAppName,
			ServerPrincipalName,
			SqlText,
			TsqlFrame,
			TsqlStack,
			FileName,
			FileOffset)
		SELECT
			xe_data.event_data.value('(event/@timestamp)[1]', 'DATETIME2(7)') EventTime,
			xe_data.event_data.value('(event/data[@name="error_number"]/value)[1]', 'INT') ErrorNumber,
			xe_data.event_data.value('(event/data[@name="severity"]/value)[1]', 'INT') Severity,
			xe_data.event_data.value('(event/data[@name="state"]/value)[1]', 'INT') State,
			xe_data.event_data.value('(event/data[@name="message"]/value)[1]', 'NVARCHAR(4000)') Message,
			xe_data.event_data.value('(event/action[@name="database_name"]/value)[1]', 'NVARCHAR(128)') DatabaseName,
			xe_data.event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'NVARCHAR(128)') ClientHostname,
			xe_data.event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'NVARCHAR(128)') ClientAppName,
			xe_data.event_data.value('(event/action[@name="server_principal_name"]/value)[1]', 'NVARCHAR(128)') ServerPrincipalName,
			xe_data.event_data.value('(event/action[@name="sql_text"]/value)[1]', 'NVARCHAR(MAX)') SqlText,
			xe_data.event_data.value('(event/action[@name="tsql_frame"]/value)[1]', 'NVARCHAR(MAX)') TsqlFrame,
			xe_data.event_data.value('(event/action[@name="tsql_stack"]/value)[1]', 'NVARCHAR(MAX)') TsqlStack,
			xe_data.file_name FileName,
			xe_data.file_offset FileOffset
		FROM xe_data
		WHERE(@LastProcessedTimestamp IS NULL OR xe_data.event_data.value('(event/@timestamp)[1]', 'DATETIME2(7)') > @LastProcessedTimestamp)
		ORDER BY EventTime;

	END TRY
	BEGIN CATCH
		-- Log the error using our error handler
		EXEC util.errorHandler;
	END CATCH;

END;
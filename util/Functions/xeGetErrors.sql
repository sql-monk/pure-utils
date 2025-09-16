/*
# Description
Таблично-значуща функція для отримання даних про помилки з Extended Events.
Читає дані з системних сесій XE та повертає їх у структурованому вигляді для аналізу.

# Parameters
@minEventTime DATETIME2(7) - мінімальний час події для фільтрації (NULL = всі події)

# Returns
TABLE - Повертає таблицю з колонками:
- EventTime DATETIME2(7) - час події
- ErrorNumber INT - номер помилки
- Severity INT - рівень серйозності
- State INT - стан помилки
- Message NVARCHAR(4000) - текст повідомлення про помилку
- DatabaseName NVARCHAR(128) - назва бази даних
- ClientHostname NVARCHAR(128) - ім'я хоста клієнта
- ClientAppName NVARCHAR(128) - назва додатку клієнта
- ServerPrincipalName NVARCHAR(128) - ім'я принципала сервера
- SqlText NVARCHAR(MAX) - SQL текст
- TsqlFrame NVARCHAR(MAX) - T-SQL фрейм
- TsqlStack NVARCHAR(MAX) - T-SQL стек
- FileName NVARCHAR(260) - ім'я файлу XE
- FileOffset BIGINT - зміщення у файлі

# Usage Examples
-- Отримати всі помилки
SELECT * FROM util.xeGetErrors(NULL);

-- Отримати помилки за останню годину
SELECT * FROM util.xeGetErrors(DATEADD(HOUR, -1, GETDATE()));

-- Отримати помилки з певного часу з деталями
SELECT EventTime, ErrorNumber, Severity, Message, DatabaseName
FROM util.xeGetErrors('2025-09-16 10:00:00')
WHERE Severity >= 16
ORDER BY EventTime DESC;

-- Аналіз найчастіших помилок
SELECT ErrorNumber, COUNT(*) as ErrorCount, MAX(EventTime) as LastOccurrence
FROM util.xeGetErrors(DATEADD(DAY, -7, GETDATE()))
GROUP BY ErrorNumber
ORDER BY ErrorCount DESC;
*/
CREATE OR ALTER FUNCTION [util].[xeGetErrors](@minEventTime DATETIME2(7))
RETURNS TABLE
AS
RETURN (
    WITH xe_data AS (
        SELECT 
            CAST(event_data AS XML) event_data, 
            file_name, 
            file_offset 
        FROM sys.fn_xe_file_target_read_file('utilsErrors*.xel', NULL, NULL, NULL)
    )
    SELECT
        xe_data.event_data.value('(event/@timestamp)[1]', 'DATETIME2(7)') AS EventTime,
        xe_data.event_data.value('(event/data[@name="error_number"]/value)[1]', 'INT') AS ErrorNumber,
        xe_data.event_data.value('(event/data[@name="severity"]/value)[1]', 'INT') AS Severity,
        xe_data.event_data.value('(event/data[@name="state"]/value)[1]', 'INT') AS State,
        xe_data.event_data.value('(event/data[@name="message"]/value)[1]', 'NVARCHAR(4000)') AS Message,
        xe_data.event_data.value('(event/action[@name="database_name"]/value)[1]', 'NVARCHAR(128)') AS DatabaseName,
        xe_data.event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'NVARCHAR(128)') AS ClientHostname,
        xe_data.event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'NVARCHAR(128)') AS ClientAppName,
        xe_data.event_data.value('(event/action[@name="server_principal_name"]/value)[1]', 'NVARCHAR(128)') AS ServerPrincipalName,
        xe_data.event_data.value('(event/action[@name="sql_text"]/value)[1]', 'NVARCHAR(MAX)') AS SqlText,
        xe_data.event_data.value('(event/action[@name="tsql_frame"]/value)[1]', 'NVARCHAR(MAX)') AS TsqlFrame,
        xe_data.event_data.value('(event/action[@name="tsql_stack"]/value)[1]', 'NVARCHAR(MAX)') AS TsqlStack,
        xe_data.file_name AS FileName,
        xe_data.file_offset AS FileOffset
    FROM xe_data
    WHERE (@minEventTime IS NULL OR xe_data.event_data.value('(event/@timestamp)[1]', 'DATETIME2(7)') > @minEventTime)
);
GO
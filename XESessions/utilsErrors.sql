/*
# Description
Створює сесію розширених подій (Extended Events) для моніторингу та захоплення помилок
високого рівня важливості. Сесія відстежує помилки з severity > 10 та зберігає їх у файл.

# Parameters
Сесія не має параметрів

# Returns
Створює сесію XE utilsErrors з конфігурацією:
- Відстежує події sqlserver.error_reported
- Фільтрує помилки з severity > 10
- Виключає специфічні помилки (17830, "Not primary hadr replica")
- Зберігає результати у файл utilsErrors
- Максимальний розмір файлу 8MB, 1 файл для ротації
- Початковий стан: OFF

# Usage
-- Запустити сесію моніторингу помилок
ALTER EVENT SESSION utilsErrors ON SERVER STATE = START;

-- Зупинити сесію
ALTER EVENT SESSION utilsErrors ON SERVER STATE = STOP;
*/
CREATE EVENT SESSION utilsErrors
ON SERVER
	ADD EVENT sqlserver.error_reported
	(ACTION(
		 sqlserver.client_app_name,
		 sqlserver.client_hostname,
		 sqlserver.database_name,
		 sqlserver.server_principal_name,
		 sqlserver.sql_text,
		 sqlserver.tsql_frame,
		 sqlserver.tsql_stack
	 )
	 WHERE(
		 package0.greater_than_int64(Severity, (10))
		 AND sqlserver.not_equal_i_sql_unicode_string(Message, N'''Not primary hadr replica''')
		 AND sqlserver.client_app_name <> N'''Sql MP Monitoring'''
		 AND error_number <> (17830)
	 )
	)
	ADD TARGET package0.event_file
	(SET filename = N'utilsErrors', max_file_size = (8), max_rollover_files = (1))
WITH(
	MAX_MEMORY = 4096KB,
	EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
	MAX_DISPATCH_LATENCY = 30 SECONDS,
	MAX_EVENT_SIZE = 0KB,
	MEMORY_PARTITION_MODE = NONE,
	TRACK_CAUSALITY = ON,
	STARTUP_STATE = OFF
);
GO


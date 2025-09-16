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
	 WHERE(severity > (10) AND message <> N'''Not primary hadr replica''')
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



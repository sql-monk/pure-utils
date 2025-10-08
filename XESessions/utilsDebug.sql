CREATE EVENT SESSION utilsBatchesDebug
ON SERVER
	ADD EVENT sqlserver.sp_statement_completed
	(SET collect_object_name = (1)
	 ACTION(
		 sqlos.task_time,
		 sqlserver.client_app_name,
		 sqlserver.client_hostname,
		 sqlserver.database_id,
		 sqlserver.database_name,
		 sqlserver.plan_handle,
		 sqlserver.server_principal_name,
		 sqlserver.session_id,
		 sqlserver.sql_text
	 )
	 WHERE(
		 sqlserver.like_i_sql_unicode_string(sqlserver.server_principal_name, N'%\_[.A-z]%[^$]')
		 AND sqlserver.like_i_sql_unicode_string(statement, N'__#debug%')
		 OR sqlserver.like_i_sql_unicode_string(object_name, N'__#debug%')
		 OR sqlserver.like_i_sql_unicode_string(sqlserver.sql_text, N'__#debug%')
	 )
	),
	ADD EVENT sqlserver.sp_statement_starting
	(SET
		 collect_object_name = (1),
		 collect_statement = (1)
	 ACTION(
		 sqlos.task_time,
		 sqlserver.client_app_name,
		 sqlserver.client_hostname,
		 sqlserver.database_id,
		 sqlserver.database_name,
		 sqlserver.plan_handle,
		 sqlserver.server_principal_name,
		 sqlserver.session_id,
		 sqlserver.sql_text
	 )
	 WHERE(
		 sqlserver.like_i_sql_unicode_string(sqlserver.server_principal_name, N'%\_[.A-z]%[^$]')
		 AND sqlserver.like_i_sql_unicode_string(statement, N'__#debug%')
		 OR sqlserver.like_i_sql_unicode_string(object_name, N'__#debug%')
		 OR sqlserver.like_i_sql_unicode_string(sqlserver.sql_text, N'__#debug%')
	 )
	),
	ADD EVENT sqlserver.sql_batch_completed
	(ACTION(
		 sqlos.task_time,
		 sqlserver.client_app_name,
		 sqlserver.client_hostname,
		 sqlserver.database_id,
		 sqlserver.database_name,
		 sqlserver.plan_handle,
		 sqlserver.server_principal_name,
		 sqlserver.session_id,
		 sqlserver.sql_text
	 )
	 WHERE(
		 sqlserver.like_i_sql_unicode_string(sqlserver.server_principal_name, N'%\_[.A-z]%[^$]')
		 AND (
			 sqlserver.like_i_sql_unicode_string(sqlserver.sql_text, N'__#debug%') OR [sqlserver].[like_i_sql_unicode_string]([batch_text], N'__#debug%')
		 )
	 )
	),
	ADD EVENT sqlserver.sql_batch_starting
	(ACTION(
		 sqlos.task_time,
		 sqlserver.client_app_name,
		 sqlserver.client_hostname,
		 sqlserver.database_id,
		 sqlserver.database_name,
		 sqlserver.plan_handle,
		 sqlserver.server_principal_name,
		 sqlserver.session_id,
		 sqlserver.sql_text
	 )
	 WHERE(
		 [sqlserver].[like_i_sql_unicode_string]([sqlserver].[server_principal_name], N'%\_[.A-z]%[^$]')
		 AND (
			 [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'__#debug%') OR [sqlserver].[like_i_sql_unicode_string]([batch_text], N'__#debug%')
		 )
	 )
	),
	ADD EVENT sqlserver.sql_statement_completed
	(SET collect_parameterized_plan_handle = (1)
	 ACTION(
		 sqlos.task_time,
		 sqlserver.client_app_name,
		 sqlserver.client_hostname,
		 sqlserver.database_id,
		 sqlserver.database_name,
		 sqlserver.plan_handle,
		 sqlserver.server_principal_name,
		 sqlserver.session_id,
		 sqlserver.sql_text
	 )
	 WHERE(
		 [sqlserver].[like_i_sql_unicode_string]([sqlserver].[server_principal_name], N'%\_[.A-z]%[^$]')
		 AND (
			 [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'__#debug%') OR [sqlserver].[like_i_sql_unicode_string]([statement], N'__#debug%')
		 )
	 )
	),
	ADD EVENT sqlserver.sql_statement_starting
	(ACTION(
		 sqlos.task_time,
		 sqlserver.client_app_name,
		 sqlserver.client_hostname,
		 sqlserver.database_id,
		 sqlserver.database_name,
		 sqlserver.plan_handle,
		 sqlserver.server_principal_name,
		 sqlserver.session_id,
		 sqlserver.sql_text
	 )
	 WHERE(
		 [sqlserver].[like_i_sql_unicode_string]([sqlserver].[server_principal_name], N'%\_[.A-z]%[^$]')
		 AND (
			 [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'__#debug%') OR [sqlserver].[like_i_sql_unicode_string]([statement], N'__#debug%')
		 )
	 )
	)
	ADD TARGET package0.event_file
	(SET FILENAME = N'Log\util\utilsBatchesDebug.xel', max_file_size = (8), MAX_ROLLOVER_FILES = (4))
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


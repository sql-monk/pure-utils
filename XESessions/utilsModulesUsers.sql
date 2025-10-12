IF (NOT EXISTS(SELECT *
FROM sys.server_event_sessions
WHERE name = 'utilsModulesUsers'))  
BEGIN
CREATE EVENT SESSION [utilsModulesUsers] ON SERVER 
ADD EVENT sqlserver.module_end(SET collect_statement=(1)
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text)
    WHERE ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[server_principal_name],N'%\_[.A-z]%[^$]') AND [object_name]<>N'xp_instance_regread')),
ADD EVENT sqlserver.module_start(SET collect_statement=(1)
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text)
    WHERE ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[server_principal_name],N'%\_[.A-z]%[^$]') AND [object_name]<>N'xp_instance_regread')),
ADD EVENT sqlserver.rpc_starting(SET collect_statement=(1)
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text)
    WHERE ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[server_principal_name],N'%\_[.A-z]%[^$]') AND [sqlserver].[not_equal_i_sql_unicode_string]([object_name],N'sp_reset_connection') AND [object_name]<>N'xp_instance_regread'))
ADD TARGET package0.event_file(SET filename=N'utilsModulesUsers.xel',max_file_size=(8),max_rollover_files=(4))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
END
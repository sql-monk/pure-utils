CREATE OR ALTER VIEW util.viewExecutionModulesUsers
AS
SELECT
	f.xeId,
	f.EventName,
	DATEADD(MINUTE,DATEDIFF(MINUTE,GETUTCDATE(),GETDATE()),f.EventTime) EventTime,
	f.hb,
	st.sqlText statmentText,
	sqltext.sqlText,
	f.StatementHash,
	f.SqlTextHash,
	f.ObjectName,
	f.LineNumber,
	f.DatabaseName,
	f.DatabaseId,
	f.SessionId,
	f.ClientHostname,
	f.ClientAppName,
	f.ServerPrincipalName,
	f.Duration,
	f.SourceDatabaseId,
	f.ObjectId,
	f.OFFSET,
	f.OffsetEnd,
	f.ObjectType,
	f.ModuleRowCount,
	f.PlanHandle,
	f.TaskTime
FROM msdb.util.executionModulesUsers(NOLOCK) f
	LEFT JOIN util.executionSqlText (NOLOCK)  st ON f.StatementHash = st.sqlHash
	LEFT JOIN util.executionSqlText (NOLOCK)  sqltext ON sqltext.sqlHash = f.SqlTextHash;
GO
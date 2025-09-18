CREATE OR ALTER VIEW util.viewExecutionModulesFaust
AS
SELECT
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
	f.Offset,
	f.OffsetEnd,
	f.ObjectType,
	f.ModuleRowCount,
	f.PlanHandle,
	f.TaskTime
FROM msdb.util.executionModulesFaust f(NOLOCK)
	LEFT JOIN util.executionSqlText st(NOLOCK)ON f.StatementHash = st.sqlHash
	LEFT JOIN util.executionSqlText sqltext(NOLOCK)ON sqltext.sqlHash = f.SqlTextHash;
GO
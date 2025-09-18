CREATE VIEW util.viewXEModulesUsers
AS
SELECT
	xeId,
	EventName,
	EventTime,
	hb,
	ObjectName,
	LineNumber,
	DatabaseName,
	DatabaseId,
	SessionId,
	ClientHostname,
	ClientAppName,
	ServerPrincipalName,
	StatementHash,
	Duration,
	SourceDatabaseId,
	ObjectId,
	Offset,
	OffsetEnd,
	ObjectType,
	ModuleRowCount,
	SqlTextHash,
	PlanHandle,
	TaskTime
FROM msdb.util.xeModulesUsers(NOLOCK);
/*
# Description
Представлення для читання даних Extended Events.

# Parameters
Представлення не має параметрів

# Returns
VIEW - набір рядків з даними

# Usage
-- Приклад використання
SELECT * FROM util.viewXEModulesSSIS;
*/
CREATE VIEW util.viewXEModulesSSIS
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
FROM msdb.util.xeModulesSSIS(NOLOCK);
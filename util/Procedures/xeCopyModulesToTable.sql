/*
# Description
Процедура для копіювання модулів з Extended Events у таблицю для подальшого аналізу та зберігання.
Читає дані з XE файлів, обробляє їх та записує в таблиці виконання модулів з відповідним скоупом.

# Parameters
@scope NVARCHAR(128) - скоуп або тип модулів для копіювання

# Usage
-- Копіювати модулі для SSIS
EXEC util.xeCopyModulesToTable 'SSIS';

-- Копіювати модулі для користувачів
EXEC util.xeCopyModulesToTable 'Users'; 
*/
CREATE OR ALTER PROCEDURE util.xeCopyModulesToTable @scope NVARCHAR(128)
AS
BEGIN
	SET TRAN ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	CREATE TABLE #xEvents (
		xeId INT NOT NULL IDENTITY(1, 1),
		EventName NVARCHAR(50) NOT NULL,
		EventTime DATETIME2(7) NOT NULL,
		hb VARBINARY(32) NOT NULL,
		ObjectName NVARCHAR(128) NOT NULL,
		LineNumber INT NULL,
		Statement NVARCHAR(MAX) NULL,
		StatementHash AS (HASHBYTES('SHA2_256', Statement))PERSISTED,
		Duration BIGINT NULL,
		SourceDatabaseId INT NULL,
		ObjectId BIGINT NULL,
		Offset INT NULL,
		OffsetEnd INT NULL,
		ObjectType NVARCHAR(10) NULL,
		ModuleRowCount BIGINT NULL,
		DatabaseName NVARCHAR(128) NULL,
		DatabaseId SMALLINT NULL,
		SessionId INT NULL,
		ClientHostname NVARCHAR(128) NULL,
		ClientAppName NVARCHAR(256) NULL,
		ServerPrincipalName NVARCHAR(128) NULL,
		SqlText NVARCHAR(MAX) NULL,
		SqlTextHash AS (HASHBYTES('SHA2_256', SqlText))PERSISTED,
		PlanHandle VARBINARY(64) NULL,
		TaskTime BIGINT NULL,
		FileName NVARCHAR(260) NOT NULL,
		FileOffset BIGINT NOT NULL
	)
	WITH (DATA_COMPRESSION = PAGE);
	
	CREATE INDEX ix_eventTime ON #xEvents(EventTime DESC)INCLUDE(FileName, FileOffset)WITH(DATA_COMPRESSION = PAGE);

	INSERT
		#xEvents
	SELECT
		EventName,
		EventTime,
		hb,
		ObjectName,
		LineNumber,
		Statement,
		Duration,
		SourceDatabaseId,
		ObjectId,
		Offset,
		OffsetEnd,
		ObjectType,
		ModuleRowCount,
		DatabaseName,
		DatabaseId,
		SessionId,
		ClientHostname,
		ClientAppName,
		ServerPrincipalName,
		SqlText,
		PlanHandle,
		TaskTime,
		FileName,
		FileOffset
	FROM util.xeReadFileModules(@scope, DEFAULT);

	INSERT
		util.executionSqlText
	SELECT
		st.SqlTextHash,
		st.sqlText
	FROM(SELECT SqlTextHash, sqlText FROM #xEvents WHERE sqlText IS NOT NULL UNION SELECT StatementHash, Statement FROM #xEvents WHERE Statement IS NOT NULL) st
	WHERE NOT EXISTS (
		SELECT * FROM util.executionSqlText t WHERE t.sqlHash = st.SqlTextHash
	);

	DELETE FROM util.xeOffsets WHERE sessionName = 'utilsModules' + @scope;
	
	INSERT
		util.xeOffsets(sessionName, LastEventTime, LastFileName, LastOffset)
	SELECT TOP(1)'utilsModules' + @scope, EventTime, FileName, FileOffset FROM #xEvents ORDER BY EventTime DESC;

	DECLARE @cmd NVARCHAR(MAX) = N'INSERT INTO util.executionModules' + @scope 	+ N'(EventName,
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
	TaskTime)
SELECT
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
FROM #xEvents xe
WHERE NOT EXISTS (SELECT * FROM util.executionModules' + @scope + ' u WHERE u.EventTime = xe.EventTime AND u.EventName = xe.EventName AND u.hb = xe.hb);';

	EXEC sys.sp_executesql @cmd;
END;
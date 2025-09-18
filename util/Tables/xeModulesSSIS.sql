/*
# Description
Таблиця для зберігання даних Extended Events.

# Parameters
Таблиця не має параметрів

# Returns
Структура таблиці для зберігання даних

# Usage
Використовується для зберігання та запиту даних
*/
CREATE TABLE util.xeModulesSSIS (
	xeId INT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
	EventName NVARCHAR(50) NOT NULL,
	EventTime DATETIME2(7) NOT NULL,
	hb VARBINARY(32) NOT NULL,
	ObjectName NVARCHAR(128) NOT NULL,
	LineNumber INT NULL,
	DatabaseName NVARCHAR(128) NULL,
	DatabaseId SMALLINT NULL,
	SessionId INT NULL,
	ClientHostname NVARCHAR(128) NULL,
	ClientAppName NVARCHAR(256) NULL,
	ServerPrincipalName NVARCHAR(128) NULL,
	StatementHash VARBINARY(32),
	Duration BIGINT NULL,
	SourceDatabaseId INT NULL,
	ObjectId BIGINT NULL,
	Offset INT NULL,
	OffsetEnd INT NULL,
	ObjectType NVARCHAR(10) NULL,
	ModuleRowCount BIGINT NULL,
	SqlTextHash VARBINARY(32),
	PlanHandle VARBINARY(64) NULL,
	TaskTime BIGINT NULL
) ON util
WITH (DATA_COMPRESSION = PAGE);

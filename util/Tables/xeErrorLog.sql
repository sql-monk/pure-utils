DROP TABLE IF EXISTS util.xeErrorLog;
CREATE TABLE util.xeErrorLog (
	id BIGINT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
	EventTime DATETIME2(7),
	ErrorNumber INT,
	Severity INT,
	State INT,
	Message NVARCHAR(4000),
	DatabaseName NVARCHAR(128),
	ClientHostname NVARCHAR(128),
	ClientAppName NVARCHAR(128),
	ServerPrincipalName NVARCHAR(128),
	SqlText NVARCHAR(MAX),
	TsqlFrame NVARCHAR(MAX),
	TsqlStack NVARCHAR(MAX),
	FileName NVARCHAR(260),
	FileOffset BIGINT
);
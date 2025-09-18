SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER FUNCTION util.xeGetLogsPath(@sessionName NVARCHAR(128) = NULL)
RETURNS NVARCHAR(260)
AS
BEGIN
	DECLARE @logspath NVARCHAR(260) = CONVERT(NVARCHAR(260), SERVERPROPERTY('ErrorLogFileName'));
	RETURN (
		SELECT CONCAT(LEFT(@logspath, LEN(@logspath) - CHARINDEX('\', REVERSE(@logspath))), '\util\') + REPLACE(@sessionName, 'utils', '') + '\'
	);
END;
GO


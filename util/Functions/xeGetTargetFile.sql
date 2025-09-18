CREATE OR ALTER FUNCTION util.xeGetTargetFile(@xeSession NVARCHAR(128))
RETURNS TABLE
AS
RETURN(
	WITH cteCurrent AS (
		SELECT
			s.name,
			CONVERT(XML, t.target_data).value('(EventFileTarget/File/@name)[1]', 'nvarchar(260)') currentFile
		FROM sys.dm_xe_sessions s
			JOIN sys.dm_xe_session_targets t ON s.address = t.event_session_address
		WHERE s.name = @xeSession AND t.target_name = N'event_file'
	)
	SELECT
		ISNULL(xo.LastEventTime, DATEADD(DAY, -7, GETDATE())) lastEventTime,
		IIF(xo.LastFileName <> s.currentFile, 0, ISNULL(xo.LastOffset, 0)) lastOffset,
		IIF(xo.LastFileName <> s.currentFile, NULL, s.currentFile)  currentFile
	FROM cteCurrent s
		LEFT JOIN util.xeOffsets xo ON xo.sessionName = s.name
);
GO




/*
# Description
Отримує інформацію про цільовий файл Extended Events сесії для відстеження останньої позиції читання.
Функція визначає поточний файл сесії та останню оброблену позицію для продовження читання з правильного місця.

# Parameters
@xeSession NVARCHAR(128) - назва Extended Events сесії

# Returns
TABLE - Повертає таблицю з колонками:
- lastEventTime DATETIME - час останньої обробленої події (по замовчуванню -7 днів від поточної дати)
- lastOffset BIGINT - останній оброблений зсув у файлі (0 якщо файл змінився)
- currentFile NVARCHAR(260) - шлях до поточного файлу сесії (NULL якщо файл змінився)

# Usage
-- Отримати інформацію про цільовий файл для сесії utilsErrors
SELECT * FROM util.xeGetTargetFile('utilsErrors');

-- Перевірити останню позицію читання для конкретної сесії
SELECT lastEventTime, lastOffset, currentFile 
FROM util.xeGetTargetFile('mySession');
*/
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




/*
# Description
Формує шлях до директорії логів Extended Events на основі розташування SQL Server error log.
Функція створює стандартизований шлях для збереження файлів XE сесій у підпапці util.

# Parameters
@sessionName NVARCHAR(128) = NULL - назва XE сесії (частина 'utils' буде видалена з назви)

# Returns
NVARCHAR(260) - повний шлях до директорії логів для відповідної сесії

# Usage
-- Отримати базовий шлях до логів
SELECT util.xeGetLogsPath(NULL);

-- Отримати шлях для конкретної сесії
SELECT util.xeGetLogsPath('utilsErrors');

-- Результат буде наприклад: C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Log\util\Errors\
*/
CREATE OR ALTER FUNCTION util.xeGetLogsPath(@sessionName NVARCHAR(128) = NULL)
RETURNS NVARCHAR(260)
AS
BEGIN
	DECLARE @logspath NVARCHAR(260) = CONVERT(NVARCHAR(260), SERVERPROPERTY('ErrorLogFileName'));
	RETURN (
		SELECT CONCAT(LEFT(@logspath, LEN(@logspath) - CHARINDEX('\', REVERSE(@logspath))), '\util\') + REPLACE(@sessionName, 'utils', '') + '\'
	);
END;
GO


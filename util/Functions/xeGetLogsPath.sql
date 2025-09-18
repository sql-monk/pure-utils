/*
# Description
Функція для роботи з Extended Events. Обробляє дані сесій XE.

# Parameters
@sessionName NVARCHAR(128 - параметр

# Returns
NVARCHAR - результат функції

# Usage
-- Приклад використання
SELECT * FROM util.xeGetLogsPath(параметри);
*/
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
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


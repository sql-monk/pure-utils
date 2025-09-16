/*
# Description
Таблиця для зберігання журналу помилок з Extended Events (XE). Використовується процедурою util.xeErrorsToTable
для перенесення структурованих даних про помилки з системних сесій XE для зручного аналізу.

# Parameters
Таблиця не має параметрів

# Returns
Структура таблиці для зберігання:
- id BIGINT IDENTITY - унікальний ідентифікатор запису
- EventTime DATETIME2(7) - точний час події
- ErrorNumber INT - номер помилки SQL Server
- Severity INT - рівень важливості помилки
- State INT - стан помилки
- Message NVARCHAR(4000) - повідомлення про помилку
- DatabaseName NVARCHAR(128) - назва бази даних
- ClientHostname NVARCHAR(128) - ім'я клієнтського хоста
- Username NVARCHAR(128) - ім'я користувача
- SessionId INT - ідентифікатор сесії

# Usage
-- Таблиця заповнюється через util.xeErrorsToTable
-- Для перегляду помилок з XE:
SELECT * FROM util.xeErrorLog ORDER BY EventTime DESC;
*/
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
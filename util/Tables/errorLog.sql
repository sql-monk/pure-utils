/*
# Description
Таблиця для зберігання журналу помилок системи. Використовується процедурою util.errorHandler
для запису детальної інформації про помилки що виникають під час виконання коду.

# Columns
- ErrorId BIGINT IDENTITY - унікальний ідентифікатор помилки
- ErrorDateTime DATETIME2(3) - дата та час виникнення помилки
- ErrorNumber INT - номер помилки SQL Server
- ErrorSeverity INT - рівень важливості помилки
- ErrorState INT - стан помилки
- ErrorProcedure NVARCHAR(128) - назва процедури де виникла помилка
- ErrorLine INT - номер рядка де виникла помилка
- ErrorLineText NVARCHAR(MAX) - текст рядка коду
- ErrorMessage NVARCHAR(MAX) - повідомлення про помилку
- ErrorAdditionalInfo NVARCHAR(MAX) - додаткова інформація
*/
DROP TABLE IF EXISTS util.ErrorLog;
CREATE TABLE util.errorLog (
    ErrorId BIGINT IDENTITY(1,1) PRIMARY KEY,
    ErrorDateTime DATETIME2(3) NOT NULL DEFAULT GETDATE(),
    ErrorNumber INT NOT NULL,
    ErrorSeverity INT NOT NULL,
    ErrorState INT NOT NULL,
    ErrorProcedure NVARCHAR(128) NULL,
    ErrorLine INT NULL,
		ErrorLineText NVARCHAR(MAX) NULL,
    ErrorMessage NVARCHAR(4000) NOT NULL,
    OriginalLogin NVARCHAR(128) NULL,
    SessionId SMALLINT NULL,
    HostName NVARCHAR(128) NULL,
    ProgramName NVARCHAR(128) NULL,
    DatabaseName NVARCHAR(128) NULL,
    UserName NVARCHAR(128) NULL,
    Attachment NVARCHAR(MAX) NULL,
    SessionInfo XML NULL
);
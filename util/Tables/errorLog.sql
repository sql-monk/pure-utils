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
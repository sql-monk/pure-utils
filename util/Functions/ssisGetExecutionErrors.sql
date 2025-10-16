/*
# Description
Повертає помилки що виникли під час виконання SSIS пакетів.
Функція допомагає аналізувати причини збоїв та проблем при виконанні пакетів.

# Parameters
@folder NVARCHAR(128) = NULL - Назва папки в SSISDB (NULL = усі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = усі проекти)
@package NVARCHAR(128) = NULL - Назва пакета (NULL = усі пакети)
@executionId BIGINT = NULL - Конкретний ідентифікатор виконання (NULL = всі виконання)
@hoursBack INT = 24 - Кількість годин назад для фільтрації (NULL = всі записи)

# Returns  
TABLE - Повертає таблицю з колонками:
- OperationMessageId BIGINT - унікальний ідентифікатор повідомлення
- ExecutionId BIGINT - ідентифікатор виконання
- FolderName NVARCHAR(128) - назва папки
- ProjectName NVARCHAR(128) - назва проекту
- PackageName NVARCHAR(260) - назва пакета
- MessageTime DATETIMEOFFSET(7) - час повідомлення
- MessageType SMALLINT - тип повідомлення (-1=Unknown, 120=Error, 110=Warning, 70=Information, 10=Pre-validate, 20=Post-validate, 30=Pre-execute, 40=Post-execute, 60=Progress, 50=StatusChange, 100=QueryCancel, 130=TaskFailed, 90=Diagnostic, 200=Custom, 140=DiagnosticEx, 400=NonDiagnostic, 80=VariableValueChanged)
- MessageSourceType SMALLINT - тип джерела (10=Entry APIs, 20=External process, 30=Package-level objects, 40=Control Flow tasks, 50=Control Flow containers, 60=Data Flow task)
- Message NVARCHAR(MAX) - текст повідомлення про помилку
- ExtendedInfoId BIGINT - ідентифікатор розширеної інформації
- PackagePath NVARCHAR(MAX) - шлях до компонента в пакеті
- ExecutionPath NVARCHAR(MAX) - шлях виконання
- ThreadId INT - ідентифікатор потоку
- MessageSourceName NVARCHAR(4000) - назва джерела повідомлення
- MessageSourceId NVARCHAR(38) - ідентифікатор джерела

# Usage
-- Отримати всі помилки за останні 24 години
SELECT * FROM util.ssisGetExecutionErrors(NULL, NULL, NULL, NULL, 24)
ORDER BY MessageTime DESC;

-- Отримати помилки для конкретного виконання
SELECT MessageTime, Message, PackagePath
FROM util.ssisGetExecutionErrors(NULL, NULL, NULL, 12345, NULL)
ORDER BY MessageTime;

-- Отримати помилки конкретного пакета
SELECT MessageTime, Message, ExecutionPath
FROM util.ssisGetExecutionErrors('ETL_Production', 'DataWarehouse', 'LoadFactSales', NULL, 168)
ORDER BY MessageTime DESC;

-- Знайти найбільш поширені помилки
SELECT LEFT(Message, 100) AS ErrorMessage, COUNT(*) AS ErrorCount
FROM util.ssisGetExecutionErrors(NULL, NULL, NULL, NULL, 168)
GROUP BY LEFT(Message, 100)
ORDER BY ErrorCount DESC;
*/
CREATE OR ALTER FUNCTION util.ssisGetExecutionErrors(
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL,
    @executionId BIGINT = NULL,
    @hoursBack INT = 24
)
RETURNS TABLE
AS
RETURN(
    SELECT 
        msg.operation_message_id OperationMessageId,
        ex.execution_id ExecutionId,
        f.name FolderName,
        proj.name ProjectName,
        ex.package_name PackageName,
        msg.message_time MessageTime,
        msg.message_type MessageType,
        msg.message_source_type MessageSourceType,
        msg.message Message,
        msg.extended_info_id ExtendedInfoId,
        msg.package_path PackagePath,
        msg.execution_path ExecutionPath,
        msg.threadID ThreadId,
        msg.message_source_name MessageSourceName,
        msg.message_source_id MessageSourceId
    FROM SSISDB.catalog.operation_messages msg (NOLOCK)
        INNER JOIN SSISDB.catalog.executions ex (NOLOCK) ON msg.operation_id = ex.execution_id
        INNER JOIN SSISDB.catalog.projects proj (NOLOCK) ON ex.project_id = proj.project_id
        INNER JOIN SSISDB.catalog.folders f (NOLOCK) ON ex.folder_id = f.folder_id
    WHERE 
        msg.message_type IN (120, 130)
        AND (@folder IS NULL OR f.name = @folder)
        AND (@project IS NULL OR proj.name = @project)
        AND (@package IS NULL OR ex.package_name = @package)
        AND (@executionId IS NULL OR ex.execution_id = @executionId)
        AND (@hoursBack IS NULL OR msg.message_time >= DATEADD(HOUR, -@hoursBack, GETDATE()))
);
GO

/*
# Description
Повертає всі повідомлення з виконання SSIS пакетів (інформаційні, попередження, помилки).
Функція надає комплексний вигляд на хід виконання пакетів для детального аналізу.

# Parameters
@folder NVARCHAR(128) = NULL - Назва папки в SSISDB (NULL = усі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = усі проекти)
@package NVARCHAR(128) = NULL - Назва пакета (NULL = усі пакети)
@executionId BIGINT = NULL - Конкретний ідентифікатор виконання (NULL = всі виконання)
@messageType SMALLINT = NULL - Тип повідомлення (120=Error, 110=Warning, 70=Information, 130=TaskFailed, NULL = всі типи)
@hoursBack INT = 24 - Кількість годин назад для фільтрації (NULL = всі записи)

# Returns  
TABLE - Повертає таблицю з колонками:
- OperationMessageId BIGINT - унікальний ідентифікатор повідомлення
- ExecutionId BIGINT - ідентифікатор виконання
- FolderName NVARCHAR(128) - назва папки
- ProjectName NVARCHAR(128) - назва проекту
- PackageName NVARCHAR(260) - назва пакета
- MessageTime DATETIMEOFFSET(7) - час повідомлення
- MessageType SMALLINT - тип повідомлення
- MessageTypeDescription NVARCHAR(20) - опис типу повідомлення
- MessageSourceType SMALLINT - тип джерела
- MessageSourceTypeDescription NVARCHAR(30) - опис типу джерела
- Message NVARCHAR(MAX) - текст повідомлення
- PackagePath NVARCHAR(MAX) - шлях до компонента в пакеті
- ExecutionPath NVARCHAR(MAX) - шлях виконання
- MessageSourceName NVARCHAR(4000) - назва джерела повідомлення
- MessageCode INT - код повідомлення
- Subcomponent NVARCHAR(MAX) - підкомпонент

# Usage
-- Отримати всі повідомлення за останні 24 години
SELECT * FROM util.ssisGetEventMessages(NULL, NULL, NULL, NULL, NULL, 24)
ORDER BY MessageTime DESC;

-- Отримати тільки помилки за останню добу
SELECT MessageTime, PackageName, Message, PackagePath
FROM util.ssisGetEventMessages(NULL, NULL, NULL, NULL, 120, 24)
ORDER BY MessageTime DESC;

-- Отримати всі повідомлення для конкретного виконання
SELECT MessageTime, MessageTypeDescription, Message, ExecutionPath
FROM util.ssisGetEventMessages(NULL, NULL, NULL, 12345, NULL, NULL)
ORDER BY MessageTime;

-- Отримати попередження для конкретного пакета
SELECT MessageTime, Message, MessageSourceName
FROM util.ssisGetEventMessages('ETL_Production', 'DataWarehouse', 'LoadFactSales', NULL, 110, 168)
ORDER BY MessageTime DESC;

-- Аналіз найчастіших повідомлень
SELECT LEFT(Message, 100) MessageText, 
       MessageTypeDescription,
       COUNT(*) MessageCount
FROM util.ssisGetEventMessages(NULL, NULL, NULL, NULL, NULL, 168)
GROUP BY LEFT(Message, 100), MessageTypeDescription
ORDER BY MessageCount DESC;
*/
CREATE OR ALTER FUNCTION util.ssisGetEventMessages(
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL,
    @executionId BIGINT = NULL,
    @messageType SMALLINT = NULL,
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
        CASE msg.message_type
            WHEN -1 THEN 'Unknown'
            WHEN 10 THEN 'Pre-validate'
            WHEN 20 THEN 'Post-validate'
            WHEN 30 THEN 'Pre-execute'
            WHEN 40 THEN 'Post-execute'
            WHEN 50 THEN 'StatusChange'
            WHEN 60 THEN 'Progress'
            WHEN 70 THEN 'Information'
            WHEN 80 THEN 'VariableValueChanged'
            WHEN 90 THEN 'Diagnostic'
            WHEN 100 THEN 'QueryCancel'
            WHEN 110 THEN 'Warning'
            WHEN 120 THEN 'Error'
            WHEN 130 THEN 'TaskFailed'
            WHEN 140 THEN 'DiagnosticEx'
            WHEN 200 THEN 'Custom'
            WHEN 400 THEN 'NonDiagnostic'
            ELSE CAST(msg.message_type AS NVARCHAR(20))
        END MessageTypeDescription,
        msg.message_source_type MessageSourceType,
        CASE msg.message_source_type
            WHEN 10 THEN 'Entry APIs'
            WHEN 20 THEN 'External process'
            WHEN 30 THEN 'Package-level objects'
            WHEN 40 THEN 'Control Flow tasks'
            WHEN 50 THEN 'Control Flow containers'
            WHEN 60 THEN 'Data Flow task'
            ELSE CAST(msg.message_source_type AS NVARCHAR(30))
        END MessageSourceTypeDescription,
        msg.message Message,
        msg.package_path PackagePath,
        msg.execution_path ExecutionPath,
        msg.message_source_name MessageSourceName,
        msg.message_code MessageCode,
        msg.subcomponent_name Subcomponent
    FROM SSISDB.catalog.operation_messages msg (NOLOCK)
        INNER JOIN SSISDB.catalog.executions ex (NOLOCK) ON msg.operation_id = ex.execution_id
        INNER JOIN SSISDB.catalog.projects proj (NOLOCK) ON ex.project_id = proj.project_id
        INNER JOIN SSISDB.catalog.folders f (NOLOCK) ON ex.folder_id = f.folder_id
    WHERE 
        (@folder IS NULL OR f.name = @folder)
        AND (@project IS NULL OR proj.name = @project)
        AND (@package IS NULL OR ex.package_name = @package)
        AND (@executionId IS NULL OR ex.execution_id = @executionId)
        AND (@messageType IS NULL OR msg.message_type = @messageType)
        AND (@hoursBack IS NULL OR msg.message_time >= DATEADD(HOUR, -@hoursBack, GETDATE()))
);
GO

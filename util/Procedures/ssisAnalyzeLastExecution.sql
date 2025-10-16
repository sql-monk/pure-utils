/*
# Description
Детальний аналіз останнього виконання SSIS пакета з помилками.
Процедура витягує всю доступну інформацію для діагностики проблем: 
помилки, попередження, параметри виконання, статистику компонентів.

# Parameters
@folder NVARCHAR(128) - Назва папки в SSISDB
@project NVARCHAR(128) - Назва проекту
@package NVARCHAR(128) - Назва пакета
@executionId BIGINT = NULL - Конкретний ID виконання (NULL = останнє виконання)

# Usage
-- Аналіз останнього виконання пакета
EXEC util.ssisAnalyzeLastExecution 'ETL_Production', 'DataWarehouse', 'LoadFactSales', NULL;

-- Аналіз конкретного виконання
EXEC util.ssisAnalyzeLastExecution 'ETL_Production', 'DataWarehouse', 'LoadFactSales', 12345;
*/
CREATE OR ALTER PROCEDURE util.ssisAnalyzeLastExecution
    @folder NVARCHAR(128),
    @project NVARCHAR(128),
    @package NVARCHAR(128),
    @executionId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @targetExecutionId BIGINT;

    -- Визначаємо execution_id для аналізу
    IF @executionId IS NULL
    BEGIN
        SELECT TOP 1 
            @targetExecutionId = ex.execution_id
        FROM SSISDB.catalog.executions ex (NOLOCK)
            INNER JOIN SSISDB.catalog.projects proj (NOLOCK) ON ex.project_id = proj.project_id
            INNER JOIN SSISDB.catalog.folders f (NOLOCK) ON ex.folder_id = f.folder_id
        WHERE 
            f.name = @folder
            AND proj.name = @project
            AND ex.package_name = @package
        ORDER BY ex.start_time DESC;
    END
    ELSE
    BEGIN
        SET @targetExecutionId = @executionId;
    END;

    IF @targetExecutionId IS NULL
    BEGIN
        PRINT 'Виконання не знайдено для вказаного пакета.';
        RETURN;
    END;

    -- 1. Загальна інформація про виконання
    PRINT '=== ЗАГАЛЬНА ІНФОРМАЦІЯ ===';
    SELECT 
        ex.execution_id ExecutionId,
        f.name FolderName,
        proj.name ProjectName,
        ex.package_name PackageName,
        CASE ex.status
            WHEN 1 THEN 'Created'
            WHEN 2 THEN 'Running'
            WHEN 3 THEN 'Canceled'
            WHEN 4 THEN 'Failed'
            WHEN 5 THEN 'Pending'
            WHEN 6 THEN 'Ended unexpectedly'
            WHEN 7 THEN 'Succeeded'
            WHEN 8 THEN 'Stopping'
            WHEN 9 THEN 'Completed'
            ELSE 'Unknown'
        END Status,
        ex.start_time StartTime,
        ex.end_time EndTime,
        DATEDIFF(SECOND, ex.start_time, ISNULL(ex.end_time, GETDATE())) DurationSeconds,
        ex.executed_as_name ExecutedBy,
        ex.server_name ServerName,
        ex.machine_name MachineName
    FROM SSISDB.catalog.executions ex (NOLOCK)
        INNER JOIN SSISDB.catalog.projects proj (NOLOCK) ON ex.project_id = proj.project_id
        INNER JOIN SSISDB.catalog.folders f (NOLOCK) ON ex.folder_id = f.folder_id
    WHERE ex.execution_id = @targetExecutionId;

    -- 2. Помилки та попередження
    PRINT '';
    PRINT '=== ПОМИЛКИ ТА ПОПЕРЕДЖЕННЯ ===';
    SELECT 
        msg.message_time MessageTime,
        CASE msg.message_type
            WHEN 120 THEN 'Error'
            WHEN 110 THEN 'Warning'
            WHEN 130 THEN 'TaskFailed'
            ELSE CAST(msg.message_type AS NVARCHAR(10))
        END MessageType,
        msg.message Message,
        msg.package_path PackagePath,
        msg.execution_path ExecutionPath,
        msg.message_source_name SourceName
    FROM SSISDB.catalog.operation_messages msg (NOLOCK)
    WHERE 
        msg.operation_id = @targetExecutionId
        AND msg.message_type IN (110, 120, 130)
    ORDER BY msg.message_time;

    -- 3. Параметри виконання
    PRINT '';
    PRINT '=== ПАРАМЕТРИ ВИКОНАННЯ ===';
    SELECT 
        param.parameter_name ParameterName,
        param.parameter_value ParameterValue,
        param.value_type ValueType,
        param.parameter_data_type DataType
    FROM SSISDB.catalog.execution_parameter_values param (NOLOCK)
    WHERE param.execution_id = @targetExecutionId
    ORDER BY param.parameter_name;

    -- 4. Статистика компонентів
    PRINT '';
    PRINT '=== СТАТИСТИКА КОМПОНЕНТІВ ===';
    SELECT 
        exs.executable_name ComponentName,
        exs.execution_result ExecutionResult,
        exs.start_time StartTime,
        exs.end_time EndTime,
        exs.execution_duration_ms DurationMs,
        exs.rows_read RowsRead,
        exs.rows_written RowsWritten,
        exs.rows_inserted RowsInserted,
        exs.rows_updated RowsUpdated,
        exs.rows_deleted RowsDeleted,
        exs.rows_error RowsError
    FROM SSISDB.catalog.executable_statistics exs (NOLOCK)
    WHERE exs.execution_id = @targetExecutionId
    ORDER BY exs.start_time;

    -- 5. Повідомлення інформаційного характеру (останні 20)
    PRINT '';
    PRINT '=== ІНФОРМАЦІЙНІ ПОВІДОМЛЕННЯ (ОСТАННІ 20) ===';
    SELECT TOP 20
        msg.message_time MessageTime,
        msg.message Message,
        msg.message_source_name SourceName
    FROM SSISDB.catalog.operation_messages msg (NOLOCK)
    WHERE 
        msg.operation_id = @targetExecutionId
        AND msg.message_type = 70
    ORDER BY msg.message_time DESC;

END;
GO

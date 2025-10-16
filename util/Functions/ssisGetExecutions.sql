/*
# Description
Повертає інформацію про останні виконання SSIS пакетів.
Функція надає детальну статистику про запуски пакетів, включаючи статус, тривалість та результати.

# Parameters
@folder NVARCHAR(128) = NULL - Назва папки в SSISDB (NULL = усі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = усі проекти)
@package NVARCHAR(128) = NULL - Назва пакета (NULL = усі пакети)
@status INT = NULL - Статус виконання (1=Created, 2=Running, 3=Canceled, 4=Failed, 5=Pending, 6=Ended unexpectedly, 7=Succeeded, 8=Stopping, 9=Completed)
@hoursBack INT = 24 - Кількість годин назад для фільтрації (NULL = всі записи)

# Returns  
TABLE - Повертає таблицю з колонками:
- ExecutionId BIGINT - унікальний ідентифікатор виконання
- FolderName NVARCHAR(128) - назва папки
- ProjectName NVARCHAR(128) - назва проекту
- PackageName NVARCHAR(260) - назва пакета
- Status INT - статус виконання
- StatusDescription NVARCHAR(20) - опис статусу
- StartTime DATETIMEOFFSET(7) - час початку виконання
- EndTime DATETIMEOFFSET(7) - час закінчення виконання
- DurationMinutes DECIMAL(18,2) - тривалість у хвилинах
- ExecutedAsUserName NVARCHAR(128) - користувач що запустив
- ServerName NVARCHAR(128) - назва сервера
- MachineName NVARCHAR(128) - назва машини
- TotalPhysicalMemoryKB BIGINT - загальна фізична пам'ять у KB
- AvailablePhysicalMemoryKB BIGINT - доступна фізична пам'ять у KB
- TotalPageFileKB BIGINT - загальний файл підкачки у KB
- AvailablePageFileKB BIGINT - доступний файл підкачки у KB

# Usage
-- Отримати всі виконання за останні 24 години
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, 24)
ORDER BY StartTime DESC;

-- Отримати невдалі виконання за останню добу
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, 4, 24)
ORDER BY StartTime DESC;

-- Отримати виконання конкретного пакета
SELECT * FROM util.ssisGetExecutions('ETL_Production', 'DataWarehouse', 'LoadFactSales', NULL, NULL)
ORDER BY StartTime DESC;

-- Отримати найдовші виконання
SELECT TOP 10 PackageName, DurationMinutes, StartTime, StatusDescription
FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, 168)
ORDER BY DurationMinutes DESC;
*/
CREATE OR ALTER FUNCTION util.ssisGetExecutions(
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL,
    @status INT = NULL,
    @hoursBack INT = 24
)
RETURNS TABLE
AS
RETURN(
    SELECT 
        ex.execution_id ExecutionId,
        f.name FolderName,
        proj.name ProjectName,
        ex.package_name PackageName,
        ex.status Status,
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
        END StatusDescription,
        ex.start_time StartTime,
        ex.end_time EndTime,
        CASE 
            WHEN ex.end_time IS NOT NULL 
            THEN CAST(DATEDIFF(SECOND, ex.start_time, ex.end_time) / 60.0 AS DECIMAL(18,2))
            ELSE NULL
        END DurationMinutes,
        ex.executed_as_name ExecutedAsUserName,
        ex.server_name ServerName,
        ex.machine_name MachineName,
        ex.total_physical_memory_kb TotalPhysicalMemoryKB,
        ex.available_physical_memory_kb AvailablePhysicalMemoryKB,
        ex.total_page_file_kb TotalPageFileKB,
        ex.available_page_file_kb AvailablePageFileKB
    FROM SSISDB.catalog.executions ex (NOLOCK)
        INNER JOIN SSISDB.catalog.projects proj (NOLOCK) ON ex.project_id = proj.project_id
        INNER JOIN SSISDB.catalog.folders f (NOLOCK) ON ex.folder_id = f.folder_id
    WHERE 
        (@folder IS NULL OR f.name = @folder)
        AND (@project IS NULL OR proj.name = @project)
        AND (@package IS NULL OR ex.package_name = @package)
        AND (@status IS NULL OR ex.status = @status)
        AND (@hoursBack IS NULL OR ex.start_time >= DATEADD(HOUR, -@hoursBack, GETDATE()))
);
GO

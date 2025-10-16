/*
# Description
Отримує інформацію про виконання SSIS пакетів з каталогу SSISDB.
Функція повертає детальну інформацію про запуски пакетів, включаючи статус, тривалість та результати.

# Parameters
@folder NVARCHAR(128) = NULL - Назва папки SSISDB (NULL = всі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = всі проекти)
@package NVARCHAR(128) = NULL - Назва пакету (NULL = всі пакети)
@status INT = NULL - Статус виконання (1=Created, 2=Running, 3=Canceled, 4=Failed, 5=Pending, 6=Ended unexpectedly, 7=Succeeded, 8=Stopping, 9=Completed)
@startTime DATETIME = NULL - Фільтр за часом початку (виконання після цієї дати)
@topN INT = NULL - Кількість останніх виконань (NULL = всі)

# Returns
TABLE - Повертає таблицю з колонками:
- ExecutionId BIGINT - ID виконання
- FolderName NVARCHAR(128) - Назва папки
- ProjectName NVARCHAR(128) - Назва проекту
- PackageName NVARCHAR(260) - Назва пакету
- Status INT - Статус виконання
- StatusDesc NVARCHAR(20) - Опис статусу
- StartTime DATETIMEOFFSET - Час початку виконання
- EndTime DATETIMEOFFSET - Час завершення виконання
- DurationSeconds BIGINT - Тривалість виконання у секундах
- DurationFormatted VARCHAR(20) - Тривалість у форматі ЧЧ:ХХ:СС
- ExecutedAsName NVARCHAR(128) - Ім'я користувача що запустив
- Use32BitRuntime BIT - Використання 32-бітного runtime
- ServerName NVARCHAR(128) - Назва сервера
- MachineName NVARCHAR(128) - Назва машини
- TotalPhysicalMemoryKB BIGINT - Загальна фізична пам'ять KB
- AvailablePhysicalMemoryKB BIGINT - Доступна фізична пам'ять KB

# Usage
-- Отримати всі виконання
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, NULL, NULL)
ORDER BY StartTime DESC;

-- Отримати останні 10 виконань
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, NULL, 10)
ORDER BY StartTime DESC;

-- Отримати невдалі виконання за останню добу
SELECT * FROM util.ssisGetExecutions(NULL, NULL, NULL, 4, DATEADD(DAY, -1, GETDATE()), NULL)
ORDER BY StartTime DESC;

-- Отримати виконання конкретного пакету
SELECT * FROM util.ssisGetExecutions('Production', 'ETL_Project', 'LoadDimensions.dtsx', NULL, NULL, 20)
ORDER BY StartTime DESC;

-- Статистика виконань по пакетах
SELECT PackageName, StatusDesc, COUNT(*) ExecutionCount, AVG(DurationSeconds) AvgDurationSec
FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, DATEADD(DAY, -7, GETDATE()), NULL)
GROUP BY PackageName, StatusDesc
ORDER BY PackageName, StatusDesc;
*/
CREATE OR ALTER FUNCTION util.ssisGetExecutions(
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL,
    @status INT = NULL,
    @startTime DATETIME = NULL,
    @topN INT = NULL
)
RETURNS TABLE
AS
RETURN(
    WITH ExecutionData AS (
        SELECT
            e.execution_id,
            f.name AS folder_name,
            p.name AS project_name,
            e.package_name,
            e.status,
            e.start_time,
            e.end_time,
            e.executed_as_name,
            e.use32bitruntime,
            e.server_name,
            e.machine_name,
            e.total_physical_memory_kb,
            e.available_physical_memory_kb,
            ROW_NUMBER() OVER (ORDER BY e.start_time DESC) AS rn
        FROM SSISDB.catalog.executions e (NOLOCK)
            INNER JOIN SSISDB.catalog.folders f (NOLOCK) ON e.folder_name = f.name
            LEFT JOIN SSISDB.catalog.projects p (NOLOCK) ON f.folder_id = p.folder_id AND e.project_name = p.name
        WHERE
            (@folder IS NULL OR e.folder_name = @folder)
            AND (@project IS NULL OR e.project_name = @project)
            AND (@package IS NULL OR e.package_name = @package)
            AND (@status IS NULL OR e.status = @status)
            AND (@startTime IS NULL OR e.start_time >= @startTime)
    )
    SELECT
        execution_id AS ExecutionId,
        folder_name AS FolderName,
        project_name AS ProjectName,
        package_name AS PackageName,
        status AS Status,
        CASE status
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
        END AS StatusDesc,
        start_time AS StartTime,
        end_time AS EndTime,
        DATEDIFF(SECOND, start_time, ISNULL(end_time, SYSDATETIMEOFFSET())) AS DurationSeconds,
        CONCAT(
            DATEDIFF(SECOND, start_time, ISNULL(end_time, SYSDATETIMEOFFSET())) / 3600, ':',
            RIGHT('0' + CAST((DATEDIFF(SECOND, start_time, ISNULL(end_time, SYSDATETIMEOFFSET())) % 3600) / 60 AS VARCHAR), 2), ':',
            RIGHT('0' + CAST(DATEDIFF(SECOND, start_time, ISNULL(end_time, SYSDATETIMEOFFSET())) % 60 AS VARCHAR), 2)
        ) AS DurationFormatted,
        executed_as_name AS ExecutedAsName,
        use32bitruntime AS Use32BitRuntime,
        server_name AS ServerName,
        machine_name AS MachineName,
        total_physical_memory_kb AS TotalPhysicalMemoryKB,
        available_physical_memory_kb AS AvailablePhysicalMemoryKB
    FROM ExecutionData
    WHERE (@topN IS NULL OR rn <= @topN)
);
GO

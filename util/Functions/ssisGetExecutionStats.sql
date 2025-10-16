/*
# Description
Повертає статистику виконання SSIS пакетів.
Агреговані дані про успішність виконань, середню тривалість та частоту запусків.

# Parameters
@folder NVARCHAR(128) = NULL - Назва папки в SSISDB (NULL = усі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = усі проекти)
@package NVARCHAR(128) = NULL - Назва пакета (NULL = усі пакети)
@daysBack INT = 30 - Кількість днів назад для аналізу

# Returns  
TABLE - Повертає таблицю з колонками:
- FolderName NVARCHAR(128) - назва папки
- ProjectName NVARCHAR(128) - назва проекту
- PackageName NVARCHAR(260) - назва пакета
- TotalExecutions INT - загальна кількість виконань
- SuccessfulExecutions INT - кількість успішних виконань
- FailedExecutions INT - кількість невдалих виконань
- CanceledExecutions INT - кількість скасованих виконань
- RunningExecutions INT - кількість виконань що зараз виконуються
- SuccessRate DECIMAL(5,2) - відсоток успішних виконань
- AvgDurationMinutes DECIMAL(18,2) - середня тривалість виконання у хвилинах
- MinDurationMinutes DECIMAL(18,2) - мінімальна тривалість виконання
- MaxDurationMinutes DECIMAL(18,2) - максимальна тривалість виконання
- LastExecutionTime DATETIMEOFFSET(7) - час останнього виконання
- LastExecutionStatus NVARCHAR(20) - статус останнього виконання
- LastSuccessfulTime DATETIMEOFFSET(7) - час останнього успішного виконання
- LastFailureTime DATETIMEOFFSET(7) - час останньої помилки

# Usage
-- Отримати статистику за останні 30 днів
SELECT * FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30)
ORDER BY FailedExecutions DESC, PackageName;

-- Знайти пакети з низьким відсотком успіху
SELECT PackageName, SuccessRate, FailedExecutions, TotalExecutions
FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30)
WHERE SuccessRate < 90
ORDER BY SuccessRate;

-- Знайти найповільніші пакети
SELECT PackageName, AvgDurationMinutes, MaxDurationMinutes
FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30)
ORDER BY AvgDurationMinutes DESC;

-- Статистика для конкретного проекту
SELECT * FROM util.ssisGetExecutionStats('ETL_Production', 'DataWarehouse', NULL, 7)
ORDER BY PackageName;
*/
CREATE OR ALTER FUNCTION util.ssisGetExecutionStats(
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL,
    @daysBack INT = 30
)
RETURNS TABLE
AS
RETURN(
    WITH ExecutionData AS (
        SELECT 
            f.name FolderName,
            proj.name ProjectName,
            ex.package_name PackageName,
            ex.status Status,
            ex.start_time StartTime,
            ex.end_time EndTime,
            CASE 
                WHEN ex.end_time IS NOT NULL 
                THEN DATEDIFF(SECOND, ex.start_time, ex.end_time) / 60.0
                ELSE NULL
            END DurationMinutes,
            ROW_NUMBER() OVER (PARTITION BY f.name, proj.name, ex.package_name ORDER BY ex.start_time DESC) rn
        FROM SSISDB.catalog.executions ex (NOLOCK)
            INNER JOIN SSISDB.catalog.projects proj (NOLOCK) ON ex.project_id = proj.project_id
            INNER JOIN SSISDB.catalog.folders f (NOLOCK) ON ex.folder_id = f.folder_id
        WHERE 
            (@folder IS NULL OR f.name = @folder)
            AND (@project IS NULL OR proj.name = @project)
            AND (@package IS NULL OR ex.package_name = @package)
            AND ex.start_time >= DATEADD(DAY, -@daysBack, GETDATE())
    )
    SELECT 
        FolderName,
        ProjectName,
        PackageName,
        COUNT(*) TotalExecutions,
        SUM(CASE WHEN Status = 7 THEN 1 ELSE 0 END) SuccessfulExecutions,
        SUM(CASE WHEN Status = 4 THEN 1 ELSE 0 END) FailedExecutions,
        SUM(CASE WHEN Status = 3 THEN 1 ELSE 0 END) CanceledExecutions,
        SUM(CASE WHEN Status = 2 THEN 1 ELSE 0 END) RunningExecutions,
        CAST(
            CASE 
                WHEN COUNT(*) > 0 
                THEN (SUM(CASE WHEN Status = 7 THEN 1 ELSE 0 END) * 100.0) / COUNT(*)
                ELSE 0 
            END AS DECIMAL(5,2)
        ) SuccessRate,
        CAST(AVG(DurationMinutes) AS DECIMAL(18,2)) AvgDurationMinutes,
        CAST(MIN(DurationMinutes) AS DECIMAL(18,2)) MinDurationMinutes,
        CAST(MAX(DurationMinutes) AS DECIMAL(18,2)) MaxDurationMinutes,
        MAX(CASE WHEN rn = 1 THEN StartTime END) LastExecutionTime,
        MAX(CASE WHEN rn = 1 THEN 
            CASE Status
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
            END
        END) LastExecutionStatus,
        MAX(CASE WHEN Status = 7 THEN StartTime END) LastSuccessfulTime,
        MAX(CASE WHEN Status = 4 THEN StartTime END) LastFailureTime
    FROM ExecutionData
    GROUP BY 
        FolderName,
        ProjectName,
        PackageName
);
GO

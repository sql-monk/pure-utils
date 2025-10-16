/*
# Description
Аналізує потоки даних у SSIS пакетах - звідки та куди переносяться дані.
Функція витягує інформацію про джерела та призначення даних з виконаних пакетів.

# Parameters
@folder NVARCHAR(128) = NULL - Назва папки в SSISDB (NULL = усі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = усі проекти)
@package NVARCHAR(128) = NULL - Назва пакета (NULL = усі пакети)
@daysBack INT = 30 - Кількість днів назад для аналізу

# Returns  
TABLE - Повертає таблицю з колонками:
- ExecutionId BIGINT - ідентифікатор виконання
- FolderName NVARCHAR(128) - назва папки
- ProjectName NVARCHAR(128) - назва проекту
- PackageName NVARCHAR(260) - назва пакета
- DataFlowTaskName NVARCHAR(4000) - назва Data Flow Task
- ComponentName NVARCHAR(4000) - назва компонента
- ComponentType NVARCHAR(20) - тип компонента (Source/Destination/Transformation)
- ExecutionTime DATETIMEOFFSET(7) - час виконання
- RowsRead BIGINT - кількість прочитаних рядків
- RowsWritten BIGINT - кількість записаних рядків
- RowsInserted BIGINT - кількість вставлених рядків
- RowsUpdated BIGINT - кількість оновлених рядків
- RowsDeleted BIGINT - кількість видалених рядків
- ExecutionDurationMs BIGINT - тривалість виконання у мілісекундах

# Usage
-- Отримати всі потоки даних за останні 30 днів
SELECT * FROM util.ssisGetDataFlows(NULL, NULL, NULL, 30)
ORDER BY ExecutionTime DESC;

-- Аналіз потоків даних для конкретного пакета
SELECT DataFlowTaskName, ComponentName, ComponentType, RowsRead, RowsWritten
FROM util.ssisGetDataFlows('ETL_Production', 'DataWarehouse', 'LoadFactSales', 7)
ORDER BY DataFlowTaskName, ExecutionTime DESC;

-- Знайти компоненти що обробили найбільше рядків
SELECT ComponentName, 
       ComponentType,
       SUM(RowsRead) TotalRowsRead,
       SUM(RowsWritten) TotalRowsWritten
FROM util.ssisGetDataFlows(NULL, NULL, NULL, 30)
GROUP BY ComponentName, ComponentType
ORDER BY TotalRowsRead DESC;

-- Побудова карти потоків даних (джерела -> призначення)
WITH Sources AS (
    SELECT DISTINCT PackageName, ComponentName
    FROM util.ssisGetDataFlows(NULL, NULL, NULL, 7)
    WHERE ComponentType = 'Source'
),
Destinations AS (
    SELECT DISTINCT PackageName, ComponentName
    FROM util.ssisGetDataFlows(NULL, NULL, NULL, 7)
    WHERE ComponentType = 'Destination'
)
SELECT s.PackageName, s.ComponentName Source, d.ComponentName Destination
FROM Sources s
    CROSS JOIN Destinations d
WHERE s.PackageName = d.PackageName;
*/
CREATE OR ALTER FUNCTION util.ssisGetDataFlows(
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL,
    @daysBack INT = 30
)
RETURNS TABLE
AS
RETURN(
    SELECT 
        ex.execution_id ExecutionId,
        f.name FolderName,
        proj.name ProjectName,
        ex.package_name PackageName,
        exs.executable_name DataFlowTaskName,
        exs.executable_name ComponentName,
        CASE 
            WHEN exs.executable_name LIKE '%Source%' OR exs.executable_name LIKE '%Extract%' THEN 'Source'
            WHEN exs.executable_name LIKE '%Destination%' OR exs.executable_name LIKE '%Load%' THEN 'Destination'
            ELSE 'Transformation'
        END ComponentType,
        ex.start_time ExecutionTime,
        exs.rows_read RowsRead,
        exs.rows_written RowsWritten,
        exs.rows_inserted RowsInserted,
        exs.rows_updated RowsUpdated,
        exs.rows_deleted RowsDeleted,
        exs.execution_duration_ms ExecutionDurationMs
    FROM SSISDB.catalog.executable_statistics exs (NOLOCK)
        INNER JOIN SSISDB.catalog.executions ex (NOLOCK) ON exs.execution_id = ex.execution_id
        INNER JOIN SSISDB.catalog.projects proj (NOLOCK) ON ex.project_id = proj.project_id
        INNER JOIN SSISDB.catalog.folders f (NOLOCK) ON ex.folder_id = f.folder_id
    WHERE 
        ex.start_time >= DATEADD(DAY, -@daysBack, GETDATE())
        AND (@folder IS NULL OR f.name = @folder)
        AND (@project IS NULL OR proj.name = @project)
        AND (@package IS NULL OR ex.package_name = @package)
);
GO

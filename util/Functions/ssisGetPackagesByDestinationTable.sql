/*
# Description
Знаходить SSIS пакети що наповнюють конкретну таблицю.
Функція аналізує статистику виконання компонентів Data Flow для визначення цільових таблиць.

# Parameters
@tableName NVARCHAR(128) = NULL - Назва таблиці для пошуку (NULL = всі таблиці)
@schemaName NVARCHAR(128) = NULL - Назва схеми (NULL = всі схеми)
@daysBack INT = 30 - Кількість днів назад для аналізу

# Returns  
TABLE - Повертає таблицю з колонками:
- FolderName NVARCHAR(128) - назва папки
- ProjectName NVARCHAR(128) - назва проекту
- PackageName NVARCHAR(260) - назва пакета
- ExecutableName NVARCHAR(4000) - назва executable компонента
- DestinationTable NVARCHAR(260) - назва цільової таблиці
- LastExecutionTime DATETIMEOFFSET(7) - час останнього виконання
- RowsInserted BIGINT - кількість вставлених рядків
- RowsUpdated BIGINT - кількість оновлених рядків
- RowsDeleted BIGINT - кількість видалених рядків
- TotalRows BIGINT - загальна кількість оброблених рядків
- ExecutionCount INT - кількість виконань

# Usage
-- Знайти всі пакети що наповнюють конкретну таблицю
SELECT * FROM util.ssisGetPackagesByDestinationTable('FactSales', 'dbo', 30);

-- Знайти всі пакети з таблицями що містять певне слово
SELECT DISTINCT FolderName, ProjectName, PackageName, DestinationTable
FROM util.ssisGetPackagesByDestinationTable(NULL, NULL, 30)
WHERE DestinationTable LIKE '%Fact%'
ORDER BY PackageName;

-- Показати статистику навантаження на таблиці
SELECT DestinationTable, 
       COUNT(DISTINCT PackageName) PackageCount,
       SUM(TotalRows) TotalRowsProcessed,
       MAX(LastExecutionTime) LastLoad
FROM util.ssisGetPackagesByDestinationTable(NULL, NULL, 30)
GROUP BY DestinationTable
ORDER BY TotalRowsProcessed DESC;
*/
CREATE OR ALTER FUNCTION util.ssisGetPackagesByDestinationTable(
    @tableName NVARCHAR(128) = NULL,
    @schemaName NVARCHAR(128) = NULL,
    @daysBack INT = 30
)
RETURNS TABLE
AS
RETURN(
    SELECT 
        f.name FolderName,
        proj.name ProjectName,
        ex.package_name PackageName,
        exs.executable_name ExecutableName,
        CASE 
            WHEN CHARINDEX('.', exs.executable_name) > 0 
            THEN SUBSTRING(exs.executable_name, CHARINDEX('.', exs.executable_name) + 1, LEN(exs.executable_name))
            ELSE exs.executable_name
        END DestinationTable,
        ex.start_time LastExecutionTime,
        SUM(ISNULL(exs.rows_inserted, 0)) RowsInserted,
        SUM(ISNULL(exs.rows_updated, 0)) RowsUpdated,
        SUM(ISNULL(exs.rows_deleted, 0)) RowsDeleted,
        SUM(ISNULL(exs.rows_inserted, 0) + ISNULL(exs.rows_updated, 0) + ISNULL(exs.rows_deleted, 0)) TotalRows,
        COUNT(DISTINCT ex.execution_id) ExecutionCount
    FROM SSISDB.catalog.executable_statistics exs (NOLOCK)
        INNER JOIN SSISDB.catalog.executions ex (NOLOCK) ON exs.execution_id = ex.execution_id
        INNER JOIN SSISDB.catalog.projects proj (NOLOCK) ON ex.project_id = proj.project_id
        INNER JOIN SSISDB.catalog.folders f (NOLOCK) ON ex.folder_id = f.folder_id
    WHERE 
        ex.start_time >= DATEADD(DAY, -@daysBack, GETDATE())
        AND (exs.executable_name LIKE '%.%' OR exs.executable_name LIKE '%Destination%')
        AND (
            @tableName IS NULL 
            OR exs.executable_name LIKE CONCAT('%', @tableName, '%')
        )
        AND (
            @schemaName IS NULL 
            OR exs.executable_name LIKE CONCAT(@schemaName, '.', '%')
        )
    GROUP BY 
        f.name,
        proj.name,
        ex.package_name,
        exs.executable_name,
        ex.start_time
);
GO

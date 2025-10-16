/*
# Description
Знаходить SSIS пакети, які наповнюють конкретну таблицю або працюють з нею.
Функція аналізує повідомлення про виконання Data Flow компонентів для визначення
які пакети читають або записують дані в зазначену таблицю.

# Parameters
@tableName NVARCHAR(128) = NULL - Назва таблиці для пошуку (може містити шаблон з %)
@databaseName NVARCHAR(128) = NULL - Назва бази даних (NULL = всі бази)
@operationType NVARCHAR(20) = NULL - Тип операції ('Read', 'Write', NULL = всі)
@startTime DATETIME = NULL - Фільтр за часом (події після цієї дати)
@topN INT = NULL - Кількість останніх результатів (NULL = всі)

# Returns
TABLE - Повертає таблицю з колонками:
- FolderName NVARCHAR(128) - Назва папки SSISDB
- ProjectName NVARCHAR(128) - Назва проекту
- PackageName NVARCHAR(260) - Назва пакету
- ComponentName NVARCHAR(4000) - Назва компонента Data Flow
- TableName NVARCHAR(128) - Знайдена назва таблиці
- DatabaseName NVARCHAR(128) - Назва бази даних (якщо визначена)
- OperationType NVARCHAR(20) - Тип операції (Read/Write)
- LastExecutionTime DATETIMEOFFSET - Час останнього виконання
- ExecutionCount INT - Кількість виконань
- Message NVARCHAR(MAX) - Приклад повідомлення

# Usage
-- Знайти які пакети наповнюють таблицю DimCustomer
SELECT * FROM util.ssisFindTableUsage('DimCustomer', NULL, 'Write', NULL, NULL)
ORDER BY LastExecutionTime DESC;

-- Знайти які пакети читають з таблиці FactSales
SELECT * FROM util.ssisFindTableUsage('FactSales', NULL, 'Read', NULL, NULL)
ORDER BY LastExecutionTime DESC;

-- Знайти всі пакети що працюють з таблицями що починаються з Dim
SELECT * FROM util.ssisFindTableUsage('Dim%', 'DWH', NULL, DATEADD(DAY, -30, GETDATE()), NULL)
ORDER BY TableName, OperationType;

-- Топ 20 таблиць з якими працюють SSIS пакети
SELECT TableName, OperationType, COUNT(DISTINCT PackageName) AS PackageCount
FROM util.ssisFindTableUsage(NULL, NULL, NULL, DATEADD(DAY, -7, GETDATE()), NULL)
GROUP BY TableName, OperationType
ORDER BY PackageCount DESC;

-- Детальний аналіз використання конкретної таблиці
SELECT 
    PackageName,
    ComponentName,
    OperationType,
    ExecutionCount,
    LastExecutionTime
FROM util.ssisFindTableUsage('MyTable', 'MyDatabase', NULL, NULL, NULL)
ORDER BY OperationType, LastExecutionTime DESC;
*/
CREATE OR ALTER FUNCTION util.ssisFindTableUsage(
    @tableName NVARCHAR(128) = NULL,
    @databaseName NVARCHAR(128) = NULL,
    @operationType NVARCHAR(20) = NULL,
    @startTime DATETIME = NULL,
    @topN INT = NULL
)
RETURNS TABLE
AS
RETURN(
    WITH TableUsage AS (
        SELECT
            e.folder_name,
            e.project_name,
            e.package_name,
            em.subcomponent_name AS component_name,
            em.message,
            em.message_time,
            CASE
                WHEN em.message LIKE '%destination%' 
                    OR em.message LIKE '%insert%' 
                    OR em.message LIKE '%writing%'
                    OR em.subcomponent_name LIKE '%Destination%' THEN 'Write'
                WHEN em.message LIKE '%source%' 
                    OR em.message LIKE '%reading%'
                    OR em.message LIKE '%select%'
                    OR em.subcomponent_name LIKE '%Source%' THEN 'Read'
                ELSE 'Unknown'
            END AS operation_type,
            -- Витягуємо назву таблиці з повідомлення
            CASE
                -- Шаблон: [dbo].[TableName]
                WHEN em.message LIKE '%].[%]%' THEN
                    SUBSTRING(
                        em.message,
                        PATINDEX('%].[[]%', em.message) + 3,
                        CHARINDEX(']', em.message, PATINDEX('%].[[]%', em.message) + 3) - PATINDEX('%].[[]%', em.message) - 3
                    )
                -- Шаблон: dbo.TableName або database.dbo.TableName
                WHEN em.message LIKE '%.%.%' OR em.message LIKE '%..%' THEN
                    REVERSE(SUBSTRING(
                        REVERSE(SUBSTRING(em.message, 1, CHARINDEX(' ', em.message + ' '))),
                        1,
                        CHARINDEX('.', REVERSE(SUBSTRING(em.message, 1, CHARINDEX(' ', em.message + ' ')))) - 1
                    ))
                -- Інші випадки - шукаємо слова після table/into/from
                WHEN em.message LIKE '%table%' OR em.message LIKE '%into%' OR em.message LIKE '%from%' THEN
                    LTRIM(RTRIM(SUBSTRING(
                        em.message,
                        PATINDEX('%[table|into|from]%', em.message) + 5,
                        CHARINDEX(' ', em.message + ' ', PATINDEX('%[table|into|from]%', em.message) + 5) - PATINDEX('%[table|into|from]%', em.message) - 5
                    )))
                ELSE NULL
            END AS extracted_table,
            -- Витягуємо назву бази даних якщо можливо
            CASE
                WHEN em.message LIKE '%].[%].[%]%' THEN
                    SUBSTRING(
                        em.message,
                        PATINDEX('%[[]%', em.message) + 1,
                        CHARINDEX(']', em.message, PATINDEX('%[[]%', em.message) + 1) - PATINDEX('%[[]%', em.message) - 1
                    )
                ELSE NULL
            END AS extracted_database
        FROM SSISDB.catalog.event_messages em (NOLOCK)
            LEFT JOIN SSISDB.catalog.executions e (NOLOCK) ON em.operation_id = e.execution_id
        WHERE
            em.message_type IN (10, 20, 30, 40, 50, 60, 70) -- Info and Warning messages
            AND (
                em.message LIKE '%table%'
                OR em.message LIKE '%destination%'
                OR em.message LIKE '%source%'
                OR em.message LIKE '%insert%'
                OR em.message LIKE '%select%'
                OR em.message LIKE '%].[%'
            )
            AND (@startTime IS NULL OR em.message_time >= @startTime)
    ),
    FilteredUsage AS (
        SELECT
            folder_name,
            project_name,
            package_name,
            component_name,
            extracted_table AS table_name,
            extracted_database AS database_name,
            operation_type,
            message_time,
            message,
            ROW_NUMBER() OVER (
                PARTITION BY package_name, component_name, extracted_table, operation_type
                ORDER BY message_time DESC
            ) AS rn
        FROM TableUsage
        WHERE
            extracted_table IS NOT NULL
            AND (@tableName IS NULL OR extracted_table LIKE @tableName)
            AND (@databaseName IS NULL OR extracted_database = @databaseName OR extracted_database IS NULL)
            AND (@operationType IS NULL OR operation_type = @operationType)
    ),
    Aggregated AS (
        SELECT
            folder_name,
            project_name,
            package_name,
            component_name,
            table_name,
            database_name,
            operation_type,
            MAX(message_time) AS last_execution_time,
            COUNT(*) AS execution_count,
            MAX(message) AS sample_message,
            ROW_NUMBER() OVER (ORDER BY MAX(message_time) DESC) AS global_rn
        FROM FilteredUsage
        WHERE rn = 1
        GROUP BY
            folder_name,
            project_name,
            package_name,
            component_name,
            table_name,
            database_name,
            operation_type
    )
    SELECT
        folder_name AS FolderName,
        project_name AS ProjectName,
        package_name AS PackageName,
        component_name AS ComponentName,
        table_name AS TableName,
        database_name AS DatabaseName,
        operation_type AS OperationType,
        last_execution_time AS LastExecutionTime,
        execution_count AS ExecutionCount,
        sample_message AS Message
    FROM Aggregated
    WHERE (@topN IS NULL OR global_rn <= @topN)
);
GO

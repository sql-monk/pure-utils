/*
# Description
Аналізує потоки даних SSIS пакетів для визначення джерел та призначень даних.
Функція витягує інформацію про компоненти Data Flow Task, включаючи джерела, призначення та трансформації.

# Parameters
@executionId BIGINT = NULL - ID виконання для фільтрації (NULL = всі виконання)
@folder NVARCHAR(128) = NULL - Назва папки SSISDB (NULL = всі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = всі проекти)
@package NVARCHAR(128) = NULL - Назва пакету (NULL = всі пакети)
@componentType NVARCHAR(50) = NULL - Тип компонента ('Source', 'Destination', 'Transformation', NULL = всі)
@startTime DATETIME = NULL - Фільтр за часом (дані після цієї дати)

# Returns
TABLE - Повертає таблицю з колонками:
- EventMessageId BIGINT - ID повідомлення про подію
- ExecutionId BIGINT - ID виконання
- FolderName NVARCHAR(128) - Назва папки
- ProjectName NVARCHAR(128) - Назва проекту
- PackageName NVARCHAR(260) - Назва пакету
- DataFlowTaskName NVARCHAR(4000) - Назва Data Flow Task
- ComponentName NVARCHAR(4000) - Назва компонента
- ComponentType NVARCHAR(50) - Тип компонента
- MessageTime DATETIMEOFFSET - Час події
- Message NVARCHAR(MAX) - Повідомлення з деталями
- PackagePath NVARCHAR(MAX) - Шлях до компонента в пакеті
- Subcomponent NVARCHAR(4000) - Назва субкомпонента
- RowsProcessed BIGINT - Кількість оброблених рядків (якщо доступно)

# Usage
-- Отримати всі Data Flow компоненти
SELECT * FROM util.ssisGetDataflows(NULL, NULL, NULL, NULL, NULL, NULL)
ORDER BY MessageTime DESC;

-- Отримати джерела даних для конкретного пакету
SELECT DISTINCT ComponentName, Message
FROM util.ssisGetDataflows(NULL, 'Production', 'ETL_Project', 'LoadDimensions.dtsx', 'Source', NULL)
ORDER BY ComponentName;

-- Отримати призначення даних (де зберігаються дані)
SELECT DISTINCT PackageName, ComponentName, Message
FROM util.ssisGetDataflows(NULL, NULL, NULL, NULL, 'Destination', NULL)
ORDER BY PackageName, ComponentName;

-- Знайти які пакети записують в конкретну таблицю
SELECT DISTINCT FolderName, ProjectName, PackageName, ComponentName, MessageTime
FROM util.ssisGetDataflows(NULL, NULL, NULL, NULL, 'Destination', NULL)
WHERE Message LIKE '%MyTable%'
ORDER BY MessageTime DESC;

-- Статистика по Data Flow компонентах за останню добу
SELECT ComponentType, COUNT(*) AS ComponentCount, PackageName
FROM util.ssisGetDataflows(NULL, NULL, NULL, NULL, NULL, DATEADD(DAY, -1, GETDATE()))
GROUP BY ComponentType, PackageName
ORDER BY PackageName, ComponentType;
*/
CREATE OR ALTER FUNCTION util.ssisGetDataflows(
    @executionId BIGINT = NULL,
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL,
    @componentType NVARCHAR(50) = NULL,
    @startTime DATETIME = NULL
)
RETURNS TABLE
AS
RETURN(
    SELECT
        em.event_message_id AS EventMessageId,
        e.execution_id AS ExecutionId,
        e.folder_name AS FolderName,
        e.project_name AS ProjectName,
        e.package_name AS PackageName,
        em.message_source_name AS DataFlowTaskName,
        em.subcomponent_name AS ComponentName,
        CASE
            WHEN em.subcomponent_name LIKE '%Source%' 
                OR em.message LIKE '%source%component%' 
                OR em.message LIKE '%reading%data%' THEN 'Source'
            WHEN em.subcomponent_name LIKE '%Destination%' 
                OR em.message LIKE '%destination%component%' 
                OR em.message LIKE '%writing%data%' 
                OR em.message LIKE '%inserting%rows%' THEN 'Destination'
            WHEN em.subcomponent_name LIKE '%Lookup%' 
                OR em.subcomponent_name LIKE '%Merge%' 
                OR em.subcomponent_name LIKE '%Transform%' 
                OR em.subcomponent_name LIKE '%Conversion%' THEN 'Transformation'
            ELSE 'Other'
        END AS ComponentType,
        em.message_time AS MessageTime,
        em.message AS Message,
        em.package_path AS PackagePath,
        em.subcomponent_name AS Subcomponent,
        TRY_CONVERT(BIGINT, 
            CASE
                WHEN em.message LIKE '%rows%' THEN
                    SUBSTRING(
                        em.message,
                        PATINDEX('%[0-9]%', em.message),
                        PATINDEX('%[^0-9]%', SUBSTRING(em.message, PATINDEX('%[0-9]%', em.message), LEN(em.message))) - 1
                    )
                ELSE NULL
            END
        ) AS RowsProcessed
    FROM SSISDB.catalog.event_messages em (NOLOCK)
        LEFT JOIN SSISDB.catalog.executions e (NOLOCK) ON em.operation_id = e.execution_id
    WHERE
        em.message_type IN (10, 20, 30, 40, 50, 60, 70, 110) -- Information and Warning messages
        AND (
            em.event_name LIKE '%DataFlow%'
            OR em.message_source_name LIKE '%Data Flow Task%'
            OR em.subcomponent_name IS NOT NULL
            OR em.message LIKE '%component%'
            OR em.message LIKE '%source%'
            OR em.message LIKE '%destination%'
        )
        AND (@executionId IS NULL OR em.operation_id = @executionId)
        AND (@folder IS NULL OR e.folder_name = @folder)
        AND (@project IS NULL OR e.project_name = @project)
        AND (@package IS NULL OR e.package_name = @package)
        AND (@startTime IS NULL OR em.message_time >= @startTime)
        AND (
            @componentType IS NULL 
            OR (
                @componentType = 'Source' AND (
                    em.subcomponent_name LIKE '%Source%' 
                    OR em.message LIKE '%source%component%'
                    OR em.message LIKE '%reading%data%'
                )
            )
            OR (
                @componentType = 'Destination' AND (
                    em.subcomponent_name LIKE '%Destination%' 
                    OR em.message LIKE '%destination%component%'
                    OR em.message LIKE '%writing%data%'
                    OR em.message LIKE '%inserting%rows%'
                )
            )
            OR (
                @componentType = 'Transformation' AND (
                    em.subcomponent_name LIKE '%Lookup%' 
                    OR em.subcomponent_name LIKE '%Merge%'
                    OR em.subcomponent_name LIKE '%Transform%'
                    OR em.subcomponent_name LIKE '%Conversion%'
                )
            )
        )
);
GO

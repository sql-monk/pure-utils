/*
# Description
Отримує інформацію про помилки виконання SSIS пакетів з каталогу SSISDB.
Функція повертає детальну інформацію про помилки, включаючи повідомлення, джерело та час виникнення.

# Parameters
@executionId BIGINT = NULL - ID виконання для фільтрації (NULL = всі виконання)
@folder NVARCHAR(128) = NULL - Назва папки SSISDB (NULL = всі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = всі проекти)
@package NVARCHAR(128) = NULL - Назва пакету (NULL = всі пакети)
@startTime DATETIME = NULL - Фільтр за часом (помилки після цієї дати)
@topN INT = NULL - Кількість останніх помилок (NULL = всі)

# Returns
TABLE - Повертає таблицю з колонками:
- EventMessageId BIGINT - ID повідомлення про подію
- OperationId BIGINT - ID операції
- ExecutionId BIGINT - ID виконання
- FolderName NVARCHAR(128) - Назва папки
- ProjectName NVARCHAR(128) - Назва проекту
- PackageName NVARCHAR(260) - Назва пакету
- EventName NVARCHAR(1024) - Назва події
- MessageSourceName NVARCHAR(4000) - Назва джерела повідомлення
- PackagePath NVARCHAR(MAX) - Шлях до пакету/задачі
- MessageTime DATETIMEOFFSET - Час повідомлення
- MessageType SMALLINT - Тип повідомлення
- MessageTypeDesc NVARCHAR(20) - Опис типу повідомлення
- MessageSourceType SMALLINT - Тип джерела
- Message NVARCHAR(MAX) - Текст повідомлення
- ExtendedInfoId BIGINT - ID розширеної інформації
- ErrorCode INT - Код помилки
- ExecutionPath NVARCHAR(MAX) - Шлях виконання

# Usage
-- Отримати всі помилки
SELECT * FROM util.ssisGetErrors(NULL, NULL, NULL, NULL, NULL, NULL)
ORDER BY MessageTime DESC;

-- Отримати помилки за останню добу
SELECT * FROM util.ssisGetErrors(NULL, NULL, NULL, NULL, DATEADD(DAY, -1, GETDATE()), NULL)
ORDER BY MessageTime DESC;

-- Отримати помилки конкретного виконання
SELECT * FROM util.ssisGetErrors(12345, NULL, NULL, NULL, NULL, NULL)
ORDER BY MessageTime;

-- Отримати топ 50 останніх помилок конкретного пакету
SELECT * FROM util.ssisGetErrors(NULL, 'Production', 'ETL_Project', 'LoadDimensions.dtsx', NULL, 50)
ORDER BY MessageTime DESC;

-- Статистика помилок по пакетах
SELECT PackageName, COUNT(*) AS ErrorCount, MAX(MessageTime) AS LastError
FROM util.ssisGetErrors(NULL, NULL, NULL, NULL, DATEADD(DAY, -7, GETDATE()), NULL)
GROUP BY PackageName
ORDER BY ErrorCount DESC;

-- Найчастіші коди помилок
SELECT ErrorCode, COUNT(*) AS ErrorCount, MAX(Message) AS SampleMessage
FROM util.ssisGetErrors(NULL, NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()), NULL)
WHERE ErrorCode IS NOT NULL
GROUP BY ErrorCode
ORDER BY ErrorCount DESC;
*/
CREATE OR ALTER FUNCTION util.ssisGetErrors(
    @executionId BIGINT = NULL,
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL,
    @startTime DATETIME = NULL,
    @topN INT = NULL
)
RETURNS TABLE
AS
RETURN(
    WITH ErrorData AS (
        SELECT
            em.event_message_id,
            em.operation_id,
            e.execution_id,
            e.folder_name,
            e.project_name,
            e.package_name,
            em.event_name,
            em.message_source_name,
            em.package_path,
            em.message_time,
            em.message_type,
            em.message_source_type,
            em.message,
            em.extended_info_id,
            TRY_CONVERT(INT, em.event_name) AS error_code,
            em.execution_path,
            ROW_NUMBER() OVER (ORDER BY em.message_time DESC) AS rn
        FROM SSISDB.catalog.event_messages em (NOLOCK)
            LEFT JOIN SSISDB.catalog.executions e (NOLOCK) ON em.operation_id = e.execution_id
        WHERE
            em.message_type IN (120, 130) -- 120 = Error, 130 = TaskFailed
            AND (@executionId IS NULL OR em.operation_id = @executionId)
            AND (@folder IS NULL OR e.folder_name = @folder)
            AND (@project IS NULL OR e.project_name = @project)
            AND (@package IS NULL OR e.package_name = @package)
            AND (@startTime IS NULL OR em.message_time >= @startTime)
    )
    SELECT
        event_message_id AS EventMessageId,
        operation_id AS OperationId,
        execution_id AS ExecutionId,
        folder_name AS FolderName,
        project_name AS ProjectName,
        package_name AS PackageName,
        event_name AS EventName,
        message_source_name AS MessageSourceName,
        package_path AS PackagePath,
        message_time AS MessageTime,
        message_type AS MessageType,
        CASE message_type
            WHEN 120 THEN 'Error'
            WHEN 130 THEN 'TaskFailed'
            ELSE 'Other'
        END AS MessageTypeDesc,
        message_source_type AS MessageSourceType,
        message AS Message,
        extended_info_id AS ExtendedInfoId,
        error_code AS ErrorCode,
        execution_path AS ExecutionPath
    FROM ErrorData
    WHERE (@topN IS NULL OR rn <= @topN)
);
GO

/*
# Description
Демонстраційний скрипт для аналізу SSIS пакетів.
Показує практичне використання всіх створених функцій для моніторингу та аналізу SSIS.

# Scenarios covered
1. Отримання списку всіх пакетів та їх статусу
2. Витягування рядків підключення
3. Аналіз останніх виконань та помилок
4. Пошук пакетів що наповнюють конкретні таблиці
5. Відстеження потоків даних
6. Детальний аналіз конкретного виконання

# Prerequisites
Для роботи скриптів необхідно мати розгорнутий SSIS каталог (SSISDB) на SQL Server.
*/

-- ==============================================================================
-- СЦЕНАРІЙ 1: Огляд всіх SSIS пакетів в каталозі
-- ==============================================================================
PRINT '=== Список всіх SSIS пакетів ===';
SELECT 
    FolderName,
    ProjectName,
    PackageName,
    Description,
    LastDeployedTime,
    ValidationStatus
FROM util.ssisGetPackages(NULL, NULL, NULL)
ORDER BY FolderName, ProjectName, PackageName;
GO

-- ==============================================================================
-- СЦЕНАРІЙ 2: Витягування всіх рядків підключення
-- ==============================================================================
PRINT '=== Рядки підключення в SSIS пакетах ===';
SELECT 
    FolderName,
    ProjectName,
    ISNULL(PackageName, '<Project Level>') PackageName,
    ConnectionManagerName,
    ConnectionString,
    CASE WHEN IsPackageLevel = 1 THEN 'Package' ELSE 'Project' END Scope
FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
ORDER BY FolderName, ProjectName, PackageName, ConnectionManagerName;
GO

-- Знайти всі підключення до конкретного сервера
SELECT 
    ProjectName,
    ConnectionManagerName,
    ConnectionString
FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
WHERE ConnectionString LIKE '%YourServerName%';
GO

-- ==============================================================================
-- СЦЕНАРІЙ 3: Аналіз виконань за останню добу
-- ==============================================================================
PRINT '=== Виконання SSIS пакетів за останні 24 години ===';
SELECT 
    ExecutionId,
    FolderName,
    ProjectName,
    PackageName,
    StatusDescription,
    StartTime,
    EndTime,
    DurationMinutes,
    ExecutedAsUserName
FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, 24)
ORDER BY StartTime DESC;
GO

-- Знайти невдалі виконання
PRINT '=== Невдалі виконання ===';
SELECT 
    ExecutionId,
    PackageName,
    StartTime,
    EndTime,
    DurationMinutes
FROM util.ssisGetExecutions(NULL, NULL, NULL, 4, 168) -- Status 4 = Failed
ORDER BY StartTime DESC;
GO

-- ==============================================================================
-- СЦЕНАРІЙ 4: Аналіз помилок
-- ==============================================================================
PRINT '=== Помилки при виконанні SSIS пакетів ===';
SELECT 
    ExecutionId,
    PackageName,
    MessageTime,
    Message,
    PackagePath,
    MessageSourceName
FROM util.ssisGetExecutionErrors(NULL, NULL, NULL, NULL, 168)
ORDER BY MessageTime DESC;
GO

-- Найбільш поширені помилки
PRINT '=== Топ-10 найчастіших помилок ===';
SELECT TOP 10
    LEFT(Message, 100) ErrorMessage,
    COUNT(*) ErrorCount,
    MAX(MessageTime) LastOccurrence
FROM util.ssisGetExecutionErrors(NULL, NULL, NULL, NULL, 168)
GROUP BY LEFT(Message, 100)
ORDER BY ErrorCount DESC;
GO

-- ==============================================================================
-- СЦЕНАРІЙ 5: Статистика виконання пакетів
-- ==============================================================================
PRINT '=== Статистика виконання пакетів за останні 30 днів ===';
SELECT 
    FolderName,
    ProjectName,
    PackageName,
    TotalExecutions,
    SuccessfulExecutions,
    FailedExecutions,
    SuccessRate,
    AvgDurationMinutes,
    MaxDurationMinutes,
    LastExecutionTime,
    LastExecutionStatus
FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30)
ORDER BY FailedExecutions DESC, PackageName;
GO

-- Пакети з низьким відсотком успіху
PRINT '=== Пакети з низькою успішністю (< 90%) ===';
SELECT 
    PackageName,
    TotalExecutions,
    SuccessRate,
    FailedExecutions,
    LastFailureTime
FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30)
WHERE SuccessRate < 90 AND TotalExecutions > 0
ORDER BY SuccessRate;
GO

-- Найповільніші пакети
PRINT '=== Топ-10 найповільніших пакетів ===';
SELECT TOP 10
    PackageName,
    AvgDurationMinutes,
    MinDurationMinutes,
    MaxDurationMinutes,
    TotalExecutions
FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30)
WHERE AvgDurationMinutes IS NOT NULL
ORDER BY AvgDurationMinutes DESC;
GO

-- ==============================================================================
-- СЦЕНАРІЙ 6: Пошук пакетів що наповнюють таблиці
-- ==============================================================================
PRINT '=== Пакети що наповнюють таблиці (Fact/Dim) ===';
SELECT 
    PackageName,
    DestinationTable,
    SUM(TotalRows) TotalRowsProcessed,
    MAX(LastExecutionTime) LastExecution
FROM util.ssisGetPackagesByDestinationTable(NULL, NULL, 30)
WHERE DestinationTable LIKE '%Fact%' OR DestinationTable LIKE '%Dim%'
GROUP BY PackageName, DestinationTable
ORDER BY TotalRowsProcessed DESC;
GO

-- Знайти який пакет наповнює конкретну таблицю
-- (розкоментуйте та вкажіть свою таблицю)
/*
SELECT 
    PackageName,
    FolderName,
    ProjectName,
    TotalRows,
    LastExecutionTime
FROM util.ssisGetPackagesByDestinationTable('YourTableName', 'dbo', 30)
ORDER BY LastExecutionTime DESC;
GO
*/

-- ==============================================================================
-- СЦЕНАРІЙ 7: Аналіз потоків даних
-- ==============================================================================
PRINT '=== Аналіз потоків даних ===';
SELECT 
    PackageName,
    ComponentName,
    ComponentType,
    SUM(RowsRead) TotalRowsRead,
    SUM(RowsWritten) TotalRowsWritten,
    AVG(ExecutionDurationMs) AvgExecutionTimeMs
FROM util.ssisGetDataFlows(NULL, NULL, NULL, 7)
GROUP BY PackageName, ComponentName, ComponentType
ORDER BY PackageName, ComponentType, TotalRowsRead DESC;
GO

-- Знайти джерела та призначення даних для пакета
-- (розкоментуйте та вкажіть назву свого пакета)
/*
WITH Sources AS (
    SELECT DISTINCT ComponentName
    FROM util.ssisGetDataFlows(NULL, NULL, 'YourPackageName', 7)
    WHERE ComponentType = 'Source'
),
Destinations AS (
    SELECT DISTINCT ComponentName
    FROM util.ssisGetDataFlows(NULL, NULL, 'YourPackageName', 7)
    WHERE ComponentType = 'Destination'
)
SELECT 
    s.ComponentName SourceComponent,
    d.ComponentName DestinationComponent
FROM Sources s
    CROSS JOIN Destinations d;
GO
*/

-- ==============================================================================
-- СЦЕНАРІЙ 8: Детальний аналіз параметрів виконання
-- ==============================================================================
PRINT '=== Параметри останніх виконань ===';
SELECT 
    ExecutionId,
    PackageName,
    ParameterName,
    ParameterValue,
    ParameterDataType,
    ExecutionTime
FROM util.ssisGetExecutionParameters(NULL, NULL, NULL, NULL, 24)
ORDER BY ExecutionTime DESC, ParameterName;
GO

-- ==============================================================================
-- СЦЕНАРІЙ 9: Всі типи повідомлень для останніх виконань
-- ==============================================================================
PRINT '=== Повідомлення з виконань (помилки та попередження) ===';
SELECT 
    ExecutionId,
    PackageName,
    MessageTime,
    MessageTypeDescription,
    Message,
    MessageSourceName
FROM util.ssisGetEventMessages(NULL, NULL, NULL, NULL, NULL, 24)
WHERE MessageType IN (110, 120, 130) -- Warnings, Errors, TaskFailed
ORDER BY MessageTime DESC;
GO

-- ==============================================================================
-- СЦЕНАРІЙ 10: Детальний аналіз конкретного виконання
-- ==============================================================================
PRINT '=== Детальний аналіз останнього виконання пакета ===';
-- Розкоментуйте та вкажіть назви своїх об'єктів
/*
EXEC util.ssisAnalyzeLastExecution 
    @folder = 'YourFolderName',
    @project = 'YourProjectName',
    @package = 'YourPackageName',
    @executionId = NULL; -- NULL = останнє виконання
GO
*/

-- Аналіз конкретного виконання за його ID
/*
EXEC util.ssisAnalyzeLastExecution 
    @folder = 'YourFolderName',
    @project = 'YourProjectName',
    @package = 'YourPackageName',
    @executionId = 12345; -- Вкажіть конкретний ExecutionId
GO
*/

-- ==============================================================================
-- ДОДАТКОВІ КОРИСНІ ЗАПИТИ
-- ==============================================================================

-- Топ-10 пакетів за кількістю помилок
PRINT '=== Топ-10 пакетів з найбільшою кількістю помилок ===';
SELECT TOP 10
    PackageName,
    COUNT(*) ErrorCount,
    MAX(MessageTime) LastError
FROM util.ssisGetExecutionErrors(NULL, NULL, NULL, NULL, 168)
GROUP BY PackageName
ORDER BY ErrorCount DESC;
GO

-- Пакети що не виконувалися протягом останніх 7 днів
PRINT '=== Пакети без виконань за останній тиждень ===';
SELECT 
    p.FolderName,
    p.ProjectName,
    p.PackageName,
    p.LastDeployedTime
FROM util.ssisGetPackages(NULL, NULL, NULL) p
WHERE NOT EXISTS (
    SELECT 1 
    FROM util.ssisGetExecutions(p.FolderName, p.ProjectName, p.PackageName, NULL, 168)
)
ORDER BY p.LastDeployedTime DESC;
GO

-- Середній час виконання пакетів по годинах доби
PRINT '=== Середній час виконання по годинах доби ===';
SELECT 
    DATEPART(HOUR, StartTime) ExecutionHour,
    COUNT(*) ExecutionCount,
    AVG(DurationMinutes) AvgDurationMinutes,
    MAX(DurationMinutes) MaxDurationMinutes
FROM util.ssisGetExecutions(NULL, NULL, NULL, 7, 168)
GROUP BY DATEPART(HOUR, StartTime)
ORDER BY ExecutionHour;
GO

PRINT '=== Аналіз завершено ===';

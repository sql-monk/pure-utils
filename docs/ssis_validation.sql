/*
# Description
Скрипт для перевірки наявності SSISDB каталогу та його компонентів.
Виконайте цей скрипт перед використанням функцій аналізу SSIS.

# Prerequisites
SQL Server 2022 з розгорнутим SSIS каталогом
*/

-- Перевірка наявності бази даних SSISDB
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'SSISDB')
BEGIN
    PRINT 'ПОМИЛКА: База даних SSISDB не знайдена!';
    PRINT 'Для створення каталогу SSISDB виконайте наступні кроки:';
    PRINT '1. Відкрийте SQL Server Management Studio';
    PRINT '2. Підключіться до екземпляра SQL Server';
    PRINT '3. У Object Explorer розгорніть вузол сервера';
    PRINT '4. Клацніть правою кнопкою на "Integration Services Catalogs"';
    PRINT '5. Виберіть "Create Catalog..."';
    PRINT '6. Встановіть пароль для каталогу та підтвердіть створення';
END
ELSE
BEGIN
    PRINT '✓ База даних SSISDB знайдена';
    
    -- Перевірка наявності необхідних представлень
    PRINT '';
    PRINT 'Перевірка наявності системних представлень:';
    
    IF OBJECT_ID('SSISDB.catalog.folders', 'V') IS NOT NULL
        PRINT '✓ SSISDB.catalog.folders';
    ELSE
        PRINT '✗ SSISDB.catalog.folders - НЕ ЗНАЙДЕНО';
    
    IF OBJECT_ID('SSISDB.catalog.projects', 'V') IS NOT NULL
        PRINT '✓ SSISDB.catalog.projects';
    ELSE
        PRINT '✗ SSISDB.catalog.projects - НЕ ЗНАЙДЕНО';
    
    IF OBJECT_ID('SSISDB.catalog.packages', 'V') IS NOT NULL
        PRINT '✓ SSISDB.catalog.packages';
    ELSE
        PRINT '✗ SSISDB.catalog.packages - НЕ ЗНАЙДЕНО';
    
    IF OBJECT_ID('SSISDB.catalog.executions', 'V') IS NOT NULL
        PRINT '✓ SSISDB.catalog.executions';
    ELSE
        PRINT '✗ SSISDB.catalog.executions - НЕ ЗНАЙДЕНО';
    
    IF OBJECT_ID('SSISDB.catalog.operation_messages', 'V') IS NOT NULL
        PRINT '✓ SSISDB.catalog.operation_messages';
    ELSE
        PRINT '✗ SSISDB.catalog.operation_messages - НЕ ЗНАЙДЕНО';
    
    IF OBJECT_ID('SSISDB.catalog.executable_statistics', 'V') IS NOT NULL
        PRINT '✓ SSISDB.catalog.executable_statistics';
    ELSE
        PRINT '✗ SSISDB.catalog.executable_statistics - НЕ ЗНАЙДЕНО';
    
    IF OBJECT_ID('SSISDB.catalog.execution_parameter_values', 'V') IS NOT NULL
        PRINT '✓ SSISDB.catalog.execution_parameter_values';
    ELSE
        PRINT '✗ SSISDB.catalog.execution_parameter_values - НЕ ЗНАЙДЕНО';
    
    IF OBJECT_ID('SSISDB.catalog.connection_managers', 'V') IS NOT NULL
        PRINT '✓ SSISDB.catalog.connection_managers';
    ELSE
        PRINT '✗ SSISDB.catalog.connection_managers - НЕ ЗНАЙДЕНО';
    
    IF OBJECT_ID('SSISDB.catalog.object_parameters', 'V') IS NOT NULL
        PRINT '✓ SSISDB.catalog.object_parameters';
    ELSE
        PRINT '✗ SSISDB.catalog.object_parameters - НЕ ЗНАЙДЕНО';
    
    -- Статистика SSISDB
    PRINT '';
    PRINT 'Статистика SSISDB:';
    
    DECLARE @folderCount INT, @projectCount INT, @packageCount INT, @executionCount INT;
    
    SELECT @folderCount = COUNT(*) FROM SSISDB.catalog.folders;
    SELECT @projectCount = COUNT(*) FROM SSISDB.catalog.projects;
    SELECT @packageCount = COUNT(*) FROM SSISDB.catalog.packages;
    SELECT @executionCount = COUNT(*) FROM SSISDB.catalog.executions;
    
    PRINT CONCAT('Папок: ', @folderCount);
    PRINT CONCAT('Проектів: ', @projectCount);
    PRINT CONCAT('Пакетів: ', @packageCount);
    PRINT CONCAT('Виконань (всього): ', @executionCount);
    
    -- Останні виконання
    PRINT '';
    PRINT 'Останні 5 виконань:';
    SELECT TOP 5
        execution_id,
        folder_name,
        project_name,
        package_name,
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
        END status,
        start_time,
        end_time
    FROM SSISDB.catalog.executions
    ORDER BY start_time DESC;
END;
GO

-- Тестування створених функцій
PRINT '';
PRINT '==================================================';
PRINT 'Тестування функцій аналізу SSIS';
PRINT '==================================================';

-- Перевірка наявності створених функцій
IF OBJECT_ID('util.ssisGetPackages', 'IF') IS NOT NULL
    PRINT '✓ util.ssisGetPackages існує';
ELSE
    PRINT '✗ util.ssisGetPackages - НЕ ЗНАЙДЕНО';

IF OBJECT_ID('util.ssisGetConnectionStrings', 'IF') IS NOT NULL
    PRINT '✓ util.ssisGetConnectionStrings існує';
ELSE
    PRINT '✗ util.ssisGetConnectionStrings - НЕ ЗНАЙДЕНО';

IF OBJECT_ID('util.ssisGetExecutions', 'IF') IS NOT NULL
    PRINT '✓ util.ssisGetExecutions існує';
ELSE
    PRINT '✗ util.ssisGetExecutions - НЕ ЗНАЙДЕНО';

IF OBJECT_ID('util.ssisGetExecutionErrors', 'IF') IS NOT NULL
    PRINT '✓ util.ssisGetExecutionErrors існує';
ELSE
    PRINT '✗ util.ssisGetExecutionErrors - НЕ ЗНАЙДЕНО';

IF OBJECT_ID('util.ssisGetExecutionStats', 'IF') IS NOT NULL
    PRINT '✓ util.ssisGetExecutionStats існує';
ELSE
    PRINT '✗ util.ssisGetExecutionStats - НЕ ЗНАЙДЕНО';

IF OBJECT_ID('util.ssisGetPackagesByDestinationTable', 'IF') IS NOT NULL
    PRINT '✓ util.ssisGetPackagesByDestinationTable існує';
ELSE
    PRINT '✗ util.ssisGetPackagesByDestinationTable - НЕ ЗНАЙДЕНО';

IF OBJECT_ID('util.ssisGetDataFlows', 'IF') IS NOT NULL
    PRINT '✓ util.ssisGetDataFlows існує';
ELSE
    PRINT '✗ util.ssisGetDataFlows - НЕ ЗНАЙДЕНО';

IF OBJECT_ID('util.ssisGetEventMessages', 'IF') IS NOT NULL
    PRINT '✓ util.ssisGetEventMessages існує';
ELSE
    PRINT '✗ util.ssisGetEventMessages - НЕ ЗНАЙДЕНО';

IF OBJECT_ID('util.ssisGetExecutionParameters', 'IF') IS NOT NULL
    PRINT '✓ util.ssisGetExecutionParameters існує';
ELSE
    PRINT '✗ util.ssisGetExecutionParameters - НЕ ЗНАЙДЕНО';

IF OBJECT_ID('util.ssisAnalyzeLastExecution', 'P') IS NOT NULL
    PRINT '✓ util.ssisAnalyzeLastExecution існує';
ELSE
    PRINT '✗ util.ssisAnalyzeLastExecution - НЕ ЗНАЙДЕНО';

IF OBJECT_ID('util.viewSsisPackageMonitoring', 'V') IS NOT NULL
    PRINT '✓ util.viewSsisPackageMonitoring існує';
ELSE
    PRINT '✗ util.viewSsisPackageMonitoring - НЕ ЗНАЙДЕНО';

PRINT '';
PRINT 'Перевірка завершена.';
GO

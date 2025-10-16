-- =============================================
-- SSIS Analysis Utilities - Validation Script
-- =============================================
-- This script demonstrates and validates the SSIS analysis utilities
-- Run sections based on what you want to test

-- =============================================
-- Prerequisites Check
-- =============================================
PRINT '=== Checking SSISDB Catalog Availability ===';
GO

IF DB_ID('SSISDB') IS NULL
BEGIN
    PRINT 'WARNING: SSISDB catalog not found on this server.';
    PRINT 'The SSIS analysis utilities require SSISDB to be configured.';
    PRINT 'To enable SSISDB, use SSMS: Integration Services Catalogs > Enable CLR Integration';
END
ELSE
BEGIN
    PRINT 'SUCCESS: SSISDB catalog is available.';
    
    -- Check permissions
    IF HAS_PERMS_BY_NAME('SSISDB', 'DATABASE', 'CONNECT') = 1
    BEGIN
        PRINT 'SUCCESS: You have access to SSISDB catalog.';
    END
    ELSE
    BEGIN
        PRINT 'WARNING: You may not have sufficient permissions to SSISDB.';
    END
END
GO

-- =============================================
-- 1. Test ssisGetPackages
-- =============================================
PRINT '';
PRINT '=== Testing util.ssisGetPackages ===';
GO

-- Get all packages (limited to 10 for test)
SELECT TOP 10
    FolderName,
    ProjectName,
    PackageName,
    CONVERT(VARCHAR(19), LastDeployedTime, 120) AS LastDeployedTime,
    DeployedByName
FROM util.ssisGetPackages(NULL, NULL, NULL)
ORDER BY LastDeployedTime DESC;

-- Count packages by folder and project
SELECT 
    FolderName,
    ProjectName,
    COUNT(*) AS PackageCount
FROM util.ssisGetPackages(NULL, NULL, NULL)
GROUP BY FolderName, ProjectName
ORDER BY FolderName, ProjectName;
GO

-- =============================================
-- 2. Test ssisGetExecutions
-- =============================================
PRINT '';
PRINT '=== Testing util.ssisGetExecutions ===';
GO

-- Get latest 20 executions
SELECT TOP 20
    ExecutionId,
    PackageName,
    StatusDesc,
    CONVERT(VARCHAR(19), StartTime, 120) AS StartTime,
    DurationFormatted,
    ExecutedAsName
FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()), NULL)
ORDER BY StartTime DESC;

-- Execution statistics by status
SELECT 
    StatusDesc,
    COUNT(*) AS ExecutionCount,
    AVG(DurationSeconds) AS AvgDurationSec,
    MAX(DurationSeconds) AS MaxDurationSec
FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()), NULL)
GROUP BY StatusDesc
ORDER BY StatusDesc;
GO

-- =============================================
-- 3. Test ssisGetErrors
-- =============================================
PRINT '';
PRINT '=== Testing util.ssisGetErrors ===';
GO

-- Get latest 10 errors
SELECT TOP 10
    PackageName,
    CONVERT(VARCHAR(19), MessageTime, 120) AS MessageTime,
    ErrorCode,
    LEFT(Message, 100) AS MessagePreview
FROM util.ssisGetErrors(NULL, NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()), NULL)
ORDER BY MessageTime DESC;

-- Top error codes
SELECT 
    ErrorCode,
    COUNT(*) AS ErrorCount,
    LEFT(MAX(Message), 100) AS SampleMessage
FROM util.ssisGetErrors(NULL, NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()), NULL)
WHERE ErrorCode IS NOT NULL
GROUP BY ErrorCode
ORDER BY ErrorCount DESC;
GO

-- =============================================
-- 4. Test ssisGetConnectionStrings
-- =============================================
PRINT '';
PRINT '=== Testing util.ssisGetConnectionStrings ===';
GO

-- Get connection strings (top 20)
SELECT TOP 20
    ProjectName,
    PackageName,
    ParameterName,
    ParameterDataType,
    CASE 
        WHEN Sensitive = 1 THEN '*** SENSITIVE ***'
        ELSE LEFT(ParameterValue, 100)
    END AS ParameterValuePreview,
    Sensitive
FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
WHERE ParameterValue IS NOT NULL
ORDER BY ProjectName, ParameterName;
GO

-- =============================================
-- 5. Test ssisGetDataflows
-- =============================================
PRINT '';
PRINT '=== Testing util.ssisGetDataflows ===';
GO

-- Get data flow components (top 20)
SELECT TOP 20
    PackageName,
    ComponentName,
    ComponentType,
    CONVERT(VARCHAR(19), MessageTime, 120) AS MessageTime,
    LEFT(Message, 100) AS MessagePreview
FROM util.ssisGetDataflows(NULL, NULL, NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()))
ORDER BY MessageTime DESC;

-- Count by component type
SELECT 
    ComponentType,
    COUNT(*) AS ComponentCount
FROM util.ssisGetDataflows(NULL, NULL, NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()))
GROUP BY ComponentType
ORDER BY ComponentCount DESC;
GO

-- =============================================
-- 6. Test ssisFindTableUsage
-- =============================================
PRINT '';
PRINT '=== Testing util.ssisFindTableUsage ===';
GO

-- Find all table usage (top 20)
SELECT TOP 20
    PackageName,
    TableName,
    DatabaseName,
    OperationType,
    CONVERT(VARCHAR(19), LastExecutionTime, 120) AS LastExecutionTime,
    ExecutionCount
FROM util.ssisFindTableUsage(NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()), NULL)
ORDER BY LastExecutionTime DESC;

-- Top tables by usage
SELECT TOP 10
    TableName,
    OperationType,
    COUNT(DISTINCT PackageName) AS PackageCount,
    SUM(ExecutionCount) AS TotalExecutions
FROM util.ssisFindTableUsage(NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()), NULL)
GROUP BY TableName, OperationType
ORDER BY TotalExecutions DESC;
GO

-- =============================================
-- 7. Test ssisAnalyze Procedure
-- =============================================
PRINT '';
PRINT '=== Testing util.ssisAnalyze ===';
GO

-- Full analysis (output = 5 returns all result sets)
EXEC util.ssisAnalyze 
    @folder = NULL,
    @project = NULL,
    @package = NULL,
    @daysBack = 30,
    @output = 5;
GO

-- =============================================
-- 8. Test MCP Procedures
-- =============================================
PRINT '';
PRINT '=== Testing MCP Procedures ===';
GO

-- Get packages as JSON
PRINT 'Testing mcp.GetSsisPackages:';
EXEC mcp.GetSsisPackages;
GO

-- Get executions as JSON
PRINT 'Testing mcp.GetSsisExecutions:';
EXEC mcp.GetSsisExecutions @daysBack = 7, @topN = 10;
GO

-- Get errors as JSON
PRINT 'Testing mcp.GetSsisErrors:';
EXEC mcp.GetSsisErrors @daysBack = 7, @topN = 10;
GO

-- =============================================
-- 9. Comprehensive Report
-- =============================================
PRINT '';
PRINT '=== Comprehensive SSIS Environment Report ===';
GO

-- Summary
SELECT 
    'SSIS Environment Summary' AS ReportSection,
    COUNT(DISTINCT FolderName) AS FolderCount,
    COUNT(DISTINCT ProjectName) AS ProjectCount,
    COUNT(DISTINCT PackageName) AS PackageCount
FROM util.ssisGetPackages(NULL, NULL, NULL);

-- Recent Activity (Last 7 days)
SELECT 
    'Recent Activity (Last 7 Days)' AS ReportSection,
    StatusDesc,
    COUNT(*) AS ExecutionCount,
    AVG(DurationSeconds) AS AvgDurationSec,
    MAX(DurationSeconds) AS MaxDurationSec
FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, DATEADD(DAY, -7, GETDATE()), NULL)
GROUP BY StatusDesc
ORDER BY StatusDesc;

-- Top 10 Most Executed Packages
SELECT TOP 10
    'Top 10 Most Executed Packages' AS ReportSection,
    PackageName,
    COUNT(*) AS ExecutionCount,
    AVG(DurationSeconds) AS AvgDurationSec,
    SUM(CASE WHEN StatusDesc = 'Failed' THEN 1 ELSE 0 END) AS FailureCount
FROM util.ssisGetExecutions(NULL, NULL, NULL, NULL, DATEADD(DAY, -30, GETDATE()), NULL)
GROUP BY PackageName
ORDER BY ExecutionCount DESC;

-- Recent Errors
SELECT TOP 10
    'Recent Errors (Last 10)' AS ReportSection,
    PackageName,
    CONVERT(VARCHAR(19), MessageTime, 120) AS MessageTime,
    ErrorCode,
    LEFT(Message, 100) AS ErrorMessagePreview
FROM util.ssisGetErrors(NULL, NULL, NULL, NULL, DATEADD(DAY, -7, GETDATE()), 10)
ORDER BY MessageTime DESC;

GO

PRINT '';
PRINT '=== Validation Complete ===';
PRINT 'All SSIS analysis utilities have been tested.';
PRINT 'Review the results above to verify functionality.';
GO

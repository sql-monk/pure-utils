/*
# Description
Створює представлення для швидкого моніторингу статусу SSIS пакетів.
Об'єднує інформацію про останні виконання, помилки та статистику.

# Usage
SELECT * FROM util.viewSsisPackageMonitoring
ORDER BY LastFailureTime DESC, PackageName;
*/
CREATE OR ALTER VIEW util.viewSsisPackageMonitoring
AS
WITH PackageList AS (
    SELECT 
        FolderName,
        ProjectName,
        PackageName,
        LastDeployedTime
    FROM util.ssisGetPackages(NULL, NULL, NULL)
),
ExecutionStats AS (
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
        LastExecutionStatus,
        LastSuccessfulTime,
        LastFailureTime
    FROM util.ssisGetExecutionStats(NULL, NULL, NULL, 30)
),
RecentErrors AS (
    SELECT 
        PackageName,
        COUNT(*) ErrorCount,
        MAX(MessageTime) LastErrorTime
    FROM util.ssisGetExecutionErrors(NULL, NULL, NULL, NULL, 168)
    GROUP BY PackageName
)
SELECT 
    pl.FolderName,
    pl.ProjectName,
    pl.PackageName,
    pl.LastDeployedTime,
    ISNULL(es.TotalExecutions, 0) TotalExecutionsLast30Days,
    ISNULL(es.SuccessfulExecutions, 0) SuccessfulExecutions,
    ISNULL(es.FailedExecutions, 0) FailedExecutions,
    ISNULL(es.SuccessRate, 0) SuccessRate,
    es.AvgDurationMinutes,
    es.MaxDurationMinutes,
    es.LastExecutionTime,
    es.LastExecutionStatus,
    es.LastSuccessfulTime,
    es.LastFailureTime,
    ISNULL(re.ErrorCount, 0) ErrorsLast7Days,
    re.LastErrorTime,
    CASE 
        WHEN es.LastFailureTime > DATEADD(HOUR, -24, GETDATE()) THEN 'Critical'
        WHEN es.SuccessRate < 90 AND es.TotalExecutions > 0 THEN 'Warning'
        WHEN es.LastExecutionTime IS NULL THEN 'NotRunning'
        WHEN es.LastExecutionStatus = 'Succeeded' THEN 'Healthy'
        ELSE 'Unknown'
    END HealthStatus
FROM PackageList pl
    LEFT JOIN ExecutionStats es ON 
        pl.FolderName = es.FolderName 
        AND pl.ProjectName = es.ProjectName 
        AND pl.PackageName = es.PackageName
    LEFT JOIN RecentErrors re ON pl.PackageName = re.PackageName;
GO

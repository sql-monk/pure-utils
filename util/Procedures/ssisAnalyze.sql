/*
# Description
Комплексна процедура для аналізу SSIS пакетів.
Надає детальну інформацію про пакети, їх виконання, помилки та рядки підключення.
Корисна для швидкого огляду стану SSIS середовища.

# Parameters
@folder NVARCHAR(128) = NULL - Назва папки SSISDB (NULL = всі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = всі проекти)
@package NVARCHAR(128) = NULL - Назва пакету (NULL = всі пакети)
@daysBack INT = 7 - Кількість днів назад для аналізу виконань (за замовчуванням 7)
@output TINYINT = 1 - Режим виводу (1=Packages, 2=Executions, 3=Errors, 4=Connections, 5=All)

# Returns
Набори результатів в залежності від параметра @output:
- 1: Інформація про пакети
- 2: Статистика виконань
- 3: Останні помилки
- 4: Рядки підключення
- 5: Всі набори результатів

# Usage
-- Отримати інформацію про всі пакети
EXEC util.ssisAnalyze @output = 1;

-- Отримати статистику виконань за останній місяць
EXEC util.ssisAnalyze @daysBack = 30, @output = 2;

-- Отримати помилки конкретного пакету
EXEC util.ssisAnalyze @package = 'LoadDimensions.dtsx', @output = 3;

-- Отримати рядки підключення проекту
EXEC util.ssisAnalyze @project = 'ETL_Project', @output = 4;

-- Повний аналіз конкретного проекту
EXEC util.ssisAnalyze @project = 'ETL_Project', @daysBack = 30, @output = 5;
*/
CREATE OR ALTER PROCEDURE util.ssisAnalyze
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL,
    @daysBack INT = 7,
    @output TINYINT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @startTime DATETIME = DATEADD(DAY, -ABS(@daysBack), GETDATE());
    
    -- 1. Інформація про пакети
    IF @output IN (1, 5)
    BEGIN
        SELECT
            FolderName,
            ProjectName,
            PackageName,
            Description,
            CONCAT(VersionMajor, '.', VersionMinor, '.', VersionBuild) AS Version,
            DeployedByName,
            LastDeployedTime,
            CreatedTime
        FROM util.ssisGetPackages(@folder, @project, @package)
        ORDER BY FolderName, ProjectName, PackageName;
    END
    
    -- 2. Статистика виконань
    IF @output IN (2, 5)
    BEGIN
        SELECT
            PackageName,
            StatusDesc,
            COUNT(*) AS ExecutionCount,
            MIN(StartTime) AS FirstExecution,
            MAX(StartTime) AS LastExecution,
            AVG(DurationSeconds) AS AvgDurationSeconds,
            MIN(DurationSeconds) AS MinDurationSeconds,
            MAX(DurationSeconds) AS MaxDurationSeconds,
            SUM(DurationSeconds) AS TotalDurationSeconds
        FROM util.ssisGetExecutions(@folder, @project, @package, NULL, @startTime, NULL)
        GROUP BY PackageName, StatusDesc
        ORDER BY PackageName, StatusDesc;
    END
    
    -- 3. Останні помилки
    IF @output IN (3, 5)
    BEGIN
        SELECT
            PackageName,
            MessageTime,
            MessageSourceName,
            ErrorCode,
            Message,
            PackagePath
        FROM util.ssisGetErrors(NULL, @folder, @project, @package, @startTime, 50)
        ORDER BY MessageTime DESC;
    END
    
    -- 4. Рядки підключення
    IF @output IN (4, 5)
    BEGIN
        SELECT
            ProjectName,
            PackageName,
            ParameterName,
            ParameterDataType,
            ParameterValue,
            Sensitive,
            Required
        FROM util.ssisGetConnectionStrings(@folder, @project, @package)
        WHERE ParameterValue IS NOT NULL
        ORDER BY ProjectName, PackageName, ParameterName;
    END
    
    -- 5. Загальна статистика (тільки при output = 5)
    IF @output = 5
    BEGIN
        -- Загальна інформація
        SELECT
            'Summary' AS ReportType,
            COUNT(DISTINCT FolderName) AS FolderCount,
            COUNT(DISTINCT ProjectName) AS ProjectCount,
            COUNT(DISTINCT PackageName) AS PackageCount
        FROM util.ssisGetPackages(@folder, @project, @package);
        
        -- Статистика виконань по статусах
        SELECT
            'Execution Status Summary' AS ReportType,
            StatusDesc,
            COUNT(*) AS Count,
            AVG(DurationSeconds) AS AvgDurationSeconds
        FROM util.ssisGetExecutions(@folder, @project, @package, NULL, @startTime, NULL)
        GROUP BY StatusDesc
        ORDER BY StatusDesc;
        
        -- Топ помилок
        SELECT
            'Top Errors' AS ReportType,
            ErrorCode,
            COUNT(*) AS ErrorCount,
            MAX(MessageTime) AS LastOccurrence,
            MAX(Message) AS SampleMessage
        FROM util.ssisGetErrors(NULL, @folder, @project, @package, @startTime, NULL)
        WHERE ErrorCode IS NOT NULL
        GROUP BY ErrorCode
        ORDER BY ErrorCount DESC;
    END
END;
GO

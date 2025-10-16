/*
# Description
Процедура для отримання списку SSIS пакетів через MCP протокол.
Повертає валідний JSON для MCP відповіді з інформацією про пакети в SSISDB каталозі,
включаючи папки, проекти, пакети та інформацію про розгортання.

# Parameters
@folder NVARCHAR(128) = NULL - Назва папки SSISDB (NULL = всі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = всі проекти)
@package NVARCHAR(128) = NULL - Назва пакету (NULL = всі пакети)

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить інформацію про SSIS пакети

# Usage
-- Отримати всі SSIS пакети
EXEC mcp.GetSsisPackages;

-- Отримати пакети конкретного проекту
EXEC mcp.GetSsisPackages @project = 'ETL_Project';

-- Отримати конкретний пакет
EXEC mcp.GetSsisPackages @folder = 'Production', @project = 'ETL_Project', @package = 'LoadDimensions.dtsx';
*/
CREATE OR ALTER PROCEDURE mcp.GetSsisPackages
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF(LEN(TRIM(ISNULL(@folder, ''))) = 0)
    BEGIN
        SET @folder = NULL;
    END;
    
    IF(LEN(TRIM(ISNULL(@project, ''))) = 0)
    BEGIN
        SET @project = NULL;
    END;
    
    IF(LEN(TRIM(ISNULL(@package, ''))) = 0)
    BEGIN
        SET @package = NULL;
    END;
    
    DECLARE @packages NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);
    
    SELECT @packages = (
        SELECT
            FolderId,
            FolderName,
            ProjectId,
            ProjectName,
            PackageId,
            PackageName,
            Description,
            PackageFormatVersion,
            VersionMajor,
            VersionMinor,
            VersionBuild,
            VersionComments,
            ProjectDescription,
            DeployedByName,
            CONVERT(VARCHAR(23), LastDeployedTime, 126) AS LastDeployedTime,
            CONVERT(VARCHAR(23), CreatedTime, 126) AS CreatedTime,
            ObjectVersionLsn
        FROM util.ssisGetPackages(@folder, @project, @package)
        ORDER BY FolderName, ProjectName, PackageName
        FOR JSON PATH
    );
    
    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (SELECT 'text' type, ISNULL(@packages, '[]') text FOR JSON PATH);
    
    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');
    
    SELECT @result result;
END;
GO

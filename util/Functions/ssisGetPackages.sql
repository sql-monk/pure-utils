/*
# Description
Отримує список SSIS пакетів з каталогу SSISDB.
Функція повертає інформацію про всі пакети, їх проекти, папки та версії.

# Parameters
@folder NVARCHAR(128) = NULL - Назва папки SSISDB (NULL = всі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = всі проекти)
@package NVARCHAR(128) = NULL - Назва пакету (NULL = всі пакети)

# Returns
TABLE - Повертає таблицю з колонками:
- FolderId BIGINT - ID папки
- FolderName NVARCHAR(128) - Назва папки
- ProjectId BIGINT - ID проекту
- ProjectName NVARCHAR(128) - Назва проекту
- PackageId BIGINT - ID пакету
- PackageName NVARCHAR(260) - Назва пакету
- Description NVARCHAR(1024) - Опис пакету
- PackageFormatVersion INT - Версія формату пакету
- VersionMajor INT - Мажорна версія
- VersionMinor INT - Мінорна версія
- VersionBuild INT - Білд версія
- VersionComments NVARCHAR(1024) - Коментарі до версії
- ProjectDescription NVARCHAR(1024) - Опис проекту
- DeployedByName NVARCHAR(128) - Ім'я користувача що розгорнув
- LastDeployedTime DATETIMEOFFSET - Час останнього розгортання
- CreatedTime DATETIMEOFFSET - Час створення
- ObjectVersionLsn BIGINT - Версія об'єкта

# Usage
-- Отримати всі пакети
SELECT * FROM util.ssisGetPackages(NULL, NULL, NULL);

-- Отримати пакети конкретного проекту
SELECT * FROM util.ssisGetPackages(NULL, 'MyProject', NULL);

-- Отримати конкретний пакет
SELECT * FROM util.ssisGetPackages('Production', 'ETL_Project', 'LoadDimensions.dtsx');

-- Пакети з останніми розгортаннями
SELECT FolderName, ProjectName, PackageName, LastDeployedTime, DeployedByName
FROM util.ssisGetPackages(NULL, NULL, NULL)
ORDER BY LastDeployedTime DESC;
*/
CREATE OR ALTER FUNCTION util.ssisGetPackages(
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL
)
RETURNS TABLE
AS
RETURN(
    SELECT
        f.folder_id AS FolderId,
        f.name AS FolderName,
        p.project_id AS ProjectId,
        p.name AS ProjectName,
        pkg.package_id AS PackageId,
        pkg.name AS PackageName,
        pkg.description AS Description,
        pkg.package_format_version AS PackageFormatVersion,
        pkg.version_major AS VersionMajor,
        pkg.version_minor AS VersionMinor,
        pkg.version_build AS VersionBuild,
        pkg.version_comments AS VersionComments,
        p.description AS ProjectDescription,
        p.deployed_by_name AS DeployedByName,
        p.last_deployed_time AS LastDeployedTime,
        p.created_time AS CreatedTime,
        p.object_version_lsn AS ObjectVersionLsn
    FROM SSISDB.catalog.folders f (NOLOCK)
        INNER JOIN SSISDB.catalog.projects p (NOLOCK) ON f.folder_id = p.folder_id
        INNER JOIN SSISDB.catalog.packages pkg (NOLOCK) ON p.project_id = pkg.project_id
    WHERE 
        (@folder IS NULL OR f.name = @folder)
        AND (@project IS NULL OR p.name = @project)
        AND (@package IS NULL OR pkg.name = @package)
);
GO

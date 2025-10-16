/*
# Description
Повертає список усіх SSIS пакетів з каталогу SSISDB.
Функція надає базову інформацію про пакети, включаючи їх розташування, версії та дати створення.

# Parameters
@folder NVARCHAR(128) = NULL - Назва папки в SSISDB (NULL = усі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = усі проекти)
@package NVARCHAR(128) = NULL - Назва пакета (NULL = усі пакети)

# Returns  
TABLE - Повертає таблицю з колонками:
- PackageId BIGINT - унікальний ідентифікатор пакета
- FolderName NVARCHAR(128) - назва папки
- ProjectName NVARCHAR(128) - назва проекту
- PackageName NVARCHAR(260) - назва пакета
- Description NVARCHAR(1024) - опис пакета
- PackageFormatVersion INT - версія формату пакета
- VersionMajor INT - мажорна версія
- VersionMinor INT - мінорна версія
- VersionBuild INT - білд версії
- VersionComment NVARCHAR(1024) - коментар до версії
- CreatedTime DATETIMEOFFSET(7) - час створення пакета
- LastDeployedTime DATETIMEOFFSET(7) - час останнього розгортання
- ValidationStatus CHAR(1) - статус валідації (V=Valid, D=Dependencies invalid, U=Unknown)
- ProjectId BIGINT - ідентифікатор проекту

# Usage
-- Отримати всі пакети
SELECT * FROM util.ssisGetPackages(NULL, NULL, NULL);

-- Отримати пакети конкретної папки
SELECT * FROM util.ssisGetPackages('ETL_Production', NULL, NULL);

-- Отримати конкретний пакет
SELECT * FROM util.ssisGetPackages('ETL_Production', 'DataWarehouse', 'LoadFactSales');

-- Отримати всі пакети з описом
SELECT FolderName, ProjectName, PackageName, Description
FROM util.ssisGetPackages(NULL, NULL, NULL)
WHERE Description IS NOT NULL;
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
        p.package_id PackageId,
        f.name FolderName,
        proj.name ProjectName,
        p.name PackageName,
        p.description Description,
        p.package_format_version PackageFormatVersion,
        p.version_major VersionMajor,
        p.version_minor VersionMinor,
        p.version_build VersionBuild,
        p.version_comments VersionComment,
        proj.created_time CreatedTime,
        proj.last_deployed_time LastDeployedTime,
        p.validation_status ValidationStatus,
        proj.project_id ProjectId
    FROM SSISDB.catalog.packages p (NOLOCK)
        INNER JOIN SSISDB.catalog.projects proj (NOLOCK) ON p.project_id = proj.project_id
        INNER JOIN SSISDB.catalog.folders f (NOLOCK) ON proj.folder_id = f.folder_id
    WHERE 
        (@folder IS NULL OR f.name = @folder)
        AND (@project IS NULL OR proj.name = @project)
        AND (@package IS NULL OR p.name = @package)
);
GO

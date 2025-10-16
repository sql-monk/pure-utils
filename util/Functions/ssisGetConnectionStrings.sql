/*
# Description
Повертає рядки підключення з SSIS пакетів.
Функція витягує інформацію про connection managers та їх налаштування з каталогу SSISDB.

# Parameters
@folder NVARCHAR(128) = NULL - Назва папки в SSISDB (NULL = усі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = усі проекти)
@package NVARCHAR(128) = NULL - Назва пакета (NULL = усі пакети)

# Returns  
TABLE - Повертає таблицю з колонками:
- FolderName NVARCHAR(128) - назва папки
- ProjectName NVARCHAR(128) - назва проекту
- PackageName NVARCHAR(260) - назва пакета (якщо застосовно)
- ConnectionManagerName NVARCHAR(128) - назва менеджера підключення
- ConnectionString NVARCHAR(MAX) - рядок підключення
- ProtectionLevel INT - рівень захисту
- IsPackageLevel BIT - чи є підключення на рівні пакета (1) чи проекту (0)
- Description NVARCHAR(1024) - опис підключення

# Usage
-- Отримати всі рядки підключення
SELECT * FROM util.ssisGetConnectionStrings(NULL, NULL, NULL);

-- Отримати рядки підключення для конкретного проекту
SELECT * FROM util.ssisGetConnectionStrings('ETL_Production', 'DataWarehouse', NULL);

-- Знайти всі підключення до конкретного сервера
SELECT FolderName, ProjectName, PackageName, ConnectionManagerName
FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
WHERE ConnectionString LIKE '%MyServer%';

-- Отримати тільки підключення на рівні проекту
SELECT ProjectName, ConnectionManagerName, ConnectionString
FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
WHERE IsPackageLevel = 0;
*/
CREATE OR ALTER FUNCTION util.ssisGetConnectionStrings(
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL
)
RETURNS TABLE
AS
RETURN(
    SELECT 
        f.name FolderName,
        proj.name ProjectName,
        NULL PackageName,
        cm.connection_manager_name ConnectionManagerName,
        cm.connection_string ConnectionString,
        cm.protection_level ProtectionLevel,
        CAST(0 AS BIT) IsPackageLevel,
        cm.description Description
    FROM SSISDB.catalog.connection_managers cm (NOLOCK)
        INNER JOIN SSISDB.catalog.projects proj (NOLOCK) ON cm.project_id = proj.project_id
        INNER JOIN SSISDB.catalog.folders f (NOLOCK) ON proj.folder_id = f.folder_id
    WHERE 
        (@folder IS NULL OR f.name = @folder)
        AND (@project IS NULL OR proj.name = @project)
        AND @package IS NULL

    UNION ALL

    SELECT 
        f.name FolderName,
        proj.name ProjectName,
        p.name PackageName,
        opm.parameter_name ConnectionManagerName,
        opm.design_default_value ConnectionString,
        NULL ProtectionLevel,
        CAST(1 AS BIT) IsPackageLevel,
        NULL Description
    FROM SSISDB.catalog.object_parameters opm (NOLOCK)
        INNER JOIN SSISDB.catalog.packages p (NOLOCK) ON opm.object_id = p.package_id
        INNER JOIN SSISDB.catalog.projects proj (NOLOCK) ON p.project_id = proj.project_id
        INNER JOIN SSISDB.catalog.folders f (NOLOCK) ON proj.folder_id = f.folder_id
    WHERE 
        opm.object_type = 30
        AND opm.parameter_name LIKE '%.CM.%'
        AND (@folder IS NULL OR f.name = @folder)
        AND (@project IS NULL OR proj.name = @project)
        AND (@package IS NULL OR p.name = @package)
);
GO

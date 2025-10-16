/*
# Description
Витягує рядки підключення (connection strings) з параметрів та властивостей SSIS пакетів.
Функція аналізує параметри проектів та пакетів для отримання інформації про підключення до джерел даних.

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
- PackageId BIGINT - ID пакету (NULL для параметрів рівня проекту)
- PackageName NVARCHAR(260) - Назва пакету (NULL для параметрів рівня проекту)
- ParameterId BIGINT - ID параметра
- ParameterName NVARCHAR(128) - Назва параметра
- ParameterDataType NVARCHAR(128) - Тип даних параметра
- ParameterValue NVARCHAR(MAX) - Значення параметра (рядок підключення)
- Sensitive BIT - Чи є параметр чутливим (sensitive)
- Required BIT - Чи є параметр обов'язковим
- ValueSet BIT - Чи встановлено значення
- DesignDefaultValue NVARCHAR(4000) - Значення за замовчуванням з дизайну

# Usage
-- Отримати всі рядки підключення
SELECT * FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
ORDER BY FolderName, ProjectName, ParameterName;

-- Отримати рядки підключення для конкретного проекту
SELECT ParameterName, ParameterValue
FROM util.ssisGetConnectionStrings('Production', 'ETL_Project', NULL)
WHERE ParameterValue IS NOT NULL
ORDER BY ParameterName;

-- Знайти всі підключення до конкретного сервера
SELECT FolderName, ProjectName, PackageName, ParameterName, ParameterValue
FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
WHERE ParameterValue LIKE '%Server=MyServer%'
ORDER BY FolderName, ProjectName;

-- Отримати несетапні (non-sensitive) рядки підключення
SELECT ProjectName, ParameterName, ParameterValue
FROM util.ssisGetConnectionStrings(NULL, NULL, NULL)
WHERE Sensitive = 0 AND ParameterValue IS NOT NULL
ORDER BY ProjectName, ParameterName;
*/
CREATE OR ALTER FUNCTION util.ssisGetConnectionStrings(
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL
)
RETURNS TABLE
AS
RETURN(
    WITH ParametersData AS (
        SELECT
            f.folder_id,
            f.name AS folder_name,
            p.project_id,
            p.name AS project_name,
            NULL AS package_id,
            CAST(NULL AS NVARCHAR(260)) AS package_name,
            prm.parameter_id,
            prm.parameter_name,
            prm.data_type,
            prm.default_value,
            prm.sensitive,
            prm.required,
            prm.value_set,
            prm.design_default_value
        FROM SSISDB.catalog.folders f (NOLOCK)
            INNER JOIN SSISDB.catalog.projects p (NOLOCK) ON f.folder_id = p.folder_id
            INNER JOIN SSISDB.catalog.object_parameters prm (NOLOCK) ON p.project_id = prm.project_id
        WHERE
            prm.object_type = 20 -- Project parameters
            AND prm.value_type = 'V' -- Variable
            AND (
                prm.parameter_name LIKE '%Connection%'
                OR prm.parameter_name LIKE '%ConnString%'
                OR prm.parameter_name LIKE '%Server%'
                OR prm.parameter_name LIKE '%Database%'
                OR prm.parameter_name LIKE '%DataSource%'
                OR prm.data_type = 'String'
            )
            AND (@folder IS NULL OR f.name = @folder)
            AND (@project IS NULL OR p.name = @project)
        
        UNION ALL
        
        SELECT
            f.folder_id,
            f.name AS folder_name,
            p.project_id,
            p.name AS project_name,
            pkg.package_id,
            pkg.name AS package_name,
            prm.parameter_id,
            prm.parameter_name,
            prm.data_type,
            prm.default_value,
            prm.sensitive,
            prm.required,
            prm.value_set,
            prm.design_default_value
        FROM SSISDB.catalog.folders f (NOLOCK)
            INNER JOIN SSISDB.catalog.projects p (NOLOCK) ON f.folder_id = p.folder_id
            INNER JOIN SSISDB.catalog.packages pkg (NOLOCK) ON p.project_id = pkg.project_id
            INNER JOIN SSISDB.catalog.object_parameters prm (NOLOCK) ON pkg.package_id = prm.object_id
        WHERE
            prm.object_type = 30 -- Package parameters
            AND prm.value_type = 'V' -- Variable
            AND (
                prm.parameter_name LIKE '%Connection%'
                OR prm.parameter_name LIKE '%ConnString%'
                OR prm.parameter_name LIKE '%Server%'
                OR prm.parameter_name LIKE '%Database%'
                OR prm.parameter_name LIKE '%DataSource%'
                OR prm.data_type = 'String'
            )
            AND (@folder IS NULL OR f.name = @folder)
            AND (@project IS NULL OR p.name = @project)
            AND (@package IS NULL OR pkg.name = @package)
    )
    SELECT
        folder_id AS FolderId,
        folder_name AS FolderName,
        project_id AS ProjectId,
        project_name AS ProjectName,
        package_id AS PackageId,
        package_name AS PackageName,
        parameter_id AS ParameterId,
        parameter_name AS ParameterName,
        data_type AS ParameterDataType,
        CASE 
            WHEN sensitive = 1 THEN '*** SENSITIVE ***'
            ELSE default_value
        END AS ParameterValue,
        sensitive AS Sensitive,
        required AS Required,
        value_set AS ValueSet,
        design_default_value AS DesignDefaultValue
    FROM ParametersData
);
GO

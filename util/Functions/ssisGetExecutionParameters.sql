/*
# Description
Повертає параметри виконання SSIS пакетів.
Функція допомагає відстежити які параметри використовувалися при запуску пакетів.

# Parameters
@folder NVARCHAR(128) = NULL - Назва папки в SSISDB (NULL = усі папки)
@project NVARCHAR(128) = NULL - Назва проекту (NULL = усі проекти)
@package NVARCHAR(128) = NULL - Назва пакета (NULL = усі пакети)
@executionId BIGINT = NULL - Конкретний ідентифікатор виконання (NULL = всі виконання)
@hoursBack INT = 24 - Кількість годин назад для фільтрації (NULL = всі записи)

# Returns  
TABLE - Повертає таблицю з колонками:
- ExecutionId BIGINT - ідентифікатор виконання
- FolderName NVARCHAR(128) - назва папки
- ProjectName NVARCHAR(128) - назва проекту
- PackageName NVARCHAR(260) - назва пакета
- ParameterName NVARCHAR(128) - назва параметра
- ParameterValue SQL_VARIANT - значення параметра
- ParameterDataType NVARCHAR(128) - тип даних параметра
- ValueType CHAR(1) - тип значення (R=Runtime, D=Design, S=System, L=Literal)
- ObjectType SMALLINT - тип об'єкта (20=Project, 30=Package, 50=Operation)
- ExecutionTime DATETIMEOFFSET(7) - час виконання

# Usage
-- Отримати всі параметри виконань за останні 24 години
SELECT * FROM util.ssisGetExecutionParameters(NULL, NULL, NULL, NULL, 24)
ORDER BY ExecutionTime DESC, ParameterName;

-- Отримати параметри конкретного виконання
SELECT ParameterName, ParameterValue, ParameterDataType
FROM util.ssisGetExecutionParameters(NULL, NULL, NULL, 12345, NULL)
ORDER BY ParameterName;

-- Знайти всі виконання з конкретним значенням параметра
SELECT ExecutionId, PackageName, ParameterName, ParameterValue
FROM util.ssisGetExecutionParameters(NULL, NULL, NULL, NULL, 168)
WHERE ParameterName = 'LoadDate'
ORDER BY ExecutionTime DESC;

-- Порівняти параметри різних виконань одного пакета
SELECT ExecutionId, ParameterName, ParameterValue
FROM util.ssisGetExecutionParameters('ETL_Production', 'DataWarehouse', 'LoadFactSales', NULL, 168)
ORDER BY ParameterName, ExecutionId;
*/
CREATE OR ALTER FUNCTION util.ssisGetExecutionParameters(
    @folder NVARCHAR(128) = NULL,
    @project NVARCHAR(128) = NULL,
    @package NVARCHAR(128) = NULL,
    @executionId BIGINT = NULL,
    @hoursBack INT = 24
)
RETURNS TABLE
AS
RETURN(
    SELECT 
        ex.execution_id ExecutionId,
        f.name FolderName,
        proj.name ProjectName,
        ex.package_name PackageName,
        param.parameter_name ParameterName,
        param.parameter_value ParameterValue,
        param.parameter_data_type ParameterDataType,
        param.value_type ValueType,
        param.object_type ObjectType,
        ex.start_time ExecutionTime
    FROM SSISDB.catalog.execution_parameter_values param (NOLOCK)
        INNER JOIN SSISDB.catalog.executions ex (NOLOCK) ON param.execution_id = ex.execution_id
        INNER JOIN SSISDB.catalog.projects proj (NOLOCK) ON ex.project_id = proj.project_id
        INNER JOIN SSISDB.catalog.folders f (NOLOCK) ON ex.folder_id = f.folder_id
    WHERE 
        (@folder IS NULL OR f.name = @folder)
        AND (@project IS NULL OR proj.name = @project)
        AND (@package IS NULL OR ex.package_name = @package)
        AND (@executionId IS NULL OR ex.execution_id = @executionId)
        AND (@hoursBack IS NULL OR ex.start_time >= DATEADD(HOUR, -@hoursBack, GETDATE()))
);
GO

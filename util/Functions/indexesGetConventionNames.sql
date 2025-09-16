/*
# Description
Генерує стандартизовані назви індексів відповідно до конвенцій найменування.
Функція аналізує існуючі індекси і пропонує нові назви за встановленими стандартами.

# Parameters
@object NVARCHAR(128) = NULL - Назва таблиці для генерації назв індексів (NULL = усі таблиці)
@index NVARCHAR(128) = NULL - Назва конкретного індексу (NULL = усі індекси)

# Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- IndexName NVARCHAR(128) - Поточна назва індексу
- NewIndexName NVARCHAR(128) - Рекомендована назва згідно конвенцій
- IndexType NVARCHAR(60) - Тип індексу

# Usage
-- Отримати рекомендовані назви для всіх індексів конкретної таблиці
SELECT * FROM util.indexesGetConventionNames('myTable', NULL);

-- Отримати рекомендовану назву для конкретного індексу
SELECT * FROM util.indexesGetConventionNames('myTable', 'myIndex');
*/
CREATE FUNCTION util.indexesGetConventionNames(@object NVARCHAR(128) = NULL, @index NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
    WITH IndexInfo AS (
        SELECT
            s.name AS SchemaName,
            t.name AS TableName,
            i.name AS IndexName,
            i.object_id,
            i.index_id,
            i.type_desc,
            i.is_unique,
            i.has_filter,
            i.filter_definition,
            i.is_padded,
            i.is_hypothetical,
            i.data_space_id,
            ds.type_desc AS data_space_type,
            CASE WHEN kc.type = 'PK' THEN 1 ELSE 0 END AS IsPrimaryKey
        FROM sys.indexes i  (NOLOCK)
            INNER JOIN sys.tables t   (NOLOCK) ON i.object_id = t.object_id
            INNER JOIN sys.schemas s   (NOLOCK) ON t.schema_id = s.schema_id
            LEFT JOIN sys.data_spaces ds (NOLOCK) ON i.data_space_id = ds.data_space_id
            LEFT JOIN sys.key_constraints kc (NOLOCK) ON i.object_id = kc.parent_object_id AND i.index_id = kc.unique_index_id AND kc.type = 'PK'
        WHERE 
            (@object IS NULL OR i.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
            AND (@index IS NULL OR i.name = @index)
            AND i.is_hypothetical = 0 -- skip hypothetical indexes
            AND i.type_desc <> 'HEAP' -- skip heaps
            AND i.name IS NOT NULL -- skip heap indexes
    )
    , IndexColumns AS (
        SELECT
            ic.object_id,
            ic.index_id,
            STRING_AGG(
                LEFT(c.name + CASE WHEN ic.is_descending_key = 1 THEN '_D' ELSE '' END, 32), '_'
            ) WITHIN GROUP (ORDER BY ic.index_column_id) AS KeyColumns
        FROM sys.index_columns ic (NOLOCK)
            INNER JOIN sys.columns c (NOLOCK) ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.is_included_column = 0
        GROUP BY ic.object_id, ic.index_id
    )
    , IndexInclude AS (
        SELECT
            ic.object_id,
            ic.index_id,
            MAX(CASE WHEN ic.is_included_column = 1 THEN 1 ELSE 0 END) AS HasInclude
        FROM sys.index_columns ic (NOLOCK)
        GROUP BY ic.object_id, ic.index_id
    )
    , ProposedIndexNames AS (
        SELECT
            ii.object_id,
            ii.index_id,
            ii.SchemaName,
            ii.TableName,
            ii.IndexName AS CurrentIndexName,
            CASE 
                WHEN ii.IsPrimaryKey = 1 THEN CONCAT('PK_', ii.TableName, '_', LEFT(ISNULL(ic.KeyColumns, ''), 100))
                WHEN ii.type_desc = 'CLUSTERED' THEN CONCAT('CI_', LEFT(ISNULL(ic.KeyColumns, ''), 100))
                WHEN ii.type_desc = 'CLUSTERED COLUMNSTORE' THEN 'CCSI'
                WHEN ii.type_desc = 'NONCLUSTERED' AND ii.data_space_type = 'COLUMNSTORE' THEN CONCAT('CS_', LEFT(ISNULL(ic.KeyColumns, ''), 100))
                WHEN ii.type_desc = 'NONCLUSTERED' THEN CONCAT('IX_', LEFT(ISNULL(ic.KeyColumns, ''), 100))
                ELSE CONCAT('IX_',ii.type_desc COLLATE DATABASE_DEFAULT, '_', LEFT(ISNULL(ic.KeyColumns, ''), 100))
            END AS BaseIndexName,
            CASE WHEN ii.IsPrimaryKey = 1 OR ii.type_desc = 'CLUSTERED COLUMNSTORE' THEN '' ELSE
                CONCAT(
                    CASE WHEN inc.HasInclude = 1 THEN '_INC' ELSE '' END,
                    CASE WHEN ii.has_filter = 1 THEN '_FLT' ELSE '' END,
                    CASE WHEN ii.is_unique = 1 THEN '_UQ' ELSE '' END,
                    CASE WHEN ii.data_space_type = 'PARTITION_SCHEME' THEN '_P' ELSE '' END
                )
            END AS IndexSuffix
        FROM IndexInfo ii
        LEFT JOIN IndexColumns ic ON ii.object_id = ic.object_id AND ii.index_id = ic.index_id
        LEFT JOIN IndexInclude inc ON ii.object_id = inc.object_id AND ii.index_id = inc.index_id
    )
    , FinalIndexNames AS (
        SELECT 
            pin.object_id,
            pin.index_id,
            pin.SchemaName,
            pin.TableName,
            pin.CurrentIndexName,
            pin.BaseIndexName + pin.IndexSuffix AS ProposedName,
            -- ��� ���������� ���� �������� ��� �������, ��� �������� ������ �����
            CASE 
                WHEN ROW_NUMBER() OVER (PARTITION BY pin.BaseIndexName + pin.IndexSuffix ORDER BY pin.index_id) = 1 
                    AND COUNT(*) OVER (PARTITION BY pin.BaseIndexName + pin.IndexSuffix) = 1 
                THEN ''
                ELSE CAST(ROW_NUMBER() OVER (PARTITION BY pin.BaseIndexName + pin.IndexSuffix ORDER BY pin.index_id) AS NVARCHAR(10))
            END AS NumberSuffix
        FROM ProposedIndexNames pin
    )
    SELECT
        QUOTENAME(fin.SchemaName) + '.' + QUOTENAME(fin.TableName) + '.' + QUOTENAME(fin.CurrentIndexName) AS currentName,
        QUOTENAME(fin.SchemaName) + '.' + QUOTENAME(fin.TableName) + '.' + QUOTENAME(fin.ProposedName + fin.NumberSuffix) AS newName
    FROM FinalIndexNames fin
);
/*
# Description
Повертає інформацію про індексовані колонки таблиць, показуючи які колонки є першими в індексах.
Функція аналізує всі індекси та показує колонки, які є першими (key_ordinal = 1) в кожному індексі.

# Parameters
@object NVARCHAR(128) = NULL - назва таблиці для аналізу індексованих колонок (NULL = усі таблиці)

# Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - назва схеми
- TableName NVARCHAR(128) - назва таблиці
- ColumnName NVARCHAR(128) - назва колонки
- IndexName NVARCHAR(128) - назва індексу
- IndexType NVARCHAR(60) - тип індексу
- IsUnique BIT - чи є індекс унікальним
- IsPrimaryKey BIT - чи є індекс первинним ключем
- IsUniqueConstraint BIT - чи є індекс унікальним обмеженням
- KeyOrdinal TINYINT - позиція колонки в ключі індексу
- PartitionOrdinal TINYINT - позиція колонки в схемі партиціонування
- IsIncludedColumn BIT - чи є колонка включеною (INCLUDE)

# Usage
-- Показати всі індексовані колонки в базі даних
SELECT * FROM util.tablesGetIndexedColumns(NULL)
ORDER BY SchemaName, TableName, ColumnName;

-- Показати індексовані колонки конкретної таблиці
SELECT * FROM util.tablesGetIndexedColumns('MyTable')
ORDER BY ColumnName;

-- Знайти колонки, які є першими в індексах
SELECT DISTINCT SchemaName, TableName, ColumnName
FROM util.tablesGetIndexedColumns(NULL)
WHERE KeyOrdinal = 1
ORDER BY SchemaName, TableName, ColumnName;

-- Аналіз покриття колонок індексами
SELECT SchemaName, TableName, ColumnName, COUNT(*) AS IndexCount
FROM util.tablesGetIndexedColumns('MyTable')
GROUP BY SchemaName, TableName, ColumnName
ORDER BY IndexCount DESC;
*/
CREATE OR ALTER FUNCTION util.tablesGetIndexedColumns(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
    SELECT 
        OBJECT_SCHEMA_NAME(ic.object_id) AS SchemaName,
        util.metadataGetObjectName(ic.object_id, DEFAULT) AS TableName,
        c.name AS ColumnName,
        i.name AS IndexName,
        i.type_desc AS IndexType,
        i.is_unique AS IsUnique,
        i.is_primary_key AS IsPrimaryKey,
        i.is_unique_constraint AS IsUniqueConstraint,
        ic.key_ordinal AS KeyOrdinal,
        ic.partition_ordinal AS PartitionOrdinal,
        ic.is_included_column AS IsIncludedColumn
    FROM sys.index_columns ic
        INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        INNER JOIN sys.indexes i ON i.index_id = ic.index_id AND i.object_id = ic.object_id
        INNER JOIN sys.tables t ON t.object_id = ic.object_id
    WHERE 
        ic.key_ordinal = 1  -- Показуємо тільки перші колонки в індексах
        AND (@object IS NULL 
            OR ic.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
);
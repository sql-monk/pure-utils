/*
# Description
Генерує DDL скрипти для створення індексів на основі існуючих індексів таблиць.
Функція формує повні CREATE INDEX інструкції включаючи всі налаштування індексу.

# Parameters
@table NVARCHAR(128) = NULL - Назва таблиці для генерації скриптів індексів (NULL = усі таблиці)
@index NVARCHAR(128) = NULL - Назва конкретного індексу (NULL = усі індекси)

# Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- IndexName NVARCHAR(128) - Назва індексу
- CreateScript NVARCHAR(MAX) - DDL скрипт для створення індексу

# Usage
-- Згенерувати скрипти для всіх індексів конкретної таблиці
SELECT * FROM util.indexesGetScript('myTable', NULL);

-- Згенерувати скрипт для конкретного індексу
SELECT * FROM util.indexesGetScript('myTable', 'myIndex');
*/
CREATE OR ALTER FUNCTION util.indexesGetScript(@table NVARCHAR(128) = NULL, @index NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	WITH IndexDetails AS (
		SELECT
			i.object_id,
			i.index_id,
			OBJECT_SCHEMA_NAME(i.object_id) schemaName,
			OBJECT_NAME(i.object_id) tableName,
			i.name indexName,
			i.type_desc indexType,
			i.is_unique,
			i.is_primary_key,
			i.is_unique_constraint,
			i.filter_definition,
			i.fill_factor,
			i.ignore_dup_key,
			i.allow_row_locks,
			i.allow_page_locks,
			i.has_filter
		FROM sys.indexes i
		WHERE
			i.name IS NOT NULL
			AND i.is_hypothetical = 0
			AND (@table IS NULL OR i.object_id = ISNULL(TRY_CONVERT(INT, @table), OBJECT_ID(@table)))
			AND (@index IS NULL OR i.name = @index)
	),
	IndexColumns AS (
		SELECT
			id.object_id,
			id.index_id,
			STRING_AGG(QUOTENAME(c.name) + CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END, ', ') WITHIN GROUP(ORDER BY ic.key_ordinal) keyColumns
		FROM IndexDetails id
			INNER JOIN sys.index_columns(NOLOCK) ic ON id.object_id = ic.object_id AND id.index_id = ic.index_id AND ic.is_included_column = 0
			INNER JOIN sys.columns(NOLOCK) c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
		GROUP BY
			id.object_id,
			id.index_id
	),
	IncludedColumns AS (
		SELECT
			id.object_id,
			id.index_id,
			STRING_AGG(QUOTENAME(c.name), ', ') includedColumns
		FROM IndexDetails id
			INNER JOIN sys.index_columns(NOLOCK) ic ON id.object_id = ic.object_id AND id.index_id = ic.index_id AND ic.is_included_column = 1
			INNER JOIN sys.columns(NOLOCK) c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
		GROUP BY
			id.object_id,
			id.index_id
	)
	SELECT
		util.metadataGetIndexName(id.object_id, id.index_id) tableName,
		'CREATE ' + CASE
									WHEN id.is_unique = 1 AND id.is_primary_key = 0 AND id.is_unique_constraint = 0 THEN 'UNIQUE '
									ELSE ''
								END + CASE
												WHEN id.indexType = 'CLUSTERED' THEN 'CLUSTERED INDEX '
												WHEN id.indexType = 'NONCLUSTERED' THEN 'NONCLUSTERED INDEX '
												ELSE 'INDEX '
											END + QUOTENAME(id.indexName) + ' ON ' + QUOTENAME(id.schemaName) + '.' + QUOTENAME(id.tableName) + ' (' + ic.keyColumns + ')'
		+ CASE
				WHEN incl.includedColumns IS NOT NULL THEN ' INCLUDE (' + incl.includedColumns + ')'
				ELSE ''
			END + CASE
							WHEN id.has_filter = 1 AND id.filter_definition IS NOT NULL THEN ' WHERE ' + id.filter_definition
							ELSE ''
						END + ' WITH (' + CASE
																WHEN id.fill_factor > 0 THEN 'FILLFACTOR = ' + CAST(id.fill_factor AS NVARCHAR(3)) + ', '
																ELSE ''
															END + 'IGNORE_DUP_KEY = ' + CASE WHEN id.ignore_dup_key = 1 THEN 'ON' ELSE 'OFF' END + ', ' + 'ALLOW_ROW_LOCKS = '
		+ CASE WHEN id.allow_row_locks = 1 THEN 'ON' ELSE 'OFF' END + ', ' + 'ALLOW_PAGE_LOCKS = ' + CASE WHEN id.allow_page_locks = 1 THEN 'ON' ELSE 'OFF' END
		+ ');' statement
	FROM IndexDetails id
		INNER JOIN IndexColumns ic ON id.object_id = ic.object_id AND id.index_id = ic.index_id
		LEFT JOIN IncludedColumns incl ON id.object_id = incl.object_id AND id.index_id = incl.index_id
);
/*
# Description
Повертає детальну статистику використання дискового простору індексами таблиці по партиціях.
Функція показує інформацію для кожної партиції окремо, включаючи дані про партиціонування та стиснення.

# Parameters
@object NVARCHAR(128) - Назва таблиці або її ID для аналізу індексів

# Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- IndexName NVARCHAR(128) - Назва індексу
- IndexType NVARCHAR(60) - Тип індексу
- PartitionNumber INT - Номер партиції
- PartitionFunction NVARCHAR(128) - Функція партиціонування
- BoundaryValue SQL_VARIANT - Граничне значення партиції
- TotalSizeKB BIGINT - Розмір партиції в КБ
- UsedSizeKB BIGINT - Використовуваний розмір в КБ
- UnusedSizeKB BIGINT - Невикористовуваний розмір в КБ
- RowsCount BIGINT - Кількість рядків у партиції
- DataCompression NVARCHAR(60) - Тип стиснення даних

# Usage
-- Детальна статистика по партиціях всіх індексів таблиці
SELECT * FROM util.indexesGetSpaceUsedDetailed('MyTable');

-- Знайти найбільші партиції
SELECT * FROM util.indexesGetSpaceUsedDetailed('MyTable') 
ORDER BY TotalSizeKB DESC;

-- Аналіз стиснення даних по партиціях
SELECT * FROM util.indexesGetSpaceUsedDetailed('MyTable')
WHERE DataCompression <> 'NONE';
*/
CREATE OR ALTER FUNCTION util.indexesGetSpaceUsedDetailed(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT
        i.object_id objectId,
        i.index_id indexId,
		s.name SchemaName,
		t.name TableName,
		ISNULL(i.name, N'HEAP') IndexName,
		i.type_desc IndexType,
		ps.partition_number PartitionNumber,
		pf.name PartitionFunction,
		prv.value BoundaryValue,
		ps.reserved_page_count / 128 TotalSizeMB,
		ps.used_page_count / 128 UsedSizeMB,
		(ps.reserved_page_count - ps.used_page_count) / 128 UnusedSizeMB,
		ps.row_count RowsCount,
		p.data_compression_desc DataCompression
	FROM sys.indexes i
		INNER JOIN sys.tables t ON i.object_id = t.object_id
		INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
		INNER JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
		LEFT JOIN sys.partitions p ON ps.object_id = p.object_id AND ps.index_id = p.index_id AND ps.partition_number = p.partition_number
		LEFT JOIN sys.partition_schemes psc ON i.data_space_id = psc.data_space_id
		LEFT JOIN sys.partition_functions pf ON psc.function_id = pf.function_id
		LEFT JOIN sys.partition_range_values prv ON pf.function_id = prv.function_id AND prv.boundary_id = ps.partition_number
	WHERE
		i.type >= 0 -- Включаємо всі типи індексів включно з HEAP
		AND (@object IS NULL OR t.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
);
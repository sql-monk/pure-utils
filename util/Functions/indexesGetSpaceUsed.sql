/*
# Description
Повертає стислу статистику використання дискового простору індексами таблиці з групуванням по індексах.
Функція використовує util.indexesGetSpaceUsedDetailed та агрегує дані по всіх партиціях кожного індексу.

# Parameters
@object NVARCHAR(128) = NULL - Назва таблиці або її ID для аналізу індексів (NULL = усі таблиці)

# Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - ID об'єкта таблиці
- indexId INT - ID індексу
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- IndexName NVARCHAR(128) - Назва індексу
- IndexType NVARCHAR(60) - Тип індексу
- TotalSizeMB BIGINT - Загальний розмір індексу в КБ (сума по всіх партиціях)
- UsedSizeMB BIGINT - Використовуваний розмір в КБ (сума по всіх партиціях)
- UnusedSizeMB BIGINT - Невикористовуваний розмір в КБ (сума по всіх партиціях)
- RowsCount BIGINT - Загальна кількість рядків в індексі (сума по всіх партиціях)
- DataCompression NVARCHAR(60) - Тип стиснення даних

# Usage
-- Стисла статистика по всіх індексах таблиці
SELECT * FROM util.indexesGetSpaceUsed('MyTable');

-- Знайти найбільші індекси
SELECT * FROM util.indexesGetSpaceUsed('MyTable') 
ORDER BY TotalSizeMB DESC;

-- Порівняти ефективність використання простору
SELECT IndexName, TotalSizeMB, RowsCount, 
       CASE WHEN RowsCount > 0 THEN TotalSizeMB / RowsCount ELSE 0 END AS AvgMBPerRow
FROM util.indexesGetSpaceUsed('MyTable')
ORDER BY AvgMBPerRow DESC;

-- Аналіз всіх індексів у базі даних
SELECT * FROM util.indexesGetSpaceUsed(NULL)
ORDER BY TotalSizeMB DESC;
*/
CREATE OR ALTER FUNCTION util.indexesGetSpaceUsed(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT 
		objectId,
		indexId,
		SchemaName,
		TableName,
		IndexName,
		IndexType,
		SUM(TotalSizeMB) TotalSizeMB,
		SUM(UsedSizeMB) UsedSizeMB,
		SUM(UnusedSizeMB) UnusedSizeMB,
		SUM(RowsCount) RowsCount,
		DataCompression
	from util.indexesGetSpaceUsedDetailed(@object)
	GROUP  BY 
		objectId,
		indexId,
		SchemaName,
		TableName,
		IndexName,
		IndexType,
		DataCompression
);
/*
# Description
Знаходить невикористовувані індекси в базі даних на основі статистики використання.
Функція аналізує DMV sys.dm_db_index_usage_stats для визначення індексів, які не використовувались
для операцій читання (seeks, scans, lookups) або використовувались тільки для операцій запису.

# Parameters
@object NVARCHAR(128) = NULL - Назва таблиці для аналізу індексів (NULL = усі таблиці)

# Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- IndexName NVARCHAR(128) - Назва індексу
- IndexType NVARCHAR(60) - Тип індексу
- UserSeeks BIGINT - Кількість пошуків користувачами
- UserScans BIGINT - Кількість сканувань користувачами
- UserLookups BIGINT - Кількість пошуків ключів користувачами
- UserUpdates BIGINT - Кількість оновлень користувачами
- LastUserSeek DATETIME - Час останнього пошуку
- LastUserScan DATETIME - Час останнього сканування
- LastUserLookup DATETIME - Час останнього пошуку ключа
- LastUserUpdate DATETIME - Час останнього оновлення
- UnusedReason NVARCHAR(200) - Причина віднесення до невикористовуваних

# Usage
-- Знайти всі невикористовувані індекси в базі даних
SELECT * FROM util.indexesGetUnused(NULL);

-- Знайти невикористовувані індекси конкретної таблиці
SELECT * FROM util.indexesGetUnused('myTable');

-- Знайти індекси з тільки операціями запису
SELECT * FROM util.indexesGetUnused(NULL) WHERE UnusedReason LIKE '%тільки запис%';
*/
CREATE OR ALTER FUNCTION util.indexesGetUnused(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	WITH IndexUsageStats AS (
		SELECT
			s.name SchemaName,
			t.name TableName,
			i.name IndexName,
			i.type_desc IndexType,
			i.object_id,
			i.index_id,
			i.is_primary_key,
			i.is_unique_constraint,
			ISNULL(ius.user_seeks, 0) UserSeeks,
			ISNULL(ius.user_scans, 0) UserScans,
			ISNULL(ius.user_lookups, 0) UserLookups,
			ISNULL(ius.user_updates, 0) UserUpdates,
			ius.last_user_seek LastUserSeek,
			ius.last_user_scan LastUserScan,
			ius.last_user_lookup LastUserLookup,
			ius.last_user_update LastUserUpdate
		FROM sys.indexes i
			INNER JOIN sys.tables t ON i.object_id = t.object_id
			INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
			LEFT JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id AND ius.database_id = DB_ID()
		WHERE
			i.type > 0 -- Виключаємо HEAP (type = 0)
			AND i.is_disabled = 0 -- Виключаємо відключені індекси
			AND i.is_hypothetical = 0 -- Виключаємо гіпотетичні індекси
			AND (@object IS NULL OR t.name = @object OR t.object_id = TRY_CONVERT(INT, @object) OR OBJECT_ID(@object) = t.object_id)
	)
	SELECT
		IndexUsageStats.object_id objectId,
		IndexUsageStats.index_id indexId,
		IndexUsageStats.SchemaName,
		IndexUsageStats.TableName,
		IndexUsageStats.IndexName,
		IndexUsageStats.IndexType,
		CASE
			WHEN IndexUsageStats.is_primary_key = 1 THEN NULL -- Не показуємо первинні ключі як невикористовувані
			WHEN IndexUsageStats.is_unique_constraint = 1 THEN NULL -- Не показуємо унікальні обмеження як невикористовувані
			WHEN IndexUsageStats.UserSeeks = 0 AND IndexUsageStats.UserScans = 0 AND IndexUsageStats.UserLookups = 0 AND IndexUsageStats.UserUpdates = 0 THEN
				N'Індекс не використовувався зовсім'
			WHEN IndexUsageStats.UserSeeks = 0 AND IndexUsageStats.UserScans = 0 AND IndexUsageStats.UserLookups = 0 AND IndexUsageStats.UserUpdates > 0 THEN
				N'Індекс використовується тільки для запису'
		END UnusedReason
	FROM IndexUsageStats
	WHERE
		-- Показуємо тільки дійсно невикористовувані індекси
		IndexUsageStats.is_primary_key = 0 -- Виключаємо первинні ключі
		AND IndexUsageStats.is_unique_constraint = 0 -- Виключаємо унікальні обмеження
		AND (
		-- Індекси, які зовсім не використовувались
		(IndexUsageStats.UserSeeks = 0 AND IndexUsageStats.UserScans = 0 AND IndexUsageStats.UserLookups = 0)
		)
);
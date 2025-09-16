CREATE PROCEDURE [dbo].[indexesRenameByPolicy]
	@tableName sysname = NULL,
	@indexName sysname = NULL,
	@output tinyint = 1
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @objectID INT = OBJECT_ID(@tableName);
	IF @objectID IS NULL
	BEGIN
		DECLARE @t NVARCHAR(128)
		DECLARE	 mcur CURSOR LOCAL STATIC FORWARD_ONLY READ_ONLY FOR SELECT CONCAT(OBJECT_SCHEMA_NAME(object_id),'.',name) FROM sys.tables WHERE is_ms_shipped = 0
		OPEN mcur;
		FETCH NEXT FROM mcur INTO @t;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC dbo.RenameIndexesByPolicy @t;
			FETCH NEXT FROM mcur INTO @t;
		END
		CLOSE mcur
		DEALLOCATE mcur
		RETURN;
	END;

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
		FROM sys.indexes i
			INNER JOIN sys.tables t ON i.object_id = t.object_id
			INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
			LEFT JOIN sys.data_spaces ds ON i.data_space_id = ds.data_space_id
			LEFT JOIN sys.key_constraints kc ON i.object_id = kc.parent_object_id AND i.index_id = kc.unique_index_id AND kc.type = 'PK'
		WHERE 
			t.object_id = @objectID
			AND ISNULL(@indexName, i.name) = i.name
			AND i.is_hypothetical = 0 -- skip hypothetical indexes
			AND i.type_desc <> 'HEAP' -- skip heaps
	)
	, IndexColumns AS (
		SELECT
			ic.object_id,
			ic.index_id,
			STRING_AGG(
				LEFT(c.name + CASE WHEN ic.is_descending_key = 1 THEN '_D' ELSE '' END, 32), '_'
			) WITHIN GROUP (ORDER BY ic.index_column_id) AS KeyColumns
		FROM sys.index_columns ic
			INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
		WHERE ic.is_included_column = 0
		GROUP BY ic.object_id, ic.index_id
	)
	, IndexInclude AS (
		SELECT
			ic.object_id,
			ic.index_id,
			MAX(CASE WHEN ic.is_included_column = 1 THEN 1 ELSE 0 END) AS HasInclude
		FROM sys.index_columns ic
		GROUP BY ic.object_id, ic.index_id
	)
	, ProposedIndexNames AS (
		SELECT
			ii.object_id,
			ii.index_id,
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
			pin.CurrentIndexName,
			pin.BaseIndexName + pin.IndexSuffix AS ProposedName,
			-- Для унікальних імен залишаємо без суфіксу, для дублікатів додаємо номер
			CASE 
				WHEN ROW_NUMBER() OVER (PARTITION BY pin.BaseIndexName + pin.IndexSuffix ORDER BY pin.index_id) = 1 
					AND COUNT(*) OVER (PARTITION BY pin.BaseIndexName + pin.IndexSuffix) = 1 
				THEN ''
				ELSE CAST(ROW_NUMBER() OVER (PARTITION BY pin.BaseIndexName + pin.IndexSuffix ORDER BY pin.index_id) AS NVARCHAR(10))
			END AS NumberSuffix
		FROM ProposedIndexNames pin
	)
	SELECT
		CONCAT(
			'EXEC sp_rename ''',
			@tableName, '.', QUOTENAME(fin.CurrentIndexName), ''', ''',
			fin.ProposedName + fin.NumberSuffix,
			''', ''INDEX'';'
		) AS RenameCommand
	INTO #RenameCommands
	FROM FinalIndexNames fin
	WHERE fin.CurrentIndexName <> fin.ProposedName + fin.NumberSuffix; -- Перейменовуємо тільки ті, що відрізняються

	DECLARE @cmd NVARCHAR(MAX);
	DECLARE rename_cursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT RenameCommand FROM #RenameCommands;

	OPEN rename_cursor;
	FETCH NEXT FROM rename_cursor INTO @cmd;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT @cmd; -- Для відладки - показуємо команду перед виконанням
		EXEC sp_executesql @cmd;
		FETCH NEXT FROM rename_cursor INTO @cmd;
	END
	CLOSE rename_cursor;
	DEALLOCATE rename_cursor;
	DROP TABLE #RenameCommands;
END;
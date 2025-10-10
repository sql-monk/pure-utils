/*
# Description
Процедура для рекурсивного пошуку всіх об'єктів від яких залежить вказаний об'єкт.
Аналізує залежності через sys.sql_expression_dependencies, обробляє синоніми та резолвить їх у реальні об'єкти.
Підтримує cross-database залежності та повертає результат у форматі JSON з рекурсивною структурою.

# Parameters
@object NVARCHAR(128) - Повне 3-х рівневе ім'я об'єкта у форматі 'database.schema.object'
@maxDepth INT = 5 - Максимальна глибина рекурсії (за замовчуванням 5 рівнів)
@references NVARCHAR(MAX) OUTPUT - Результат у форматі JSON з рекурсивною структурою залежностей

# Returns
OUTPUT параметр @references - JSON структура з рекурсивними залежностями:
{
		"dbName": "database",
		"schName": "schema",
		"objName": "object",
		"type": "P",
		"references": [
				{
						"dbName": "database",
						"schName": "schema",
						"objName": "dependency1",
						"type": "FN",
						"references": [...]
				}
		]
}

# Usage
-- Отримати залежності для процедури (5 рівнів)
DECLARE @refs NVARCHAR(MAX);
EXEC util.objectsGetReferences 
		@object = 'utils.util.metadataGetDescriptions',
		@references = @refs OUTPUT;
SELECT @refs;

-- Отримати залежності з обмеженням глибини
DECLARE @refs NVARCHAR(MAX);
EXEC util.objectsGetReferences 
		@object = 'utils.util.indexesGetConventionNames',
		@maxDepth = 3,
		@references = @refs OUTPUT;
PRINT @refs;

# Notes
- Обробляє синоніми та резолвить їх у реальні об'єкти
- Підтримує cross-database залежності
- Запобігає циклічним залежностям через відстеження вже оброблених об'єктів
- Обмежує глибину рекурсії параметром @maxDepth
*/
CREATE OR ALTER PROCEDURE util.objectsGetReferences
	@object NVARCHAR(128),
	@maxDepth INT = 5,
	@references NVARCHAR(MAX) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	-- Парсинг вхідного об'єкта
	DECLARE @dbName sysname = PARSENAME(@object, 3);
	DECLARE @schName sysname = PARSENAME(@object, 2);
	DECLARE @objName sysname = PARSENAME(@object, 1);

	-- Валідація вхідних параметрів
	IF @dbName IS NULL OR @schName IS NULL OR @objName IS NULL
	BEGIN
		RAISERROR('Очікується формат "database.schema.object".', 16, 1);
		RETURN;
	END;

	-- Таблиця для відстеження вже оброблених об'єктів (запобігання циклам)
	DECLARE @processedObjects TABLE(
		dbName sysname,
		schName sysname,
		objName sysname,
		PRIMARY KEY(dbName, schName, objName)
	);

	-- Тимчасова таблиця для зберігання результатів
	CREATE TABLE #DependencyTree (
		Id INT IDENTITY(1, 1) PRIMARY KEY,
		ParentId INT NULL,
		Level INT NOT NULL,
		DbName sysname NOT NULL,
		SchName sysname NOT NULL,
		ObjName sysname NOT NULL,
		ObjType CHAR(2) NULL,
		IsProcessed BIT
			DEFAULT 0,
		JsonFragment NVARCHAR(MAX) NULL
	);

	-- Додаємо кореневий об'єкт
	INSERT INTO #DependencyTree(Level, DbName, SchName, ObjName, ParentId)VALUES(0, @dbName, @schName, @objName, NULL);

	-- Отримуємо тип кореневого об'єкта
	DECLARE @rootType CHAR(2);
	DECLARE @getRootTypeSql NVARCHAR(MAX)
		= CONCAT(
				N'USE ',
				QUOTENAME(@dbName),
				N';
        SELECT @type = o.type 
        FROM sys.objects o (NOLOCK)
        WHERE SCHEMA_NAME(o.schema_id) = @sch 
            AND OBJECT_NAME(o.object_id) = @obj;'
			);

	EXEC sys.sp_executesql @getRootTypeSql, N'@sch SYSNAME, @obj SYSNAME, @type CHAR(2) OUTPUT', @sch = @schName, @obj = @objName, @type = @rootType OUTPUT;

	UPDATE #DependencyTree SET ObjType = @rootType WHERE Id = 1;

	-- Рекурсивна обробка залежностей
	DECLARE @currentLevel INT = 0;
	DECLARE @hasUnprocessed BIT = 1;

	WHILE @hasUnprocessed = 1 AND @currentLevel < @maxDepth
	BEGIN
		-- Курсор для необроблених об'єктів на поточному рівні
		DECLARE @currentId INT;
		DECLARE @currentDb sysname;
		DECLARE @currentSch sysname;
		DECLARE @currentObj sysname;

		DECLARE objCur CURSOR LOCAL FAST_FORWARD FOR SELECT Id, DbName, SchName, ObjName FROM #DependencyTree WHERE Level = @currentLevel AND IsProcessed = 0;

		OPEN objCur;
		FETCH NEXT FROM objCur
		INTO
			@currentId,
			@currentDb,
			@currentSch,
			@currentObj;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Перевіряємо чи не обробляли вже цей об'єкт
			IF NOT EXISTS (SELECT 1 FROM @processedObjects WHERE dbName = @currentDb AND schName = @currentSch AND objName = @currentObj)
			BEGIN
				-- Додаємо до оброблених
				INSERT INTO @processedObjects(dbName, schName, objName)VALUES(@currentDb, @currentSch, @currentObj);

				-- Отримуємо залежності через sys.sql_expression_dependencies
				DECLARE @depSql NVARCHAR(MAX)
					= CONCAT(
							N'USE ',
							QUOTENAME(@currentDb),
							N';
                    SELECT 
                        COALESCE(NULLIF(referenced_database_name, N''''), DB_NAME()) dbName,
                        COALESCE(NULLIF(referenced_schema_name, N''''), N''dbo'') schName,
                        referenced_entity_name objName
                    FROM sys.sql_expression_dependencies (NOLOCK)
                    WHERE referencing_id = OBJECT_ID(@fullName)
                        AND referenced_entity_name IS NOT NULL;'
						);

				DECLARE @fullName NVARCHAR(256) = CONCAT(QUOTENAME(@currentSch), N'.', QUOTENAME(@currentObj));

				DECLARE @deps TABLE(dbName sysname, schName sysname, objName sysname);

				INSERT INTO @deps(dbName, schName, objName)EXEC sys.sp_executesql @depSql, N'@fullName NVARCHAR(256)', @fullName = @fullName;

				-- Додаємо знайдені залежності до дерева
				INSERT INTO
					#DependencyTree(Level, DbName, SchName, ObjName, ParentId)
				SELECT
					@currentLevel + 1,
					d.dbName,
					d.schName,
					d.objName,
					@currentId
				FROM @deps d
				WHERE NOT EXISTS (
					SELECT 1 FROM @processedObjects p WHERE p.dbName = d.dbName AND p.schName = d.schName AND p.objName = d.objName
				);

				-- Отримуємо типи для нових об'єктів
				DECLARE typeCur CURSOR LOCAL FAST_FORWARD FOR
				SELECT Id, DbName, SchName, ObjName FROM #DependencyTree WHERE Level = @currentLevel + 1 AND ParentId = @currentId AND ObjType IS NULL;

				DECLARE @typeId INT;
				DECLARE @typeDb sysname;
				DECLARE @typeSch sysname;
				DECLARE @typeObj sysname;
				DECLARE @objType CHAR(2);

				OPEN typeCur;
				FETCH NEXT FROM typeCur
				INTO
					@typeId,
					@typeDb,
					@typeSch,
					@typeObj;

				WHILE @@FETCH_STATUS = 0
				BEGIN
					DECLARE @getTypeSql NVARCHAR(MAX)
						= CONCAT(
								N'USE ',
								QUOTENAME(@typeDb),
								N';
                        SELECT @type = o.type 
                        FROM sys.objects o (NOLOCK)
                        WHERE SCHEMA_NAME(o.schema_id) = @sch 
                            AND OBJECT_NAME(o.object_id) = @obj;'
							);

					SET @objType = NULL;

					EXEC sys.sp_executesql @getTypeSql, N'@sch SYSNAME, @obj SYSNAME, @type CHAR(2) OUTPUT', @sch = @typeSch, @obj = @typeObj, @type = @objType OUTPUT;

					UPDATE #DependencyTree SET ObjType = @objType WHERE Id = @typeId;

					FETCH NEXT FROM typeCur
					INTO
						@typeId,
						@typeDb,
						@typeSch,
						@typeObj;
				END;

				CLOSE typeCur;
				DEALLOCATE typeCur;

				-- Обробка синонімів: додаємо реальні об'єкти як дітей синонімів
				DECLARE synCur CURSOR LOCAL FAST_FORWARD FOR
				SELECT Id, DbName, SchName, ObjName, ObjType FROM #DependencyTree WHERE Level = @currentLevel + 1 AND ParentId = @currentId AND ObjType = 'SN';

				DECLARE @synId INT;
				DECLARE @synDb sysname;
				DECLARE @synSch sysname;
				DECLARE @synName sysname;
				DECLARE @synType CHAR(2);

				OPEN synCur;
				FETCH NEXT FROM synCur
				INTO
					@synId,
					@synDb,
					@synSch,
					@synName,
					@synType;

				WHILE @@FETCH_STATUS = 0
				BEGIN
					-- Знаходимо реальний об'єкт за синонімом
					DECLARE @synResolveSql NVARCHAR(MAX)
						= CONCAT(
								N'USE ',
								QUOTENAME(@synDb),
								N';
                        SELECT 
                            COALESCE(PARSENAME(base_object_name, 3), DB_NAME()) realDb,
                            COALESCE(PARSENAME(base_object_name, 2), ''dbo'') realSchema,
                            PARSENAME(base_object_name, 1) realObject
                        FROM sys.synonyms (NOLOCK)
                        WHERE SCHEMA_NAME(schema_id) = @sch 
                            AND name = @nm
                            AND PARSENAME(base_object_name, 1) IS NOT NULL;'
							);

					DECLARE @realSynTarget TABLE(realDb sysname, realSchema sysname, realObject sysname);

					DELETE FROM @realSynTarget;

					INSERT INTO @realSynTarget(realDb, realSchema, realObject)EXEC sys.sp_executesql @synResolveSql, N'@sch SYSNAME, @nm SYSNAME', @sch = @synSch, @nm = @synName;

					-- Додаємо реальний об'єкт як дочірній до синоніма
					IF EXISTS (SELECT 1 FROM @realSynTarget)
					BEGIN
						DECLARE @realDb sysname;
						DECLARE @realSch sysname;
						DECLARE @realObj sysname;

						SELECT @realDb = realDb, @realSch = realSchema, @realObj = realObject FROM @realSynTarget;

						-- Перевіряємо чи не обробляли вже цей об'єкт
						IF NOT EXISTS (SELECT 1 FROM @processedObjects WHERE dbName = @realDb AND schName = @realSch AND objName = @realObj)
						BEGIN
							-- Додаємо реальний об'єкт як дитину синоніма
							INSERT INTO #DependencyTree(Level, DbName, SchName, ObjName, ParentId)VALUES(@currentLevel + 2, @realDb, @realSch, @realObj, @synId);

							-- Отримуємо тип реального об'єкта
							DECLARE @realObjType CHAR(2);
							DECLARE @getRealTypeSql NVARCHAR(MAX)
								= CONCAT(
										N'USE ',
										QUOTENAME(@realDb),
										N';
                                SELECT @type = o.type 
                                FROM sys.objects o (NOLOCK)
                                WHERE SCHEMA_NAME(o.schema_id) = @sch 
                                    AND OBJECT_NAME(o.object_id) = @obj;'
									);

							SET @realObjType = NULL;

							EXEC sys.sp_executesql @getRealTypeSql, N'@sch SYSNAME, @obj SYSNAME, @type CHAR(2) OUTPUT', @sch = @realSch, @obj = @realObj, @type = @realObjType OUTPUT;

							UPDATE #DependencyTree
							SET ObjType = @realObjType
							WHERE DbName = @realDb AND SchName = @realSch AND ObjName = @realObj AND Level = @currentLevel + 2 AND ParentId = @synId;

							-- Додаємо до оброблених
							INSERT INTO @processedObjects(dbName, schName, objName)VALUES(@realDb, @realSch, @realObj);
						END;
					END;

					FETCH NEXT FROM synCur
					INTO
						@synId,
						@synDb,
						@synSch,
						@synName,
						@synType;
				END;

				CLOSE synCur;
				DEALLOCATE synCur;

				DELETE FROM @deps;
			END;

			-- Позначаємо об'єкт як оброблений
			UPDATE #DependencyTree SET IsProcessed = 1 WHERE Id = @currentId;

			FETCH NEXT FROM objCur
			INTO
				@currentId,
				@currentDb,
				@currentSch,
				@currentObj;
		END;

		CLOSE objCur;
		DEALLOCATE objCur;

		-- Переходимо на наступний рівень
		SET @currentLevel = @currentLevel + 1;

		-- Перевіряємо чи є ще необроблені об'єкти
		IF NOT EXISTS (SELECT 1 FROM #DependencyTree WHERE Level = @currentLevel AND IsProcessed = 0)
		BEGIN
			SET @hasUnprocessed = 0;
		END;
	END;

	-- Формуємо JSON з рекурсивною структурою
	-- Будуємо JSON знизу вгору (від листів до кореня)
	DECLARE @maxLevel INT = (SELECT MAX(Level)FROM #DependencyTree);
	DECLARE @buildLevel INT = @maxLevel;

	WHILE @buildLevel >= 0
	BEGIN
		-- Для кожного вузла на поточному рівні
		UPDATE
			dt
		SET
			dt.JsonFragment = CONCAT(
													'{"dbName":"',
													dt.DbName,
													'","schName":"',
													dt.SchName,
													'","objName":"',
													dt.ObjName,
													'","type":"',
													RTRIM(ISNULL(dt.ObjType, '??')),
													'"',
													',"references":[',
													ISNULL(
														STUFF(
															(
																SELECT CONCAT(',', child.JsonFragment)FROM #DependencyTree child WHERE child.ParentId = dt.Id ORDER BY child.Id FOR XML PATH(''), TYPE
															).value('.', 'NVARCHAR(MAX)'),
															1,
															1,
															''
														),
														''
													),
													']}'
												)
		FROM #DependencyTree dt
		WHERE dt.Level = @buildLevel;

		SET @buildLevel = @buildLevel - 1;
	END;

	-- Отримуємо JSON кореневого об'єкта
	SELECT @references = JsonFragment FROM #DependencyTree WHERE ParentId IS NULL;
END;
GO
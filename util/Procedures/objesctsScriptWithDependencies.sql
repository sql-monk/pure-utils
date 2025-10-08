/*
# Description
Процедура для генерації DDL скрипта об'єкта разом з усіма його залежностями.
Виконує рекурсивний обхід залежностей через sys.sql_expression_dependencies,
підтримує cross-database залежності, резолвить синоніми та формує правильний порядок створення об'єктів.
Генерує повний скрипт для відтворення об'єкта та всіх його залежностей в іншій базі даних.

# Parameters
@objectFullName sysname - Повна назва об'єкта у форматі 'database.schema.object'
@outputScript NVARCHAR(MAX) OUTPUT - Вихідний параметр, який містить згенерований DDL скрипт

# Returns
OUTPUT параметр @outputScript - повний DDL скрипт з усіма залежностями в правильному порядку

# Usage
-- Згенерувати скрипт для процедури з залежностями
DECLARE @script NVARCHAR(MAX);
EXEC util.objectsScriptWithDependencies 
	@objectFullName = 'utils.util.metadataGetDescriptions',
	@outputScript = @script OUTPUT;
PRINT @script;

-- Згенерувати скрипт для функції
DECLARE @script NVARCHAR(MAX);
EXEC util.objectsScriptWithDependencies 
	@objectFullName = 'utils.util.tablesGetScript',
	@outputScript = @script OUTPUT;
SELECT @script script;

# Notes
- Підтримує різні типи об'єктів: таблиці (U), представлення (V), процедури (P), функції (FN, IF, TF), тригери (TR)
- Обробляє синоніми (SN) та резолвить їх у реальні об'єкти
- Підтримує cross-database залежності
- Генерує скрипти у правильному порядку (залежності перед об'єктами, які їх використовують)
- Використовує topological sort для визначення порядку створення
*/
CREATE OR ALTER PROCEDURE util.objectsScriptWithDependencies
	@objectFullName sysname, -- 'db.schema.object'
	@outputScript NVARCHAR(MAX) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @crlf NVARCHAR(2) = CONCAT(CHAR(13), CHAR(10));
	/*  1) Парсинг  */
	DECLARE @dbName sysname = PARSENAME(@objectFullName, 3);
	DECLARE @schName sysname = PARSENAME(@objectFullName, 2);
	DECLARE @objName sysname = PARSENAME(@objectFullName, 1);

	IF @dbName IS NULL OR @schName IS NULL OR @objName IS NULL
	BEGIN
		RAISERROR('Очікується формат "dbname.schname.objectname".', 16, 1);
		RETURN;
	END;

	-- Нормалізація схеми на випадок db..obj
	SET @schName = CASE WHEN @schName = N'' THEN N'dbo' ELSE @schName END;


	CREATE TABLE #nodes (
		dbName sysname NOT NULL,
		schName sysname NOT NULL,
		objName sysname NOT NULL,
		objectId INT NULL,
		type CHAR(2) NULL, -- 'U','V','P','FN','TF','IF','TR','SO','SN',...
		levelNo INT NOT NULL,
		isInput BIT NOT NULL
			DEFAULT(0),
		CONSTRAINT PK_nodes
			PRIMARY KEY(dbName, schName, objName)
	);
	CREATE TABLE #toVisit (
		dbName sysname NOT NULL,
		schName sysname NOT NULL,
		objName sysname NOT NULL,
		levelNo INT NOT NULL
	);
	CREATE TABLE #ordered (
		dbName sysname NOT NULL,
		schName sysname NOT NULL,
		objName sysname NOT NULL,
		type CHAR(2) NULL,
		sortOrd INT NOT NULL IDENTITY(1, 1)
	);

	DECLARE @script NVARCHAR(MAX) = N'';

	/*  3) Стартовий вузол  */
	INSERT INTO
		#nodes(dbName, schName, objName, objectId, type, levelNo, isInput)
	SELECT
		@dbName,
		@schName,
		@objName,
		NULL,
		NULL,
		0,
		1
	WHERE NOT EXISTS (
		SELECT * FROM #nodes WHERE dbName = @dbName AND schName = @schName AND objName = @objName
	);

	INSERT INTO #toVisit(dbName, schName, objName, levelNo)VALUES(@dbName, @schName, @objName, 0);

	/*  4) Обхід залежностей (SQL 2022)  */
	WHILE EXISTS (SELECT * FROM #toVisit)
	BEGIN
		DECLARE
			@curDb sysname,
			@curSch sysname,
			@curObj sysname,
			@lvl INT;
		SELECT TOP(1)@curDb = dbName, @curSch = schName, @curObj = objName, @lvl = levelNo FROM #toVisit ORDER BY levelNo, dbName, schName, objName;

		DELETE FROM #toVisit WHERE dbName = @curDb AND schName = @curSch AND objName = @curObj AND levelNo = @lvl;

		/* --- 4.1 Залежності для поточного --- */
		DECLARE @depSql NVARCHAR(MAX)
			= CONCAT(
					N'USE ',
					QUOTENAME(@curDb),
					N';
DECLARE @rid int = OBJECT_ID(CONCAT(QUOTENAME(@s), N''.'', QUOTENAME(@o)));
SELECT 
    dbName  = COALESCE(NULLIF(referenced_database_name, N''''), DB_NAME()),
    schName = COALESCE(NULLIF(referenced_schema_name,  N''''), N''dbo''),
    objName = referenced_entity_name
FROM sys.sql_expression_dependencies
WHERE referencing_id = @rid
  AND referenced_entity_name IS NOT NULL;'
				);

		DECLARE @deps TABLE(
			dbName sysname NOT NULL,
			schName sysname NOT NULL,
			objName sysname NOT NULL
		);

		INSERT INTO @deps(dbName, schName, objName)EXEC sys.sp_executesql @depSql, N'@s sysname, @o sysname', @s = @curSch, @o = @curObj;

		/* --- 4.1.1 Резолвимо синоніми в реальні об'єкти --- */
		-- Синоніми знаходяться в ПОТОЧНІЙ БД (@curDb), а не в тій, на яку вони вказують
		-- Додаємо реальні об'єкти ДО залежностей (включаючи cross-database)
		DECLARE synCur CURSOR LOCAL FAST_FORWARD FOR 
			SELECT dbName, schName, objName FROM @deps;
		
		DECLARE @synDb sysname, @synSch sysname, @synName sysname;
		OPEN synCur;
		FETCH NEXT FROM synCur INTO @synDb, @synSch, @synName;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- ВАЖЛИВО: Синонім знаходиться в @curDb (поточна БД), а НЕ в @synDb
			DECLARE @synCheck NVARCHAR(MAX)
				= CONCAT(
						N'USE ',
						QUOTENAME(@curDb),
						N';
IF EXISTS (SELECT 1 FROM sys.synonyms WHERE SCHEMA_NAME(schema_id) = @sch AND name = @nm)
BEGIN
    SELECT 
        COALESCE(PARSENAME(base_object_name, 3), DB_NAME()) AS realDb,
        COALESCE(PARSENAME(base_object_name, 2), ''dbo'') AS realSchema,
        PARSENAME(base_object_name, 1) AS realObject
    FROM sys.synonyms
    WHERE SCHEMA_NAME(schema_id) = @sch AND name = @nm
      AND PARSENAME(base_object_name, 1) IS NOT NULL;
END;'
					);

			DECLARE @realTarget TABLE(realDb sysname, realSchema sysname, realObject sysname);
			DELETE FROM @realTarget;

			INSERT INTO @realTarget(realDb, realSchema, realObject)
			EXEC sys.sp_executesql @synCheck, N'@sch sysname, @nm sysname', @sch = @synSch, @nm = @synName;

			-- Якщо знайшли реальний об'єкт за синонімом, додаємо його (навіть якщо в іншій БД)
			IF EXISTS (SELECT 1 FROM @realTarget)
			BEGIN
				INSERT INTO @deps(dbName, schName, objName)
				SELECT realDb, realSchema, realObject
				FROM @realTarget
				WHERE NOT EXISTS (
					SELECT 1 FROM @deps d
					WHERE d.dbName = realDb 
					  AND d.schName = realSchema 
					  AND d.objName = realObject
				);
			END;

			FETCH NEXT FROM synCur INTO @synDb, @synSch, @synName;
		END;

		CLOSE synCur;
		DEALLOCATE synCur;

		/* --- 4.2 Для кожної залежності визначаємо object_id/type --- */
		DECLARE depCur CURSOR LOCAL FAST_FORWARD FOR SELECT dbName, schName, objName FROM @deps;

		DECLARE
			@dDb sysname,
			@dSch sysname,
			@dObj sysname;
		OPEN depCur;
		FETCH NEXT FROM depCur
		INTO
			@dDb,
			@dSch,
			@dObj;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @dSch = CASE WHEN @dSch = N'' THEN N'dbo' ELSE @dSch END;

			DECLARE @res TABLE(object_id INT NULL, type CHAR(2) NULL);

			DECLARE @fillSql NVARCHAR(MAX)
				= CONCAT(
						N'USE ',
						QUOTENAME(@dDb),
						N';
IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_SCHEMA_NAME(object_id)=@s AND OBJECT_NAME(object_id)=@o)
    SELECT TOP(1) object_id, [type]
    FROM sys.objects
    WHERE OBJECT_SCHEMA_NAME(object_id)=@s AND OBJECT_NAME(object_id)=@o;
ELSE IF EXISTS (SELECT * FROM sys.sequences WHERE OBJECT_SCHEMA_NAME(object_id)=@s AND OBJECT_NAME(object_id)=@o)
    SELECT TOP(1) object_id, ''SO'' AS [type]
    FROM sys.sequences
    WHERE OBJECT_SCHEMA_NAME(object_id)=@s AND OBJECT_NAME(object_id)=@o;
ELSE IF EXISTS (SELECT * FROM sys.synonyms WHERE SCHEMA_NAME(schema_id)=@s AND name=@o)
    SELECT CAST(NULL AS int) AS object_id, ''SN'' AS [type];
ELSE
    SELECT CAST(NULL AS int) AS object_id, CAST(NULL AS char(2)) AS [type];'
					);

			INSERT INTO @res(object_id, type)EXEC sys.sp_executesql @fillSql, N'@s sysname, @o sysname', @s = @dSch, @o = @dObj;

			DECLARE
				@foundId INT = NULL,
				@foundType CHAR(2) = NULL;
			SELECT TOP(1)@foundId = object_id, @foundType = type FROM @res;

			-- додаємо/оновлюємо вузол (навіть якщо тип невідомий; це не зламає генерацію, бо ми пропустимо)
			IF NOT EXISTS (SELECT * FROM #nodes WHERE dbName = @dDb AND schName = @dSch AND objName = @dObj)
			BEGIN
				INSERT INTO #nodes(dbName, schName, objName, objectId, type, levelNo, isInput)VALUES(@dDb, @dSch, @dObj, @foundId, @foundType, @lvl + 1, 0);

				INSERT INTO #toVisit(dbName, schName, objName, levelNo)VALUES(@dDb, @dSch, @dObj, @lvl + 1);
			END;
			ELSE
			BEGIN
				UPDATE n
				SET
					n.objectId = COALESCE(n.objectId, @foundId),
					n.type = COALESCE(n.type, @foundType),
					n.levelNo = CASE WHEN n.levelNo > @lvl + 1 THEN @lvl + 1 ELSE n.levelNo END
				FROM #nodes n
				WHERE n.dbName = @dDb AND n.schName = @dSch AND n.objName = @dObj;
			END;

			FETCH NEXT FROM depCur
			INTO
				@dDb,
				@dSch,
				@dObj;
		END;

		CLOSE depCur;
		DEALLOCATE depCur;

		/* --- 4.3 Заповнюємо тип/ID для самого вузла --- */
		DECLARE @self TABLE(object_id INT NULL, type CHAR(2) NULL);

		DECLARE @selfFill NVARCHAR(MAX)
			= CONCAT(
					N'USE ',
					QUOTENAME(@curDb),
					N';
IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_SCHEMA_NAME(object_id)=@s AND OBJECT_NAME(object_id)=@o)
    SELECT TOP(1) object_id, [type]
    FROM sys.objects
    WHERE OBJECT_SCHEMA_NAME(object_id)=@s AND OBJECT_NAME(object_id)=@o;
ELSE IF EXISTS (SELECT * FROM sys.sequences WHERE OBJECT_SCHEMA_NAME(object_id)=@s AND OBJECT_NAME(object_id)=@o)
    SELECT TOP(1) object_id, ''SO'' AS [type]
    FROM sys.sequences
    WHERE OBJECT_SCHEMA_NAME(object_id)=@s AND OBJECT_NAME(object_id)=@o;
ELSE IF EXISTS (SELECT * FROM sys.synonyms WHERE SCHEMA_NAME(schema_id)=@s AND name=@o)
    SELECT CAST(NULL AS int) AS object_id, ''SN'' AS [type];
ELSE
    SELECT CAST(NULL AS int) AS object_id, CAST(NULL AS char(2)) AS [type];'
				);

		INSERT INTO @self(object_id, type)EXEC sys.sp_executesql @selfFill, N'@s sysname, @o sysname', @s = @curSch, @o = @curObj;

		UPDATE n
		SET
			n.objectId = COALESCE(n.objectId, s.object_id),
			n.type = COALESCE(n.type, s.type)
		FROM #nodes n
			CROSS APPLY(SELECT TOP(1)object_id, type FROM @self) s
		WHERE n.dbName = @curDb AND n.schName = @curSch AND n.objName = @curObj;
	END

	/*  5) Дедуп через '' vs 'dbo'  */
	;
	WITH dups AS (
		SELECT *, ROW_NUMBER() OVER (PARTITION BY dbName, LOWER(schName), objName ORDER BY levelNo DESC) rn FROM #nodes
	)
	DELETE FROM dups WHERE dups.rn > 1;

	/*  6) Порядок виконання: найглибші спочатку  */
	INSERT INTO #ordered(dbName, schName, objName, type)SELECT dbName, schName, objName, type FROM #nodes ORDER BY levelNo DESC, dbName, schName, objName;

	UPDATE #ordered SET schName = CASE WHEN schName = N'' THEN N'dbo' ELSE schName END;

	/*  7) Генерація скриптів з м’якими пропусками  */
	DECLARE ord CURSOR LOCAL FAST_FORWARD FOR SELECT dbName, schName, objName, type FROM #ordered ORDER BY sortOrd;

	DECLARE
		@oDb sysname,
		@oSch sysname,
		@oObj sysname,
		@oType CHAR(2);
	OPEN ord;
	FETCH NEXT FROM ord
	INTO
		@oDb,
		@oSch,
		@oObj,
		@oType;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Якщо тип невідомий — просто коментуємо і далі
		IF @oType IS NULL
		BEGIN
			SET @script = CONCAT(@script, N'-- SKIP: не знайдено типу для ', QUOTENAME(@oDb), N'.', QUOTENAME(@oSch), N'.', QUOTENAME(@oObj), @crlf, @crlf);
			GOTO nextItem;
		END;

		IF @oType = 'U'
		BEGIN
			BEGIN TRY
				DECLARE @tblOut NVARCHAR(MAX) = N'';
				DECLARE @currentDb sysname = DB_NAME();
				
				-- Генеруємо скрипт таблиці, викликаючи функцію з utils БД, що знаходиться в БД таблиці
				-- ВАЖЛИВО: викликаємо @oDb.util.tablesGetScript, а не @currentDb.util.tablesGetScript
				DECLARE @tblSql NVARCHAR(MAX) = CONCAT(
					N'SELECT @out = createScript ',
					N'FROM ', QUOTENAME(@oDb), N'.util.tablesGetScript(@tbl, NULL);'
				);
				
				-- Передаємо повне ім'я таблиці: [schema].[object]
				DECLARE @fullTableName NVARCHAR(256) = CONCAT(QUOTENAME(@oSch), N'.', QUOTENAME(@oObj));
				
				EXEC sys.sp_executesql @tblSql, 
					N'@tbl NVARCHAR(256), @out NVARCHAR(MAX) OUTPUT', 
					@tbl = @fullTableName, 
					@out = @tblOut OUTPUT;

				IF @tblOut IS NOT NULL AND LEN(@tblOut) > 0
				BEGIN
					SET @script = CONCAT(@script, N'--  TABLE: ', QUOTENAME(@oDb), N'.', QUOTENAME(@oSch), N'.', QUOTENAME(@oObj), N' ', @crlf, @tblOut, @crlf, @crlf);
				END;
				ELSE
				BEGIN
					SET @script = CONCAT(@script, N'-- SKIP: util.tablesGetScript не повернув скрипт для ', QUOTENAME(@oDb), N'.', QUOTENAME(@oSch), N'.', QUOTENAME(@oObj), @crlf, @crlf);
				END;
			END TRY
			BEGIN CATCH
				-- Пропускаємо відсутні таблиці або будь-яку помилку процедури
				SET @script = CONCAT(@script, N'-- SKIP: таблиця відсутня або не згенерувалась: ', QUOTENAME(@oDb), N'.', QUOTENAME(@oSch), N'.', QUOTENAME(@oObj), N' | Error ', ERROR_NUMBER(), N': ', ERROR_MESSAGE(), @crlf, @crlf);
			END CATCH;
		END;
		ELSE IF @oType IN ('V', 'P', 'FN', 'TF', 'IF', 'TR')
		BEGIN
			DECLARE @def NVARCHAR(MAX) = NULL;
			BEGIN TRY
				DECLARE @defSql NVARCHAR(MAX)
					= CONCAT(
							N'USE ', QUOTENAME(@oDb), N';
DECLARE @full sysname = CONCAT(QUOTENAME(@s), N''.'', QUOTENAME(@o));
SELECT @d = OBJECT_DEFINITION(OBJECT_ID(@full));'
						);
				EXEC sys.sp_executesql @defSql, N'@s sysname, @o sysname, @d nvarchar(max) OUTPUT', @s = @oSch, @o = @oObj, @d = @def OUTPUT;

				IF @def IS NOT NULL
					SET @script
						= CONCAT(
								@script,
								N'--  MODULE: ',
								QUOTENAME(@oDb),
								N'.',
								QUOTENAME(@oSch),
								N'.',
								QUOTENAME(@oObj),
								N' [',
								@oType,
								N'] ',
								@crlf,
								@def,
								@crlf,
								@crlf
							);
				ELSE
					SET @script
						= CONCAT(
								@script,
								N'-- SKIP: не знайдено визначення для ',
								QUOTENAME(@oDb),
								N'.',
								QUOTENAME(@oSch),
								N'.',
								QUOTENAME(@oObj),
								N' [',
								@oType,
								N']',
								@crlf,
								@crlf
							);
			END TRY
			BEGIN CATCH
				SET @script = CONCAT(@script, N'-- SKIP: помилка отримання визначення для ', QUOTENAME(@oDb), N'.', QUOTENAME(@oSch), N'.', QUOTENAME(@oObj), N' [', @oType, N'] | Error ', ERROR_NUMBER(), N': ', ERROR_MESSAGE(), @crlf, @crlf);
			END CATCH;
		END;
		ELSE IF @oType = 'SN'
		BEGIN
			BEGIN TRY
				DECLARE @synCreate NVARCHAR(MAX) = NULL;
				DECLARE @synSql NVARCHAR(MAX)
					= CONCAT(
							N'USE ',
							QUOTENAME(@oDb),
							N';
SELECT @c = 
    CONCAT(''CREATE SYNONYM '', QUOTENAME(@s), ''.'', QUOTENAME(@o), '' FOR '', s.base_object_name)
FROM sys.synonyms s
WHERE SCHEMA_NAME(s.schema_id)=@s AND s.name=@o;'
						);
				EXEC sys.sp_executesql @synSql, N'@s sysname, @o sysname, @c nvarchar(max) OUTPUT', @s = @oSch, @o = @oObj, @c = @synCreate OUTPUT;

				IF @synCreate IS NOT NULL
					SET @script = CONCAT(@script, N'--  SYNONYM: ', QUOTENAME(@oDb), N'.', QUOTENAME(@oSch), N'.', QUOTENAME(@oObj), N' ', @crlf, @synCreate, @crlf, @crlf);
				ELSE
					SET @script = CONCAT(@script, N'-- SKIP: синонім не знайдено ', QUOTENAME(@oDb), N'.', QUOTENAME(@oSch), N'.', QUOTENAME(@oObj), @crlf, @crlf);
			END TRY
			BEGIN CATCH
				SET @script = CONCAT(@script, N'-- SKIP: помилка генерації синоніма для ', QUOTENAME(@oDb), N'.', QUOTENAME(@oSch), N'.', QUOTENAME(@oObj), N' | Error ', ERROR_NUMBER(), N': ', ERROR_MESSAGE(), @crlf, @crlf);
			END CATCH;
		END;
 
		nextItem:
		FETCH NEXT FROM ord
		INTO
			@oDb,
			@oSch,
			@oObj,
			@oType;
	END;

	CLOSE ord;
	DEALLOCATE ord;
	SET @outputScript = @script;
	/*  8) Повернення як XML/CDATA  */
	--SET @outputScript = CONVERT(XML, CONCAT(N'<script><![CDATA[', ISNULL(@script, N''), N']]></script>'));
END;

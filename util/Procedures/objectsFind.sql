/*
# Description
Процедура для пошуку об'єктів та їх елементів у всіх доступних базах даних.
Виконує пошук серед таблиць, представлень, процедур, функцій та інших об'єктів.
При @onlyMajor = 0 додатково шукає в колонках, параметрах та визначеннях модулів.

# Parameters
@filter NVARCHAR(128) = NULL - фільтр для пошуку (підтримує шаблони LIKE, NULL = всі об'єкти)
@onlyMajor BIT = 1 - режим пошуку:
	1 = тільки об'єкти (таблиці, представлення, процедури, функції тощо)
	0 = об'єкти + колонки + параметри + пошук у визначеннях модулів

# Returns
ResultSet - таблиця з інформацією про знайдені елементи:
- databaseName NVARCHAR(128) - назва бази даних
- schemaName NVARCHAR(128) - назва схеми
- objectName NVARCHAR(128) - назва об'єкта
- fullName NVARCHAR(512) - повна назва у форматі [database].[schema].[object]
- objectType NVARCHAR(60) - тип об'єкта
- typeDesc NVARCHAR(60) - опис типу об'єкта
- elementType NVARCHAR(20) - тип елемента (Object, Column, Parameter, Definition)
- elementName NVARCHAR(128) - назва елемента (для колонок/параметрів)
- matchInfo NVARCHAR(MAX) - додаткова інформація про збіг

# Usage
-- Знайти всі об'єкти в усіх базах
EXEC util.objectsFind;

-- Знайти об'єкти за назвою (тільки об'єкти)
EXEC util.objectsFind @filter = 'metadata%', @onlyMajor = 1;

-- Знайти об'єкти в конкретній схемі
EXEC util.objectsFind @filter = 'util.%', @onlyMajor = 1;

-- Повний пошук: об'єкти + колонки + параметри + визначення
EXEC util.objectsFind @filter = '%GetScript%', @onlyMajor = 0;

-- Пошук в колонках та параметрах
EXEC util.objectsFind @filter = 'userId', @onlyMajor = 0;
*/
CREATE OR ALTER PROCEDURE util.objectsFind
	@filter NVARCHAR(128) = NULL,
	@onlyMajor BIT = 1
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	-- Якщо фільтр не заданий, показуємо всі об'єкти
	IF @filter IS NULL
		SET @filter = '%';

	-- Створюємо тимчасову таблицю для результатів
	CREATE TABLE #results (
		databaseName NVARCHAR(128),
		schemaName NVARCHAR(128),
		objectName NVARCHAR(128),
		fullName NVARCHAR(512),
		objectType NVARCHAR(60),
		typeDesc NVARCHAR(60),
		elementType NVARCHAR(20),
		elementName NVARCHAR(128),
		matchInfo NVARCHAR(MAX)
	);

	-- Нормалізуємо фільтр для пошуку
	DECLARE @schemaFilter NVARCHAR(128);
	DECLARE @objectFilter NVARCHAR(128);

	-- Перевіряємо чи є в фільтрі точка (розділювач схеми та об'єкта)
	IF CHARINDEX('.', @filter) > 0
	BEGIN
		-- Розділяємо на схему та об'єкт
		SET @schemaFilter = PARSENAME(@filter, 2);
		SET @objectFilter = PARSENAME(@filter, 1);
		
		-- Якщо не вказана схема, використовуємо шаблон
		IF @schemaFilter IS NULL
			SET @schemaFilter = '%';
		IF @objectFilter IS NULL
			SET @objectFilter = '%';
	END
	ELSE
	BEGIN
		-- Шукаємо в усіх схемах за назвою об'єкта
		SET @schemaFilter = '%';
		SET @objectFilter = @filter;
	END

	-- Динамічний SQL для пошуку в кожній базі даних
	DECLARE @dbName NVARCHAR(128);
	DECLARE @sql NVARCHAR(MAX);

	DECLARE dbCursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT name
		FROM sys.databases (NOLOCK)
		WHERE 
			state_desc = 'ONLINE'
			AND user_access_desc = 'MULTI_USER'
			AND is_read_only = 0
			AND database_id > 4 -- Пропускаємо системні бази
			AND HAS_DBACCESS(name) = 1;

	OPEN dbCursor;
	FETCH NEXT FROM dbCursor INTO @dbName;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
			-- Пошук об'єктів
			SET @sql = N'
			USE ' + QUOTENAME(@dbName) + N';
			
			INSERT INTO #results (databaseName, schemaName, objectName, fullName, objectType, typeDesc, elementType, elementName, matchInfo)
			SELECT
				DB_NAME() databaseName,
				SCHEMA_NAME(o.schema_id) schemaName,
				o.name objectName,
				CONCAT(QUOTENAME(DB_NAME()), ''.'', QUOTENAME(SCHEMA_NAME(o.schema_id)), ''.'', QUOTENAME(o.name)) fullName,
				o.type objectType,
				o.type_desc typeDesc,
				''Object'' elementType,
				NULL elementName,
				NULL matchInfo
			FROM sys.objects o (NOLOCK)
			WHERE
				o.is_ms_shipped = 0
				AND SCHEMA_NAME(o.schema_id) LIKE @schemaFilter
				AND o.name LIKE @objectFilter
				AND o.type IN (''U'', ''V'', ''P'', ''FN'', ''IF'', ''TF'', ''TR'', ''SO'', ''SN'');';

			EXEC sp_executesql @sql, 
				N'@schemaFilter NVARCHAR(128), @objectFilter NVARCHAR(128)',
				@schemaFilter = @schemaFilter,
				@objectFilter = @objectFilter;

			-- Якщо @onlyMajor = 0, шукаємо також колонки, параметри та в визначеннях
			IF @onlyMajor = 0
			BEGIN
				-- Пошук в колонках
				SET @sql = N'
				USE ' + QUOTENAME(@dbName) + N';
				
				INSERT INTO #results (databaseName, schemaName, objectName, fullName, objectType, typeDesc, elementType, elementName, matchInfo)
				SELECT
					DB_NAME() databaseName,
					SCHEMA_NAME(o.schema_id) schemaName,
					o.name objectName,
					CONCAT(QUOTENAME(DB_NAME()), ''.'', QUOTENAME(SCHEMA_NAME(o.schema_id)), ''.'', QUOTENAME(o.name)) fullName,
					o.type objectType,
					o.type_desc typeDesc,
					''Column'' elementType,
					c.name elementName,
					CONCAT(''Column: '', c.name, '' ('', TYPE_NAME(c.user_type_id), '')'') matchInfo
				FROM sys.objects o (NOLOCK)
					INNER JOIN sys.columns c (NOLOCK) ON o.object_id = c.object_id
				WHERE
					o.is_ms_shipped = 0
					AND c.name LIKE @objectFilter
					AND o.type IN (''U'', ''V'');';

				EXEC sp_executesql @sql,
					N'@objectFilter NVARCHAR(128)',
					@objectFilter = @objectFilter;

				-- Пошук в параметрах
				SET @sql = N'
				USE ' + QUOTENAME(@dbName) + N';
				
				INSERT INTO #results (databaseName, schemaName, objectName, fullName, objectType, typeDesc, elementType, elementName, matchInfo)
				SELECT
					DB_NAME() databaseName,
					SCHEMA_NAME(o.schema_id) schemaName,
					o.name objectName,
					CONCAT(QUOTENAME(DB_NAME()), ''.'', QUOTENAME(SCHEMA_NAME(o.schema_id)), ''.'', QUOTENAME(o.name)) fullName,
					o.type objectType,
					o.type_desc typeDesc,
					''Parameter'' elementType,
					p.name elementName,
					CONCAT(''Parameter: '', p.name, '' ('', TYPE_NAME(p.user_type_id), '')'') matchInfo
				FROM sys.objects o (NOLOCK)
					INNER JOIN sys.parameters p (NOLOCK) ON o.object_id = p.object_id
				WHERE
					o.is_ms_shipped = 0
					AND p.name IS NOT NULL
					AND p.name LIKE @objectFilter
					AND o.type IN (''P'', ''FN'', ''IF'', ''TF'');';

				EXEC sp_executesql @sql,
					N'@objectFilter NVARCHAR(128)',
					@objectFilter = @objectFilter;

				-- Пошук в визначеннях модулів (sys.sql_modules)
				SET @sql = N'
				USE ' + QUOTENAME(@dbName) + N';
				
				INSERT INTO #results (databaseName, schemaName, objectName, fullName, objectType, typeDesc, elementType, elementName, matchInfo)
				SELECT
					DB_NAME() databaseName,
					SCHEMA_NAME(o.schema_id) schemaName,
					o.name objectName,
					CONCAT(QUOTENAME(DB_NAME()), ''.'', QUOTENAME(SCHEMA_NAME(o.schema_id)), ''.'', QUOTENAME(o.name)) fullName,
					o.type objectType,
					o.type_desc typeDesc,
					''Definition'' elementType,
					NULL elementName,
					''Found in module definition'' matchInfo
				FROM sys.objects o (NOLOCK)
					INNER JOIN sys.sql_modules m (NOLOCK) ON o.object_id = m.object_id
				WHERE
					o.is_ms_shipped = 0
					AND m.definition LIKE @searchPattern
					AND o.type IN (''V'', ''P'', ''FN'', ''IF'', ''TF'', ''TR'');';

				-- Для пошуку в definition додаємо wildcards
				DECLARE @searchPattern NVARCHAR(130) = N'%' + @objectFilter + N'%';

				EXEC sp_executesql @sql,
					N'@searchPattern NVARCHAR(130)',
					@searchPattern = @searchPattern;
			END

		END TRY
		BEGIN CATCH
			-- Ігноруємо помилки доступу до окремих баз даних
			PRINT 'Error accessing database: ' + @dbName + ' - ' + ERROR_MESSAGE();
		END CATCH

		FETCH NEXT FROM dbCursor INTO @dbName;
	END

	CLOSE dbCursor;
	DEALLOCATE dbCursor;

	-- Виводимо результати
	SELECT
		databaseName,
		schemaName,
		objectName,
		fullName,
		objectType,
		typeDesc,
		elementType,
		elementName,
		matchInfo
	FROM #results
	ORDER BY
		databaseName,
		schemaName,
		objectName,
		elementType,
		elementName;

	-- Очищаємо тимчасову таблицю
	DROP TABLE #results;
END;
GO

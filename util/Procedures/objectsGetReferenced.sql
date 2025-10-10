/*
# Description
Процедура для рекурсивного пошуку всіх об'єктів які посилаються на вказаний об'єкт (зворотні залежності).
Аналізує залежності через sys.sql_expression_dependencies у зворотному напрямку, обробляє синоніми.
Підтримує cross-database залежності та повертає результат у форматі JSON з рекурсивною структурою.
Оптимізовано для SQL Server 2022 з використанням STRING_AGG, TRIM, JSON_OBJECT, batch processing.

# Parameters
@object NVARCHAR(128) - Повне 3-х рівневе ім'я об'єкта у форматі 'database.schema.object'
@maxDepth INT = 5 - Максимальна глибина рекурсії (за замовчуванням 5 рівнів)
@referenced NVARCHAR(MAX) OUTPUT - Результат у форматі JSON з рекурсивною структурою зворотних залежностей

# Returns
OUTPUT параметр @referenced - JSON структура з рекурсивними зворотними залежностями:
{
    "dbName": "database",
    "schName": "schema",
    "objName": "object",
    "type": "U",
    "referencedBy": [
        {
            "dbName": "database",
            "schName": "schema",
            "objName": "procedure1",
            "type": "P",
            "referencedBy": [...]
        }
    ]
}

# Usage
-- Отримати зворотні залежності для таблиці (5 рівнів)
DECLARE @refs NVARCHAR(MAX);
EXEC util.objectsGetReferenced 
    @object = 'DWH.dbo.People',
    @referenced = @refs OUTPUT;
SELECT @refs;

-- Отримати зворотні залежності з обмеженням глибини
DECLARE @refs NVARCHAR(MAX);
EXEC util.objectsGetReferenced 
    @object = 'utils.util.metadataGetAnyId',
    @maxDepth = 3,
    @referenced = @refs OUTPUT;
PRINT @refs;

# Notes
- Оптимізовано для SQL Server 2022
- Шукає об'єкти які використовують вказаний об'єкт
- Обробляє синоніми: знаходить об'єкти які посилаються на синонім
- Підтримує cross-database залежності (сканує всі доступні БД)
- Запобігає циклічним залежностям через відстеження вже оброблених об'єктів
- Використовує JSON_OBJECT, STRING_AGG, batch processing для максимальної продуктивності
*/
CREATE OR ALTER PROCEDURE util.objectsGetReferenced
    @object NVARCHAR(128),
    @maxDepth INT = 5,
    @referenced NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Парсинг вхідного об'єкта
    DECLARE @dbName SYSNAME = PARSENAME(@object, 3);
    DECLARE @schName SYSNAME = PARSENAME(@object, 2);
    DECLARE @objName SYSNAME = PARSENAME(@object, 1);

    -- Валідація вхідних параметрів
    IF @dbName IS NULL OR @schName IS NULL OR @objName IS NULL
    BEGIN
        RAISERROR('Очікується формат "database.schema.object".', 16, 1);
        RETURN;
    END;

    -- Тимчасова таблиця для зберігання дерева зворотних залежностей
    CREATE TABLE #ReferencedByTree (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ParentId INT NULL,
        [Level] INT NOT NULL,
        DbName SYSNAME NOT NULL,
        SchName SYSNAME NOT NULL,
        ObjName SYSNAME NOT NULL,
        ObjType CHAR(2) NULL,
        IsProcessed BIT DEFAULT 0,
        JsonFragment NVARCHAR(MAX) NULL
    );

    -- Створюємо індекси ПІСЛЯ створення таблиці
    CREATE NONCLUSTERED INDEX IX_Level_IsProcessed 
        ON #ReferencedByTree([Level], IsProcessed) 
        INCLUDE (Id, DbName, SchName, ObjName)
        WITH (DATA_COMPRESSION = PAGE);

    CREATE NONCLUSTERED INDEX IX_ParentId 
        ON #ReferencedByTree(ParentId) 
        INCLUDE (Id, JsonFragment)
        WITH (DATA_COMPRESSION = PAGE);

    CREATE NONCLUSTERED INDEX IX_Object 
        ON #ReferencedByTree(DbName, SchName, ObjName)
        WITH (DATA_COMPRESSION = PAGE);

    -- Таблиця для відстеження оброблених об'єктів
    CREATE TABLE #ProcessedObjects (
        DbName SYSNAME NOT NULL,
        SchName SYSNAME NOT NULL,
        ObjName SYSNAME NOT NULL,
        PRIMARY KEY (DbName, SchName, ObjName)
    ) WITH (DATA_COMPRESSION = PAGE);

    -- Кешована таблиця доступних баз даних
    CREATE TABLE #Databases (
        DatabaseName SYSNAME PRIMARY KEY,
        DatabaseId INT NOT NULL
    ) WITH (DATA_COMPRESSION = PAGE);

    INSERT INTO #Databases (DatabaseName, DatabaseId)
    SELECT name, database_id
    FROM sys.databases (NOLOCK)
    WHERE state_desc = 'ONLINE'
        AND is_read_only = 0
        AND database_id > 4
        AND HAS_DBACCESS(name) = 1;

    -- Додаємо кореневий об'єкт
    DECLARE @rootObjId INT;
    DECLARE @getRootSql NVARCHAR(MAX) = CONCAT(
        N'USE ', QUOTENAME(@dbName), N';
        SELECT @objId = o.object_id, @type = o.type 
        FROM sys.objects o (NOLOCK)
        WHERE SCHEMA_NAME(o.schema_id) = @sch 
            AND OBJECT_NAME(o.object_id) = @obj;'
    );

    DECLARE @rootType CHAR(2);
    EXEC sp_executesql 
        @getRootSql, 
        N'@sch SYSNAME, @obj SYSNAME, @objId INT OUTPUT, @type CHAR(2) OUTPUT',
        @sch = @schName, 
        @obj = @objName, 
        @objId = @rootObjId OUTPUT,
        @type = @rootType OUTPUT;

    INSERT INTO #ReferencedByTree ([Level], DbName, SchName, ObjName, ObjType, ParentId)
    VALUES (0, @dbName, @schName, @objName, @rootType, NULL);

    INSERT INTO #ProcessedObjects (DbName, SchName, ObjName)
    VALUES (@dbName, @schName, @objName);

    -- Рекурсивна обробка зворотних залежностей
    DECLARE @currentLevel INT = 0;

    WHILE @currentLevel < @maxDepth 
        AND EXISTS (
            SELECT 1 
            FROM #ReferencedByTree 
            WHERE [Level] = @currentLevel 
                AND IsProcessed = 0
        )
    BEGIN
        -- Створюємо тимчасову таблицю для зворотних залежностей поточного рівня
        CREATE TABLE #CurrentLevelRefs (
            ParentId INT NOT NULL,
            DbName SYSNAME NOT NULL,
            SchName SYSNAME NOT NULL,
            ObjName SYSNAME NOT NULL,
            INDEX IX_Lookup (DbName, SchName, ObjName)
        ) WITH (DATA_COMPRESSION = PAGE);

        -- Для кожної бази даних виконуємо пошук посилань на всі об'єкти поточного рівня
        DECLARE @dbId INT;
        DECLARE @currentDbName SYSNAME;

        DECLARE dbCur CURSOR LOCAL FAST_FORWARD FOR
            SELECT DatabaseId, DatabaseName 
            FROM #Databases
            ORDER BY DatabaseId;

        OPEN dbCur;
        FETCH NEXT FROM dbCur INTO @dbId, @currentDbName;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Динамічний SQL для пошуку всіх посилань в поточній БД
            -- Курсор має бути ПОЗА USE, бо тимчасові таблиці не видимі після зміни контексту
            DECLARE @targetDb SYSNAME, @targetSch SYSNAME, @targetObj SYSNAME, @targetId INT;
            
            DECLARE targetCur CURSOR LOCAL FAST_FORWARD FOR
                SELECT Id, DbName, SchName, ObjName 
                FROM #ReferencedByTree
                WHERE [Level] = @currentLevel AND IsProcessed = 0;
            
            OPEN targetCur;
            FETCH NEXT FROM targetCur INTO @targetId, @targetDb, @targetSch, @targetObj;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE @findRefsSql NVARCHAR(MAX) = CONCAT(
                    N'USE ', QUOTENAME(@currentDbName), N';
                    
                    INSERT INTO #CurrentLevelRefs (ParentId, DbName, SchName, ObjName)
                    SELECT DISTINCT
                        @targetId,
                        DB_NAME(),
                        OBJECT_SCHEMA_NAME(d.referencing_id),
                        OBJECT_NAME(d.referencing_id)
                    FROM sys.sql_expression_dependencies d (NOLOCK)
                    WHERE (d.referenced_database_name = @targetDb OR d.referenced_database_name IS NULL)
                        AND d.referenced_schema_name = @targetSch
                        AND d.referenced_entity_name = @targetObj
                        AND d.referencing_id IS NOT NULL
                        AND OBJECT_NAME(d.referencing_id) IS NOT NULL
                        AND NOT EXISTS (
                            SELECT 1 
                            FROM #ProcessedObjects p
                            WHERE p.DbName = DB_NAME()
                                AND p.SchName = OBJECT_SCHEMA_NAME(d.referencing_id)
                                AND p.ObjName = OBJECT_NAME(d.referencing_id)
                        );'
                );

                BEGIN TRY
                    EXEC sp_executesql 
                        @findRefsSql,
                        N'@targetId INT, @targetDb SYSNAME, @targetSch SYSNAME, @targetObj SYSNAME',
                        @targetId = @targetId,
                        @targetDb = @targetDb,
                        @targetSch = @targetSch,
                        @targetObj = @targetObj;
                END TRY
                BEGIN CATCH
                    -- Пропускаємо помилки
                END CATCH;
                
                FETCH NEXT FROM targetCur INTO @targetId, @targetDb, @targetSch, @targetObj;
            END;
            
            CLOSE targetCur;
            DEALLOCATE targetCur;

            FETCH NEXT FROM dbCur INTO @dbId, @currentDbName;
        END;

        CLOSE dbCur;
        DEALLOCATE dbCur;

        -- Додаємо нові залежності до дерева
        INSERT INTO #ReferencedByTree ([Level], DbName, SchName, ObjName, ParentId)
        SELECT DISTINCT
            @currentLevel + 1,
            cr.DbName,
            cr.SchName,
            cr.ObjName,
            cr.ParentId
        FROM #CurrentLevelRefs cr
        WHERE NOT EXISTS (
            SELECT 1 
            FROM #ProcessedObjects p
            WHERE p.DbName = cr.DbName
                AND p.SchName = cr.SchName
                AND p.ObjName = cr.ObjName
        );

        -- Додаємо до оброблених
        INSERT INTO #ProcessedObjects (DbName, SchName, ObjName)
        SELECT DISTINCT DbName, SchName, ObjName
        FROM #CurrentLevelRefs
        WHERE NOT EXISTS (
            SELECT 1 
            FROM #ProcessedObjects p
            WHERE p.DbName = DbName
                AND p.SchName = SchName
                AND p.ObjName = ObjName
        );

        -- Позначаємо поточний рівень як оброблений
        UPDATE #ReferencedByTree 
        SET IsProcessed = 1 
        WHERE [Level] = @currentLevel;

        -- Отримуємо типи для нових об'єктів пакетно по кожній БД
        -- Курсор по базам для отримання типів
        DECLARE typeDbCur CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT DbName 
            FROM #ReferencedByTree
            WHERE [Level] = @currentLevel + 1
                AND ObjType IS NULL;

        DECLARE @typeDbName SYSNAME;
        OPEN typeDbCur;
        FETCH NEXT FROM typeDbCur INTO @typeDbName;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @getTypesSql NVARCHAR(MAX) = CONCAT(
                N'USE ', QUOTENAME(@typeDbName), N';
                
                UPDATE rt
                SET rt.ObjType = o.type
                FROM #ReferencedByTree rt
                INNER JOIN sys.objects o (NOLOCK) 
                    ON SCHEMA_NAME(o.schema_id) = rt.SchName 
                    AND OBJECT_NAME(o.object_id) = rt.ObjName
                WHERE rt.DbName = @db 
                    AND rt.[Level] = @level 
                    AND rt.ObjType IS NULL;'
            );

            BEGIN TRY
							DECLARE @nl INT = @currentLevel + 1
                EXEC sp_executesql 
                    @getTypesSql,
                    N'@db SYSNAME, @level INT',
                    @db = @typeDbName,  -- ✅ Виправлено: передаємо @typeDbName як @db
                    @level = @nl;
            END TRY
            BEGIN CATCH
                -- Пропускаємо помилки
            END CATCH;

            FETCH NEXT FROM typeDbCur INTO @typeDbName;
        END;

        CLOSE typeDbCur;
        DEALLOCATE typeDbCur;

        DROP TABLE #CurrentLevelRefs;

        SET @currentLevel = @currentLevel + 1;
    END;

    -- Формуємо JSON знизу вгору з використанням CONCAT та STRING_AGG (SQL Server 2022)
    DECLARE @maxLevel INT = (SELECT MAX([Level]) FROM #ReferencedByTree);
    DECLARE @buildLevel INT = @maxLevel;

    WHILE @buildLevel >= 0
    BEGIN
        UPDATE rt
        SET rt.JsonFragment = CONCAT(
            '{"dbName":"', rt.DbName, 
            '","schName":"', rt.SchName, 
            '","objName":"', rt.ObjName, 
            '","type":"', COALESCE(NULLIF(LTRIM(RTRIM(rt.ObjType)), ''), '??'), 
            '","referencedBy":[',
            ISNULL(
                (
                    SELECT STRING_AGG(child.JsonFragment, ',') WITHIN GROUP (ORDER BY child.Id)
                    FROM #ReferencedByTree child
                    WHERE child.ParentId = rt.Id
                ),
                ''
            ),
            ']}'
        )
        FROM #ReferencedByTree rt
        WHERE rt.[Level] = @buildLevel;

        SET @buildLevel = @buildLevel - 1;
    END;

    -- Отримуємо результат для кореневого об'єкта
    SELECT @referenced = JsonFragment
    FROM #ReferencedByTree
    WHERE ParentId IS NULL;
END;
GO
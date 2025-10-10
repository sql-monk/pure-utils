/*
# Description
Знаходить всі об'єкти які залежать від не існуючих об'єктів в базі даних через аналіз залежностей.
Включає views які посилаються на не існуючі таблиці, процедури які викликають не існуючі об'єкти,
та рекурсивний пошук всього ланцюжка залежностей. Якщо вказано конкретний об'єкт, перевіряє 
лише ланцюжок який починається із вказаного об'єкта.

# Parameters
@object NVARCHAR(128) = NULL - назва об'єкта для перевірки ланцюжка залежностей 
    (NULL = перевіряє всі об'єкти в базі даних)

# Returns
TABLE - Повертає таблицю з колонками:
- referencingObjectId INT - ідентифікатор об'єкта який посилається
- referencingObjectName NVARCHAR(256) - повна назва об'єкта який посилається
- referencingObjectType NVARCHAR(60) - тип об'єкта який посилається
- referencedObjectName NVARCHAR(256) - назва об'єкта на який посилається (не існує)
- referencedDatabaseName NVARCHAR(128) - база даних не існуючого об'єкта
- referencedSchemaName NVARCHAR(128) - схема не існуючого об'єкта  
- referencedEntityName NVARCHAR(128) - назва не існуючого об'єкта
- dependencyLevel INT - рівень вкладеності в ланцюжку залежностей
- invalidReason NVARCHAR(200) - причина чому посилання є невалідним

# Usage
-- Знайти всі об'єкти з невалідними посиланнями
SELECT * FROM util.modulesRecureSearchInvalidReferences(NULL);

-- Перевірити ланцюжок залежностей конкретного об'єкта
SELECT * FROM util.modulesRecureSearchInvalidReferences('dbo.myView');

-- Групування по типах проблем
SELECT invalidReason, COUNT(*) as IssueCount
FROM util.modulesRecureSearchInvalidReferences(NULL)
GROUP BY invalidReason
ORDER BY IssueCount DESC;
*/
CREATE OR ALTER FUNCTION util.modulesRecureSearchInvalidReferences(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
    WITH InvalidObjects AS (
        -- Крок 1: Знаходимо всі інвалідні об'єкти (на які посилаються, але які не існують)
        SELECT DISTINCT
            d.referenced_database_name,
            d.referenced_schema_name,
            d.referenced_entity_name,
            d.is_ambiguous,
            CASE
                -- База даних не існує
                WHEN d.referenced_database_name IS NOT NULL 
                     AND d.referenced_database_name <> DB_NAME()
                     AND DB_ID(d.referenced_database_name) IS NULL
                THEN N'База даних не існує: ' + d.referenced_database_name
                
                -- Схема не існує в поточній базі даних
                WHEN (d.referenced_database_name IS NULL OR d.referenced_database_name = DB_NAME())
                     AND d.referenced_schema_name IS NOT NULL
                     AND SCHEMA_ID(d.referenced_schema_name) IS NULL
                THEN N'Схема не існує: ' + d.referenced_schema_name
                
                -- Об'єкт не існує в існуючій схемі
                WHEN (d.referenced_database_name IS NULL OR d.referenced_database_name = DB_NAME())
                     AND d.referenced_schema_name IS NOT NULL
                     AND d.referenced_entity_name IS NOT NULL
                     AND SCHEMA_ID(d.referenced_schema_name) IS NOT NULL
                     AND OBJECT_ID(QUOTENAME(d.referenced_schema_name) + '.' + QUOTENAME(d.referenced_entity_name)) IS NULL
                THEN N'Об''єкт не існує в схемі: ' + d.referenced_schema_name + '.' + d.referenced_entity_name
                
                -- Двозначні посилання
                WHEN d.is_ambiguous = 1
                THEN N'Двозначне посилання на об''єкт'
                
                -- Невизначена назва об'єкта
                WHEN d.referenced_entity_name IS NULL AND d.referenced_schema_name IS NOT NULL
                THEN N'Невизначена назва об''єкта в схемі: ' + d.referenced_schema_name
                
                ELSE NULL
            END as invalidReason
        FROM sys.sql_expression_dependencies d (NOLOCK)
        WHERE 
            -- Фільтруємо тільки інваліди
            (
                -- База даних не існує
                (d.referenced_database_name IS NOT NULL 
                 AND d.referenced_database_name <> DB_NAME()
                 AND DB_ID(d.referenced_database_name) IS NULL)
                OR
                -- Схема не існує
                (d.referenced_schema_name IS NOT NULL
                 AND SCHEMA_ID(d.referenced_schema_name) IS NULL
                 AND (d.referenced_database_name IS NULL OR d.referenced_database_name = DB_NAME()))
                OR
                -- Об'єкт не існує
                (d.referenced_entity_name IS NOT NULL
                 AND OBJECT_ID(QUOTENAME(d.referenced_schema_name) + '.' + QUOTENAME(d.referenced_entity_name)) IS NULL
                 AND SCHEMA_ID(d.referenced_schema_name) IS NOT NULL
                 AND (d.referenced_database_name IS NULL OR d.referenced_database_name = DB_NAME()))
                OR
                -- Двозначні посилання
                d.is_ambiguous = 1
                OR
                -- Невизначені назви
                (d.referenced_entity_name IS NULL AND d.referenced_schema_name IS NOT NULL)
            )
    ),
    ReferencingObjects AS (
        -- Крок 2: Знаходимо хто посилається на інвалідні об'єкти (рекурсивно)
        SELECT
            d.referencing_id,
            io.referenced_database_name,
            io.referenced_schema_name,
            io.referenced_entity_name,
            io.is_ambiguous,
            io.invalidReason,
            1 as dependencyLevel
        FROM sys.sql_expression_dependencies d (NOLOCK)
        INNER JOIN InvalidObjects io ON 
            ISNULL(d.referenced_database_name, DB_NAME()) = ISNULL(io.referenced_database_name, DB_NAME())
            AND ISNULL(d.referenced_schema_name, '') = ISNULL(io.referenced_schema_name, '')
            AND ISNULL(d.referenced_entity_name, '') = ISNULL(io.referenced_entity_name, '')
        WHERE (@object IS NULL OR d.referencing_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
            AND (@object IS NULL OR ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)) IS NOT NULL)
            
        UNION ALL
        
        -- Крок 3: Рекурсивно шукаємо хто посилається на ті об'єкти, що мають інвалідні залежності
        SELECT
            d.referencing_id,
            ro.referenced_database_name,
            ro.referenced_schema_name,
            ro.referenced_entity_name,
            ro.is_ambiguous,
            ro.invalidReason,
            ro.dependencyLevel + 1
        FROM sys.sql_expression_dependencies d (NOLOCK)
        INNER JOIN ReferencingObjects ro ON d.referenced_id = ro.referencing_id
        WHERE ro.dependencyLevel < 10 -- Захист від циклічних залежностей
    )
    -- Крок 4: Формуємо фінальний результат
    SELECT
        ro.referencing_id as referencingObjectId,
        util.metadataGetObjectName(ro.referencing_id, DEFAULT) as referencingObjectName,
        o.type_desc as referencingObjectType,
        CONCAT(
            CASE WHEN ro.referenced_database_name IS NOT NULL 
                 THEN QUOTENAME(ro.referenced_database_name) + '.' 
                 ELSE '' END,
            CASE WHEN ro.referenced_schema_name IS NOT NULL
                 THEN QUOTENAME(ro.referenced_schema_name) + '.'
                 ELSE '' END,
            CASE WHEN ro.referenced_entity_name IS NOT NULL
                 THEN QUOTENAME(ro.referenced_entity_name)
                 ELSE N'<невизначено>' END
        ) as referencedObjectName,
        ro.referenced_database_name as referencedDatabaseName,
        ro.referenced_schema_name as referencedSchemaName,
        ro.referenced_entity_name as referencedEntityName,
        ro.dependencyLevel,
        ro.invalidReason
    FROM ReferencingObjects ro
    LEFT JOIN sys.objects o (NOLOCK) ON ro.referencing_id = o.object_id
    WHERE (@object IS NULL OR 
           (ro.dependencyLevel = 1 AND ro.referencing_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object))) OR
           (ro.dependencyLevel > 1))
);
GO
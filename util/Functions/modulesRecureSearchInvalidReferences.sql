/*
# Description
��������� �� ��'���� �� �������� �� �� �������� ��'���� � ��� ����� ����� ����� �����������.
������ views �� ����������� �� �� ������� �������, ��������� �� ���������� �� ������� ��'����,
�� ����������� ����� ������ �������� �����������. ���� ������� ���������� ��'���, �������� 
���� �������� ���� ���������� �� ��������� ��'����.

# Parameters
@object NVARCHAR(128) = NULL - ����� ��'���� ��� �������� �������� ����������� 
    (NULL = �������� �� ��'���� � ��� �����)

# Returns
TABLE - ������� ������� � ���������:
- referencingObjectId INT - ������������� ��'���� ���� ����������
- referencingObjectName NVARCHAR(256) - ����� ����� ��'���� ���� ����������
- referencingObjectType NVARCHAR(60) - ��� ��'���� ���� ����������
- referencedObjectName NVARCHAR(256) - ����� ��'���� �� ���� ���������� (�� ����)
- referencedDatabaseName NVARCHAR(128) - ���� ����� �� ��������� ��'����
- referencedSchemaName NVARCHAR(128) - ����� �� ��������� ��'����  
- referencedEntityName NVARCHAR(128) - ����� �� ��������� ��'����
- dependencyLevel INT - ����� ���������� � �������� �����������
- invalidReason NVARCHAR(200) - ������� ���� ��������� � ���������

# Usage
-- ������ �� ��'���� � ���������� �����������
SELECT * FROM util.modulesRecureSearchInvalidReferences(NULL);

-- ��������� �������� ����������� ����������� ��'����
SELECT * FROM util.modulesRecureSearchInvalidReferences('dbo.myView');

-- ���������� �� ����� �������
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
        -- ���� 1: ��������� �� ������� ��'���� (�� �� �����������, ��� �� �� �������)
        SELECT DISTINCT
            d.referenced_database_name,
            d.referenced_schema_name,
            d.referenced_entity_name,
            d.is_ambiguous,
            CASE
                -- ���� ����� �� ����
                WHEN d.referenced_database_name IS NOT NULL 
                     AND d.referenced_database_name <> DB_NAME()
                     AND DB_ID(d.referenced_database_name) IS NULL
                THEN N'���� ����� �� ����: ' + d.referenced_database_name
                
                -- ����� �� ���� � ������� ��� �����
                WHEN (d.referenced_database_name IS NULL OR d.referenced_database_name = DB_NAME())
                     AND d.referenced_schema_name IS NOT NULL
                     AND SCHEMA_ID(d.referenced_schema_name) IS NULL
                THEN N'����� �� ����: ' + d.referenced_schema_name
                
                -- ��'��� �� ���� � �������� ����
                WHEN (d.referenced_database_name IS NULL OR d.referenced_database_name = DB_NAME())
                     AND d.referenced_schema_name IS NOT NULL
                     AND d.referenced_entity_name IS NOT NULL
                     AND SCHEMA_ID(d.referenced_schema_name) IS NOT NULL
                     AND OBJECT_ID(QUOTENAME(d.referenced_schema_name) + '.' + QUOTENAME(d.referenced_entity_name)) IS NULL
                THEN N'��''��� �� ���� � ����: ' + d.referenced_schema_name + '.' + d.referenced_entity_name
                
                -- �������� ���������
                WHEN d.is_ambiguous = 1
                THEN N'��������� ��������� �� ��''���'
                
                -- ����������� ����� ��'����
                WHEN d.referenced_entity_name IS NULL AND d.referenced_schema_name IS NOT NULL
                THEN N'����������� ����� ��''���� � ����: ' + d.referenced_schema_name
                
                ELSE NULL
            END as invalidReason
        FROM sys.sql_expression_dependencies d (NOLOCK)
        WHERE 
            -- Գ������� ����� �������
            (
                -- ���� ����� �� ����
                (d.referenced_database_name IS NOT NULL 
                 AND d.referenced_database_name <> DB_NAME()
                 AND DB_ID(d.referenced_database_name) IS NULL)
                OR
                -- ����� �� ����
                (d.referenced_schema_name IS NOT NULL
                 AND SCHEMA_ID(d.referenced_schema_name) IS NULL
                 AND (d.referenced_database_name IS NULL OR d.referenced_database_name = DB_NAME()))
                OR
                -- ��'��� �� ����
                (d.referenced_entity_name IS NOT NULL
                 AND OBJECT_ID(QUOTENAME(d.referenced_schema_name) + '.' + QUOTENAME(d.referenced_entity_name)) IS NULL
                 AND SCHEMA_ID(d.referenced_schema_name) IS NOT NULL
                 AND (d.referenced_database_name IS NULL OR d.referenced_database_name = DB_NAME()))
                OR
                -- �������� ���������
                d.is_ambiguous = 1
                OR
                -- ���������� �����
                (d.referenced_entity_name IS NULL AND d.referenced_schema_name IS NOT NULL)
            )
    ),
    ReferencingObjects AS (
        -- ���� 2: ��������� ��� ���������� �� ������� ��'���� (����������)
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
        
        -- ���� 3: ���������� ������ ��� ���������� �� � ��'����, �� ����� ������� ���������
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
        WHERE ro.dependencyLevel < 10 -- ������ �� �������� �����������
    )
    -- ���� 4: ������� ��������� ���������
    SELECT
        ro.referencing_id as referencingObjectId,
        util.metadataGetObjectName(ro.referencing_id) as referencingObjectName,
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
                 ELSE N'<�����������>' END
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
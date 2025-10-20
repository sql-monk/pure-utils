/*
# Description
Scalar function для отримання детальної інформації про конкретну таблицю.
Повертає валідний JSON з повною інформацією про таблицю включаючи колонки та індекси.

# Parameters
@name NVARCHAR(128) - назва таблиці (може бути schema.table або просто table)

# Returns
NVARCHAR(MAX) - валідний JSON з детальною інформацією про таблицю

# Usage
-- Отримати інформацію про таблицю
SELECT pupy.tablesGet('dbo.MyTable');

-- Використання в HTTP запиті
-- GET /tables/get?name=dbo.MyTable
*/
CREATE OR ALTER FUNCTION pupy.tablesGet(@name NVARCHAR(128))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    DECLARE @objectId INT;
    
    -- Отримання object_id
    SET @objectId = ISNULL(TRY_CONVERT(INT, @name), OBJECT_ID(@name));
    
    IF @objectId IS NULL
    BEGIN
        RETURN JSON_MODIFY('{}', '$.error', 'Table not found');
    END
    
    -- Формування JSON з інформацією про таблицю
    SELECT @result = (
        SELECT
            OBJECT_SCHEMA_NAME(t.object_id) schemaName,
            t.name tableName,
            t.object_id objectId,
            CONVERT(VARCHAR(23), t.create_date, 126) createDate,
            CONVERT(VARCHAR(23), t.modify_date, 126) modifyDate,
            (
                SELECT
                    c.column_id columnId,
                    c.name columnName,
                    TYPE_NAME(c.user_type_id) dataType,
                    c.max_length maxLength,
                    c.precision [precision],
                    c.scale scale,
                    c.is_nullable isNullable,
                    c.is_identity isIdentity
                FROM sys.columns c (NOLOCK)
                WHERE c.object_id = t.object_id
                ORDER BY c.column_id
                FOR JSON PATH
            ) columns,
            (
                SELECT
                    i.index_id indexId,
                    i.name indexName,
                    i.type_desc indexType,
                    i.is_unique isUnique,
                    i.is_primary_key isPrimaryKey
                FROM sys.indexes i (NOLOCK)
                WHERE i.object_id = t.object_id
                ORDER BY i.index_id
                FOR JSON PATH
            ) indexes
        FROM sys.tables t (NOLOCK)
        WHERE t.object_id = @objectId
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
    
    RETURN ISNULL(@result, '{}');
END;
GO

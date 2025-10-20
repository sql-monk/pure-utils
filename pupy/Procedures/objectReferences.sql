/*
# Description
Stored procedure для отримання переліку об'єктів, на які посилається заданий об'єкт.
Повертає валідний JSON через OUTPUT параметр @response.

# Parameters
@object NVARCHAR(128) - назва об'єкта (може бути schema.object або просто object)
@response NVARCHAR(MAX) OUTPUT - валідний JSON з переліком залежностей

# Returns
Через @response OUTPUT параметр повертається JSON масив з об'єктами залежностей

# Usage
-- Виклик процедури
DECLARE @response NVARCHAR(MAX);
EXEC pupy.objectReferences @object = 'dbo.MyTable', @response = @response OUTPUT;
SELECT @response;

-- Використання в HTTP запиті
-- POST /pupy/objectReferences?object=dbo.MyTable
*/
CREATE OR ALTER PROCEDURE pupy.objectReferences
    @object NVARCHAR(128),
    @response NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    DECLARE @objectId INT;
    
    -- Отримання object_id
    SET @objectId = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object));
    
    IF @objectId IS NULL
    BEGIN
        SET @response = JSON_MODIFY('{}', '$.error', 'Object not found');
        RETURN;
    END
    
    -- Отримання залежностей
    SELECT @response = (
        SELECT
            OBJECT_SCHEMA_NAME(sed.referenced_id) referencedSchema,
            OBJECT_NAME(sed.referenced_id) referencedObject,
            sed.referenced_entity_name referencedEntityName,
            o.type_desc referencedObjectType,
            sed.is_ambiguous isAmbiguous,
            sed.is_selected isSelected,
            sed.is_updated isUpdated,
            sed.is_select_all isSelectAll
        FROM sys.sql_expression_dependencies sed (NOLOCK)
            LEFT JOIN sys.objects o (NOLOCK) ON sed.referenced_id = o.object_id
        WHERE sed.referencing_id = @objectId
            AND sed.referenced_id IS NOT NULL
        ORDER BY 
            OBJECT_SCHEMA_NAME(sed.referenced_id),
            OBJECT_NAME(sed.referenced_id)
        FOR JSON PATH
    );
    
    -- Якщо немає залежностей, повертаємо порожній масив
    SET @response = ISNULL(@response, '[]');
END;
GO

/*
# Description
Повертає детальну інформацію про об'єкт у форматі JSON.
Scalar Function для демонстрації endpoint GET /{resource}/{action}
Використовується для endpoint GET /api/objects/Get?name={name}

# Parameters
@name NVARCHAR(256) - ім'я об'єкта (може бути schema.object або просто object)

# Returns  
JSON string з детальною інформацією про об'єкт:
- objectId: ID об'єкта
- schemaName: Ім'я схеми
- objectName: Ім'я об'єкта
- objectType: Тип об'єкта (U, P, FN, тощо)
- objectTypeDesc: Опис типу
- createDate: Дата створення
- modifyDate: Дата останньої модифікації

# Usage
-- За повним ім'ям
SELECT api.objectsGet('dbo.Orders');

-- За коротким ім'ям
SELECT api.objectsGet('Orders');
*/
CREATE OR ALTER FUNCTION api.objectsGet(@name NVARCHAR(256))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @objectId INT = OBJECT_ID(@name);
    
    RETURN (
        SELECT 
            o.object_id objectId,
            OBJECT_SCHEMA_NAME(o.object_id) schemaName,
            o.name objectName,
            o.type objectType,
            o.type_desc objectTypeDesc,
            o.create_date createDate,
            o.modify_date modifyDate
        FROM sys.objects o (NOLOCK)
        WHERE o.object_id = @objectId
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
END;
GO

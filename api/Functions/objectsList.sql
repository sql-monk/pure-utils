/*
# Description
Повертає список об'єктів бази даних з можливістю фільтрації.
Table-Valued Function для демонстрації endpoint GET /{resource}/{action}
Використовується для endpoint GET /api/objects/List?schema={schema}&type={type}

# Parameters
@schema NVARCHAR(128) = NULL - фільтр по схемі (якщо NULL, то всі схеми)
@type NVARCHAR(60) = NULL - фільтр по типу об'єкта (U, P, FN, тощо)

# Returns  
Таблиця з колонками:
- schemaName: Ім'я схеми
- objectName: Ім'я об'єкта
- objectId: ID об'єкта
- objectType: Тип об'єкта
- objectTypeDesc: Опис типу
- createDate: Дата створення
- modifyDate: Дата модифікації

# Usage
-- Всі об'єкти
SELECT * FROM api.objectsList(NULL, NULL);

-- Тільки таблиці схеми dbo
SELECT * FROM api.objectsList('dbo', 'U');

-- Тільки процедури
SELECT * FROM api.objectsList(NULL, 'P');
*/
CREATE OR ALTER FUNCTION api.objectsList(
    @schema NVARCHAR(128) = NULL,
    @type NVARCHAR(60) = NULL
)
RETURNS TABLE
AS
RETURN(
    SELECT 
        OBJECT_SCHEMA_NAME(o.object_id) schemaName,
        o.name objectName,
        o.object_id objectId,
        o.type objectType,
        o.type_desc objectTypeDesc,
        o.create_date createDate,
        o.modify_date modifyDate
    FROM sys.objects o (NOLOCK)
    WHERE o.is_ms_shipped = 0
        AND (@schema IS NULL OR OBJECT_SCHEMA_NAME(o.object_id) = @schema)
        AND (@type IS NULL OR o.type = @type)
);
GO

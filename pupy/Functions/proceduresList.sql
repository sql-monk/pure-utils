/*
# Description
Table-valued function для отримання списку збережених процедур в базі даних.
Повертає список всіх user процедур з основною інформацією.

# Returns
Таблиця з інформацією про процедури:
- schemaName: назва схеми
- procedureName: назва процедури
- objectId: ID об'єкта
- createDate: дата створення
- modifyDate: дата модифікації

# Usage
-- Отримати список всіх процедур
SELECT * FROM pupy.proceduresList();
*/
CREATE OR ALTER FUNCTION pupy.proceduresList()
RETURNS TABLE
AS
RETURN(
    SELECT
        OBJECT_SCHEMA_NAME(p.object_id) schemaName,
        p.name procedureName,
        p.object_id objectId,
        CONVERT(VARCHAR(23), p.create_date, 126) createDate,
        CONVERT(VARCHAR(23), p.modify_date, 126) modifyDate
    FROM sys.procedures p (NOLOCK)
    WHERE p.is_ms_shipped = 0
);
GO

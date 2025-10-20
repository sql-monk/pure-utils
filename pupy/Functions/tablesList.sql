/*
# Description
Table-valued function для отримання списку таблиць в базі даних.
Повертає список всіх user таблиць з основною інформацією.

# Returns
Таблиця з інформацією про таблиці:
- schemaName: назва схеми
- tableName: назва таблиці
- objectId: ID об'єкта
- createDate: дата створення
- modifyDate: дата модифікації
- rowCount: приблизна кількість рядків

# Usage
-- Отримати список всіх таблиць
SELECT * FROM pupy.tablesList();
*/
CREATE OR ALTER FUNCTION pupy.tablesList()
RETURNS TABLE
AS
RETURN(
    SELECT
        OBJECT_SCHEMA_NAME(t.object_id) schemaName,
        t.name tableName,
        t.object_id objectId,
        CONVERT(VARCHAR(23), t.create_date, 126) createDate,
        CONVERT(VARCHAR(23), t.modify_date, 126) modifyDate,
        SUM(p.rows) rowCount
    FROM sys.tables t (NOLOCK)
        LEFT JOIN sys.partitions p (NOLOCK) ON t.object_id = p.object_id AND p.index_id IN (0, 1)
    WHERE t.is_ms_shipped = 0
    GROUP BY 
        t.object_id,
        t.name,
        t.create_date,
        t.modify_date
);
GO

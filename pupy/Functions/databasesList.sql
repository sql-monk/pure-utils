/*
# Description
Table-valued function для отримання списку баз даних на SQL Server.
Повертає список всіх баз даних з основною інформацією про кожну.

# Returns
Таблиця з інформацією про бази даних:
- name: назва бази даних
- databaseId: ID бази даних
- createDate: дата створення
- compatibilityLevel: рівень сумісності
- isReadOnly: чи тільки для читання
- stateDesc: статус бази даних
- recoveryModelDesc: модель відновлення

# Usage
-- Отримати список всіх баз даних
SELECT * FROM pupy.databasesList();
*/
CREATE OR ALTER FUNCTION pupy.databasesList()
RETURNS TABLE
AS
RETURN(
    SELECT
        d.name,
        d.database_id databaseId,
        CONVERT(VARCHAR(23), d.create_date, 126) createDate,
        d.compatibility_level compatibilityLevel,
        d.is_read_only isReadOnly,
        d.state_desc stateDesc,
        d.recovery_model_desc recoveryModelDesc,
        d.is_published isPublished,
        d.is_trustworthy_on isTrustworthyOn,
        d.snapshot_isolation_state_desc snapshotIsolationStateDesc,
        d.is_read_committed_snapshot_on isReadCommittedSnapshotOn
    FROM sys.databases d
    WHERE d.database_id > 4  -- Виключаємо системні бази за бажанням або включаємо всі
    ORDER BY d.name
);
GO

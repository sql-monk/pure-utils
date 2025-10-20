/*
# Description
Представлення для отримання списку всіх баз даних на сервері через REST API.
Виключає системні бази даних (master, tempdb, model, msdb).
Повертає базову інформацію про кожну базу даних: назву, ID, дату створення,
рівень сумісності, стан та модель відновлення.

# Returns
Набір рядків з інформацією про бази даних

# Usage
SELECT * FROM pupy.databasesGetList;
*/
CREATE OR ALTER VIEW pupy.databasesGetList
AS
SELECT
    name,
    database_id,
    create_date,
    compatibility_level,
    state_desc,
    recovery_model_desc
FROM sys.databases (NOLOCK)
WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb');
GO

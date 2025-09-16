/*
# Description
Генерує скрипти для перейменування індексів відповідно до стандартних конвенцій найменування.
Функція створює EXEC sp_rename команди для зміни назв індексів на рекомендовані.

# Parameters
@table NVARCHAR(128) = NULL - Назва таблиці для генерації скриптів перейменування (NULL = усі таблиці)
@index NVARCHAR(128) = NULL - Назва конкретного індексу (NULL = усі індекси)

# Returns
TABLE - Повертає таблицю з колонками:
- RenameScript NVARCHAR(MAX) - SQL скрипт для перейменування індексу

# Usage
-- Згенерувати скрипти перейменування для всіх індексів таблиці
SELECT * FROM util.indexesGetScriptConventionRename('myTable', NULL);

-- Згенерувати скрипт перейменування для конкретного індексу
SELECT * FROM util.indexesGetScriptConventionRename('myTable', 'myIndex');
*/
CREATE FUNCTION util.indexesGetScriptConventionRename(@table NVARCHAR(128) = NULL, @index NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
    SELECT
        CONCAT(
            'EXEC sp_rename N''',
            icn.currentName,
            ''', N''',
            icn.newName,
            ''', N''INDEX'';'
        ) AS statement
    FROM util.indexesGetConventionNames(@table, @index) icn
    WHERE icn.currentName <> icn.newName -- Only return indexes that need renaming
);
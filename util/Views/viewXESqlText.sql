/*
# Description
Представлення для читання даних Extended Events.

# Parameters
Представлення не має параметрів

# Returns
VIEW - набір рядків з даними

# Usage
-- Приклад використання
SELECT * FROM util.viewXESqlText;
*/
CREATE VIEW util.viewXESqlText AS SELECT sqlHash, sqlText FROM msdb.util.xeSqlText (NOLOCK);

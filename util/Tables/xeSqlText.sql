/*
# Description
Таблиця для зберігання даних Extended Events.

# Parameters
Таблиця не має параметрів

# Returns
Структура таблиці для зберігання даних

# Usage
Використовується для зберігання та запиту даних
*/
DROP TABLE IF EXISTS util.xeSqlText;

CREATE TABLE xeSqlText (sqlHash VARBINARY(32) NOT NULL, sqlText NVARCHAR(MAX)) ON util
WITH (DATA_COMPRESSION = PAGE);

CREATE CLUSTERED INDEX ix_sqlHash ON dbo.xeSqlText(sqlHash)WITH(DATA_COMPRESSION = PAGE)ON util;
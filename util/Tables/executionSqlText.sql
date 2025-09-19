/*
# Description
Таблиця для зберігання SQL текстів з їх хешами для оптимізації зберігання та пошуку.
Використовується разом з таблицями виконання модулів для зберігання унікальних SQL команд.

# Columns
- sqlHash VARBINARY(32) - хеш SQL тексту (кластерний індекс)
- sqlText NVARCHAR(MAX) - повний текст SQL команди
*/
DROP TABLE IF EXISTS util.xeSqlText;

CREATE TABLE xeSqlText (sqlHash VARBINARY(32) NOT NULL, sqlText NVARCHAR(MAX)) ON util
WITH (DATA_COMPRESSION = PAGE);

CREATE CLUSTERED INDEX ix_sqlHash ON dbo.xeSqlText(sqlHash)WITH(DATA_COMPRESSION = PAGE)ON util;
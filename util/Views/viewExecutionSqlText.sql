/*
# Description
Представлення для доступу до SQL текстів із таблиці executionSqlText в базі msdb.
Надає простий доступ до збережених SQL команд з їх хешами.

# Columns
- sqlHash VARBINARY(32) - хеш SQL тексту
- sqlText NVARCHAR(MAX) - повний текст SQL команди
*/
CREATE VIEW util.viewExecutionSqlText AS SELECT sqlHash, sqlText FROM msdb.util.executionSqlText (NOLOCK);

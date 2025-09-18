CREATE VIEW util.viewExecutionSqlText AS SELECT sqlHash, sqlText FROM msdb.util.executionSqlText (NOLOCK);

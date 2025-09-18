CREATE VIEW util.viewXESqlText AS SELECT sqlHash, sqlText FROM msdb.util.xeSqlText (NOLOCK);

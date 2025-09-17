/*
# Description
Відстежує прогрес активного створення індексів поточним користувачем.
Функція моніторить операції CREATE INDEX та показує детальну інформацію про їх виконання в реальному часі.

# Returns
TABLE - Повертає таблицю з колонками:
- sessionId INT - Ідентифікатор сесії
- pysicalOperatorName NVARCHAR - Назва фізичного оператора
- CurrentStep NVARCHAR - Поточний крок виконання
- TotalRows BIGINT - Загальна кількість рядків для обробки
- RowsProcessed BIGINT - Кількість оброблених рядків
- RowsLeft BIGINT - Кількість рядків що залишились
- ElapsedSeconds DECIMAL - Час виконання в секундах
- currentStatement NVARCHAR - Поточна T-SQL команда CREATE INDEX

# Usage
-- Відстежити прогрес всіх активних операцій створення індексів
SELECT * FROM util.myselfActiveIndexCreation();

*/
CREATE OR ALTER FUNCTION util.myselfActiveIndexCreation()
RETURNS TABLE
AS
RETURN(
	WITH myIndexCreation AS (
		SELECT
			r.session_id,
			SUBSTRING(sqlt.text, r.statement_start_offset / 2, r.statement_end_offset / 2) currentStatement
		FROM sys.dm_exec_requests r
			JOIN sys.dm_exec_sessions s ON s.session_id = r.session_id
			OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) sqlt
		WHERE
			r.command = 'CREATE INDEX' AND s.original_login_name = ORIGINAL_LOGIN()
	),
	agg AS (
		SELECT
			ic.session_id,
			ic.currentStatement,
			qp.physical_operator_name,
			IIF(SUM(qp.row_count) > 0, SUM(qp.row_count), -1) RowsProcessed,
			IIF(SUM(qp.estimate_row_count) > 0, SUM(qp.estimate_row_count), -1) TotalRows,
			MAX(qp.last_active_time) - MIN(qp.first_active_time) ElapsedMS,
			MAX(IIF(qp.close_time = 0 AND qp.first_row_time > 0, qp.physical_operator_name, N'<Transition>')) CurrentStep
		FROM sys.dm_exec_query_profiles qp
			JOIN myIndexCreation ic ON ic.session_id = qp.session_id
		WHERE
			qp.physical_operator_name IN (N'Table Scan', N'Clustered Index Scan', N'Sort', 'Online Index Insert', 'Nested Loops')
		GROUP BY
			ic.session_id,
			ic.currentStatement,
			qp.physical_operator_name
	),
	comp AS (
		SELECT
			agg.session_id sessionId,
			agg.currentStatement,
			agg.physical_operator_name pysicalOperatorName,
			CONVERT(DECIMAL(5, 2), ((agg.RowsProcessed * 1.0) / agg.TotalRows) * 100) PercentComplete,
			agg.RowsProcessed,
			agg.TotalRows,
			agg.ElapsedMS,
			agg.CurrentStep,
			(agg.TotalRows - agg.RowsProcessed) RowsLeft,
			(agg.ElapsedMS / 1000.0) ElapsedSeconds
		FROM agg
	)
	SELECT
		comp.sessionId,
		comp.pysicalOperatorName pysicalOperatorName,
		comp.CurrentStep,
		comp.TotalRows,
		comp.RowsProcessed,
		comp.RowsLeft,
		comp.ElapsedSeconds,
		comp.currentStatement
	FROM comp
);

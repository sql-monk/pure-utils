/*
# Description
Отримує інформацію про поточний statement, що виконується в зазначеній сесії.
Повертає деталі сесії, програму, користувача, поточний SQL statement та query plan.

# Parameters
@sessionId INT = NULL - ID сесії для якої потрібно отримати поточний statement. NULL = поточна сесія

# Returns
Таблицю з колонками:
- sessionId - ID сесії
- programName - назва програми
- loginName - ім'я користувача
- statementExecuting - поточний SQL statement що виконується
- queryPlan - план виконання запиту в форматі XML

# Usage
-- Отримати поточний statement для конкретної сесії
SELECT * FROM util.executionGetCurrentStatement(330);

-- Отримати поточний statement для поточної сесії
SELECT * FROM util.executionGetCurrentStatement(DEFAULT);
*/
CREATE OR ALTER FUNCTION util.executionGetCurrentStatement(@sessionId INT = NULL)
RETURNS TABLE
AS
RETURN(
    SELECT 
        s.session_id sessionId,
        s.program_name programName,
        s.login_name loginName,
        SUBSTRING(
            st.text, 
            r.statement_start_offset / 2 + 1, 
            (CASE 
                WHEN r.statement_end_offset = -1 THEN DATALENGTH(st.text)
                ELSE r.statement_end_offset 
            END - r.statement_start_offset) / 2 + 1
        ) statementExecuting,
        CAST(qp.query_plan AS XML) queryPlan
    FROM sys.dm_exec_sessions s (NOLOCK)
        INNER JOIN sys.dm_exec_requests r (NOLOCK) ON s.session_id = r.session_id
        CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
        CROSS APPLY sys.dm_exec_text_query_plan(r.plan_handle, r.statement_start_offset, r.statement_end_offset) qp
    WHERE s.is_user_process = 1 
        AND (@sessionId IS NULL OR r.session_id = @sessionId)
);
GO

/*
# Description
Витягує параметри з XML плану виконання запиту.
Аналізує XML план виконання та повертає інформацію про параметри, включаючи їх назви, типи даних,
скомпільовані та runtime значення.

# Parameters
@plan XML - XML план виконання запиту (з SET SHOWPLAN_XML або sys.dm_exec_query_plan)

# Returns
TABLE - Повертає таблицю з колонками:
- ParameterName SYSNAME - назва параметра
- ParameterDataType NVARCHAR(128) - тип даних параметра
- CompiledValue NVARCHAR(MAX) - значення параметра під час компіляції
- RuntimeValue NVARCHAR(MAX) - значення параметра під час виконання

# Usage
-- Витягти параметри з плану виконання
DECLARE @plan XML;
SELECT @plan = query_plan 
FROM sys.dm_exec_query_plan(0x...);

SELECT * FROM util.planFindParameters(@plan);

-- Використання з кешованими планами
SELECT 
    qs.query_hash,
    p.ParameterName,
    p.ParameterDataType,
    p.CompiledValue,
    p.RuntimeValue
FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
    CROSS APPLY util.planFindParameters(qp.query_plan) p
WHERE qs.query_hash = 0x...;

-- Аналіз параметрів для конкретної процедури
SELECT 
    p.ParameterName,
    p.ParameterDataType,
    p.CompiledValue
FROM sys.dm_exec_procedure_stats ps
    CROSS APPLY sys.dm_exec_query_plan(ps.plan_handle) qp
    CROSS APPLY util.planFindParameters(qp.query_plan) p
WHERE ps.object_id = OBJECT_ID('dbo.MyProcedure');
*/
CREATE OR ALTER FUNCTION util.planGetParameters(@plan XML)
RETURNS TABLE
AS 
RETURN(
	WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
	SELECT 
		param.value('(@Column)[1]', 'SYSNAME') ParameterName,
		param.value('(@ParameterDataType)[1]', 'NVARCHAR(128)') ParameterDataType,
		param.value('(@ParameterCompiledValue)[1]', 'NVARCHAR(MAX)') CompiledValue,
		param.value('(@ParameterRuntimeValue)[1]', 'NVARCHAR(MAX)') RuntimeValue
	FROM @plan.nodes('//ParameterList/ColumnReference') params(param)
	WHERE @plan.exist('//ParameterList') = 1
);
GO

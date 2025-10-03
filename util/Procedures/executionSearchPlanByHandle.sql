CREATE OR ALTER PROCEDURE util.executionSearchPlanByHandle
	@planHandle VARBINARY(64),
	@plan NVARCHAR(MAX) OUTPUT
AS
BEGIN
	SELECT @plan = CONVERT(NVARCHAR(MAX), query_plan)FROM sys.dm_exec_query_plan(@planHandle);

	IF @plan IS NOT NULL RETURN;

	DECLARE @database NVARCHAR(128) = NULL;

	DECLARE @cmd NVARCHAR(MAX)
		= N'WITH cteQS AS (SELECT qsp.query_plan, ROW_NUMBER() OVER (ORDER BY qsp.last_execution_time DESC) rn FROM msdb.util.executionPlanHandleHash phh LEFT JOIN 
[#db#].sys.query_store_plan qsp ON qsp.query_plan_hash = phh.planHash
WHERE phh.planHandle = @planHandle)
SELECT @plan = query_plan FROM cteQS WHERE rn = 1';

	/*
	search database
	*/
	IF @database IS NULL
		SELECT TOP(1)@database = emu.DatabaseName
		FROM(
			SELECT DISTINCT u.DatabaseName
			FROM util.executionModulesUsers u
			WHERE u.PlanHandle = @planHandle
			UNION
			SELECT DISTINCT f.DatabaseName
			FROM util.executionModulesFaust f
			WHERE f.PlanHandle = @planHandle
			UNION
			SELECT DISTINCT s.DatabaseName
			FROM util.executionModulesSSIS s
			WHERE s.PlanHandle = @planHandle
		) emu;

	SELECT @cmd = REPLACE(@cmd, '#db#', @database);
	IF @database IS NOT NULL
		EXEC sys.sp_executesql @cmd, N'@planHandle VARBINARY(64), @plan NVARCHAR(MAX) OUTPUT', @planHandle = @planHandle, @plan = @plan OUTPUT;

END;
/*
# Description
Inline TVF — швидкий пошук імені job та кроку за ApplicationName.
# Parameters
@appName - Client Application Name (clientAppName)
# Returns
jobName NVARCHAR(128), stepId INT, stepName NVARCHAR(128)
# Usag
```sql
SELECT 
		s.session_id,
		s.program_name,
		j.jobName,
		j.stepId,
		j.stepName
FROM sys.dm_exec_sessions s
CROSS APPLY util.jobsGetNameByAppName_i(s.program_name) j
WHERE s.program_name LIKE N'SQLAgent - TSQL JobStep (%';
```
*/
CREATE OR ALTER FUNCTION util.jobsGetNameByAppNameInline(@appName NVARCHAR(256))
RETURNS TABLE
AS
RETURN(
	WITH cteRaw AS (
		SELECT REPLACE(value, ')', '') jobstepid FROM STRING_SPLIT(REPLACE(REPLACE(@appName, '(Job ', CHAR(31)), ' : Step ', ':'), CHAR(31), 1)WHERE ordinal = 2
	),
	cteIds AS (
		SELECT ids.value, ordinal FROM cteRaw js CROSS APPLY STRING_SPLIT(js.jobstepid, ':', 1) ids
	),
	cteJobStep AS (
		SELECT
			TRY_CONVERT(UNIQUEIDENTIFIER, TRY_CONVERT(VARBINARY(64), (SELECT cteIds.value FROM cteIds WHERE ordinal = 1), 1), 1) jobid,
			TRY_CONVERT(SMALLINT, (SELECT cteIds.value FROM cteIds WHERE ordinal = 2)) stepId
	)
	SELECT
		j.name,
		s.step_name stepName
	FROM cteJobStep r
		JOIN msdb.dbo.sysjobs j ON j.job_id = r.jobid
		JOIN msdb.dbo.sysjobsteps s ON s.job_id = j.job_id AND s.step_id = r.stepId
);

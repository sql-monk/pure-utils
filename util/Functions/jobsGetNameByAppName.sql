/*
# Description
Scalar-версія — повертає готовий рядок для відображення/логів.
Формат: JobName — Step N (StepName)
# Parameters
@appName - Client Application Name (clientAppName)
# Returns
NVARCHAR(256) - відформатований рядок або NULL, якщо розпізнати не вдалось
*/
CREATE OR ALTER FUNCTION util.jobsGetNameByAppName(@appName NVARCHAR(256), @includeStepName BIT = 0)
RETURNS NVARCHAR(256)
AS
BEGIN
	DECLARE @result NVARCHAR(4000);

	SELECT @result = CASE @includeStepName WHEN 0 THEN f.name ELSE CONCAT(f.name, N' (', f.stepName, N')') END FROM util.jobsGetNameByAppNameInline(@appName) f;

	RETURN @result; -- буде NULL, якщо парсинг/зв’язка не вдалися
END;
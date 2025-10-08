/*
# Description
Шукає execution plan для збереженої процедури або функції за повним ім'ям об'єкта.
Процедура використовує декілька джерел для пошуку плану виконання:
1. sys.dm_exec_procedure_stats - статистика виконання процедур
2. util.executionModulesUsers - історія виконання користувацьких запитів
3. util.executionModulesSSIS - історія виконання через SSIS пакети
4. util.executionModulesFaust - історія виконання через Faust систему

# Parameters
@fullObjectName NVARCHAR(256) - повна назва об'єкта включно з базою даних та схемою (формат: database.schema.object)
@plan NVARCHAR(MAX) OUTPUT - вихідний параметр з XML execution plan

# Usage
-- Отримати план виконання для процедури
DECLARE @plan NVARCHAR(MAX);
EXEC util.executionSearchPlanByObjectName 'MyDatabase.dbo.MyProcedure', @plan OUTPUT;
SELECT @plan;

-- Знайти план для функції
DECLARE @execPlan NVARCHAR(MAX);
EXEC util.executionSearchPlanByObjectName 'AdventureWorks.dbo.ufnGetProductListPrice', @execPlan OUTPUT;
PRINT @execPlan;
*/
CREATE or ALTER PROCEDURE util.executionSearchPlanByObjectName @fullObjectName NVARCHAR(256), @plan NVARCHAR(max) OUTPUT
AS
BEGIN

	DECLARE @databaseId SMALLINT = DB_ID(PARSENAME(@fullObjectName, 3));
	IF @databaseId IS NULL RAISERROR('Базу даних не знайдено. Очікується повна назва включно із базою та схемою.', 16, 1);


	DECLARE @objectId INT = OBJECT_ID(@fullObjectName);

	DECLARE @planHandle VARBINARY(64);
	WITH ctePS AS (
		SELECT
			ps.plan_handle,
			ROW_NUMBER() OVER (ORDER BY ps.last_execution_time DESC) rn
		FROM sys.dm_exec_procedure_stats ps
		WHERE ps.database_id = @databaseId AND ps.object_id = @objectId
	)
	SELECT @planHandle = ctePS.plan_handle FROM ctePS WHERE ctePS.rn = 1;

	IF(@planHandle IS NULL)
		WITH cteUsers AS (
			SELECT
				u.PlanHandle,
				ROW_NUMBER() OVER (ORDER BY u.EventTime DESC) rn
			FROM util.executionModulesUsers u
			WHERE u.DatabaseId = @databaseId AND u.ObjectId = @objectId
		),
		cteSSIS AS (
			SELECT u.PlanHandle, ROW_NUMBER() OVER (ORDER BY u.EventTime DESC) rn FROM util.executionModulesSSIS u WHERE u.DatabaseId = @databaseId
																																																									 AND u.ObjectId = @objectId
		),
		cteFaust AS (
			SELECT
				u.PlanHandle,
				ROW_NUMBER() OVER (ORDER BY u.EventTime DESC) rn
			FROM util.executionModulesFaust u
			WHERE u.DatabaseId = @databaseId AND u.ObjectId = @objectId
		)
		SELECT TOP(1)@planHandle = emu.PlanHandle
		FROM(
			SELECT cteUsers.PlanHandle
			FROM cteUsers
			WHERE cteUsers.rn = 1
			UNION
			SELECT cteSSIS.PlanHandle
			FROM cteSSIS
			WHERE cteSSIS.rn = 1
			UNION
			SELECT cteFaust.PlanHandle
			FROM cteFaust
			WHERE cteFaust.rn = 1
		) emu;

	EXEC util.executionSearchPlanByHandle @planHandle, @plan OUTPUT;
END;
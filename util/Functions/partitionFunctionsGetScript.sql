/*
# Description
Генерує DDL скрипт для створення функції розділення (partition function).
Функція формує повну CREATE PARTITION FUNCTION інструкцію включаючи тип даних, діапазон та граничні значення.

# Parameters
@partitionFunction NVARCHAR(128) = NULL - Назва функції розділення (NULL = усі функції розділення)

# Returns
TABLE - Повертає таблицю з колонками:
- PartitionFunctionName NVARCHAR(128) - Назва функції розділення
- CreateScript NVARCHAR(MAX) - DDL скрипт для створення функції розділення

# Usage
-- Згенерувати скрипт для конкретної функції розділення
SELECT * FROM util.partitionFunctionsGetScript('myPartitionFunction');

-- Згенерувати скрипти для всіх функцій розділення
SELECT * FROM util.partitionFunctionsGetScript(NULL);
*/
CREATE OR ALTER FUNCTION util.partitionFunctionsGetScript(@partitionFunction NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	WITH PartitionFunctions AS (
		SELECT
			pf.function_id,
			pf.name partitionFunctionName,
			pf.type_desc rangeType,
			t.name dataTypeName,
			CASE
				WHEN t.name IN ('varchar', 'char', 'varbinary', 'binary', 'text') THEN t.name + '(' + CASE
																																																WHEN pp.max_length = -1 THEN 'MAX'
																																																ELSE CAST(pp.max_length AS NVARCHAR(10))
																																															END + ')'
				WHEN t.name IN ('nvarchar', 'nchar', 'ntext') THEN t.name + '(' + CASE
																																										WHEN pp.max_length = -1 THEN 'MAX'
																																										ELSE CAST(pp.max_length / 2 AS NVARCHAR(10))
																																									END + ')'
				WHEN t.name IN ('decimal', 'numeric') THEN t.name + '(' + CAST(pp.precision AS NVARCHAR(10)) + ',' + CAST(pp.scale AS NVARCHAR(10)) + ')'
				WHEN t.name IN ('datetime2', 'time', 'datetimeoffset') THEN t.name + '(' + CAST(pp.scale AS NVARCHAR(10)) + ')'
				ELSE t.name
			END dataType
		FROM sys.partition_functions pf(NOLOCK)
			INNER JOIN sys.partition_parameters pp(NOLOCK) ON pf.function_id = pp.function_id
			INNER JOIN sys.types t(NOLOCK) ON pp.user_type_id = t.user_type_id
		WHERE
			(@partitionFunction IS NULL OR pf.name = @partitionFunction)
	),
	BoundaryValues AS (
		SELECT
			pf.function_id,
			STRING_AGG(CASE
										WHEN t.name IN ('datetime', 'datetime2', 'date', 'smalldatetime') THEN '''' + CONVERT(NVARCHAR(50), prv.value, 121) + ''''
										WHEN t.name IN ('char', 'varchar', 'nchar', 'nvarchar', 'text', 'ntext') THEN '''' + CAST(prv.value AS NVARCHAR(MAX)) + ''''
										ELSE CAST(prv.value AS NVARCHAR(MAX))
									END, ', ') WITHIN GROUP(ORDER BY prv.boundary_id) boundaryList
		FROM sys.partition_functions pf(NOLOCK)
			INNER JOIN sys.partition_range_values prv(NOLOCK) ON pf.function_id = prv.function_id
			INNER JOIN sys.partition_parameters pp(NOLOCK) ON pf.function_id = pp.function_id
			INNER JOIN sys.types t(NOLOCK) ON pp.user_type_id = t.user_type_id
		GROUP BY
			pf.function_id
	)
	SELECT
		pf.partitionFunctionName,
		'CREATE PARTITION FUNCTION ' + QUOTENAME(pf.partitionFunctionName) + '(' + pf.dataType + ')' + CHAR(13) + CHAR(10) + 'AS RANGE ' + CASE
																																																																									WHEN pf.rangeType = 'RANGE_LEFT' THEN 'LEFT'
																																																																									WHEN pf.rangeType = 'RANGE_RIGHT' THEN 'RIGHT'
																																																																								END + CHAR(13) + CHAR(10) + 'FOR VALUES (' + ISNULL(bv.boundaryList, '')
		+ ');' createScript
	FROM PartitionFunctions pf
		LEFT JOIN BoundaryValues bv ON pf.function_id = bv.function_id
);
GO

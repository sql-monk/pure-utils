/*
# Description
Генерує DDL скрипт для створення схеми розділення (partition scheme).
Функція формує повну CREATE PARTITION SCHEME інструкцію включаючи функцію розділення та файлові групи.

# Parameters
@partitionScheme NVARCHAR(128) = NULL - Назва схеми розділення (NULL = усі схеми розділення)

# Returns
TABLE - Повертає таблицю з колонками:
- PartitionSchemeName NVARCHAR(128) - Назва схеми розділення
- CreateScript NVARCHAR(MAX) - DDL скрипт для створення схеми розділення

# Usage
-- Згенерувати скрипт для конкретної схеми розділення
SELECT * FROM util.partitionSchemesGetScript('myPartitionScheme');

-- Згенерувати скрипти для всіх схем розділення
SELECT * FROM util.partitionSchemesGetScript(NULL);
*/
CREATE OR ALTER FUNCTION util.partitionSchemesGetScript(@partitionScheme NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	WITH PartitionSchemes AS (
		SELECT
			ps.data_space_id,
			ps.name partitionSchemeName,
			pf.name partitionFunctionName
		FROM sys.partition_schemes ps(NOLOCK)
			INNER JOIN sys.partition_functions pf(NOLOCK) ON ps.function_id = pf.function_id
		WHERE
			(@partitionScheme IS NULL OR ps.name = @partitionScheme)
	),
	FileGroups AS (
		SELECT
			ps.data_space_id,
			STRING_AGG(QUOTENAME(fg.name), ', ') WITHIN GROUP(ORDER BY dds.destination_id) filegroupList
		FROM PartitionSchemes ps
			INNER JOIN sys.destination_data_spaces dds(NOLOCK) ON ps.data_space_id = dds.partition_scheme_id
			INNER JOIN sys.filegroups fg(NOLOCK) ON dds.data_space_id = fg.data_space_id
		GROUP BY
			ps.data_space_id
	)
	SELECT
		ps.partitionSchemeName,
		'CREATE PARTITION SCHEME ' + QUOTENAME(ps.partitionSchemeName) + CHAR(13) + CHAR(10) + 'AS PARTITION ' + QUOTENAME(ps.partitionFunctionName) + CHAR(13) + CHAR(10) + 'TO (' + fg.filegroupList
		+ ');' createScript
	FROM PartitionSchemes ps
		INNER JOIN FileGroups fg ON ps.data_space_id = fg.data_space_id
);
GO

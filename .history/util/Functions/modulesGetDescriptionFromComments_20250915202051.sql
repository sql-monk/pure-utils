CREATE FUNCTION modulesGetDescriptionFromComments(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT
		CONCAT(QUOTENAME(OBJECT_SCHEMA_NAME(object_id)), '.', QUOTENAME(OBJECT_NAME(object_id))) objectName,
		TRIM(REPLACE(s.value, 'Description:', '')) description
	FROM sys.sql_modules
		CROSS APPLY STRING_SPLIT(REPLACE(definition, '--', CHAR(31)), CHAR(31)) s
	WHERE
		(@object IS NULL OR object_id = CONVERT(INT, @object) OR OBJECT_NAME(object_id) = @object)
		AND definition LIKE '%-- Description:	%'
		AND s.value LIKE '%Description:	%'
);-- Write your own SQL object definition here, and it'll be included in your package.

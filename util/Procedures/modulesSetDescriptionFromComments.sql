
--CREATE PROCEDURE util.modulesSetDescriptionFromComments @object NVARCHAR(128), @OnlyEmpty BIT = 1
--AS
--BEGIN

--DECLARE @cmd NVARCHAR(max);
WITH cteCD AS (
	SELECT
		cd.objectId,
		cd.description,
		util.metadataGetObjectType(cd.objectId) objectType
	FROM util.modulesGetDescriptionFromComments(DEFAULT) cd
	WHERE NOT EXISTS (SELECT * FROM util.metadataGetDescriptions(cd.objectId, DEFAULT) )
),
ctePre AS (
	SELECT
		util.metadataGetObjectName(cd.objectId) objName,
		STUFF(cd.objectType, 1, 1, UPPER(LEFT(cd.objectType, 1))) objType,
		CONCAT('''', REPLACE(cd.description, '''', ''''''), '''') objDescr
	FROM cteCD cd
)
SELECT CONCAT('EXEC util.metadataSet', c.objType, 'Description ''', c.objName,''', ',  c.objDescr) FROM ctePre c;
--END
--EXEC util.metadataSetTableDescription
--	@table = N'', -- nvarchar(128)
--	@description = N'' -- nvarchar(max)


/*
# Description
Встановлює описи для об'єктів бази даних, витягуючи їх з коментарів у вихідному коді модулів.
Автоматично аналізує коментарі типу "-- Description:" та встановлює відповідні розширені властивості.

# Parameters
@object NVARCHAR(128) - назва об'єкта для обробки
@OnlyEmpty BIT = 1 - встановлювати описи тільки для об'єктів без існуючих описів (1) або для всіх (0)

# Returns
Нічого не повертає. Встановлює розширені властивості MS_Description на основі коментарів

# Usage
-- Встановити описи з коментарів для конкретного об'єкта
EXEC util.modulesSetDescriptionFromComments @object = 'myProcedure', @OnlyEmpty = 1;

-- Оновити описи для всіх об'єктів навіть якщо вони вже існують
EXEC util.modulesSetDescriptionFromComments @object = 'myFunction', @OnlyEmpty = 0;
*/
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

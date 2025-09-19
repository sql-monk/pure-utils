/*
# Description
Процедура для автоматичного встановлення описів об'єктів на основі коментарів у коді модулів.
Використовує функцію modulesGetDescriptionFromComments для витягання описів з коментарів
та генерує команди для встановлення розширених властивостей.

# Parameters
@object NVARCHAR(128) - назва або ID об'єкта модуля для обробки

# Usage
-- Встановити опис для конкретного об'єкта
EXEC util.modulesSetDescriptionFromComments 'util.errorHandler'

-- Встановити опис для об'єкта за ID
EXEC util.modulesSetDescriptionFromComments '123456789'
*/
CREATE OR ALTER PROCEDURE util.modulesSetDescriptionFromComments @object NVARCHAR(128)
AS
BEGIN
	DECLARE @objectId INT = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object));
	IF(@objectId IS NULL)
	BEGIN
		DECLARE @e NVARCHAR(1000) = N'Object not found ' + QUOTENAME(@object);
		RAISERROR(@e, 10, 1);
	END;
	DECLARE @cmd NVARCHAR(MAX) = N'';
	SELECT
		@cmd = CONCAT(@cmd,
						 'EXEC util.metadataSet',
						 CASE
							 WHEN descr.minor IS NULL THEN descr.objectType
							 ELSE IIF(LEFT(descr.minor, 1) = '@', 'Parameter', 'Column')
						 END,
						 'Description ', descr.objectId,', ',
						  IIF(descr.minor IS NOT NULL, '''' + descr.minor + ''',',''),
						 descr.description, ';', CHAR(13), CHAR(10))
	FROM util.modulesGetDescriptionFromComments(@objectId) descr
	OPTION(MAXRECURSION 32000);

	IF(LEN(@cmd) > 0) EXEC(@cmd);

END;
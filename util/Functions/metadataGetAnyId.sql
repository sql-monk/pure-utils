/*
# Description
Універсальна функція для отримання ID будь-якого об'єкта бази даних залежно від його класу. 
Підтримує різні типи об'єктів: таблиці, колонки, індекси, схеми, користувачів, файли та інші.

# Parameters
@object NVARCHAR(128) - назва об'єкта
@class NVARCHAR(128) = 1 - клас об'єкта (число або текстова назва класу)
@minorName NVARCHAR(128) = NULL - додаткова назва для складних об'єктів (наприклад, колонка або індекс)

# Returns
INT - ідентифікатор об'єкта відповідного типу або NULL якщо об'єкт не знайдено

# Usage
-- Отримати object_id таблиці
SELECT util.metadataGetAnyId('dbo.MyTable', 'OBJECT');

-- Отримати column_id колонки
SELECT util.metadataGetAnyId('dbo.MyTable', 'OBJECT', 'MyColumn');
*/
CREATE OR ALTER FUNCTION util.metadataGetAnyId(@object NVARCHAR(128), @class NVARCHAR(128) = 1, @minorName NVARCHAR(128) = NULL)
RETURNS INT
AS
BEGIN
	DECLARE @majorId INT;
	--DECLARE @minorId INT = 0;
	DECLARE @cls INT = ISNULL(TRY_CONVERT(INT, @class), util.metadataGetClassByName(@class));
	-- Визначаємо majorId залежно від класу об'єкта
	SET @majorId = CASE @cls
									 WHEN 0 THEN DB_ID()
									 WHEN 1 THEN CASE
																 WHEN @minorName IS NULL THEN OBJECT_ID(@object)
																 ELSE util.metadataGetColumnId(OBJECT_ID(@object), @minorName)
															 END
									 WHEN 2 THEN CASE
																 WHEN @minorName IS NULL THEN OBJECT_ID(@object)
																 ELSE util.metadataGetIndexId(@object, @minorName)
															 END
									 WHEN 7 THEN CASE
																 WHEN @minorName IS NULL THEN OBJECT_ID(@object)
																 ELSE util.metadataGetParameterId(@object, @minorName)
															 END
									 WHEN 3 THEN SCHEMA_ID(@object) -- Schema
									 WHEN 4 THEN USER_ID(@object) -- User
									 WHEN 20 THEN util.metadataGetDataspaceId(@object)
									 WHEN 21 THEN util.metadataGetPartitionFunctionId(@object)
									 WHEN 22 THEN FILE_ID(@object) -- File
									 WHEN 25 THEN CERT_ID(@object)
								 END;


	RETURN @majorId;
END;
GO

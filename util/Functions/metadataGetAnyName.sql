/*
# Description
Універсальна функція для отримання імені будь-якого об'єкта бази даних за його ID та класом.
Дозволяє отримувати імена для різних типів об'єктів залежно від їх класу.

# Parameters
@majorId INT - основний ідентифікатор об'єкта
@minorId INT = 0 - додатковий ідентифікатор (для колонок, індексів, параметрів)
@class NVARCHAR(128) = '1' - клас об'єкта (число або текстова назва)

# Returns
NVARCHAR(128) - ім'я відповідного об'єкта

# Usage
-- Отримати ім'я таблиці за object_id
SELECT util.metadataGetAnyName(OBJECT_ID('dbo.MyTable'), 0, '1');

-- Отримати ім'я колонки
SELECT util.metadataGetAnyName(OBJECT_ID('dbo.MyTable'), 1, '1');
*/
CREATE OR ALTER FUNCTION util.metadataGetAnyName(@majorId INT, @minorId INT = 0, @class NVARCHAR(128) = '1')
RETURNS NVARCHAR(128)
AS
BEGIN
	DECLARE @cls INT = ISNULL(TRY_CONVERT(INT, @class), util.metadataGetClassByName(@class));
	RETURN CASE @cls
					 WHEN 0 THEN QUOTENAME(DB_NAME())
					 WHEN 1 THEN CASE
												 WHEN @minorId = 0 THEN util.metadataGetObjectName(@majorId, DEFAULT)
												 ELSE CONCAT(util.metadataGetObjectName(@majorId, DEFAULT), '.', util.metadataGetColumnName(@majorId, @minorId))
											 END
					 WHEN 2 THEN  util.metadataGetParameterName(@majorId, @minorId)
					 WHEN 3 THEN QUOTENAME(SCHEMA_NAME(@majorId))
					 WHEN 4 THEN QUOTENAME(USER_NAME(@majorId))
					 WHEN 7 THEN CONCAT(util.metadataGetObjectName(@majorId, DEFAULT), '.', util.metadataGetIndexName(@majorId, @minorId))
					 WHEN 20 THEN util.metadataGetDataspaceName(@majorId)
					 WHEN 21 THEN util.metadataGetPartitionFunctionName(@majorId)
					 WHEN 22 THEN QUOTENAME(FILE_NAME(@majorId))
					 WHEN 25 THEN util.metadataGetCertificateName(@majorId)
					 ELSE CONVERT(NVARCHAR(128), @majorId)
				 END;
END;


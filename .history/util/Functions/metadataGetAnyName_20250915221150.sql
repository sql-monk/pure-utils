CREATE FUNCTION [util].[metadataGetAnyName](@majorId INT, @minorId INT = 0, @class TINYINT = 1)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN CASE @class
				WHEN 0 THEN QUOTENAME(DB_NAME())
				WHEN 1 THEN
					CASE
						WHEN @minorId = 0 THEN util.metadataGetObjectName(@majorId)
						ELSE CONCAT(util.metadataGetObjectName(@majorId), '.', util.metadataGetColumnName(@majorId, @minorId))
					END
				WHEN 2 THEN
					CONCAT(util.metadataGetObjectName(@majorId), ' (', util.metadataGetParameterName(@majorId, @minorId), ')')
				WHEN 3 THEN QUOTENAME(SCHEMA_NAME(@majorId))
				WHEN 4 THEN QUOTENAME(USER_NAME(@majorId))
				WHEN 7 THEN CONCAT(util.metadataGetObjectName(@majorId), '.', util.metadataGetIndexName(@majorId, @minorId))
				WHEN 20 THEN util.metadataGetDataspaceName(@majorId)
				WHEN 21 THEN util.metadataGetPartitionFunctionName(@majorId)
				WHEN 22 THEN QUOTENAME(FILE_NAME(@majorId))
				WHEN 25 THEN util.metadataGetCertificateName(@majorId)
				ELSE CONVERT(NVARCHAR(128), @majorId)
			END;
END;


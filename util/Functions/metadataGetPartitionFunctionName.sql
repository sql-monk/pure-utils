/*
# Description
Отримує назву функції розділення за її ідентифікатором.

# Parameters
@functionId INT - ідентифікатор функції розділення

# Returns
NVARCHAR(128) - назва функції розділення в квадратних дужках або NULL якщо не знайдено

# Usage
-- Отримати назву функції розділення за ID
SELECT util.metadataGetPartitionFunctionName(1);
*/
CREATE OR ALTER FUNCTION util.metadataGetPartitionFunctionName(@functionId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT QUOTENAME(name) name FROM sys.partition_functions(NOLOCK)WHERE function_id = @functionId);
END;
GO


/*
# Description
Отримує ідентифікатор функції розділення за її назвою.

# Parameters
@function NVARCHAR(128) - назва функції розділення

# Returns
INT - ідентифікатор функції розділення або NULL якщо не знайдено

# Usage
-- Отримати ID функції розділення
SELECT util.metadataGetPartitionFunctionId('myPartitionFunction');
*/
CREATE FUNCTION util.metadataGetPartitionFunctionId(@function NVARCHAR(128))
RETURNS INT
AS
BEGIN
	RETURN (SELECT function_id FROM sys.partition_functions(NOLOCK)WHERE name = @function);
END;
GO
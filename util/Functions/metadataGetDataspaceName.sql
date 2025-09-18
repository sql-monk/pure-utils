/*
# Description
Отримує назву простору даних (data space) за його ідентифікатором.
Повертає назву в квадратних дужках для безпечного використання в SQL.

# Parameters
@dataSpaceId INT - ідентифікатор простору даних

# Returns
NVARCHAR(128) - назва простору даних в квадратних дужках або NULL якщо не знайдено

# Usage
-- Отримати назву файлової групи за ID
SELECT util.metadataGetDataspaceName(1);

-- Отримати назву схеми розділення за ID
SELECT util.metadataGetDataspaceName(65537);
*/
CREATE OR ALTER FUNCTION util.metadataGetDataspaceName(@dataSpaceId INT)
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT QUOTENAME(name) name FROM sys.data_spaces(NOLOCK)WHERE data_space_id = @dataSpaceId);
END;
GO


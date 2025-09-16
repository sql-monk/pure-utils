/*
# Description
Отримує ідентифікатор простору даних (data space) за його назвою.
Підтримує файлові групи та схеми розділення.

# Parameters
@dataSpace NVARCHAR(128) - назва простору даних

# Returns
INT - ідентифікатор простору даних або NULL якщо не знайдено

# Usage
-- Отримати ID файлової групи
SELECT util.metadataGetDataspaceId('PRIMARY');

-- Отримати ID схеми розділення
SELECT util.metadataGetDataspaceId('MyPartitionScheme');
*/
CREATE FUNCTION util.metadataGetDataspaceId(@dataSpace NVARCHAR(128))
RETURNS INT
AS
BEGIN
	RETURN (SELECT data_space_id FROM sys.data_spaces(NOLOCK) WHERE name = @dataSpace);
END;
GO


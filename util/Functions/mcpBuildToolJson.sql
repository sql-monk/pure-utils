CREATE OR ALTER FUNCTION util.mcpBuildToolJson(
    @schemaName SYSNAME,
    @objectName SYSNAME,
    @description NVARCHAR(MAX),
    @propertiesJson NVARCHAR(MAX),
    @requiredJson NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    -- Description вже екранований через STRING_ESCAPE в ToolsList
    DECLARE @descriptionJson NVARCHAR(MAX) = CASE 
        WHEN @description IS NOT NULL THEN CONCAT('"', @description, '"')
        ELSE 'null'
    END;
    
    -- Екрануємо імена схеми та об'єкта
    DECLARE @escapedSchema NVARCHAR(256) = STRING_ESCAPE(@schemaName, 'json');
    DECLARE @escapedObject NVARCHAR(256) = STRING_ESCAPE(@objectName, 'json');

    RETURN CONCAT(
        '{',
            '"name":"', @escapedSchema, '.', @escapedObject, '",',
            '"description":', @descriptionJson, ',',
            '"inputSchema":{',
                '"type":"object",',
                '"properties":', ISNULL(@propertiesJson, '{}'), ',',
                '"required":', ISNULL(@requiredJson, '[]'),
            '}',
        '}'
    );
END;
GO
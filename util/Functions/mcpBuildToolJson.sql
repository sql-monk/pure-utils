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
        ELSE '""'
    END;
    
    -- Екрануємо імена схеми та об'єкта
    -- Для імен використовуємо лише допустимі символи (букви, цифри, _, -)
    DECLARE @escapedSchema NVARCHAR(256) = @schemaName;
    DECLARE @escapedObject NVARCHAR(256) = @objectName;

    RETURN CONCAT(
        '{',
            '"name":"', @escapedObject, '",',
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
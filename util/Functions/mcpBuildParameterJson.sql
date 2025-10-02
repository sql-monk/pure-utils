/* 
# Description
Функція 2: Формування JSON для одного параметра
*/
CREATE OR ALTER FUNCTION util.mcpBuildParameterJson(
    @paramName NVARCHAR(128),
    @typeName SYSNAME,
    @description NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    -- Видаляємо @ з початку імені параметра
    DECLARE @cleanParamName NVARCHAR(128) = SUBSTRING(@paramName, 2, LEN(@paramName));
    
    -- Екрануємо ім'я параметра для JSON
    DECLARE @escapedParamName NVARCHAR(128) = STRING_ESCAPE(@cleanParamName, 'json');
    
    DECLARE @jsonType NVARCHAR(50) = util.mcpMapSqlTypeToJsonType(@typeName);
    
    -- Description вже екранований через STRING_ESCAPE в mcpGetObjectParameters
    DECLARE @descriptionPart NVARCHAR(MAX) = CASE 
        WHEN @description IS NOT NULL 
        THEN CONCAT(',"description":"', @description, '"')
        ELSE ''
    END;

    RETURN CONCAT(
        '"', @escapedParamName, '":{',
        '"type":"', @jsonType, '"',
        @descriptionPart,
        '}'
    );
END;

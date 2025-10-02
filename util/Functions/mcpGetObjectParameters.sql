/* 
# Description
Отримання параметрів функції/процедури
*/
CREATE OR ALTER FUNCTION util.mcpGetObjectParameters(
    @objectId INT
)
RETURNS TABLE
AS
RETURN
    SELECT
        p.object_id,
        p.parameter_id,
        p.name AS ParamName,
        STRING_ESCAPE(pd.description, 'json') AS ParamDescription,
        t.name AS TypeName,
        p.has_default_value AS HasDefaultValue
    FROM sys.parameters p
    LEFT JOIN sys.types t
        ON p.system_type_id = t.system_type_id
       AND t.user_type_id = t.system_type_id
    OUTER APPLY util.metadataGetDescriptions(p.object_id, p.parameter_id) pd
    WHERE p.object_id = @objectId
      AND p.is_output = 0;
GO
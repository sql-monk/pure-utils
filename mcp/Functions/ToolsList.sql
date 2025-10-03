CREATE OR ALTER FUNCTION mcp.ToolsList()
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @tools NVARCHAR(MAX);

	-- Крок 1: Знаходимо всі об'єкти в схемі util з коментарями
	;
	WITH UtilObjects AS (
		SELECT
			m.object_id,
			OBJECT_SCHEMA_NAME(m.object_id) SchemaName,
			OBJECT_NAME(m.object_id) ObjectName
		FROM sys.sql_modules m
		WHERE OBJECT_SCHEMA_NAME(m.object_id) = 'mcp' --AND m.definition LIKE '/*%'
	),

	-- Крок 2: Отримуємо описи об'єктів (беремо тільки перший опис)
	ObjectDescriptions AS (
		SELECT 
			o.object_id, 
			STRING_ESCAPE((
				SELECT TOP 1 d.description 
				FROM util.metadataGetDescriptions(o.object_id, DEFAULT) d
			), 'json') AS Description 
		FROM UtilObjects o
	),

	-- Крок 3: Збираємо всі параметри
	AllParameters AS (
		SELECT
			o.object_id,
			p.parameter_id,
			p.ParamName,
			p.ParamDescription,
			p.TypeName,
			p.HasDefaultValue
		FROM UtilObjects o
			CROSS APPLY util.mcpGetObjectParameters(o.OBJECT_ID) p
	),

	-- Крок 4: Формуємо JSON properties для параметрів
	ParameterProperties AS (
		SELECT DISTINCT
			o.object_id,
			CONCAT('{',
				STUFF((
								SELECT CONCAT(',', util.mcpBuildParameterJson(p.ParamName, p.TypeName, p.ParamDescription))
								FROM AllParameters p
								WHERE p.object_id = o.object_id
								ORDER BY p.parameter_id
								FOR XML PATH(''), TYPE
							).value('.', 'nvarchar(max)'),
					1,
					1,
					''
				),
				'}'
			) PropertiesJson
		FROM UtilObjects o
	),

	-- Крок 5: Формуємо масив обов'язкових параметрів
	RequiredParameters AS (
		SELECT DISTINCT
			o.object_id,
			COALESCE(CONCAT('[',
								 STUFF((
												 SELECT CONCAT(',"', SUBSTRING(p.ParamName, 2, LEN(p.ParamName)), '"')
												 FROM AllParameters p
												 WHERE p.object_id = o.object_id AND p.HasDefaultValue = 0
												 ORDER BY p.parameter_id
												 FOR XML PATH(''), TYPE
											 ).value('.', 'nvarchar(max)'),
									 1,
									 1,
									 ''
								 ),
								 ']'
							 ),
				'[]'
			) RequiredJson
		FROM UtilObjects o
	),

	-- Крок 6: Збираємо фінальний JSON для кожного tool
	ToolsJson AS (
		SELECT DISTINCT
			o.object_id,
			util.mcpBuildToolJson(o.SchemaName, o.ObjectName, od.Description, pp.PropertiesJson, rp.RequiredJson) ToolJson
		FROM UtilObjects o
			LEFT JOIN ObjectDescriptions od ON od.object_id = o.object_id
			LEFT JOIN ParameterProperties pp ON pp.object_id = o.object_id
			LEFT JOIN RequiredParameters rp ON rp.object_id = o.object_id
	)

	-- Фінальна агрегація (з дедуплікацією)
	SELECT @tools = CONCAT('[',
										STUFF((
			SELECT DISTINCT CONCAT(',', t.ToolJson)
			FROM ToolsJson t 
			FOR XML PATH(''), TYPE
		)											.value('.', 'nvarchar(max)'),
											1,
											1,
											''
										),
										']'
									);

	RETURN CONCAT('{"tools":', ISNULL(@tools, '[]'), '}');
END;
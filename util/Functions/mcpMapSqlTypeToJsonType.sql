CREATE OR ALTER FUNCTION util.mcpMapSqlTypeToJsonType(
    @sqlTypeName SYSNAME
)
RETURNS NVARCHAR(128)
AS
BEGIN
    RETURN CASE @sqlTypeName
        -- Текстові типи
        WHEN 'nvarchar' THEN 'string'
        WHEN 'nchar' THEN 'string'
        WHEN 'varchar' THEN 'string'
        WHEN 'char' THEN 'string'
        WHEN 'text' THEN 'string'
        WHEN 'ntext' THEN 'string'
        WHEN 'uniqueidentifier' THEN 'string'
        WHEN 'sysname' THEN 'string'
        WHEN 'xml' THEN 'string'
        -- Типи дат - також string
        WHEN 'date' THEN 'string'
        WHEN 'datetime' THEN 'string'
        WHEN 'datetime2' THEN 'string'
        WHEN 'smalldatetime' THEN 'string'
        WHEN 'datetimeoffset' THEN 'string'
        WHEN 'time' THEN 'string'
        -- Цілочисельні типи
        WHEN 'int' THEN 'integer'
        WHEN 'bigint' THEN 'integer'
        WHEN 'smallint' THEN 'integer'
        WHEN 'tinyint' THEN 'integer'
        -- Числові типи
        WHEN 'decimal' THEN 'number'
        WHEN 'numeric' THEN 'number'
        WHEN 'money' THEN 'number'
        WHEN 'smallmoney' THEN 'number'
        WHEN 'float' THEN 'number'
        WHEN 'real' THEN 'number'
        -- Логічний тип
        WHEN 'bit' THEN 'boolean'
        -- За замовчуванням
        ELSE 'string'
    END;
END;

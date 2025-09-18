/*
# Description
Повертає детальну інформацію про параметри для вказаної збереженої процедури або функції, 
включаючи назви параметрів, типи даних, напрямки та значення за замовчуванням. 
Виключає системні параметри без імені.

# Parameters
@object NVARCHAR(128) = NULL - Назва об'єкта або object_id для отримання параметрів (NULL = всі об'єкти)

# Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - Ідентифікатор об'єкта
- schemaName NVARCHAR(128) - Назва схеми
- objectName NVARCHAR(128) - Назва об'єкта
- parameterId INT - Ідентифікатор параметра
- parameterName NVARCHAR(128) - Назва параметра

# Usage
-- Отримати параметри конкретної процедури
SELECT * FROM util.metadataGetParameters('util.errorHandler');

-- Отримати параметри всіх об'єктів
SELECT * FROM util.metadataGetParameters(DEFAULT);
*/
CREATE OR ALTER FUNCTION util.metadataGetParameters(@object NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT
    p.object_id objectId,
    OBJECT_SCHEMA_NAME(p.object_id) schemaName,
    OBJECT_NAME(p.object_id) objectName,
    p.parameter_id parameterId,
    p.name parameterName
	FROM sys.parameters p
	WHERE p.name IS NOT NULL -- Виключаємо системні параметри без імені
		AND (@object IS NULL OR p.object_id = ISNULL(TRY_CONVERT(INT, @object), OBJECT_ID(@object)))
);

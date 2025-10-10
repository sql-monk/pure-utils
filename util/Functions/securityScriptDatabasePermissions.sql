/*
# Description
Генерує T-SQL скрипти для відтворення дозволів на рівні бази даних.
Функція аналізує системні каталоги та створює GRANT/DENY команди для копіювання permissions між середовищами.

# Parameters
@granteePrincipal NVARCHAR(128) = NULL - Ім'я principal (користувача/ролі) для якого генерувати скрипти (NULL = всі principals)
@filter NVARCHAR(128) = '%' - Фільтр для назви дозволів за патерном LIKE (NULL або '' = '%')
@includeInherited BIT = 0 - Включати дозволи успадковані через членство в ролях (0 = тільки явні дозволи, 1 = включаючи успадковані)

# Returns
TABLE - Повертає таблицю з колонками:
- principalName NVARCHAR(128) - Ім'я principal (користувача/ролі)
- principalType NVARCHAR(60) - Тип principal
- permissionState NVARCHAR(60) - Стан дозволу (GRANT/DENY/REVOKE)
- permissionName NVARCHAR(128) - Назва дозволу
- objectSchema NVARCHAR(128) - Назва схеми об'єкта (NULL для database-level permissions)
- objectName NVARCHAR(128) - Назва об'єкта (NULL для database-level permissions)
- objectType NVARCHAR(60) - Тип об'єкта
- columnName NVARCHAR(128) - Назва колонки (для column-level permissions)
- permissionScript NVARCHAR(MAX) - Готовий T-SQL скрипт для відтворення дозволу

# Usage
-- Отримати всі дозволи в поточній базі даних
SELECT * FROM util.securityScriptDatabasePermissions(NULL, DEFAULT, DEFAULT);

-- Отримати дозволи для конкретного користувача
SELECT * FROM util.securityScriptDatabasePermissions('myUser', DEFAULT, DEFAULT);

-- Отримати тільки SELECT дозволи
SELECT * FROM util.securityScriptDatabasePermissions(NULL, 'SELECT', DEFAULT);

-- Отримати дозволи включаючи успадковані через ролі
SELECT * FROM util.securityScriptDatabasePermissions('myUser', DEFAULT, 1);
*/
CREATE OR ALTER FUNCTION util.securityScriptDatabasePermissions(
	@granteePrincipal NVARCHAR(128) = NULL,
	@filter NVARCHAR(128) = '%',
	@includeInherited BIT = 0
)
RETURNS TABLE
AS
RETURN(
	WITH PermissionsData AS (
		SELECT
			dp.name principalName,
			dp.type_desc principalType,
			pe.state_desc permissionState,
			pe.permission_name permissionName,
			pe.class_desc permissionClass,
			pe.class,
			pe.major_id,
			pe.minor_id
		FROM sys.database_principals dp(NOLOCK)
			LEFT JOIN sys.database_permissions pe(NOLOCK)ON dp.principal_id = pe.grantee_principal_id
		WHERE dp.is_fixed_role = 0
					AND (
						@granteePrincipal IS NULL OR dp.name = @granteePrincipal
					)
					AND pe.permission_name IS NOT NULL
					AND pe.permission_name LIKE ISNULL(NULLIF(@filter, ''), '%')
					AND USER_NAME(pe.grantee_principal_id) <> 'public'
	)
	SELECT
		pd.principalName,
		pd.principalType,
		pd.permissionState,
		pd.permissionName,
		CASE
			WHEN pd.permissionClass = N'OBJECT_OR_COLUMN' COLLATE DATABASE_DEFAULT
			THEN SCHEMA_NAME(o.schema_id)
			WHEN pd.permissionClass = N'SCHEMA' COLLATE DATABASE_DEFAULT
			THEN SCHEMA_NAME(pd.major_id)
			ELSE NULL
		END objectSchema,
		CASE
			WHEN pd.permissionClass = N'OBJECT_OR_COLUMN' COLLATE DATABASE_DEFAULT
			THEN OBJECT_NAME(pd.major_id)
			WHEN pd.permissionClass = N'TYPE' COLLATE DATABASE_DEFAULT
			THEN TYPE_NAME(pd.major_id)
			WHEN pd.permissionClass = N'ASSEMBLY' COLLATE DATABASE_DEFAULT
			THEN (
				SELECT name FROM sys.assemblies WHERE assembly_id = pd.major_id
			)
			ELSE NULL
		END objectName,
		CASE
			WHEN pd.permissionClass = N'OBJECT_OR_COLUMN' COLLATE DATABASE_DEFAULT
			THEN o.type_desc
			ELSE pd.permissionClass
		END objectType,
		CASE
			WHEN pd.minor_id > 0
			THEN util.metadataGetColumnName(pd.major_id, pd.minor_id)
			ELSE NULL
		END columnName,
		CONCAT(
			pd.permissionState,
			N' ' COLLATE DATABASE_DEFAULT,
			pd.permissionName,
			CASE
				WHEN pd.permissionClass = N'DATABASE' COLLATE DATABASE_DEFAULT
				THEN N'' COLLATE DATABASE_DEFAULT
				ELSE
				CONCAT(
					N' ON ' COLLATE DATABASE_DEFAULT, pd.permissionClass, N'::' COLLATE DATABASE_DEFAULT, util.metadataGetAnyName(pd.major_id, pd.minor_id, pd.class)
				)
			END,
			N' TO ' COLLATE DATABASE_DEFAULT,
			QUOTENAME(pd.principalName),
			N';' COLLATE DATABASE_DEFAULT
		) permissionScript
	FROM PermissionsData pd
		LEFT JOIN sys.objects o(NOLOCK)ON pd.major_id = o.object_id AND pd.permissionClass = N'OBJECT_OR_COLUMN' COLLATE DATABASE_DEFAULT
	WHERE pd.permissionName IS NOT NULL
);
GO

# Security - Налаштування безпеки

## Огляд

Директорія `Security` містить SQL скрипти для налаштування прав доступу до схем `util` та `mcp`. Ці скрипти забезпечують мінімальні необхідні права для використання бібліотеки.

## Файли

### util.sql

**Призначення**: Налаштування прав доступу для схеми util

**Вміст**:
```sql
GRANT EXECUTE ON SCHEMA::util TO [YourRole];
```

**Опис**:
- Надає право виконання всіх функцій та процедур у схемі util
- Замініть `[YourRole]` на назву вашої ролі або користувача

**Використання**:
```sql
-- Створити роль
CREATE ROLE db_util_user;

-- Надати права
GRANT EXECUTE ON SCHEMA::util TO db_util_user;

-- Додати користувачів до ролі
ALTER ROLE db_util_user ADD MEMBER [DOMAIN\User1];
ALTER ROLE db_util_user ADD MEMBER [DOMAIN\User2];
```

### mcp.sql

**Призначення**: Налаштування прав доступу для схеми mcp

**Вміст**:
```sql
GRANT EXECUTE ON SCHEMA::mcp TO [YourRole];
```

**Опис**:
- Надає право виконання всіх процедур у схемі mcp
- Необхідно для роботи MCP серверів

**Використання**:
```sql
-- Створити окрему роль для MCP
CREATE ROLE db_mcp_user;

-- Надати права на mcp (включає виклики util)
GRANT EXECUTE ON SCHEMA::mcp TO db_mcp_user;
GRANT EXECUTE ON SCHEMA::util TO db_mcp_user;

-- Для MCP серверів також потрібні права на читання metadata
GRANT VIEW DEFINITION TO db_mcp_user;

-- Додати SQL login для MCP сервера
CREATE LOGIN mcp_service WITH PASSWORD = 'SecurePassword123';
CREATE USER mcp_service FOR LOGIN mcp_service;
ALTER ROLE db_mcp_user ADD MEMBER mcp_service;
```

## Рекомендовані налаштування безпеки

### 1. Принцип мінімальних прав

Створіть окремі ролі для різних сценаріїв:

```sql
-- Роль для читання metadata (DBA, Developers)
CREATE ROLE db_util_reader;
GRANT EXECUTE ON SCHEMA::util TO db_util_reader;
GRANT VIEW DEFINITION TO db_util_reader;

-- Роль для MCP серверів (AI інтеграція)
CREATE ROLE db_mcp_service;
GRANT EXECUTE ON SCHEMA::mcp TO db_mcp_service;
GRANT EXECUTE ON SCHEMA::util TO db_mcp_service;
GRANT VIEW DEFINITION TO db_mcp_service;
GRANT VIEW SERVER STATE TO db_mcp_service; -- для execution plans

-- Роль для адміністрування (встановлення описів, тощо)
CREATE ROLE db_util_admin;
GRANT EXECUTE ON SCHEMA::util TO db_util_admin;
GRANT ALTER ON SCHEMA::util TO db_util_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::util TO db_util_admin;
```

### 2. Права для Extended Events

Якщо використовуєте XE моніторинг:

```sql
-- Права для читання XE файлів
GRANT ALTER ANY EVENT SESSION TO db_util_admin;
GRANT VIEW SERVER STATE TO db_util_admin;

-- Права для копіювання XE даних у таблиці
GRANT SELECT, INSERT ON util.executionModulesUsers TO db_util_admin;
GRANT SELECT, INSERT ON util.executionModulesSSIS TO db_util_admin;
GRANT SELECT, INSERT ON util.errorLog TO db_util_admin;
```

### 3. Права для cross-database запитів

Деякі функції util можуть працювати з іншими БД:

```sql
-- На рівні сервера
GRANT VIEW ANY DATABASE TO [YourLogin];

-- На рівні кожної БД
USE [TargetDatabase];
GRANT VIEW DEFINITION TO [YourUser];
```

### 4. Обмеження для production

На production середовищі обмежте права:

```sql
-- Тільки читання, без змін
CREATE ROLE db_util_readonly;
GRANT SELECT ON SCHEMA::util TO db_util_readonly;
DENY INSERT, UPDATE, DELETE ON SCHEMA::util TO db_util_readonly;
DENY EXECUTE ON util.metadataSetTableDescription TO db_util_readonly;
DENY EXECUTE ON util.metadataSetColumnDescription TO db_util_readonly;
```

## Приклади налаштувань

### Сценарій 1: DBA з повним доступом

```sql
-- Створити login
CREATE LOGIN [DOMAIN\DBA_User] FROM WINDOWS;

-- Створити user у БД
USE [YourDatabase];
CREATE USER [DOMAIN\DBA_User] FOR LOGIN [DOMAIN\DBA_User];

-- Надати повні права
ALTER ROLE db_owner ADD MEMBER [DOMAIN\DBA_User];
```

### Сценарій 2: Developer з обмеженим доступом

```sql
-- Створити login
CREATE LOGIN [DOMAIN\Dev_User] FROM WINDOWS;

-- Створити user
CREATE USER [DOMAIN\Dev_User] FOR LOGIN [DOMAIN\Dev_User];

-- Надати тільки читання util
GRANT EXECUTE ON SCHEMA::util TO [DOMAIN\Dev_User];
GRANT VIEW DEFINITION TO [DOMAIN\Dev_User];
DENY ALTER ON SCHEMA::util TO [DOMAIN\Dev_User];
```

### Сценарій 3: Service account для MCP серверів

```sql
-- Створити SQL login
CREATE LOGIN mcp_service WITH PASSWORD = 'ComplexPassword123!', 
    CHECK_POLICY = ON, 
    CHECK_EXPIRATION = OFF;

-- Створити user у БД
CREATE USER mcp_service FOR LOGIN mcp_service;

-- Надати мінімальні права
GRANT EXECUTE ON SCHEMA::mcp TO mcp_service;
GRANT EXECUTE ON SCHEMA::util TO mcp_service;
GRANT VIEW DEFINITION TO mcp_service;
GRANT VIEW SERVER STATE TO mcp_service;

-- Заборонити зміни даних
DENY INSERT, UPDATE, DELETE ON SCHEMA::util TO mcp_service;
```

### Сценарій 4: Auditor - тільки перегляд

```sql
-- Створити роль для аудиторів
CREATE ROLE db_auditor;

-- Права тільки на читання audit таблиць
GRANT SELECT ON util.errorLog TO db_auditor;
GRANT SELECT ON util.eventsNotifications TO db_auditor;
GRANT SELECT ON util.executionModulesUsers TO db_auditor;
GRANT SELECT ON util.executionModulesSSIS TO db_auditor;

-- Функції для аналізу (без виконання процедур)
GRANT SELECT ON util.xeGetErrors TO db_auditor;
GRANT SELECT ON util.xeGetModules TO db_auditor;

-- Додати користувача
ALTER ROLE db_auditor ADD MEMBER [DOMAIN\Auditor_User];
```

## Аудит доступу

### Налаштування аудиту на схеми

```sql
-- Створити server audit
CREATE SERVER AUDIT UtilSchemaAudit
TO FILE (FILEPATH = 'C:\Audit\', MAXSIZE = 100 MB, MAX_ROLLOVER_FILES = 10);

-- Створити database audit specification
CREATE DATABASE AUDIT SPECIFICATION UtilSchemaAccess
FOR SERVER AUDIT UtilSchemaAudit
ADD (EXECUTE ON SCHEMA::util BY public),
ADD (EXECUTE ON SCHEMA::mcp BY public),
ADD (SELECT ON SCHEMA::util BY public);

-- Увімкнути аудит
ALTER SERVER AUDIT UtilSchemaAudit WITH (STATE = ON);
ALTER DATABASE AUDIT SPECIFICATION UtilSchemaAccess WITH (STATE = ON);
```

### Моніторинг через Extended Events

```sql
-- Створити XE сесію для відстеження виконань
CREATE EVENT SESSION UtilExecutionAudit ON SERVER
ADD EVENT sqlserver.rpc_completed(
    WHERE schema_name = 'util' OR schema_name = 'mcp'
),
ADD EVENT sqlserver.sql_batch_completed(
    WHERE sqlserver.database_name = 'YourDatabase'
)
ADD TARGET package0.event_file(SET filename='UtilAudit.xel');

-- Запустити сесію
ALTER EVENT SESSION UtilExecutionAudit ON SERVER STATE = START;
```

## Row-Level Security (опціонально)

Для таблиць audit можна налаштувати RLS:

```sql
-- Функція фільтрації (користувачі бачать тільки свої дані)
CREATE FUNCTION util.fn_SecurityPredicateUserData(@UserName NVARCHAR(128))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS result
    WHERE @UserName = ORIGINAL_LOGIN();

-- Застосувати до таблиці
CREATE SECURITY POLICY util.UserDataFilter
ADD FILTER PREDICATE util.fn_SecurityPredicateUserData(UserName)
ON util.executionModulesUsers
WITH (STATE = ON);
```

## Шифрування

### Шифрування чутливих даних

Якщо таблиці util містять чутливі дані:

```sql
-- Створити master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'ComplexPassword123!';

-- Створити сертифікат
CREATE CERTIFICATE UtilCert WITH SUBJECT = 'Util Schema Certificate';

-- Створити симетричний ключ
CREATE SYMMETRIC KEY UtilKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE UtilCert;

-- Шифрування колонки (приклад)
ALTER TABLE util.errorLog
ADD ErrorMessageEncrypted VARBINARY(MAX);

-- Використання
OPEN SYMMETRIC KEY UtilKey DECRYPTION BY CERTIFICATE UtilCert;

UPDATE util.errorLog
SET ErrorMessageEncrypted = ENCRYPTBYKEY(KEY_GUID('UtilKey'), ErrorMessage);

CLOSE SYMMETRIC KEY UtilKey;
```

## Backup та Restore прав

### Скрипт backup прав

```sql
-- Збереження прав у таблицю
SELECT 
    dp.name AS PrincipalName,
    dp.type_desc AS PrincipalType,
    o.name AS ObjectName,
    p.permission_name,
    p.state_desc
INTO util.PermissionsBackup
FROM sys.database_permissions p
    JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
    LEFT JOIN sys.objects o ON p.major_id = o.object_id
WHERE o.schema_id IN (SCHEMA_ID('util'), SCHEMA_ID('mcp'))
   OR p.class = 3; -- SCHEMA level permissions
```

### Скрипт restore прав

```sql
-- Генерація команд відновлення
SELECT 
    CASE state_desc
        WHEN 'GRANT' THEN 'GRANT'
        WHEN 'DENY' THEN 'DENY'
    END + ' ' + permission_name + 
    CASE 
        WHEN ObjectName IS NOT NULL THEN ' ON ' + ObjectName
        WHEN class = 3 THEN ' ON SCHEMA::' + SCHEMA_NAME(major_id)
    END +
    ' TO [' + PrincipalName + ']'
FROM util.PermissionsBackup;
```

## Best Practices

1. **Використовуйте ролі** замість прямих прав користувачам
2. **Застосовуйте принцип мінімальних прав**
3. **Регулярно переглядайте** надані права
4. **Аудитуйте доступ** до критичних функцій
5. **Документуйте** бізнес-обґрунтування для прав
6. **Використовуйте AD групи** де можливо
7. **Періодично ротуйте паролі** для service accounts
8. **Тестуйте права** на dev середовищі

## Troubleshooting

### Помилка: "Permission denied on object"

**Рішення**: 
```sql
-- Перевірити права
SELECT * FROM fn_my_permissions('util.indexesGetMissing', 'OBJECT');

-- Надати права
GRANT EXECUTE ON util.indexesGetMissing TO [User];
```

### Помилка: "Cannot access database"

**Рішення**:
```sql
-- Перевірити членство у ролях
SELECT 
    dp.name,
    USER_NAME(drm.member_principal_id) AS MemberName
FROM sys.database_role_members drm
    JOIN sys.database_principals dp ON drm.role_principal_id = dp.principal_id;
```

## Наступні кроки

- [Extended Events моніторинг](XESessions.md)
- [Конфігурація](../config.md)
- [FAQ](../faq.md)

# Quick Start Guide - PureSqlsApi

## 5-хвилинний старт

### 1. Запустіть сервіс (1 хв)
```bash
cd PureSqlsApi
dotnet run -- --server localhost --database msdb --port 5000
```

### 2. Створіть SQL функцію (2 хв)
```sql
USE msdb;
GO

-- Створення схеми api
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'api')
    EXEC('CREATE SCHEMA api');
GO

-- Приклад list функції
CREATE OR ALTER FUNCTION api.serverInfoList()
RETURNS TABLE
AS
RETURN(
    SELECT 
        (
            SELECT 
                SERVERPROPERTY('ServerName') AS serverName,
                SERVERPROPERTY('Edition') AS edition,
                SERVERPROPERTY('ProductVersion') AS version
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS jsondata
);
GO
```

### 3. Викличте API (1 хв)
```bash
curl http://localhost:5000/serverInfo/list
```

### 4. Результат
```json
{
  "count": 1,
  "data": [
    {
      "serverName": "MYSERVER",
      "edition": "Developer Edition",
      "version": "16.0.1000.6"
    }
  ]
}
```

## Шаблони SQL об'єктів

### 📋 LIST - Таблична функція (повертає список)

```sql
CREATE OR ALTER FUNCTION api.{resourceName}List(
    @param1 TYPE = NULL,
    @param2 TYPE = NULL
)
RETURNS TABLE
AS
RETURN(
    SELECT 
        (
            SELECT 
                t.column1,
                t.column2,
                t.column3
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS jsondata
    FROM YourTable t
    WHERE 
        (@param1 IS NULL OR t.column1 = @param1)
        AND (@param2 IS NULL OR t.column2 = @param2)
);
GO
```

**HTTP виклик:**
```
GET /{resourceName}/list?param1=value1&param2=value2
```

### 🔍 GET - Скалярна функція (повертає один об'єкт)

```sql
CREATE OR ALTER FUNCTION api.{resourceName}Get(@id INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (
        SELECT 
            t.column1,
            t.column2,
            t.column3
        FROM YourTable t
        WHERE t.id = @id
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
END;
GO
```

**HTTP виклик:**
```
GET /{resourceName}/get?id=123
```

### ⚡ EXEC - Процедура (виконує операцію)

```sql
CREATE OR ALTER PROCEDURE api.{ProcedureName}
    @param1 TYPE,
    @param2 TYPE = NULL,
    @response NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Ваша логіка тут
        -- INSERT, UPDATE, DELETE, etc.
        
        SET @response = (
            SELECT 
                'true' AS success,
                'Operation completed' AS message,
                (
                    SELECT 
                        -- результати операції
                        @param1 AS param1
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ) AS data
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END TRY
    BEGIN CATCH
        SET @response = (
            SELECT 
                'false' AS success,
                ERROR_MESSAGE() AS message,
                ERROR_NUMBER() AS errorCode
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END CATCH
END;
GO
```

**HTTP виклик:**
```
GET /exec/{ProcedureName}?param1=value1&param2=value2
```

## Корисні приклади

### Отримання списку таблиць

```sql
CREATE OR ALTER FUNCTION api.tablesList(@schemaName NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
    SELECT 
        (
            SELECT 
                s.name AS schemaName,
                t.name AS tableName,
                t.create_date AS created,
                t.modify_date AS modified
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS jsondata
    FROM sys.tables t
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE @schemaName IS NULL OR s.name = @schemaName
);
GO
```

**Виклик:**
```bash
# Всі таблиці
curl http://localhost:5000/tables/list

# Тільки dbo schema
curl "http://localhost:5000/tables/list?schemaName=dbo"
```

### Отримання інформації про базу даних

```sql
CREATE OR ALTER FUNCTION api.databaseGet()
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (
        SELECT 
            DB_NAME() AS databaseName,
            DATABASEPROPERTYEX(DB_NAME(), 'Status') AS status,
            DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS collation,
            DATABASEPROPERTYEX(DB_NAME(), 'Recovery') AS recoveryModel
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
END;
GO
```

**Виклик:**
```bash
curl http://localhost:5000/database/get
```

### Статистика по таблиці

```sql
CREATE OR ALTER FUNCTION api.tableStatsGet(
    @schemaName NVARCHAR(128),
    @tableName NVARCHAR(128)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (
        SELECT 
            QUOTENAME(@schemaName) + '.' + QUOTENAME(@tableName) AS fullName,
            p.rows AS rowCount,
            SUM(a.total_pages) * 8 / 1024 AS totalSpaceMB,
            SUM(a.used_pages) * 8 / 1024 AS usedSpaceMB,
            (SUM(a.total_pages) - SUM(a.used_pages)) * 8 / 1024 AS unusedSpaceMB
        FROM sys.tables t
            INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
            INNER JOIN sys.indexes i ON t.object_id = i.object_id
            INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
            INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
        WHERE 
            s.name = @schemaName 
            AND t.name = @tableName
            AND i.object_id > 255
        GROUP BY 
            s.name,
            t.name,
            p.rows
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
END;
GO
```

**Виклик:**
```bash
curl "http://localhost:5000/tableStats/get?schemaName=dbo&tableName=MyTable"
```

## Типи параметрів

PureSqlsApi автоматично конвертує HTTP query параметри:

| SQL Тип | Приклад HTTP параметра | Що передається в SQL |
|---------|----------------------|---------------------|
| INT | `?id=123` | `123` (int) |
| DECIMAL | `?price=99.99` | `99.99` (decimal) |
| BIT | `?active=true` | `1` (bit) |
| NVARCHAR | `?name=John` | `'John'` (nvarchar) |
| DATE | `?date=2024-01-15` | `'2024-01-15'` (string, SQL конвертує) |

## Налагодження

### Помилка: "Invalid object name 'api.xxxList'"

**Причина:** Функція не існує у схемі api

**Рішення:**
```sql
-- Перевірте існування
SELECT * FROM sys.objects 
WHERE schema_id = SCHEMA_ID('api') 
  AND name = 'xxxList';

-- Створіть функцію
CREATE OR ALTER FUNCTION api.xxxList()
RETURNS TABLE
AS RETURN(SELECT '{}' AS jsondata);
GO
```

### Помилка: "Conversion failed..."

**Причина:** Тип параметра в HTTP не відповідає SQL типу

**Рішення:**
- Перевірте правильність передачі параметрів
- Додайте валідацію в SQL функції/процедури

### Сервіс не підключається до SQL Server

**Перевірте:**
1. SQL Server запущено
2. TCP/IP протокол увімкнено
3. Firewall не блокує порт 1433
4. Connection string правильний

## Best Practices

1. **Завжди використовуйте параметри за замовчуванням = NULL** для опціональних фільтрів
2. **Валідуйте вхідні дані на SQL рівні**, не покладайтесь на HTTP валідацію
3. **Використовуйте TRY/CATCH** в процедурах для обробки помилок
4. **Обмежуйте кількість результатів** в list функціях (TOP 1000)
5. **Додавайте індекси** на колонки, які використовуються для фільтрації
6. **Документуйте параметри** в коментарях SQL об'єктів

## Наступні кроки

1. ✅ Створіть свої перші API endpoints
2. ✅ Протестуйте з curl або Postman
3. ✅ Використайте в d3.js або іншому фронтенді
4. ⚠️ Додайте автентифікацію через reverse proxy для продакшн
5. ⚠️ Налаштуйте моніторинг та логування

---

**Документація:** [README.md](README.md) | **Тестування:** [TESTING.md](TESTING.md)

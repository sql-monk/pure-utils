# PureSqlsApi Test Guide

Цей документ описує як протестувати PureSqlsApi після запуску.

## Підготовка

1. Створіть тестову базу даних або використайте існуючу
2. Виконайте SQL скрипт для створення схеми api:
```sql
USE [YourDatabase];
GO
:r api/Security/api.sql
GO
```

3. Створіть приклади SQL об'єктів:
```sql
:r api/Functions/exampleList.sql
GO
:r api/Functions/exampleGet.sql
GO
:r api/Procedures/ExampleCreate.sql
GO
```

## Запуск сервісу

### Варіант 1: З Windows автентифікацією
```bash
cd PureSqlsApi
dotnet run -- --server localhost --database TestDB --port 5000
```

### Варіант 2: З SQL автентифікацією
```bash
dotnet run -- --server localhost --database TestDB --user sa --port 5000
# Буде запитано пароль
```

## Тестові запити

### 1. Тест LIST endpoint

**Запит:** Отримати всі об'єкти
```bash
curl http://localhost:5000/example/list
```

**Очікувана відповідь:**
```json
{
  "count": 4,
  "data": [
    {"id": 1, "name": "Example 1", "type": "demo", "value": 100},
    {"id": 2, "name": "Example 2", "type": "test", "value": 200},
    {"id": 3, "name": "Example 3", "type": "demo", "value": 300},
    {"id": 4, "name": "Example 4", "type": "prod", "value": 400}
  ]
}
```

**Запит:** З фільтром по типу
```bash
curl "http://localhost:5000/example/list?type=demo"
```

**Очікувана відповідь:**
```json
{
  "count": 2,
  "data": [
    {"id": 1, "name": "Example 1", "type": "demo", "value": 100},
    {"id": 3, "name": "Example 3", "type": "demo", "value": 300}
  ]
}
```

### 2. Тест GET endpoint

**Запит:** Отримати об'єкт з ID=2
```bash
curl "http://localhost:5000/example/get?id=2"
```

**Очікувана відповідь:**
```json
{
  "id": 2,
  "name": "Example 2",
  "type": "test",
  "value": 200,
  "description": "Second example item"
}
```

**Запит:** Неіснуючий ID
```bash
curl "http://localhost:5000/example/get?id=999"
```

**Очікувана відповідь:**
```json
{}
```
або `null`

### 3. Тест EXEC endpoint

**Запит:** Створити новий об'єкт
```bash
curl "http://localhost:5000/exec/ExampleCreate?name=Test%20Product&value=1500"
```

**Очікувана відповідь:**
```json
{
  "success": "true",
  "message": "Object created successfully",
  "data": {
    "id": 1234,
    "name": "Test Product",
    "value": 1500,
    "createdAt": "2024-10-21T01:40:00.123"
  }
}
```

## Тестування з PowerShell

```powershell
# List endpoint
Invoke-RestMethod -Uri "http://localhost:5000/example/list" -Method Get

# Get endpoint
Invoke-RestMethod -Uri "http://localhost:5000/example/get?id=2" -Method Get

# Exec endpoint
Invoke-RestMethod -Uri "http://localhost:5000/exec/ExampleCreate?name=MyItem&value=500" -Method Get
```

## Тестування з curl (Windows)

```cmd
REM List all
curl http://localhost:5000/example/list

REM List with filter
curl "http://localhost:5000/example/list?type=demo"

REM Get by ID
curl "http://localhost:5000/example/get?id=2"

REM Execute procedure
curl "http://localhost:5000/exec/ExampleCreate?name=TestItem&value=999"
```

## Тестування помилок

### Неіснуючий SQL об'єкт
```bash
curl http://localhost:5000/unknown/list
```

**Очікувана відповідь (HTTP 500):**
```json
{
  "error": "Invalid object name 'api.unknownList'.",
  "type": "SqlException"
}
```

### Неправильні параметри
```bash
curl "http://localhost:5000/example/get?id=abc"
```

**Може бути SQL помилка про конвертацію типів**

## Створення власних API endpoints

### 1. Таблична функція для списку продуктів

```sql
CREATE OR ALTER FUNCTION api.productsList(
    @category NVARCHAR(50) = NULL,
    @minPrice DECIMAL(10,2) = NULL
)
RETURNS TABLE
AS
RETURN(
    WITH cteProducts AS (
        SELECT 1 AS id, 'Laptop' AS name, 'electronics' AS category, 1200.00 AS price
        UNION ALL
        SELECT 2, 'Mouse', 'electronics', 25.00
        UNION ALL
        SELECT 3, 'Desk', 'furniture', 350.00
        UNION ALL
        SELECT 4, 'Chair', 'furniture', 180.00
    )
    SELECT 
        (
            SELECT 
                p.id,
                p.name,
                p.category,
                p.price
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS jsondata
    FROM cteProducts p
    WHERE 
        (@category IS NULL OR p.category = @category)
        AND (@minPrice IS NULL OR p.price >= @minPrice)
);
GO
```

**Тестування:**
```bash
# Всі продукти
curl http://localhost:5000/products/list

# Тільки electronics
curl "http://localhost:5000/products/list?category=electronics"

# Мінімальна ціна
curl "http://localhost:5000/products/list?minPrice=100"

# Комбінований фільтр
curl "http://localhost:5000/products/list?category=electronics&minPrice=30"
```

### 2. Скалярна функція для одного продукту

```sql
CREATE OR ALTER FUNCTION api.productGet(@id INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    
    WITH cteProducts AS (
        SELECT 1 AS id, 'Laptop' AS name, 'electronics' AS category, 1200.00 AS price, 'High-end laptop' AS description
        UNION ALL
        SELECT 2, 'Mouse', 'electronics', 25.00, 'Wireless mouse'
        UNION ALL
        SELECT 3, 'Desk', 'furniture', 350.00, 'Standing desk'
        UNION ALL
        SELECT 4, 'Chair', 'furniture', 180.00, 'Office chair'
    )
    SELECT @result = (
        SELECT 
            p.id,
            p.name,
            p.category,
            p.price,
            p.description
        FROM cteProducts p
        WHERE p.id = @id
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
    
    RETURN @result;
END;
GO
```

**Тестування:**
```bash
curl "http://localhost:5000/product/get?id=1"
curl "http://localhost:5000/product/get?id=3"
```

### 3. Процедура для створення замовлення

```sql
CREATE OR ALTER PROCEDURE api.CreateOrder
    @customerId INT,
    @productId INT,
    @quantity INT = 1,
    @response NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @orderId INT = ABS(CHECKSUM(NEWID())) % 100000;
    DECLARE @orderDate DATETIME2 = SYSDATETIME();
    
    BEGIN TRY
        -- В реальному коді тут би був INSERT INTO orders...
        
        SET @response = (
            SELECT 
                'true' AS success,
                'Order created successfully' AS message,
                (
                    SELECT 
                        @orderId AS orderId,
                        @customerId AS customerId,
                        @productId AS productId,
                        @quantity AS quantity,
                        @orderDate AS orderDate,
                        'pending' AS status
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ) AS order
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

**Тестування:**
```bash
curl "http://localhost:5000/exec/CreateOrder?customerId=1&productId=2&quantity=3"
```

## Поради для продакшн використання

1. **Безпека**: Додайте reverse proxy (nginx, IIS) з автентифікацією
2. **CORS**: Якщо потрібно - додайте CORS middleware
3. **Rate Limiting**: Обмежте кількість запитів
4. **Логування**: Додайте structured logging (Serilog)
5. **Валідація**: Додайте валідацію параметрів на SQL рівні
6. **Кешування**: Використовуйте response caching для read-only endpoints
7. **Здоров'я**: Додайте `/health` endpoint для моніторингу

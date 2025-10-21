# PureSqlsApi

HTTP API мікросервіс, який слугує тонким адаптером між HTTP-запитами та SQL-об'єктами (процедурами, функціями, представленнями) у схемі `api` бази даних SQL Server.

## 🎯 Мета

Надати простий HTTP API для доступу до SQL об'єктів без дублювання бізнес-логіки в коді C#. Вся логіка залишається в базі даних, а мікросервіс лише маршрутизує запити та серіалізує відповіді у JSON формат.

## 🚀 Запуск

### Базовий запуск
```bash
dotnet run
```

За замовчуванням:
- SQL Server: `localhost`
- База даних: `msdb`
- Автентифікація: Windows
- HTTP порт: `51433`
- HTTP host: `localhost`

### Запуск з параметрами

```bash
# З вказанням сервера та бази даних
dotnet run -- --server localhost --database TestDB --port 5000

# Скорочені параметри
dotnet run -- -s myserver -d MyDatabase -p 8080

# З SQL автентифікацією
dotnet run -- -s localhost -d TestDB -u myuser -p 5000
# (пароль буде запитано інтерактивно)

# Показати довідку
dotnet run -- --help
```

### Параметри командного рядка

| Параметр | Скорочений | Опис | За замовчуванням |
|----------|-----------|------|------------------|
| `--server` | `-s` | SQL Server instance | `localhost` |
| `--database` | `-d` | Ім'я бази даних | `msdb` |
| `--user` | `-u` | Користувач SQL (якщо не вказано - Windows auth) | - |
| `--port` | `-p` | HTTP порт | `51433` |
| `--host` | `-h` | HTTP host | `localhost` |
| `--help` | - | Показати довідку | - |

## 📡 API Маршрути

### 1. List - Отримання списку (таблична функція)

**Маршрут:** `GET /{resource}/list`

**Виклик SQL:** `api.{resource}List()`

**Опис:** Викликає табличну функцію, яка повертає результати у вигляді таблиці з колонкою `jsondata`, де кожен рядок - валідний JSON-об'єкт.

**Відповідь:**
```json
{
  "count": 2,
  "data": [
    {"id": 1, "name": "Item 1"},
    {"id": 2, "name": "Item 2"}
  ]
}
```

**Приклади:**
```bash
# Без параметрів
curl http://localhost:51433/products/list

# З параметрами
curl "http://localhost:51433/products/list?category=electronics&minPrice=100"
```

### 2. Get - Отримання одного значення (скалярна функція)

**Маршрут:** `GET /{resource}/get`

**Виклик SQL:** `api.{resource}Get()`

**Опис:** Викликає скалярну функцію, яка повертає NVARCHAR(MAX) з JSON.

**Відповідь:**
```json
{"id": 1, "name": "Product Name", "price": 99.99}
```

**Приклади:**
```bash
# Отримати продукт за ID
curl "http://localhost:51433/product/get?id=123"

# Отримати користувача
curl "http://localhost:51433/user/get?email=user@example.com"
```

### 3. Exec - Виконання процедури

**Маршрут:** `GET /exec/{procedureName}`

**Виклик SQL:** `api.{procedureName}`

**Опис:** Викликає процедуру з OUTPUT параметром `@response`, який повертає валідний JSON.

**Відповідь:**
```json
{"success": true, "message": "Operation completed", "result": {...}}
```

**Приклади:**
```bash
# Виконати процедуру без параметрів
curl http://localhost:51433/exec/GetServerInfo

# Виконати процедуру з параметрами
curl "http://localhost:51433/exec/CreateUser?name=John&email=john@example.com"
```

## 🔧 SQL Об'єкти в схемі api

### Приклад таблично функції (list)

```sql
CREATE OR ALTER FUNCTION api.productsList(@category NVARCHAR(50) = NULL)
RETURNS TABLE
AS
RETURN(
    SELECT 
        (
            SELECT 
                p.product_id AS id,
                p.name,
                p.price,
                p.category
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS jsondata
    FROM products p
    WHERE @category IS NULL OR p.category = @category
);
GO
```

### Приклад скалярної функції (get)

```sql
CREATE OR ALTER FUNCTION api.productGet(@id INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (
        SELECT 
            p.product_id AS id,
            p.name,
            p.price,
            p.category,
            p.description
        FROM products p
        WHERE p.product_id = @id
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
END;
GO
```

### Приклад процедури (exec)

```sql
CREATE OR ALTER PROCEDURE api.CreateProduct
    @name NVARCHAR(100),
    @price DECIMAL(10,2),
    @category NVARCHAR(50),
    @response NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @newId INT;
    
    BEGIN TRY
        INSERT INTO products (name, price, category)
        VALUES (@name, @price, @category);
        
        SET @newId = SCOPE_IDENTITY();
        
        SET @response = (
            SELECT 
                'true' AS success,
                'Product created successfully' AS message,
                @newId AS productId
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END TRY
    BEGIN CATCH
        SET @response = (
            SELECT 
                'false' AS success,
                ERROR_MESSAGE() AS message
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END CATCH
END;
GO
```

## 🔒 Безпека

⚠️ **ВАЖЛИВО:** Даний сервіс призначений для локального використання і не має вбудованої автентифікації/авторизації.

**Рекомендації:**
- Не відкривайте доступ до сервісу з зовнішньої мережі
- Використовуйте обмежені права для SQL користувача
- При необхідності публічного доступу - додайте reverse proxy з автентифікацією (наприклад, nginx з basic auth)

## 🛠️ Обробка помилок

При виникненні помилки в SQL запиті, сервіс повертає HTTP 500 з описом помилки у JSON форматі:

```json
{
  "error": "Invalid object name 'api.unknownList'.",
  "type": "SqlException"
}
```

## 📦 Компіляція

### Для Windows (x64)
```bash
cd PureSqlsApi
.\build.ps1
```

Або з явними параметрами:
```bash
.\build.ps1 -Configuration Release -Runtime win-x64
```

### Для інших платформ
```bash
# Linux x64
dotnet publish -c Release -r linux-x64 --self-contained -p:PublishSingleFile=true

# macOS x64
dotnet publish -c Release -r osx-x64 --self-contained -p:PublishSingleFile=true
```

Результат буде у `bin/Release/net8.0/{runtime}/publish/`

## 🧪 Тестування

### Базова перевірка

1. Запустіть сервіс:
```bash
dotnet run -- -s localhost -d TestDB -p 5000
```

2. Перевірте доступність (у іншому терміналі):
```bash
# Тестовий запит
curl http://localhost:5000/test/list
```

### Приклад тестування з curl

```bash
# List endpoint
curl -X GET "http://localhost:51433/products/list?category=books"

# Get endpoint
curl -X GET "http://localhost:51433/product/get?id=1"

# Exec endpoint
curl -X GET "http://localhost:51433/exec/GetStatistics"
```

## 📚 Розширення

### Додавання нового API ресурсу

1. Створіть SQL функцію або процедуру у схемі `api`:
   - Для списків: `api.{resourceName}List`
   - Для одного запису: `api.{resourceName}Get`
   - Для процедур: `api.{procedureName}`

2. API автоматично стане доступним через відповідний маршрут

### Приклад з параметрами за замовчуванням

```sql
CREATE OR ALTER FUNCTION api.ordersList(
    @status NVARCHAR(20) = NULL,
    @fromDate DATE = NULL,
    @toDate DATE = NULL
)
RETURNS TABLE
AS
RETURN(
    SELECT 
        (
            SELECT 
                o.order_id AS id,
                o.customer_name AS customer,
                o.order_date AS date,
                o.status,
                o.total
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS jsondata
    FROM orders o
    WHERE 
        (@status IS NULL OR o.status = @status)
        AND (@fromDate IS NULL OR o.order_date >= @fromDate)
        AND (@toDate IS NULL OR o.order_date <= @toDate)
);
GO
```

Використання:
```bash
# Всі замовлення
curl http://localhost:51433/orders/list

# Тільки активні
curl "http://localhost:51433/orders/list?status=active"

# За період
curl "http://localhost:51433/orders/list?fromDate=2024-01-01&toDate=2024-12-31"
```

## 🔍 Діагностика

### Перевірка підключення до SQL Server

Сервіс автоматично перевіряє підключення при запуску:
```
✓ Підключено до SQL Server: localhost, база даних: TestDB
✓ PureSqlsApi запущено на http://localhost:51433
```

### Налагодження SQL запитів

При помилці SQL, перевірте:
1. Чи існує схема `api` в базі даних
2. Чи існує функція/процедура з правильним ім'ям
3. Чи відповідають параметри у HTTP запиті параметрам SQL об'єкта
4. Чи має користувач права на виконання об'єкта

## 📄 Ліцензія

Частина проекту pure-utils.

## 🤝 Внесок

При додаванні нових можливостей дотримуйтесь принципу мінімальної бізнес-логіки в C# коді. Всі трансформації даних та валідації повинні бути в SQL об'єктах.

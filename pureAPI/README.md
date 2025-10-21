# pureAPI - Thin HTTP Adapter for SQL Server API Objects

## Опис

pureAPI - це мікросервіс на Python, який слугує тонким адаптером між HTTP-запитами та SQL-об'єктами (процедурами, функціями, представленнями) у схемі `api` бази даних. Вся бізнес-логіка залишається в базі даних, Python-шар лише маршрутизує запити та серіалізує відповіді.

**Мета:** прискорити створення API-інтерфейсів до існуючих SQL-об'єктів, мінімізувати дублювання логіки.

## Особливості

- ✅ Автоматична маршрутизація до SQL-об'єктів у схемі `api`
- ✅ Підтримка табличних функцій (list), скалярних функцій (get) та процедур (exec)
- ✅ Використання сучасного драйвера `pymssql` для SQL Server
- ✅ Мінімальна конфігурація - всі параметри через CLI
- ✅ Windows та SQL Server автентифікація
- ✅ Автоматична серіалізація/десеріалізація JSON
- ✅ Простий запуск без додаткових налаштувань

## Вимоги

- Python 3.8+
- SQL Server 2016+ (з підтримкою FOR JSON)
- Схема `api` в базі даних

## Встановлення

```bash
cd pureAPI
pip install -r requirements.txt
```

## Запуск

### Windows автентифікація

```bash
python server.py -s localhost -d msdb
```

### SQL Server автентифікація

```bash
python server.py -s localhost -d msdb -u sa
# Пароль буде запитано інтерактивно
```

### З власним портом

```bash
python server.py -s localhost -d msdb -p 8080
```

## Параметри CLI

| Параметр | Короткий | Опис | За замовчуванням |
|----------|----------|------|------------------|
| `--server` | `-s` | Ім'я або адреса SQL Server | *обов'язковий* |
| `--database` | `-d` | Назва бази даних | `msdb` |
| `--user` | `-u` | Користувач SQL Server (не вказувати для Windows auth) | - |
| `--port` | `-p` | HTTP порт сервера | `51433` |
| `--host` | - | HTTP хост сервера | `127.0.0.1` |

## API Endpoints

### 1. List - Табличні функції

**Endpoint:** `GET /{resource}/list`

**SQL об'єкт:** `api.{resource}List` - табличне функція

**Повертає:** Таблиця з однією колонкою `jsondata`, де кожен рядок містить валідний JSON-об'єкт

**Відповідь:**
```json
{
  "data": [
    {...},
    {...}
  ],
  "count": 2
}
```

**Приклад SQL функції:**
```sql
CREATE OR ALTER FUNCTION api.usersList(@status NVARCHAR(50) = NULL)
RETURNS TABLE
AS
RETURN(
    SELECT 
        (
            SELECT 
                u.userId,
                u.userName,
                u.email,
                u.status
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS jsondata
    FROM users u
    WHERE @status IS NULL OR u.status = @status
);
GO
```

**Виклик:**
```bash
curl "http://localhost:51433/users/list?status=active"
```

### 2. Get - Скалярні функції

**Endpoint:** `GET /{resource}/get`

**SQL об'єкт:** `api.{resource}Get` - скалярна функція

**Повертає:** `NVARCHAR(MAX)` з JSON-контентом

**Відповідь:** JSON-об'єкт або значення

**Приклад SQL функції:**
```sql
CREATE OR ALTER FUNCTION api.userGet(@userId INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    
    SELECT @result = (
        SELECT 
            u.userId,
            u.userName,
            u.email,
            u.status,
            u.createdDate
        FROM users u
        WHERE u.userId = @userId
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
    
    RETURN @result;
END;
GO
```

**Виклик:**
```bash
curl "http://localhost:51433/user/get?userId=123"
```

### 3. Exec - Процедури

**Endpoint:** `GET /exec/{procedureName}`

**SQL об'єкт:** `api.{procedureName}` - збережена процедура

**Вимоги:** Процедура повинна мати OUTPUT параметр `@response NVARCHAR(MAX)`

**Відповідь:** JSON з OUTPUT параметра

**Приклад SQL процедури:**
```sql
CREATE OR ALTER PROCEDURE api.createUser
    @userName NVARCHAR(100),
    @email NVARCHAR(255),
    @response NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @userId INT;
    
    BEGIN TRY
        INSERT INTO users (userName, email, status, createdDate)
        VALUES (@userName, @email, 'active', GETDATE());
        
        SET @userId = SCOPE_IDENTITY();
        
        SELECT @response = (
            SELECT 
                'success' AS status,
                @userId AS userId,
                'User created successfully' AS message
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END TRY
    BEGIN CATCH
        SELECT @response = (
            SELECT 
                'error' AS status,
                ERROR_MESSAGE() AS message
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END CATCH
END;
GO
```

**Виклик:**
```bash
curl "http://localhost:51433/exec/createUser?userName=john&email=john@example.com"
```

### 4. Health Check

**Endpoint:** `GET /health`

**Опис:** Перевірка стану сервісу та підключення до бази даних

**Відповідь:**
```json
{
  "status": "healthy",
  "database": "msdb"
}
```

## Передача параметрів

HTTP GET параметри автоматично передаються як параметри SQL-об'єкта:

- `?param1=value1&param2=value2` → `@param1 = 'value1', @param2 = 'value2'`
- Імена параметрів повинні точно відповідати іменам параметрів SQL-об'єкта
- Відсутність параметра означає `NULL` (якщо параметр має значення за замовчуванням)

## Обробка помилок

При помилках SQL Server повертається HTTP 500 з описом помилки:

```json
{
  "detail": "Database error: ..."
}
```

## Структура проекту

```
pureAPI/
├── server.py           # Основний файл сервісу
├── requirements.txt    # Python залежності
└── README.md          # Документація
```

## Приклади використання

### Створення простого API для таблиці

```sql
-- Створіть схему api, якщо її немає
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'api')
    EXEC('CREATE SCHEMA api');
GO

-- List функція
CREATE OR ALTER FUNCTION api.productsList(@category NVARCHAR(50) = NULL)
RETURNS TABLE
AS
RETURN(
    SELECT 
        (
            SELECT 
                p.productId,
                p.productName,
                p.category,
                p.price
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS jsondata
    FROM products p
    WHERE @category IS NULL OR p.category = @category
);
GO

-- Get функція
CREATE OR ALTER FUNCTION api.productGet(@productId INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (
        SELECT 
            p.productId,
            p.productName,
            p.category,
            p.price,
            p.description
        FROM products p
        WHERE p.productId = @productId
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
END;
GO
```

Запустіть сервер:
```bash
python server.py -s localhost -d MyDatabase
```

Викликайте API:
```bash
# Всі продукти
curl "http://localhost:51433/products/list"

# Продукти за категорією
curl "http://localhost:51433/products/list?category=Electronics"

# Конкретний продукт
curl "http://localhost:51433/product/get?productId=123"
```

## Безпека

⚠️ **Важливо:** На поточному етапі сервіс призначений для локального використання та не містить:

- Автентифікації на рівні HTTP
- Авторізації запитів
- HTTPS підтримки
- Rate limiting

### Захист від SQL Injection

Сервіс використовує наступні механізми захисту:

1. **Валідація ідентифікаторів**: всі імена функцій, процедур та параметрів валідуються перед використанням. Дозволено лише алфавітно-цифрові символи та підкреслення.
2. **Параметризовані запити**: всі значення параметрів передаються через підготовлені запити (prepared statements).
3. **Фіксована схема**: всі об'єкти повинні бути в схемі `api` - не можна викликати довільні схеми.
4. **Обмеження помилок**: детальні помилки не передаються клієнту, щоб не розкривати внутрішню структуру.

### Для production використання рекомендується:

- Використовувати reverse proxy (nginx, IIS) з HTTPS
- Додати автентифікацію (JWT, API keys)
- Обмежити доступ firewall правилами
- Використовувати SQL Server автентифікацію з обмеженими правами
- Надати користувачу SQL Server лише EXECUTE права на об'єкти схеми `api`

## Troubleshooting

### Помилка підключення до SQL Server

Переконайтеся, що:
- SQL Server запущений і доступний
- TCP/IP протокол увімкнений в SQL Server Configuration Manager
- Firewall дозволяє підключення до SQL Server порту (зазвичай 1433)
- Назва instance вказана правильно (наприклад, `localhost\SQLEXPRESS`)

### Помилка "Invalid object name 'api.xxxList'"

Переконайтеся, що:
- Схема `api` існує в базі даних
- Функція/процедура існує з правильним ім'ям
- Поточний користувач має права на виконання об'єктів у схемі `api`

### Помилка парсингу JSON

Переконайтеся, що:
- SQL функція повертає валідний JSON
- Використовується `FOR JSON PATH` або `FOR JSON AUTO`
- JSON не містить синтаксичних помилок

## Розробка

### Додавання нових типів endpoints

Для додавання нових типів endpoints відредагуйте `server.py`:

```python
@app.get("/{resource}/custom")
async def resource_custom(resource: str, request: Request):
    params = dict(request.query_params)
    function_name = f"{resource}Custom"
    result = execute_table_function(function_name, params)
    return JSONResponse(content=result)
```

## Ліцензія

Цей проект є частиною репозиторію pure-utils.

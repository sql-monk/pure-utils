# Quick Start Guide - pureAPI

Швидкий старт для роботи з pureAPI мікросервісом.

## Крок 1: Встановлення

```bash
cd pureAPI
pip install -r requirements.txt
```

## Крок 2: Створення схеми API в SQL Server

Підключіться до вашої бази даних і виконайте:

```sql
-- Створити схему api
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'api')
    EXEC('CREATE SCHEMA api');
GO
```

## Крок 3: Розгортання прикладів SQL об'єктів

Розгорніть приклади з директорії `../api/`:

```bash
# З папки pureAPI
cd ..

# Розгорнути функції
sqlcmd -S localhost -d YourDatabase -i api/Functions/databasesList.sql
sqlcmd -S localhost -d YourDatabase -i api/Functions/databaseGet.sql

# Розгорнути процедури
sqlcmd -S localhost -d YourDatabase -i api/Procedures/testOperation.sql
```

Або використовуйте SSMS/Azure Data Studio для виконання SQL скриптів.

## Крок 4: Запуск сервера

### Варіант 1: Windows автентифікація

```bash
cd pureAPI
python server.py -s localhost -d YourDatabase
```

### Варіант 2: SQL Server автентифікація

```bash
python server.py -s localhost -d YourDatabase -u YourUsername
# Пароль буде запитано інтерактивно
```

### Варіант 3: З власним портом

```bash
python server.py -s localhost -d YourDatabase -p 8080
```

## Крок 5: Тестування API

Після запуску сервер буде доступний за адресою `http://127.0.0.1:51433`

### Перевірка здоров'я

```bash
curl http://localhost:51433/health
```

Очікувана відповідь:
```json
{"status": "healthy", "database": "YourDatabase"}
```

### Тест list endpoint

```bash
curl http://localhost:51433/databases/list
```

Очікувана відповідь:
```json
{
  "data": [
    {
      "databaseId": 1,
      "databaseName": "master",
      "stateDesc": "ONLINE",
      ...
    }
  ],
  "count": 4
}
```

### Тест get endpoint

```bash
curl "http://localhost:51433/database/get?databaseId=1"
```

### Тест exec endpoint

```bash
curl "http://localhost:51433/exec/testOperation?testValue=hello"
```

Очікувана відповідь:
```json
{
  "status": "success",
  "message": "Operation completed successfully",
  "data": {
    "inputValue": "hello",
    "upperValue": "HELLO",
    "valueLength": 5,
    "processedAt": "2024-..."
  }
}
```

## Крок 6: Документація API

Відкрийте в браузері:
```
http://localhost:51433/docs
```

Ви побачите інтерактивну документацію Swagger UI, де можна тестувати всі endpoints.

## Створення власних API endpoints

### 1. List endpoint (таблична функція)

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
                u.status
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS jsondata
    FROM users u
    WHERE @status IS NULL OR u.status = @status
);
GO
```

Використання:
```bash
curl http://localhost:51433/users/list
curl "http://localhost:51433/users/list?status=active"
```

### 2. Get endpoint (скалярна функція)

```sql
CREATE OR ALTER FUNCTION api.userGet(@userId INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (
        SELECT 
            u.userId,
            u.userName,
            u.email
        FROM users u
        WHERE u.userId = @userId
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
END;
GO
```

Використання:
```bash
curl "http://localhost:51433/user/get?userId=123"
```

### 3. Exec endpoint (процедура)

```sql
CREATE OR ALTER PROCEDURE api.createUser
    @userName NVARCHAR(100),
    @email NVARCHAR(255),
    @response NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Ваша логіка тут
        INSERT INTO users (userName, email) VALUES (@userName, @email);
        
        SELECT @response = (
            SELECT 
                'success' AS status,
                SCOPE_IDENTITY() AS userId
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

Використання:
```bash
curl "http://localhost:51433/exec/createUser?userName=john&email=john@example.com"
```

## Поширені проблеми

### Сервер не стартує
- Перевірте, чи порт 51433 вільний: `netstat -an | grep 51433`
- Спробуйте інший порт: `python server.py -s localhost -d YourDB -p 8080`

### Помилка підключення до SQL Server
- Перевірте, чи SQL Server запущений
- Перевірте назву instance: `localhost\SQLEXPRESS`
- Перевірте, чи TCP/IP увімкнено в SQL Server Configuration Manager

### "Invalid object name 'api.xxxList'"
- Перевірте, чи існує схема `api`: `SELECT * FROM sys.schemas WHERE name = 'api'`
- Перевірте, чи існує функція: `SELECT * FROM sys.objects WHERE name = 'xxxList' AND schema_id = SCHEMA_ID('api')`

## Наступні кроки

1. Створіть власні API endpoints для ваших таблиць
2. Додайте валідацію на рівні SQL
3. Налаштуйте права доступу SQL Server користувача
4. Розгляньте додавання автентифікації для production
5. Налаштуйте reverse proxy (nginx/IIS) з HTTPS

Детальна документація: [README.md](README.md)

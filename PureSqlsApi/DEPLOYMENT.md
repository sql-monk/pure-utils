# PureSqlsApi - Чеклист розгортання

## 📋 Перед першим запуском

### 1. Перевірка середовища

- [ ] .NET 8 SDK встановлено (`dotnet --version`)
- [ ] SQL Server доступний і запущений
- [ ] Є доступ до бази даних (Windows auth або SQL auth)
- [ ] TCP/IP протокол увімкнено в SQL Server Configuration Manager
- [ ] Firewall не блокує порт SQL Server (1433)

### 2. Підготовка бази даних

- [ ] Створено базу даних (або буде використана існуюча)
- [ ] Виконано скрипт створення схеми api:
  ```sql
  USE [YourDatabase];
  GO
  :r api/Security/api.sql
  GO
  ```
- [ ] Створено необхідні SQL об'єкти (функції/процедури)
- [ ] Користувач має права на виконання об'єктів в схемі api

### 3. Компіляція проекту

- [ ] Виконано `dotnet restore` в директорії PureSqlsApi
- [ ] Виконано `dotnet build` без помилок
- [ ] (Опціонально) Виконано `.\build.ps1` для створення standalone executable

## 🚀 Запуск сервісу

### Варіант 1: Development (dotnet run)

```bash
cd PureSqlsApi
dotnet run -- --server localhost --database YourDB --port 5000
```

### Варіант 2: Standalone executable (після build.ps1)

```bash
.\PureSqlsApi\bin\Release\net8.0\win-x64\publish\PureSqlsApi.exe --server localhost --database YourDB --port 5000
```

### Параметри запуску

- [ ] Перевірено правильність `--server` параметра
- [ ] Перевірено правильність `--database` параметра
- [ ] Вибрано вільний `--port` (default: 51433)
- [ ] Якщо потрібно SQL auth - вказано `--user` (буде запитано пароль)

## ✅ Перевірка роботи

### 1. Базова перевірка

- [ ] Сервіс стартував без помилок
- [ ] У консолі відображається:
  ```
  ✓ Підключено до SQL Server: <server>, база даних: <database>
  ✓ PureSqlsApi запущено на http://localhost:<port>
  ```

### 2. Тестові запити

- [ ] Створено тестові SQL об'єкти (приклади з api/ директорії):
  ```sql
  :r api/Functions/exampleList.sql
  :r api/Functions/exampleGet.sql
  :r api/Procedures/ExampleCreate.sql
  ```

- [ ] Виконано тестові HTTP запити:
  ```bash
  # List endpoint
  curl http://localhost:5000/example/list
  
  # Get endpoint
  curl "http://localhost:5000/example/get?id=2"
  
  # Exec endpoint
  curl "http://localhost:5000/exec/ExampleCreate?name=Test&value=100"
  ```

- [ ] Всі запити повертають валідний JSON
- [ ] HTTP статус 200 для успішних запитів
- [ ] HTTP статус 500 для помилок SQL (з JSON описом помилки)

## 📊 Створення власних endpoints

### Для List endpoint (список об'єктів)

- [ ] Створено табличну функцію `api.{resourceName}List`
- [ ] Функція повертає таблицю з колонкою `jsondata` типу NVARCHAR(MAX)
- [ ] Кожен рядок jsondata містить валідний JSON
- [ ] Функція протестована прямо в SQL:
  ```sql
  SELECT * FROM api.{resourceName}List(параметри);
  ```
- [ ] HTTP endpoint працює: `GET /{resourceName}/list`

### Для Get endpoint (один об'єкт)

- [ ] Створено скалярну функцію `api.{resourceName}Get`
- [ ] Функція повертає NVARCHAR(MAX) з JSON
- [ ] Функція протестована прямо в SQL:
  ```sql
  SELECT api.{resourceName}Get(параметри);
  ```
- [ ] HTTP endpoint працює: `GET /{resourceName}/get`

### Для Exec endpoint (виконання операції)

- [ ] Створено процедуру `api.{procedureName}`
- [ ] Процедура має OUTPUT параметр `@response NVARCHAR(MAX)`
- [ ] Процедура повертає JSON через @response
- [ ] Процедура протестована прямо в SQL:
  ```sql
  DECLARE @result NVARCHAR(MAX);
  EXEC api.{procedureName} @param1 = 'value', @response = @result OUTPUT;
  SELECT @result;
  ```
- [ ] HTTP endpoint працює: `GET /exec/{procedureName}`

## 🔒 Безпека та продакшн

### Для локального використання

- [ ] Сервіс запущено тільки на localhost
- [ ] Порт не відкритий в firewall для зовнішніх підключень
- [ ] Використовується обмежений SQL користувач (тільки права на api схему)

### Для продакшн розгортання (рекомендації)

- [ ] Налаштовано reverse proxy (nginx/IIS) з автентифікацією
- [ ] Додано HTTPS сертифікат
- [ ] Налаштовано rate limiting
- [ ] Обмежено доступ за IP адресами
- [ ] Налаштовано логування (Serilog або аналог)
- [ ] Налаштовано моніторинг (health checks)
- [ ] SQL користувач має мінімальні необхідні права
- [ ] Додано CORS якщо потрібен доступ з браузера

## 🐛 Діагностика проблем

### Проблема: Не вдається підключитися до SQL Server

- [ ] SQL Server запущено (службу перевірено)
- [ ] TCP/IP протокол увімкнено
- [ ] Firewall не блокує порт
- [ ] Connection string правильний
- [ ] Користувач/пароль правильні
- [ ] Спробувати з SQL Server Management Studio з тими ж credentials

### Проблема: HTTP 500 - Invalid object name 'api.xxxList'

- [ ] Схема api створена в базі даних
- [ ] SQL об'єкт існує і має правильне ім'я
- [ ] Користувач має права на виконання об'єкта
- [ ] Перевірено через SSMS:
  ```sql
  SELECT * FROM sys.objects 
  WHERE schema_id = SCHEMA_ID('api') AND name = 'xxxList';
  ```

### Проблема: HTTP 500 - Conversion failed

- [ ] Типи параметрів у HTTP запиті відповідають SQL типам
- [ ] Додано обробку помилок в SQL об'єкті
- [ ] Перевірено SQL об'єкт з тими ж параметрами в SSMS

### Проблема: Пустий JSON або {}

- [ ] SQL функція/процедура повертає валідний JSON
- [ ] FOR JSON PATH використовується правильно
- [ ] Немає NULL значень які не обробляються
- [ ] Перевірено SQL в SSMS напряму

## 📚 Додаткові ресурси

- [README.md](README.md) - Повна документація
- [TESTING.md](TESTING.md) - Детальні приклади тестування
- [QUICKSTART.md](QUICKSTART.md) - Швидкий старт з шаблонами
- [api/README.md](../api/README.md) - Документація SQL структури

## 🎯 Чеклист готовності до використання

### Мінімальний набір для початку роботи:

- [x] .NET 8 SDK встановлено
- [x] SQL Server доступний
- [x] Проект скомпільовано
- [x] Схема api створена
- [x] Хоча б один тестовий endpoint працює
- [x] Документація прочитана

### Рекомендований набір:

- [x] Всі пункти з мінімального набору
- [ ] Створено власні SQL endpoints для вашої предметної області
- [ ] Протестовано з d3.js або іншим фронтендом
- [ ] Налаштовано логування
- [ ] Додано обробку помилок в SQL об'єкти
- [ ] Створено документацію для вашої команди

---

**Версія:** 1.0  
**Дата:** 2024-10-21  
**Автор:** PureSqlsApi Team

# PuPy - Pure-Utils Python REST API

**PuPy** (Pure-Utils PYthon) - це тонкий REST API шар над SQL Server схемою `pupy`. Вся бізнес-логіка залишається в SQL, Python лише маршрутизує запити та серіалізує дані.

## 🎯 Філософія

```
HTTP Request → PuPy (Python) → pupy.* (SQL) → Response
```

- **Вся бізнес-логіка в SQL** (schema `pupy`)
- **Python тільки маршрутизація + серіалізація**
- **Динамічна маршрутизація**: URL pattern → SQL object

## 🚀 Швидкий старт

### Вимоги

1. **Python 3.10+**
2. **ODBC Driver 18 for SQL Server** (або новіше)
   - Windows: Зазвичай вже встановлений
   - Linux: 
     ```bash
     # Ubuntu/Debian
     curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
     curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
     sudo apt-get update
     sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
     ```

### Встановлення залежностей

```bash
pip install -r PuPy/requirements.txt
```

### Запуск

**Windows Authentication:**
```bash
python PuPy/main.py --server localhost
```

**SQL Authentication:**
```bash
python PuPy/main.py --server localhost --user sa
Password: ********
Target database [msdb]: AdventureWorks
```

**З вказаною базою даних:**
```bash
python PuPy/main.py --server localhost --database AdventureWorks
```

**На кастомному порту:**
```bash
python PuPy/main.py --server localhost --port 8080
```

## 📋 Параметри командного рядка

### Обов'язкові параметри:

- `-s, --server` - SQL Server instance (localhost, IP, або FQDN)

### Опціональні параметри:

- `-d, --database` - Цільова база даних (якщо не вказано, буде prompt з suggestion `msdb`)
- `-u, --user` - SQL Authentication login (якщо не вказано, використовується Windows Auth)
- `-p, --port` - API port (за замовчуванням: `51433`)
- `--host` - API host (за замовчуванням: `127.0.0.1`)

### Безпека паролів:

- Пароль **ніколи** не передається як параметр командного рядка
- Пароль завжди запитується через `getpass.getpass()` якщо вказано `--user`
- Пароль не логується і не зберігається

## 🔗 URL → SQL Mapping

### Правила маршрутизації

```
HTTP Pattern:  /{resource}/{action}?param1=value1&param2=value2
SQL Object:    pupy.{resource}{action}
```

### Приклади маршрутизації

| HTTP Request | SQL Object | SQL Type |
|--------------|------------|----------|
| `GET /databases/GetList` | `pupy.databasesGetList` | VIEW |
| `GET /databases/GetDetails?databaseName=AdventureWorks` | `pupy.databasesGetDetails(@databaseName)` | Table-Valued Function |
| `GET /objects/GetDefinition?name=dbo.uspTest` | `SELECT pupy.objectsGetDefinition(@name)` | Scalar Function |
| `POST /objects/GetHistory` | `EXEC pupy.objectsGetHistory @params, @response OUT` | Stored Procedure |

### Формування імені SQL об'єкта

```
/{resource}/{action} → pupy.{resource}{action}
```

**Приклади:**
- `/databases/GetList` → `pupy.databasesGetList`
- `/objects/GetAll` → `pupy.objectsGetAll`
- `/dependencies/GetGraph` → `pupy.dependenciesGetGraph`
- `/permissions/GetMap` → `pupy.permissionsGetMap`

## 📊 Типи SQL об'єктів та Response формати

### 1. VIEW / Table-Valued Function (TVF)

**SQL повертає:**
```sql
| column1 | column2 | column3 |
| value1  | value2  | value3  |
| value4  | value5  | value6  |
```

**JSON Response:**
```json
{
  "data": [
    {"column1": "value1", "column2": "value2", "column3": "value3"},
    {"column1": "value4", "column2": "value5", "column3": "value6"}
  ],
  "count": 2
}
```

### 2. Scalar Function

**Вимоги:** Функція повинна повертати `NVARCHAR(MAX)` із валідним JSON

**Приклад функції:**
```sql
CREATE FUNCTION pupy.objectsGetDefinition(@name NVARCHAR(256))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    SELECT @result = (
        SELECT 
            name,
            type_desc,
            create_date
        FROM sys.objects
        WHERE name = @name
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
    RETURN @result;
END;
```

**Response:** Прямо повертається JSON з функції

### 3. Stored Procedure

**Вимоги:** Процедура повинна мати `@response NVARCHAR(MAX) OUTPUT` параметр із валідним JSON

**Приклад процедури:**
```sql
CREATE PROCEDURE pupy.objectsGetHistory
    @objectName NVARCHAR(256),
    @response NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SELECT @response = (
        SELECT 
            event_time,
            event_type,
            object_name
        FROM util.eventsNotifications
        WHERE object_name = @objectName
        ORDER BY event_time DESC
        FOR JSON PATH
    );
END;
```

**Response:** JSON з `@response` output параметра

## 🔧 Мапінг параметрів HTTP → SQL

**Правило:** Імена параметрів мають співпадати точно

**Приклад:**
```
HTTP:  localhost:51433/databases/GetDetails?databaseName=AdventureWorks
SQL:   pupy.databasesGetDetails(@databaseName = 'AdventureWorks')
```

### GET запити

Параметри передаються як query string:
```bash
curl "http://localhost:51433/databases/GetDetails?databaseName=AdventureWorks"
```

### POST запити

Параметри передаються як JSON в body:
```bash
curl -X POST http://localhost:51433/objects/GetHistory \
  -H "Content-Type: application/json" \
  -d '{"objectName": "dbo.uspTest"}'
```

## 📦 SQL Schema: pupy

### Існуючі об'єкти

#### pupy.databasesGetList (VIEW)
```sql
SELECT * FROM pupy.databasesGetList;
```
Повертає список всіх баз даних (крім системних).

#### pupy.databasesGetDetails (TVF)
```sql
SELECT * FROM pupy.databasesGetDetails('AdventureWorks');
```
Повертає детальну інформацію про вказану базу даних.

### Додавання нових об'єктів

Для додавання нового endpoint достатньо створити відповідний SQL об'єкт у схемі `pupy`:

1. **VIEW або TVF** - для запитів, що повертають набір рядків
2. **Scalar Function** - для обчислень, що повертають JSON
3. **Stored Procedure** - для складних операцій з output параметром `@response`

**Приклад:**
```sql
-- Створюємо функцію
CREATE FUNCTION pupy.objectsGetAll()
RETURNS TABLE
AS
RETURN (
    SELECT 
        name,
        type_desc,
        create_date
    FROM sys.objects
    WHERE schema_id = SCHEMA_ID('dbo')
);
GO

-- Автоматично з'являється endpoint
-- GET /objects/GetAll
```

## 🔍 API Endpoints

### Root endpoint
```bash
GET http://localhost:51433/
```
Повертає інформацію про API, версію та доступні приклади.

### Приклади використання

```bash
# Отримати список баз даних
curl http://localhost:51433/databases/GetList

# Отримати деталі конкретної бази даних
curl "http://localhost:51433/databases/GetDetails?databaseName=AdventureWorks"

# POST запит з JSON body
curl -X POST http://localhost:51433/objects/GetHistory \
  -H "Content-Type: application/json" \
  -d '{"objectName": "dbo.uspTest", "days": 7}'
```

## 🛠️ Технологічний стек

- **Python**: 3.10+
- **Framework**: FastAPI
- **SQL Driver**: pyodbc (with ODBC Driver 18 for SQL Server)
- **База даних**: SQL Server
- **Schema**: pupy
- **Port**: 51433 (за замовчуванням)

## 📝 Структура проекту

```
PuPy/
├── main.py              # Головний файл з FastAPI додатком
├── requirements.txt     # Python залежності
└── README.md           # Документація

pupy/
├── Views/
│   └── databasesGetList.sql
└── Functions/
    └── databasesGetDetails.sql
```

## 🔒 Безпека

- Використовується параметризовані запити для запобігання SQL injection
- Паролі не зберігаються і не логуються
- TrustServerCertificate для локального розробки (в продакшн використовуйте валідні сертифікати)

## 📚 Додаткова інформація

Для більш детальної інформації про SQL об'єкти та конвенції кодування, дивіться:
- [codestyle.md](/codestyle.md) - Стиль кодування SQL
- [util schema](/util) - Бібліотека утилітарних функцій

## 🤝 Контрибуція

При створенні нових SQL об'єктів у схемі `pupy`, дотримуйтесь:
1. Іменування: `{resource}{action}` (camelCase)
2. Документація українською в коментарях
3. Параметри з чіткими типами
4. Валідний JSON для scalar functions та stored procedures

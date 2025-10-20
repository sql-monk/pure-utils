# PuPy - FastAPI REST API для SQL Server

REST API з FastAPI (Python 3.10+) поверх SQL Server (схема `pupy`) з драйвером **`pymssql`**.

```
HTTP → FastAPI (PuPy) → SQL Server (schema pupy) → JSON
```

## Встановлення

```bash
pip install -r requirements.txt
```

## Запуск

### Windows Authentication
```bash
python PuPy/main.py --server "localhost"
```

### SQL Authentication
```bash
python PuPy/main.py --server "192.168.1.10" --user "sa" --database "MyDB"
```

### Кастомний порт
```bash
python PuPy/main.py --server "localhost" --port 8080
```

### Всі параметри
- `--server` (str, дефолт localhost): SQL Server hostname/IP
- `--port` (int, дефолт 1433): SQL Server порт
- `--user` (str, опціональний): SQL користувач (якщо не задано, використовується Windows Auth)
- `--database` (str, дефолт msdb): База даних за замовчуванням
- `--trust-server-certificate` (bool, дефолт True): Довіряти серверному сертифікату SSL
- `--host` (str, дефолт 0.0.0.0): FastAPI server host
- `--api-port` (int, дефолт 8000): FastAPI server port

## Маршрутизація

### Правила іменування

* HTTP: `/{resource}/{action}` → SQL: `pupy.{resource}{Action}`
* У URL все **lowercase**, у SQL — **camelCase**
* Параметри HTTP точно збігаються з іменами SQL-параметрів (CASE INSENSITIVE)

### Типи об'єктів

1. **Table-valued function** → повертають табличний результат (для методів list)
2. **Scalar function** → повертає NVARCHAR(MAX) валідний JSON (для методів details)
3. **Stored procedure** → має `@response NVARCHAR(MAX) OUTPUT` з JSON відповіддю

### Приклади

| HTTP                                      | SQL                                          | Тип                   |
| ----------------------------------------- | -------------------------------------------- | --------------------- |
| `GET /databases/list`                     | `pupy.databasesList()`                       | Table valued function |
| `GET /databases/get?databaseName=msdb`    | `SELECT pupy.databasesGet(@databaseName)`    | Scalar function       |
| `POST /pupy/objectReferences?object=...`  | `EXEC pupy.objectReferences @object, @response OUT` | Stored procedure |

## Документація API

Після запуску сервера, документація доступна за адресою:
```
http://localhost:8000/docs
```

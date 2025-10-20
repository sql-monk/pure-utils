# Security Considerations for PuPy

## Overview

PuPy використовує динамічний SQL для маршрутизації HTTP запитів до SQL об'єктів. Це створює потенційні ризики SQL injection, які мітигуються через багаторівневий підхід до безпеки.

## Security Layers

### 1. Object Validation

**Що робиться:**
- Перед виконанням будь-якого SQL об'єкта, система перевіряє його існування через `sys.objects`
- Використовується параметризований запит для валідації

**Код:**
```python
def _validate_object_name(self, schema: str, name: str) -> bool:
    query = """
        SELECT COUNT(*)
        FROM sys.objects o
        INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE s.name = %s AND o.name = %s
    """
    cursor.execute(query, (schema, name))
```

### 2. Input Sanitization

**Що робиться:**
- Всі значення параметрів санітизуються перед вставкою в SQL
- Одинарні лапки екрануються (`'` → `''`)
- Використовується Unicode префікс `N''` для строк

**Код:**
```python
def _sanitize_param_value(self, value: Any) -> str:
    if isinstance(value, str):
        sanitized = value.replace("'", "''")
        return f"N'{sanitized}'"
```

### 3. Alphanumeric Validation

**Що робиться:**
- Імена схем та об'єктів повинні бути alphanumeric (+ underscore)
- Імена параметрів також валідуються

**Код:**
```python
if not schema.replace('_', '').isalnum():
    return False
```

### 4. Limited SQL Server Permissions

**Рекомендація:**
- Створити окремого SQL користувача з обмеженими правами
- Надати права тільки на виконання об'єктів в схемі `pupy`
- Заборонити DDL операції

**Приклад:**
```sql
-- Створити користувача
CREATE LOGIN pupy_api_user WITH PASSWORD = 'StrongPassword123!';
CREATE USER pupy_api_user FOR LOGIN pupy_api_user;

-- Надати права тільки на схему pupy
GRANT EXECUTE ON SCHEMA::pupy TO pupy_api_user;

-- Заборонити DDL
DENY CREATE TABLE TO pupy_api_user;
DENY ALTER ANY SCHEMA TO pupy_api_user;
DENY DROP ANY DATABASE TO pupy_api_user;
```

## Known Limitations

### Dynamic SQL Required

CodeQL та інші статичні аналізатори можуть позначати код як вразливий до SQL injection через використання динамічного SQL. Це **очікувана поведінка** через архітектуру API:

- URL маршрути динамічно мапляться на SQL об'єкти
- Неможливо використати чисто параметризовані запити для імен об'єктів
- Міграції через багаторівневу валідацію та санітизацію

### Trust Boundary

Система **не призначена** для публічного інтернету без додаткового захисту:

1. **Використовуйте API Gateway** з автентифікацією
2. **Обмежте доступ за IP** (firewall, network policies)
3. **Додайте rate limiting** для запобігання DoS
4. **Використовуйте HTTPS** для шифрування трафіку

## Recommended Architecture

```
┌──────────────┐
│   Internet   │
└──────┬───────┘
       │
       │ HTTPS
       ↓
┌──────────────────┐
│   API Gateway    │  ← Authentication (OAuth2/JWT)
│  (nginx/traefik) │  ← Rate Limiting
└──────┬───────────┘  ← IP Whitelisting
       │
       │ HTTP (internal)
       ↓
┌──────────────────┐
│   PuPy FastAPI   │  ← Input Validation
└──────┬───────────┘  ← Object Validation
       │
       │ TDS (SQL)
       ↓
┌──────────────────┐
│   SQL Server     │  ← Limited Permissions User
│  (schema pupy)   │  ← Execute Only on pupy schema
└──────────────────┘
```

## Additional Security Measures

### 1. Add Authentication to FastAPI

```python
from fastapi import Depends, HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

async def verify_token(credentials: HTTPAuthorizationCredentials = Security(security)):
    if credentials.credentials != "expected_token":
        raise HTTPException(status_code=401, detail="Invalid token")
    return credentials.credentials

# Use in routes
@app.get("/databases/list", dependencies=[Depends(verify_token)])
async def handle_get_request(...):
    ...
```

### 2. Add Rate Limiting

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.get("/databases/list")
@limiter.limit("100/minute")
async def handle_get_request(request: Request, ...):
    ...
```

### 3. Add Input Validation

```python
from pydantic import BaseModel, Field, validator

class DatabaseRequest(BaseModel):
    databaseName: str = Field(..., max_length=128)
    
    @validator('databaseName')
    def validate_name(cls, v):
        if not v.replace('_', '').isalnum():
            raise ValueError('Invalid database name')
        return v
```

### 4. Enable SQL Server Auditing

```sql
-- Увімкнути аудит для моніторингу
CREATE SERVER AUDIT PuPy_Audit
TO FILE (FILEPATH = 'C:\Audit\', MAXSIZE = 100 MB);

CREATE DATABASE AUDIT SPECIFICATION PuPy_DB_Audit
FOR SERVER AUDIT PuPy_Audit
ADD (EXECUTE ON SCHEMA::pupy BY pupy_api_user);

ALTER SERVER AUDIT PuPy_Audit WITH (STATE = ON);
ALTER DATABASE AUDIT SPECIFICATION PuPy_DB_Audit WITH (STATE = ON);
```

## Incident Response

Якщо виявлено підозрілу активність:

1. **Негайно** - Заблокувати IP адресу атакуючого
2. **Переглянути логи** - Перевірити SQL Server audit logs
3. **Змінити credentials** - Оновити паролі SQL користувачів
4. **Оновити правила** - Додати додаткові обмеження якщо потрібно
5. **Повідомити команду** - Інформувати DevSecOps

## Security Contact

Для повідомлень про вразливості:
- GitHub Security Advisories: https://github.com/sql-monk/pure-utils/security/advisories
- Email: security@yourdomain.com (налаштувати)

## References

- [OWASP SQL Injection Prevention](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [Microsoft SQL Server Security Best Practices](https://learn.microsoft.com/en-us/sql/relational-databases/security/security-center-for-sql-server-database-engine-and-azure-sql-database)
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/)

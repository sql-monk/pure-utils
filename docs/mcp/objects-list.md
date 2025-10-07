# Схема mcp - Повний список об'єктів

Повний перелік всіх об'єктів схеми `mcp` (Model Context Protocol) з короткими описами.

## Статистика

- **Процедури:** 10
- **Функції:** 1
- **Всього:** 11 об'єктів

---

## Процедури (Procedures)

### Списки об'єктів бази даних

| Назва | Опис |
|-------|------|
| `GetDatabases` | Отримання списку всіх баз даних на сервері з повною інформацією |
| `GetTables` | Отримання списку таблиць в базі даних з фільтрацією та статистикою |
| `GetViews` | Отримання списку представлень (views) в базі даних |
| `GetFunctions` | Отримання списку функцій в базі даних з фільтрацією |
| `GetProcedures` | Отримання списку збережених процедур в базі даних |

### Детальна інформація про об'єкти

| Назва | Опис |
|-------|------|
| `GetTableInfo` | Детальна інформація про таблицю (колонки, індекси, партиції, розмір) |
| `GetSqlModule` | Отримання вихідного коду модуля (процедури, функції, view, тригера) |

### Генерація скриптів

| Назва | Опис |
|-------|------|
| `ScriptObjectAndReferences` | Генерація SQL скрипту об'єкта разом з усіма його залежностями |

### Історія та аудит

| Назва | Опис |
|-------|------|
| `GetDdlHistory` | Отримання історії DDL змін об'єктів (створення, зміна, видалення) |
| `FindLastModulePlan` | Пошук останнього плану виконання для модуля |

---

## Функції (Functions)

### MCP Tools Registry

| Назва | Опис |
|-------|------|
| `ToolsList` | Повертає JSON список всіх доступних MCP tools для реєстрації в MCP сервері |

---

## Детальний опис процедур

### GetDatabases
**Параметри:** Немає  
**Повертає:** JSON з масивом баз даних, включаючи:
- Назва
- ID бази даних
- Дата створення
- Рівень сумісності
- Статус read-only
- Стан бази даних
- Модель відновлення
- Налаштування ізоляції транзакцій

**Приклад використання:**
```sql
EXEC mcp.GetDatabases;
```

---

### GetTables
**Параметри:**
- `@database NVARCHAR(128)` - Назва бази даних
- `@filter NVARCHAR(128) = NULL` - Фільтр за назвою таблиці (LIKE pattern)

**Повертає:** JSON з масивом таблиць, включаючи:
- Назва схеми та таблиці
- Object ID
- Дата створення та модифікації
- Тип об'єкта
- Кількість рядків

**Приклад використання:**
```sql
EXEC mcp.GetTables @database = 'AdventureWorks';
EXEC mcp.GetTables @database = 'AdventureWorks', @filter = 'Sales%';
```

---

### GetViews
**Параметри:**
- `@database NVARCHAR(128)` - Назва бази даних
- `@filter NVARCHAR(128) = NULL` - Фільтр за назвою представлення

**Повертає:** JSON з масивом views, включаючи:
- Назва схеми та представлення
- Object ID
- Дата створення та модифікації

**Приклад використання:**
```sql
EXEC mcp.GetViews @database = 'AdventureWorks';
EXEC mcp.GetViews @database = 'AdventureWorks', @filter = 'v%';
```

---

### GetFunctions
**Параметри:**
- `@database NVARCHAR(128)` - Назва бази даних
- `@filter NVARCHAR(128) = NULL` - Фільтр за назвою функції

**Повертає:** JSON з масивом функцій, включаючи:
- Назва схеми та функції
- Object ID
- Тип функції (scalar, table-valued, inline)
- Дата створення та модифікації

**Приклад використання:**
```sql
EXEC mcp.GetFunctions @database = 'AdventureWorks';
```

---

### GetProcedures
**Параметри:**
- `@database NVARCHAR(128)` - Назва бази даних
- `@filter NVARCHAR(128) = NULL` - Фільтр за назвою процедури

**Повертає:** JSON з масивом процедур, включаючи:
- Назва схеми та процедури
- Object ID
- Дата створення та модифікації

**Приклад використання:**
```sql
EXEC mcp.GetProcedures @database = 'AdventureWorks';
EXEC mcp.GetProcedures @database = 'AdventureWorks', @filter = 'usp%';
```

---

### GetTableInfo
**Параметри:**
- `@database NVARCHAR(128)` - Назва бази даних
- `@table NVARCHAR(128)` - Назва таблиці (може бути schema.table або просто table)

**Повертає:** JSON з детальною інформацією про таблицю:
- Назва та опис
- Дата створення
- Кількість рядків
- Колонки (назва, тип, nullable, identity, computed)
- Індекси (тип, колонки, партиції, розмір)

**Приклад використання:**
```sql
EXEC mcp.GetTableInfo @database = 'AdventureWorks', @table = 'Sales.SalesOrderHeader';
EXEC mcp.GetTableInfo @database = 'AdventureWorks', @table = 'SalesOrderHeader';
```

---

### GetSqlModule
**Параметри:**
- `@database NVARCHAR(128)` - Назва бази даних
- `@schema NVARCHAR(128) = NULL` - Назва схеми (NULL для пошуку в усіх схемах)
- `@object NVARCHAR(128)` - Назва об'єкта

**Повертає:** JSON з вихідним кодом модуля

**Приклад використання:**
```sql
EXEC mcp.GetSqlModule @database = 'AdventureWorks', @schema = 'dbo', @object = 'uspGetEmployeeManagers';
EXEC mcp.GetSqlModule @database = 'AdventureWorks', @object = 'uspGetEmployeeManagers';
```

---

### ScriptObjectAndReferences
**Параметри:**
- `@objectFullName NVARCHAR(128)` - Повне ім'я об'єкта у форматі 'database.schema.object'

**Повертає:** JSON з SQL скриптом, який включає:
1. Всі залежні об'єкти в правильному порядку
2. Сам об'єкт

**Приклад використання:**
```sql
EXEC mcp.ScriptObjectAndReferences @objectFullName = 'AdventureWorks.Sales.vSalesPerson';
EXEC mcp.ScriptObjectAndReferences @objectFullName = 'utils.util.metadataGetDescriptions';
```

---

### GetDdlHistory
**Параметри:**
- `@database NVARCHAR(128)` - Назва бази даних
- `@objectName NVARCHAR(128) = NULL` - Назва об'єкта для фільтрації (NULL для всіх)

**Повертає:** JSON з історією DDL операцій:
- Тип події (CREATE, ALTER, DROP)
- Час події
- Користувач
- Назва об'єкта
- Тип об'єкта
- DDL команда

**Приклад використання:**
```sql
EXEC mcp.GetDdlHistory @database = 'AdventureWorks';
EXEC mcp.GetDdlHistory @database = 'AdventureWorks', @objectName = 'Sales.SalesOrderHeader';
```

---

### FindLastModulePlan
**Параметри:**
- `@database NVARCHAR(128)` - Назва бази даних
- `@schema NVARCHAR(128) = NULL` - Назва схеми
- `@object NVARCHAR(128)` - Назва об'єкта (процедури або функції)

**Повертає:** JSON з останнім планом виконання модуля

**Приклад використання:**
```sql
EXEC mcp.FindLastModulePlan @database = 'AdventureWorks', @object = 'uspGetEmployeeManagers';
```

---

### ToolsList (Function)
**Параметри:** Немає  
**Повертає:** JSON масив з описом всіх MCP tools у форматі MCP protocol

**Формат результату:**
```json
{
  "tools": [
    {
      "name": "GetDatabases",
      "description": "Процедура для отримання списку баз даних",
      "inputSchema": {
        "type": "object",
        "properties": {},
        "required": []
      }
    },
    ...
  ]
}
```

**Приклад використання:**
```sql
SELECT mcp.ToolsList();
```

---

## Формат MCP відповідей

Всі процедури схеми `mcp` повертають результат у стандартному MCP форматі:

```json
{
  "content": [
    {
      "type": "text",
      "text": "<JSON data або текстовий контент>"
    }
  ]
}
```

У випадку помилки:
```json
{
  "content": [
    {
      "type": "text",
      "text": "Error: <опис помилки>"
    }
  ]
}
```

---

## Використання з MCP серверами

Процедури схеми `mcp` автоматично реєструються як tools в MCP серверах:
- **PureSqlsMcp** - консольний сервер
- **PureSqlsMcpWeb** - веб-сервер
- **PlanSqlsMcp** - сервер для аналізу планів

Функція `ToolsList()` автоматично викликається серверами для виявлення доступних tools.

---

## Див. також

- [Огляд можливостей mcp](README.md)
- [Детальна документація по кожному MCP об'єкту](detailed/)
- [Документація по схемі util](../util/README.md)
- [Інструкції по розгортанню](../deploy.md)

# Схема mcp - Огляд можливостей

Схема `mcp` (Model Context Protocol) містить процедури та функції для інтеграції SQL Server з MCP протоколом. Ці об'єкти дозволяють AI асистентам отримувати інформацію про структуру бази даних, виконувати запити та генерувати скрипти через стандартизований JSON-based протокол.

## Що таке MCP?

Model Context Protocol (MCP) - це відкритий протокол для інтеграції AI асистентів з різними джерелами даних. Схема `mcp` реалізує серверну частину цього протоколу для SQL Server, дозволяючи AI моделям безпечно взаємодіяти з базами даних.

## Основні можливості

### 1. Отримання метаданих бази даних

**Процедури для списків об'єктів:**
- `GetDatabases` - список всіх баз даних на сервері
- `GetTables` - список таблиць в базі даних з фільтрацією
- `GetViews` - список представлень (views)
- `GetFunctions` - список функцій
- `GetProcedures` - список збережених процедур

**Детальна інформація:**
- `GetTableInfo` - повна інформація про таблицю (колонки, індекси, статистика)
- `GetSqlModule` - вихідний код модуля (процедури, функції, view)

### 2. Генерація скриптів

**Процедури для створення DDL:**
- `ScriptObjectAndReferences` - генерує SQL скрипт об'єкта разом з усіма його залежностями

### 3. Історія та аудит

**Процедури для відстеження змін:**
- `GetDdlHistory` - історія DDL змін (створення, зміна, видалення об'єктів)
- `FindLastModulePlan` - пошук останнього плану виконання для модуля

### 4. MCP Tools Registry

**Функції для реєстрації інструментів:**
- `ToolsList` - повертає список всіх доступних MCP tools у форматі JSON

## Формат відповідей MCP

Всі процедури схеми `mcp` повертають результат у стандартному форматі MCP:

```json
{
  "content": [
    {
      "type": "text",
      "text": "JSON data or text content"
    }
  ]
}
```

Це забезпечує сумісність з MCP клієнтами та AI асистентами.

## Приклади використання

### Отримання списку баз даних
```sql
EXEC mcp.GetDatabases;
```

**Результат:**
```json
{
  "content": [
    {
      "type": "text",
      "text": "[{\"name\":\"master\",\"databaseId\":1,...},{\"name\":\"tempdb\",\"databaseId\":2,...}]"
    }
  ]
}
```

### Отримання таблиць з фільтрацією
```sql
-- Всі таблиці
EXEC mcp.GetTables @database = 'AdventureWorks';

-- З фільтром
EXEC mcp.GetTables @database = 'AdventureWorks', @filter = 'Product%';
```

### Детальна інформація про таблицю
```sql
EXEC mcp.GetTableInfo 
    @database = 'AdventureWorks', 
    @table = 'Sales.SalesOrderHeader';
```

**Результат включає:**
- Назву та опис таблиці
- Дату створення
- Кількість рядків
- Список колонок з типами даних
- Індекси з детальною інформацією

### Генерація скрипту з залежностями
```sql
EXEC mcp.ScriptObjectAndReferences 
    @objectFullName = 'AdventureWorks.Sales.vSalesPerson';
```

**Результат:**
SQL скрипт який включає:
1. Всі залежні об'єкти (таблиці, функції, які використовує view)
2. Сам об'єкт

### Отримання коду модуля
```sql
EXEC mcp.GetSqlModule 
    @database = 'AdventureWorks',
    @schema = 'dbo',
    @object = 'uspGetEmployeeManagers';
```

### Пошук історії змін
```sql
EXEC mcp.GetDdlHistory 
    @database = 'AdventureWorks',
    @objectName = 'Sales.SalesOrderHeader';
```

### Отримання списку всіх MCP tools
```sql
SELECT mcp.ToolsList();
```

**Результат:**
JSON масив з описом всіх доступних MCP процедур у форматі, сумісному з MCP protocol.

## Інтеграція з AI асистентами

Схема `mcp` розроблена для використання з AI асистентами через MCP серверні реалізації:
- **PureSqlsMcp** - консольний MCP сервер
- **PureSqlsMcpWeb** - веб-базований MCP сервер
- **PlanSqlsMcp** - MCP сервер для аналізу планів виконання

Ці сервери автоматично виявляють процедури схеми `mcp` та реєструють їх як MCP tools, доступні для AI моделей.

## Безпека

### Рекомендації:
1. **Обмежте доступ** - надавайте права на схему `mcp` тільки довіреним користувачам
2. **Використовуйте read-only з'єднання** - для AI інтеграцій рекомендується read-only доступ
3. **Аудит** - використовуйте Extended Events для моніторингу всіх викликів MCP процедур
4. **Обмеження по базах даних** - можна обмежити доступ до конкретних баз даних через права доступу

## Архітектура

```
AI Assistant (Claude, GPT, etc.)
      ↓
MCP Client (Cline, Cursor, etc.)
      ↓
MCP Server (PureSqlsMcp/Web)
      ↓
SQL Server mcp.* procedures
      ↓
util.* utility functions
      ↓
SQL Server metadata (sys.*)
```

## Розширення

Щоб додати нову MCP процедуру:

1. Створіть процедуру в схемі `mcp`
2. Додайте структурований коментар з описом:
   ```sql
   /*
   # Description
   Короткий опис процедури
   
   # Parameters
   @param1 TYPE - опис параметра
   
   # Returns
   Опис результату
   */
   ```
3. Процедура має повертати результат у форматі MCP (JSON з content array)
4. Після розгортання вона автоматично з'явиться в `mcp.ToolsList()`

## Див. також

- [Повний список MCP об'єктів](objects-list.md)
- [Детальна документація по кожному MCP об'єкту](detailed/)
- [Документація по схемі util](../util/README.md)
- [Інструкції по розгортанню](../deploy.md)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)

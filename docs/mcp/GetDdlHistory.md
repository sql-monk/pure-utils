# mcp.GetDdlHistory

## Опис

Процедура для отримання історії DDL операцій (CREATE, ALTER, DROP) через MCP протокол. Використовує default trace або Extended Events для відстеження змін в схемі бази даних.

## Синтаксис

```sql
EXEC mcp.GetDdlHistory 
    @database = '<database_name>',
    [@objectName = '<object_name>'];
```

## Параметри

| Параметр | Тип | Обов'язковий | Опис |
|----------|-----|--------------|------|
| `@database` | NVARCHAR(128) | Так | Назва бази даних |
| `@objectName` | NVARCHAR(128) | Ні | Фільтр за назвою об'єкта (NULL = всі об'єкти) |

## Приклади

```sql
-- Вся історія DDL в базі даних
EXEC mcp.GetDdlHistory @database = 'AdventureWorks';

-- Історія для конкретного об'єкта
EXEC mcp.GetDdlHistory 
    @database = 'AdventureWorks',
    @objectName = 'Sales.SalesOrderHeader';
```

## Повертає

JSON з історією DDL операцій, включаючи:
- Тип події (CREATE_TABLE, ALTER_PROCEDURE, DROP_FUNCTION, тощо)
- Час події
- Користувач
- Назва об'єкта
- Тип об'єкта
- DDL команда (текст)

## Типи подій

- CREATE_* (TABLE, PROCEDURE, FUNCTION, VIEW, INDEX, тощо)
- ALTER_* (TABLE, PROCEDURE, FUNCTION, VIEW, тощо)
- DROP_* (TABLE, PROCEDURE, FUNCTION, VIEW, INDEX, тощо)

## Примітки

1. **Default Trace** - використовує системний trace SQL Server
2. **Обмеження** - зберігається обмежена історія (залежить від розміру trace файлів)
3. **Продуктивність** - запит може бути повільним для великих історій

## Використання в MCP Client

В AI асистенті:
```
Покажи мені історію змін таблиці Sales.SalesOrderHeader
```

## Пов'язані об'єкти

- `mcp.GetSqlModule` - поточний код об'єкта
- `util.objectGetHistory` - альтернативний метод отримання історії

## Див. також

- [Огляд схеми mcp](../README.md)

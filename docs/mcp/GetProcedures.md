# mcp.GetProcedures

## Опис

Процедура для отримання списку збережених процедур у заданій базі даних через MCP протокол.

## Синтаксис

```sql
EXEC mcp.GetProcedures 
    @database = '<database_name>',
    [@filter = '<filter_pattern>'];
```

## Параметри

| Параметр | Тип | Обов'язковий | Опис |
|----------|-----|--------------|------|
| `@database` | NVARCHAR(128) | Так | Назва бази даних |
| `@filter` | NVARCHAR(128) | Ні | Фільтр за назвою процедури (LIKE pattern) |

## Приклади

```sql
-- Всі процедури
EXEC mcp.GetProcedures @database = 'AdventureWorks';

-- З фільтром
EXEC mcp.GetProcedures @database = 'AdventureWorks', @filter = 'usp%';
```

## Повертає

JSON з масивом процедур, включаючи:
- Назва схеми та процедури
- Object ID
- Дата створення та модифікації

## Пов'язані об'єкти

- `mcp.GetFunctions` - список функцій
- `mcp.GetSqlModule` - вихідний код процедури
- `mcp.FindLastModulePlan` - пошук плану виконання

## Див. також

- [Огляд схеми mcp](../README.md)

# mcp.GetViews

## Опис

Процедура для отримання списку представлень (views) у заданій базі даних через MCP протокол.

## Синтаксис

```sql
EXEC mcp.GetViews 
    @database = '<database_name>',
    [@filter = '<filter_pattern>'];
```

## Параметри

| Параметр | Тип | Обов'язковий | Опис |
|----------|-----|--------------|------|
| `@database` | NVARCHAR(128) | Так | Назва бази даних |
| `@filter` | NVARCHAR(128) | Ні | Фільтр за назвою view (LIKE pattern) |

## Приклади

```sql
-- Всі views
EXEC mcp.GetViews @database = 'AdventureWorks';

-- З фільтром
EXEC mcp.GetViews @database = 'AdventureWorks', @filter = 'v%';
```

## Повертає

JSON з масивом views, включаючи:
- Назва схеми та view
- Object ID
- Дата створення та модифікації

## Пов'язані об'єкти

- `mcp.GetTables` - список таблиць
- `mcp.GetFunctions` - список функцій
- `mcp.GetSqlModule` - вихідний код view

## Див. також

- [Огляд схеми mcp](../README.md)

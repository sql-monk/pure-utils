# mcp.GetFunctions

## Опис

Процедура для отримання списку функцій у заданій базі даних через MCP протокол.

## Синтаксис

```sql
EXEC mcp.GetFunctions 
    @database = '<database_name>',
    [@filter = '<filter_pattern>'];
```

## Параметри

| Параметр | Тип | Обов'язковий | Опис |
|----------|-----|--------------|------|
| `@database` | NVARCHAR(128) | Так | Назва бази даних |
| `@filter` | NVARCHAR(128) | Ні | Фільтр за назвою функції (LIKE pattern) |

## Приклади

```sql
-- Всі функції
EXEC mcp.GetFunctions @database = 'AdventureWorks';

-- З фільтром
EXEC mcp.GetFunctions @database = 'AdventureWorks', @filter = 'ufn%';
```

## Повертає

JSON з масивом функцій, включаючи:
- Назва схеми та функції
- Object ID
- Тип функції (SCALAR_FUNCTION, INLINE_TABLE_VALUED_FUNCTION, TABLE_VALUED_FUNCTION)
- Дата створення та модифікації

## Типи функцій

- **SCALAR_FUNCTION** (FN) - повертає скалярне значення
- **INLINE_TABLE_VALUED_FUNCTION** (IF) - повертає таблицю (inline)
- **TABLE_VALUED_FUNCTION** (TF) - повертає таблицю (multi-statement)

## Пов'язані об'єкти

- `mcp.GetProcedures` - список процедур
- `mcp.GetSqlModule` - вихідний код функції

## Див. також

- [Огляд схеми mcp](../README.md)

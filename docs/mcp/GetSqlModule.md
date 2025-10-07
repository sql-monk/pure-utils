# mcp.GetSqlModule

## Опис

Процедура для отримання вихідного коду SQL модуля (процедури, функції, view, тригера) через MCP протокол.

## Синтаксис

```sql
EXEC mcp.GetSqlModule 
    @database = '<database_name>',
    [@schema = '<schema_name>',]
    @object = '<object_name>';
```

## Параметри

| Параметр | Тип | Обов'язковий | Опис |
|----------|-----|--------------|------|
| `@database` | NVARCHAR(128) | Так | Назва бази даних |
| `@schema` | NVARCHAR(128) | Ні | Назва схеми (NULL для пошуку в усіх схемах) |
| `@object` | NVARCHAR(128) | Так | Назва об'єкта |

## Повертає

JSON з вихідним кодом модуля

## Приклади

```sql
-- З вказанням схеми
EXEC mcp.GetSqlModule 
    @database = 'AdventureWorks',
    @schema = 'dbo',
    @object = 'uspGetEmployeeManagers';

-- Без схеми (пошук в усіх)
EXEC mcp.GetSqlModule 
    @database = 'AdventureWorks',
    @object = 'uspGetEmployeeManagers';
```

## Підтримувані типи об'єктів

- Stored Procedures (P)
- Functions (FN, IF, TF)
- Views (V)
- Triggers (TR)

## Пов'язані об'єкти

- `mcp.ScriptObjectAndReferences` - скрипт з залежностями
- `mcp.GetProcedures` - список процедур
- `mcp.GetFunctions` - список функцій
- `mcp.GetViews` - список представлень

## Вихідний код

Розташування: `/mcp/Procedures/GetSqlModule.sql`

## Див. також

- [mcp.ScriptObjectAndReferences](ScriptObjectAndReferences.md)
- [Огляд схеми mcp](../README.md)

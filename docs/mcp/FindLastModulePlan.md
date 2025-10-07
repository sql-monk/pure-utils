# mcp.FindLastModulePlan

## Опис

Процедура для пошуку останнього плану виконання модуля (процедури або функції) через MCP протокол. Шукає в кеші планів виконання SQL Server.

## Синтаксис

```sql
EXEC mcp.FindLastModulePlan 
    @database = '<database_name>',
    [@schema = '<schema_name>',]
    @object = '<object_name>';
```

## Параметри

| Параметр | Тип | Обов'язковий | Опис |
|----------|-----|--------------|------|
| `@database` | NVARCHAR(128) | Так | Назва бази даних |
| `@schema` | NVARCHAR(128) | Ні | Назва схеми (NULL для пошуку в усіх) |
| `@object` | NVARCHAR(128) | Так | Назва модуля (процедури або функції) |

## Приклади

```sql
-- З вказанням схеми
EXEC mcp.FindLastModulePlan 
    @database = 'AdventureWorks',
    @schema = 'dbo',
    @object = 'uspGetEmployeeManagers';

-- Без схеми
EXEC mcp.FindLastModulePlan 
    @database = 'AdventureWorks',
    @object = 'uspGetEmployeeManagers';
```

## Повертає

JSON з інформацією про останній план виконання:
- Query plan (XML)
- Час останнього виконання
- Статистика виконання (час CPU, reads, writes)
- Кількість виконань

## Примітки

1. **Кеш планів** - шукає тільки в поточному кеші планів
2. **Доступність** - план може бути відсутнім якщо:
   - Модуль не виконувався нещодавно
   - Кеш планів був очищений
   - SQL Server перезавантажувався
3. **Права доступу** - потрібні VIEW SERVER STATE

## Використання в MCP Client

В AI асистенті:
```
Покажи мені план виконання процедури uspGetEmployeeManagers
```

## Пов'язані об'єкти

- `util.executionSearchPlanByObjectName` - базова функція пошуку плану
- `mcp.GetSqlModule` - вихідний код модуля

## Див. також

- [Огляд схеми mcp](../README.md)

# mcp.ScriptObjectAndReferences

## Опис

Процедура для генерації SQL скрипту об'єкта разом з усіма його залежностями через MCP протокол. Автоматично аналізує залежності та створює скрипт у правильному порядку (спочатку залежності, потім сам об'єкт).

## Синтаксис

```sql
EXEC mcp.ScriptObjectAndReferences 
    @objectFullName = '<database.schema.object>';
```

## Параметри

| Параметр | Тип | Обов'язковий | Опис |
|----------|-----|--------------|------|
| `@objectFullName` | NVARCHAR(128) | Так | Повне ім'я об'єкта у форматі 'database.schema.object' |

## Повертає

**Тип:** JSON string  
**Формат:** MCP response з SQL скриптом

## Приклади

```sql
-- Скрипт таблиці з залежностями
EXEC mcp.ScriptObjectAndReferences 
    @objectFullName = 'AdventureWorks.dbo.Employees';

-- Скрипт view з залежностями
EXEC mcp.ScriptObjectAndReferences 
    @objectFullName = 'AdventureWorks.Sales.vSalesPerson';

-- Скрипт процедури
EXEC mcp.ScriptObjectAndReferences 
    @objectFullName = 'utils.util.metadataGetDescriptions';
```

## Використання з MCP Client

В AI асистенті:
```
Згенеруй SQL скрипт для view Sales.vSalesPerson разом з усіма залежностями
```

## Пов'язані об'єкти

- `util.objectScriptWithDependencies` - базова функція для генерації скриптів
- `mcp.GetSqlModule` - отримання коду без залежностей

## Вихідний код

Розташування: `/mcp/Procedures/ScriptObjectAndReferences.sql`

## Див. також

- [mcp.GetSqlModule](GetSqlModule.md)
- [Огляд схеми mcp](../README.md)

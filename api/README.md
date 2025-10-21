# API Schema

Ця директорія містить SQL об'єкти схеми `api`, які використовуються мікросервісом PureSqlsApi.

## Структура

- `Functions/` - SQL функції (inline table functions та scalar functions)
- `Procedures/` - SQL процедури
- `Security/` - скрипт створення схеми

## Конвенція найменування

### Для таблично функцій (list endpoint)
- Ім'я: `api.{resourceName}List`
- Приклад: `api.productsList`, `api.ordersList`
- Повертає таблицю з колонкою `jsondata` (NVARCHAR(MAX))

### Для скалярних функцій (get endpoint)
- Ім'я: `api.{resourceName}Get`
- Приклад: `api.productGet`, `api.orderGet`
- Повертає NVARCHAR(MAX) з JSON

### Для процедур (exec endpoint)
- Ім'я: `api.{procedureName}`
- Приклад: `api.CreateOrder`, `api.UpdateProduct`
- Має OUTPUT параметр `@response NVARCHAR(MAX)` для повернення JSON

## Приклади

Див. файли у відповідних директоріях для прикладів реалізації.

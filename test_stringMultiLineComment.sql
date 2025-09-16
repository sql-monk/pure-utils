-- Тест функції stringMultiLineComment з оновленими вимогами
DECLARE @testComment NVARCHAR(MAX) = '/*
# Description
Генерує стандартизовані назви індексів відповідно до конвенцій найменування.
Функція аналізує існуючі індекси і пропонує нові назви за встановленими стандартами.

# Parameters
@object	NVARCHAR(128) = NULL - Назва таблиці для генерації назв індексів (NULL = усі таблиці)
@index   NVARCHAR(128) = NULL - Назва конкретного індексу (NULL = усі індекси)

# Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- IndexName NVARCHAR(128) - Поточна назва індексу
- NewIndexName NVARCHAR(128) - Рекомендована назва згідно конвенцій
- IndexType NVARCHAR(60) - Тип індексу

# Usage
-- Отримати рекомендовані назви для всіх індексів конкретної таблиці
SELECT * FROM util.indexesGetConventionNames(''myTable'', NULL);

-- Отримати рекомендовану назву для конкретного індексу
SELECT * FROM util.indexesGetConventionNames(''myTable'', ''myIndex'');
*/';

-- Тестуємо функцію
SELECT 
    description,
    minor,
    returns,
    usage
FROM util.stringMultiLineComment(@testComment);
/*
# Description
Створення схеми pupy для REST API об'єктів

# Usage
Виконати для створення схеми, якщо вона не існує
*/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'pupy')
BEGIN
    EXEC('CREATE SCHEMA pupy');
    PRINT 'Schema pupy created successfully';
END
ELSE
BEGIN
    PRINT 'Schema pupy already exists';
END
GO

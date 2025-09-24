/*
# Description
Inline table-valued функція для аналізу SQL запиту та генерації відповідного CREATE TABLE DDL.
Використовує sys.dm_exec_describe_first_result_set з підтримкою параметризованих запитів.
Автоматично визначає типи даних, nullable constraints та форматує результуючий скрипт.

# Parameters
@query NVARCHAR(MAX) - SQL запит для аналізу структури результуючого набору
@tablename NVARCHAR(128) = NULL - назва створюваної тимчасової таблиці (default: #temp)
@params NVARCHAR(MAX) = NULL - рядок декларації параметрів у форматі sp_executesql

# Returns
TABLE - табличний результат з єдиною колонкою:
- createScript NVARCHAR(MAX) - форматований CREATE TABLE скрипт з переносами рядків

# Usage
-- Простий SELECT аналіз
SELECT createScript FROM util.stringGetCreateTempScriptInline(
    'SELECT UserID, UserName, CreateDate FROM Users'
);

-- З кастомною назвою таблиці
SELECT createScript FROM util.stringGetCreateTempScriptInline(
    'SELECT OrderID, Total, OrderDate FROM Orders', 
    '#MyOrders'
);

-- Складний запит з агрегацією
SELECT createScript FROM util.stringGetCreateTempScriptInline('
    SELECT CategoryID, COUNT(*) as ProductCount, AVG(Price) as AvgPrice
    FROM Products 
    WHERE Active = 1
    GROUP BY CategoryID
', '#CategoryStats');

-- Параметризований запит
SELECT createScript FROM util.stringGetCreateTempScriptInline(
    'SELECT * FROM Orders WHERE CustomerID = @CustID AND OrderDate >= @FromDate',
    '#CustomerOrders',
    '@CustID INT, @FromDate DATETIME'
);

-- Динамічний SQL
DECLARE @dynamicQuery NVARCHAR(MAX) = 'SELECT TOP 100 * FROM Products WHERE Price > 100';
SELECT createScript FROM util.stringGetCreateTempScriptInline(@dynamicQuery, DEFAULT);
*/
CREATE OR ALTER FUNCTION [util].[stringGetCreateTempScriptInline](
    @query NVARCHAR(MAX), 
    @tablename NVARCHAR(128) = NULL,
    @params NVARCHAR(MAX) = NULL
)
RETURNS TABLE
AS
RETURN(
    WITH cteColumns AS (
        SELECT
            rs.column_ordinal,
            rs.name AS column_name,
            rs.system_type_name,
            rs.is_nullable
        FROM sys.dm_exec_describe_first_result_set(@query, @params, 1) rs
        WHERE rs.is_hidden = 0
    ),
    cteColumnDefinitions AS (
        SELECT 
            column_ordinal,
            CONCAT(
                QUOTENAME(column_name), ' ',
                system_type_name,
                CASE WHEN is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END
            ) AS column_definition
        FROM cteColumns
    )
    SELECT 
        CONCAT(
            'CREATE TABLE ', ISNULL(@tablename, '#temp'), ' (',
            CHAR(13) + CHAR(10) + CHAR(9),
            STRING_AGG(column_definition, ',' + CHAR(13) + CHAR(10) + CHAR(9)) 
                WITHIN GROUP (ORDER BY column_ordinal),
            CHAR(13) + CHAR(10) + ');'
        ) AS createScript
    FROM cteColumnDefinitions
);
GO
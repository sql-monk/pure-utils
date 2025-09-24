/*
Тестовий скрипт для перевірки функцій генерації скриптів створення тимчасових таблиць
*/

-- Перевіримо чи існує схема util
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'util')
    CREATE SCHEMA [util] AUTHORIZATION [dbo];
GO

-- Тест 1: stringGetCreateTempScriptInline - простий SELECT
PRINT '=== Тест 1: stringGetCreateTempScriptInline ===';
SELECT createScript 
FROM util.stringGetCreateTempScriptInline('SELECT 1 as ID, ''Test'' as Name, GETDATE() as CreateDate');
GO

-- Тест 2: stringGetCreateTempScript - складний запит
PRINT '=== Тест 2: stringGetCreateTempScript ===';
DECLARE @script NVARCHAR(MAX);
SET @script = util.stringGetCreateTempScript('SELECT TOP 5 name, object_id, create_date FROM sys.objects WHERE type = ''U''');
PRINT @script;
GO

-- Тест 3: objectGetCreateTempScriptInline - для системного об'єкта
PRINT '=== Тест 3: objectGetCreateTempScriptInline ===';
-- Створимо тестову процедуру для демонстрації
CREATE OR ALTER PROCEDURE dbo.TestProc
AS
BEGIN
    SELECT 
        name,
        object_id,
        type,
        create_date
    FROM sys.objects 
    WHERE type IN ('U', 'V', 'P')
    ORDER BY create_date DESC;
END;
GO

SELECT createScript 
FROM util.objectGetCreateTempScriptInline('dbo.TestProc');
GO

-- Тест 4: objectGetCreateTempScript - для тієї ж процедури
PRINT '=== Тест 4: objectGetCreateTempScript ===';
DECLARE @objectScript NVARCHAR(MAX);
SET @objectScript = util.objectGetCreateTempScript('dbo.TestProc');
PRINT @objectScript;
GO

-- Тест 5: Використання згенерованого скрипта для створення таблиці
PRINT '=== Тест 5: Реальне створення тимчасової таблиці ===';
DECLARE @createSQL NVARCHAR(MAX);
SET @createSQL = util.stringGetCreateTempScript('SELECT ''Sample'' as TextColumn, 123 as NumberColumn, CAST(1 as BIT) as BoolColumn');

-- Виконати згенерований скрипт
EXEC sp_executesql @createSQL;

-- Перевірити структуру створеної таблиці
IF OBJECT_ID('tempdb..#temp') IS NOT NULL
BEGIN
    PRINT 'Тимчасова таблиця успішно створена!';
    
    -- Показати колонки таблиці
    SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        IS_NULLABLE,
        CHARACTER_MAXIMUM_LENGTH
    FROM tempdb.INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME LIKE '#temp%'
    ORDER BY ORDINAL_POSITION;
    
    -- Вставити тестові дані
    INSERT INTO #temp VALUES ('Test data', 456, 0);
    
    -- Показати дані
    SELECT * FROM #temp;
    
    DROP TABLE #temp;
    PRINT 'Тимчасова таблиця видалена.';
END
ELSE
BEGIN
    PRINT 'Помилка: Тимчасова таблиця не була створена.';
END
GO

-- Очистити тестову процедуру
DROP PROCEDURE IF EXISTS dbo.TestProc;
GO

PRINT '=== Тестування завершено ===';
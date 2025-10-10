/*
# Description
Процедура для пошуку об'єктів та їх елементів через MCP протокол.
Повертає валідний JSON для MCP відповіді з результатами пошуку серед таблиць, представлень,
процедур, функцій та інших об'єктів у всіх доступних базах даних.

# Parameters
@filter NVARCHAR(128) = NULL - фільтр для пошуку (підтримує шаблони LIKE, NULL = всі об'єкти)
@onlyMajor BIT = 1 - режим пошуку:
    1 = тільки об'єкти (таблиці, представлення, процедури, функції тощо)
    0 = об'єкти + колонки + параметри + пошук у визначеннях модулів

# Returns
JSON string - валідна MCP відповідь з масивом content, що містить результати пошуку

# Usage
-- Знайти всі об'єкти в усіх базах
EXEC mcp.FindObjects;

-- Знайти об'єкти за назвою (тільки об'єкти)
EXEC mcp.FindObjects @filter = 'metadata%', @onlyMajor = 1;

-- Повний пошук: об'єкти + колонки + параметри + визначення
EXEC mcp.FindObjects @filter = '%GetScript%', @onlyMajor = 0;
*/
CREATE OR ALTER PROCEDURE mcp.FindObjects
    @filter NVARCHAR(128) = NULL,
    @onlyMajor BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    -- Створюємо тимчасову таблицю для результатів
    CREATE TABLE #searchResults (
        databaseName NVARCHAR(128),
        schemaName NVARCHAR(128),
        objectName NVARCHAR(128),
        fullName NVARCHAR(512),
        objectType NVARCHAR(60),
        typeDesc NVARCHAR(60),
        elementType NVARCHAR(20),
        elementName NVARCHAR(128),
        matchInfo NVARCHAR(MAX)
    );
    
    -- Викликаємо основну процедуру пошуку
    INSERT INTO #searchResults
    EXEC util.objectsFind 
        @filter = @filter, 
        @onlyMajor = @onlyMajor;
    
    DECLARE @searchJson NVARCHAR(MAX);
    DECLARE @content NVARCHAR(MAX);
    DECLARE @result NVARCHAR(MAX);
    
    -- Формуємо JSON з результатами пошуку
    SELECT @searchJson = (
        SELECT
            databaseName,
            schemaName,
            objectName,
            fullName,
            objectType,
            typeDesc,
            elementType,
            elementName,
            matchInfo
        FROM #searchResults
        ORDER BY
            databaseName,
            schemaName,
            objectName,
            elementType,
            elementName
        FOR JSON PATH
    );
    
    -- Формуємо масив content з одним елементом типу text
    SELECT @content = (SELECT 'text' type, ISNULL(@searchJson, '[]') text FOR JSON PATH);
    
    -- Обгортаємо у фінальну структуру MCP відповіді
    SET @result = CONCAT('{"content":', @content, '}');
    
    SELECT @result result;
END;
GO

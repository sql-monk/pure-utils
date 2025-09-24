# DESCRIPTION & MS_DESCRIPTION та EXTENDED PROPERTIES - Детальний огляд системи документування

## Архітектура системи документування

Система DESCRIPTION & MS_DESCRIPTION в Pure Utils - це комплексне рішення для автоматизації процесу документування об'єктів бази даних через розширені властивості (Extended Properties). Система забезпечує як автоматичне витягнення документації з коментарів коду, так і ручне управління описами для всіх типів об'єктів SQL Server.

### Ключові концепції

**Extended Properties** - це механізм SQL Server для зберігання додаткової метаінформації про об'єкти бази даних. Властивість `MS_Description` є стандартною властивістю для зберігання описів об'єктів, яка підтримується більшістю інструментів управління базами даних.

**Автоматичне витягнення** - система може парсити структуровані коментарі в коді модулів (процедур, функцій, представлень) та автоматично створювати відповідні Extended Properties.

**Ручне управління** - набір процедур для встановлення описів різних типів об'єктів через програмний інтерфейс.

---

## Компоненти системи (15 об'єктів)

### **Автоматичне витягнення описів з коментарів (5 об'єктів)**

#### 1. **`util.modulesGetDescriptionFromComments`** - Парсинг сучасних коментарів
- **Призначення**: Витягує описи з структурованих багаторядкових коментарів
- **Формат**: Підтримує markdown-подібний синтаксис з секціями
- **Результат**: Повертає таблицю з розібраними елементами опису

#### 2. **`util.modulesGetDescriptionFromCommentsLegacy`** - Парсинг застарілих коментарів  
- **Призначення**: Витягує описи зі старого формату коментарів
- **Формат**: Підтримує простий формат "-- Description:"
- **Сумісність**: Забезпечує міграцію з старих систем документування

#### 3. **`util.stringSplitMultiLineComment`** - Розбір структурованих коментарів
- **Призначення**: Парсить багаторядкові коментарі на секції
- **Технологія**: Розпізнає заголовки секцій та їх вміст
- **Застосування**: Базова функція для інших парсерів

#### 4. **`util.modulesSetDescriptionFromComments`** - Автоматичне встановлення описів
- **Призначення**: Встановлює Extended Properties на основі коментарів
- **Процес**: Парсить ? Аналізує ? Встановлює властивості
- **Підтримка**: Процедури, функції, представлення, тригери

#### 5. **`util.modulesSetDescriptionFromCommentsLegacy`** - Міграція старих описів
- **Призначення**: Встановлює описи з коментарів старого формату
- **Режими**: Тільки порожні описи або перезапис існуючих
- **Параметр**: `@OnlyEmpty BIT` для контролю поведінки

### **Ручне встановлення описів (12 об'єктів)**

#### 6. **`util.metadataSetTableDescription`** - Описи таблиць
```sql
-- Встановлює MS_Description для таблиці
-- Підтримує схеми та повні назви об'єктів
EXEC util.metadataSetTableDescription 
    @table = 'dbo.Users', 
    @description = 'Таблиця користувачів системи з основною інформацією';
```

#### 7. **`util.metadataSetColumnDescription`** - Описи колонок
```sql
-- Встановлює MS_Description для колонки таблиці або представлення
EXEC util.metadataSetColumnDescription 
    @object = 'dbo.Users', 
    @column = 'Email', 
    @description = 'Email адреса користувача для аутентифікації';
```

#### 8. **`util.metadataSetProcedureDescription`** - Описи процедур
```sql
-- Встановлює MS_Description для збереженої процедури
EXEC util.metadataSetProcedureDescription 
    @procedure = 'dbo.CreateUser', 
    @description = 'Створює нового користувача в системі з валідацією';
```

#### 9. **`util.metadataSetFunctionDescription`** - Описи функцій
```sql
-- Встановлює MS_Description для функції (скалярної або табличної)
EXEC util.metadataSetFunctionDescription 
    @function = 'dbo.GetUserName', 
    @description = 'Повертає повне ім''я користувача за його ID';
```

#### 10. **`util.metadataSetViewDescription`** - Описи представлень
```sql
-- Встановлює MS_Description для представлення
EXEC util.metadataSetViewDescription 
    @view = 'dbo.vw_ActiveUsers', 
    @description = 'Представлення активних користувачів з розширеною інформацією';
```

#### 11. **`util.metadataSetTriggerDescription`** - Описи тригерів
```sql
-- Встановлює MS_Description для тригера
EXEC util.metadataSetTriggerDescription 
    @trigger = 'dbo.tr_Users_Audit', 
    @description = 'Тригер аудиту змін користувацьких записів';
```

#### 12. **`util.metadataSetParameterDescription`** - Описи параметрів
```sql
-- Встановлює MS_Description для параметра процедури або функції
EXEC util.metadataSetParameterDescription 
    @major = 'dbo.CreateUser', 
    @parameter = '@Email', 
    @description = 'Email адреса нового користувача (обов''язковий параметр)';
```

#### 13. **`util.metadataSetIndexDescription`** - Описи індексів
```sql
-- Встановлює MS_Description для індексу
EXEC util.metadataSetIndexDescription 
    @major = 'dbo.Users', 
    @index = 'IX_Users_Email', 
    @description = 'Унікальний індекс для швидкого пошуку по email';
```

#### 14. **`util.metadataSetSchemaDescription`** - Описи схем
```sql
-- Встановлює MS_Description для схеми бази даних
EXEC util.metadataSetSchemaDescription 
    @schema = 'sales', 
    @description = 'Схема об''єктів системи продажів та CRM';
```

#### 15. **`util.metadataSetDataspaceDescription`** - Описи просторів даних
```sql
-- Встановлює MS_Description для файлової групи або схеми розділення
EXEC util.metadataSetDataspaceDescription 
    @dataspace = 'SALES_DATA', 
    @description = 'Файлова група для зберігання даних продажів';
```

#### 16. **`util.metadataSetFilegroupDescription`** - Описи файлових груп
```sql
-- Встановлює MS_Description для файлової групи
EXEC util.metadataSetFilegroupDescription 
    @filegroup = 'ARCHIVE_FG', 
    @description = 'Файлова група для архівних даних на повільному сховищі';
```

#### 17. **`util.metadataSetExtendedProperty`** - Універсальна процедура
```sql
-- Універсальна процедура для встановлення будь-яких Extended Properties
EXEC util.metadataSetExtendedProperty 
    @name = 'DataClassification', 
    @value = 'Confidential',
    @level0type = 'SCHEMA', @level0name = 'dbo',
    @level1type = 'TABLE', @level1name = 'Users',
    @level2type = 'COLUMN', @level2name = 'SSN';
```

### **Читання та отримання описів (2 об'єкти)**

#### 18. **`util.metadataGetDescriptions`** - Отримання описів об'єктів
```sql
-- Повертає всі MS_Description для об'єкта або його частин
-- Параметри: @object - назва об'єкта, @subObject - підоб'єкт (колонка, параметр)
SELECT * FROM util.metadataGetDescriptions('dbo.Users', NULL); -- вся таблиця
SELECT * FROM util.metadataGetDescriptions('dbo.Users', 'Email'); -- конкретна колонка
```

#### 19. **`util.metadataGetExtendedProperiesValues`** - Читання розширених властивостей
```sql
-- Повертає значення конкретної Extended Property
SELECT * FROM util.metadataGetExtendedProperiesValues(
    'dbo.Users', 
    'Email', 
    'MS_Description'
);
```

---

## Принцип роботи системи

### **Автоматичне витягнення з коментарів**

#### Етап 1: Парсинг коментарів
```sql
-- Система читає вихідний код модуля
DECLARE @moduleText NVARCHAR(MAX) = (
    SELECT definition 
    FROM sys.sql_modules 
    WHERE object_id = OBJECT_ID('dbo.MyProcedure')
);

-- Витягує структуровані коментарі
SELECT * FROM util.stringSplitMultiLineComment(@moduleText);
```

#### Етап 2: Аналіз структури
```sql
-- Розпізнає секції опису
WITH ParsedComments AS (
    SELECT 
        sectionName,
        sectionValue,
        ROW_NUMBER() OVER (ORDER BY position) as RowNum
    FROM util.modulesGetDescriptionFromComments('dbo.MyProcedure')
)
SELECT 
    CASE sectionName 
        WHEN 'Description' THEN 'MS_Description для процедури'
        WHEN 'Parameters' THEN 'MS_Description для параметрів'
        WHEN 'Returns' THEN 'MS_Description для результату'
    END as Target,
    sectionValue
FROM ParsedComments;
```

#### Етап 3: Встановлення властивостей
```sql
-- Автоматично створює Extended Properties
EXEC util.modulesSetDescriptionFromComments 'dbo.MyProcedure';

-- Результат: встановлені MS_Description для:
-- - Самої процедури (основний опис)
-- - Кожного параметра (якщо описані)
-- - Повернутих значень (для функцій)
```

### **Ручне управління описами**

#### Створення нового опису
```sql
-- Перевіряє існування властивості
IF EXISTS (
    SELECT 1 FROM fn_listextendedproperty('MS_Description', 
        'SCHEMA', 'dbo', 'TABLE', 'Users', 'COLUMN', 'Email')
)
BEGIN
    -- Оновлює існуючу
    EXEC sp_updateextendedproperty 
        @name = 'MS_Description',
        @value = 'Новий опис',
        @level0type = 'SCHEMA', @level0name = 'dbo',
        @level1type = 'TABLE', @level1name = 'Users',
        @level2type = 'COLUMN', @level2name = 'Email';
END
ELSE
BEGIN
    -- Створює нову
    EXEC sp_addextendedproperty 
        @name = 'MS_Description',
        @value = 'Новий опис',
        @level0type = 'SCHEMA', @level0name = 'dbo',
        @level1type = 'TABLE', @level1name = 'Users',
        @level2type = 'COLUMN', @level2name = 'Email';
END
```

#### Резервне копіювання
```sql
-- Система автоматично створює бекап перед зміною
DECLARE @backupName NVARCHAR(128) = CONCAT(
    'MS_Description_Backup_', 
    FORMAT(GETDATE(), 'yyyyMMdd_HHmmss')
);

-- Зберігає старе значення
EXEC sp_addextendedproperty 
    @name = @backupName,
    @value = @oldDescription,
    @level0type = 'SCHEMA', @level0name = 'dbo',
    @level1type = 'TABLE', @level1name = 'Users',
    @level2type = 'COLUMN', @level2name = 'Email';
```

---

## Формат багаторядкових коментарів для автоматичного парсингу

### **Стандартний формат сучасних коментарів**

Для коректної роботи автоматичного парсингу коментарі повинні мати наступну структуру:

```sql
/*
# Description
Детальний опис призначення процедури або функції.
Може містити кілька рядків з поясненням логіки роботи,
бізнес-правил та особливостей використання.

# Parameters  
@param1 TYPE [= DEFAULT] - опис першого параметра з поясненням призначення
@param2 TYPE [= DEFAULT] - опис другого параметра, може бути багаторядковим
    опис що продовжується на наступному рядку з відступом
@param3 TYPE [= DEFAULT] - опис третього параметра

# Returns
Опис того, що повертає функція або процедура.
Для функцій - тип даних та формат результату.
Для процедур - опис вихідних параметрів або результуючих наборів.

# Usage
Приклади використання з конкретними значеннями параметрів:
EXEC dbo.MyProcedure @param1 = 'value1', @param2 = 123;

# Notes  
Додаткові примітки, обмеження, попередження про продуктивність,
залежності від інших об'єктів або системних налаштувань.

# Author
Ім'я автора та дата створення (опціонально)

# History
Журнал змін з датами та описом модифікацій (опціонально)
*/
```

### **Правила оформлення коментарів**

#### **1. Загальні принципи:**
- Коментар повинен починатися з `/*` та закінчуватися `*/`
- Секції позначаються символом `#` на початку рядка
- Назви секцій регістронезалежні, але рекомендується CamelCase
- Порожні рядки між секціями ігноруються

#### **2. Обов'язкові секції:**
```sql
/*
# Description  
Мінімально необхідна секція з описом об'єкта
*/
```

#### **3. Секція Parameters:**
```sql
/*
# Parameters
@userId INT - ідентифікатор користувача (обов'язковий)
@startDate DATETIME = NULL - початкова дата фільтрації (опціонально)
@endDate DATETIME = NULL - кінцева дата фільтрації, 
    якщо не вказана, використовується поточна дата
@includeInactive BIT = 0 - включати неактивних користувачів:
    0 - тільки активні (за замовчуванням)
    1 - всі користувачі
*/
```

#### **4. Секція Returns (для функцій):**
```sql
/*
# Returns
TABLE - Повертає таблицю з колонками:
- UserId INT - ідентифікатор користувача  
- UserName NVARCHAR(100) - повне ім'я користувача
- LastLogin DATETIME - час останнього входу в систему
- IsActive BIT - статус активності акаунту

Для скалярних функцій:
NVARCHAR(100) - повертає повне ім'я користувача у форматі "Прізвище, Ім'я"
або NULL якщо користувач не знайдений
*/
```

#### **5. Секція Usage з прикладами:**
```sql
/*
# Usage
-- Отримати активних користувачів за останній місяць
SELECT * FROM dbo.GetUserActivity(@userId = NULL, @startDate = '2024-01-01', @endDate = NULL, @includeInactive = 0);

-- Перевірити активність конкретного користувача
SELECT * FROM dbo.GetUserActivity(@userId = 123, @startDate = NULL, @endDate = NULL, @includeInactive = 1);

-- Розширений аналіз за період
DECLARE @result TABLE (UserId INT, ActivityScore DECIMAL(5,2));
INSERT INTO @result 
SELECT UserId, COUNT(*) * 1.5 as ActivityScore 
FROM dbo.GetUserActivity(@userId = NULL, @startDate = '2024-01-01', @endDate = '2024-12-31', @includeInactive = 0)
GROUP BY UserId;
*/
```

### **Застарілий формат (Legacy)**

Для міграції існуючого коду підтримується простий формат:

```sql
-- Description: Короткий опис процедури або функції в одному рядку
-- Author: Ім'я автора  
-- Created: 2024-01-15
-- Modified: 2024-02-20 - додано новий параметр @includeInactive
```

### **Приклад повного коментаря**

```sql
/*
# Description
Процедура для створення нового користувача в системі з повною валідацією
даних та автоматичним призначенням початкових ролей. Виконує перевірку
унікальності email, валідацію формату даних та створення супутніх записів
в таблицях профілю та налаштувань.

# Parameters
@email NVARCHAR(255) - email адреса користувача (обов'язковий)
    Повинен мати валідний формат та бути унікальним в системі
@firstName NVARCHAR(100) - ім'я користувача (обов'язковий)
    Мінімум 2 символи, максимум 100, тільки літери та дефіс
@lastName NVARCHAR(100) - прізвище користувача (обов'язковий)  
    Мінімум 2 символи, максимум 100, тільки літери та дефіс
@departmentId INT = NULL - ідентифікатор департаменту (опціонально)
    Якщо не вказано, користувач буде призначений до департаменту за замовчуванням
@isActive BIT = 1 - початковий статус активності акаунту
    1 - активний (за замовчуванням), 0 - неактивний
@sendWelcomeEmail BIT = 1 - надіслати привітальний email
    1 - надіслати (за замовчуванням), 0 - не надсилати

# Returns
Процедура повертає через вихідні параметри:
@newUserId INT OUTPUT - ідентифікатор створеного користувача
@errorMessage NVARCHAR(500) OUTPUT - повідомлення про помилку (якщо є)

# Usage  
-- Створення стандартного користувача
DECLARE @userId INT, @error NVARCHAR(500);
EXEC dbo.CreateUser 
    @email = 'john.doe@company.com',
    @firstName = 'John', 
    @lastName = 'Doe',
    @departmentId = 5,
    @newUserId = @userId OUTPUT,
    @errorMessage = @error OUTPUT;

-- Створення неактивного користувача без email
DECLARE @userId INT, @error NVARCHAR(500);
EXEC dbo.CreateUser 
    @email = 'temp.user@company.com',
    @firstName = 'Temporary', 
    @lastName = 'User',
    @isActive = 0,
    @sendWelcomeEmail = 0,
    @newUserId = @userId OUTPUT,
    @errorMessage = @error OUTPUT;

# Notes
- Процедура автоматично створює запис в таблиці UserProfiles
- Призначає роль 'StandardUser' за замовчуванням  
- Логує всі дії створення користувача в таблицю AuditLog
- При помилці валідації откочує всі зміни через транзакцію
- Максимальна довжина пароля генерується автоматично (12 символів)

# Author
John Smith (john.smith@company.com)

# History  
2024-01-15 - Початкова версія (John Smith)
2024-02-20 - Додано параметр @sendWelcomeEmail (Jane Doe)  
2024-03-10 - Покращено валідацію email адрес (John Smith)
2024-04-05 - Додано підтримку департаментів (Mike Johnson)
*/
CREATE OR ALTER PROCEDURE dbo.CreateUser
    @email NVARCHAR(255),
    @firstName NVARCHAR(100), 
    @lastName NVARCHAR(100),
    @departmentId INT = NULL,
    @isActive BIT = 1,
    @sendWelcomeEmail BIT = 1,
    @newUserId INT OUTPUT,
    @errorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    -- Код процедури
END;
```

---

## Практичні сценарії використання

### **Сценарій 1: Документування існуючої системи**

```sql
-- Крок 1: Аналіз існуючих коментарів
SELECT 
    OBJECT_SCHEMA_NAME(object_id) as SchemaName,
    OBJECT_NAME(object_id) as ObjectName,
    definition
FROM sys.sql_modules 
WHERE definition LIKE '%Description%'
ORDER BY SchemaName, ObjectName;

-- Крок 2: Автоматичне встановлення описів з коментарів  
DECLARE @objectName NVARCHAR(128);
DECLARE object_cursor CURSOR FOR
    SELECT QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) + '.' + QUOTENAME(OBJECT_NAME(object_id))
    FROM sys.sql_modules 
    WHERE definition LIKE '%# Description%';

OPEN object_cursor;
FETCH NEXT FROM object_cursor INTO @objectName;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC util.modulesSetDescriptionFromComments @objectName;
        PRINT 'Processed: ' + @objectName;
    END TRY
    BEGIN CATCH  
        PRINT 'Error processing ' + @objectName + ': ' + ERROR_MESSAGE();
    END CATCH
    
    FETCH NEXT FROM object_cursor INTO @objectName;
END

CLOSE object_cursor;
DEALLOCATE object_cursor;
```

### **Сценарій 2: Масове документування таблиць**

```sql
-- Документування всіх таблиць схеми
DECLARE @tables TABLE (
    SchemaName NVARCHAR(128),
    TableName NVARCHAR(128), 
    Description NVARCHAR(500)
);

-- Заповнення описів (можна завантажити з Excel або іншого джерела)
INSERT INTO @tables VALUES 
('dbo', 'Users', 'Основна таблиця користувачів системи'),
('dbo', 'Orders', 'Таблиця замовлень клієнтів'),  
('dbo', 'Products', 'Каталог товарів та послуг'),
('sales', 'Customers', 'Інформація про клієнтів відділу продажів');

-- Встановлення описів
DECLARE @schema NVARCHAR(128), @table NVARCHAR(128), @desc NVARCHAR(500);
DECLARE table_cursor CURSOR FOR SELECT SchemaName, TableName, Description FROM @tables;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @schema, @table, @desc;

WHILE @@FETCH_STATUS = 0  
BEGIN
    DECLARE @fullName NVARCHAR(256) = QUOTENAME(@schema) + '.' + QUOTENAME(@table);
    EXEC util.metadataSetTableDescription @table = @fullName, @description = @desc;
    
    FETCH NEXT FROM table_cursor INTO @schema, @table, @desc;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;
```

### **Сценарій 3: Документування колонок через метадані**

```sql
-- Автоматичне створення описів колонок на основі назв
WITH ColumnDescriptions AS (
    SELECT 
        OBJECT_SCHEMA_NAME(t.object_id) as SchemaName,
        OBJECT_NAME(t.object_id) as TableName,
        c.name as ColumnName,
        CASE 
            WHEN c.name LIKE '%ID' OR c.name LIKE '%Id' 
            THEN 'Унікальний ідентифікатор запису'
            WHEN c.name LIKE '%Name' OR c.name LIKE '%Title'
            THEN 'Назва або заголовок'  
            WHEN c.name LIKE '%Date' OR c.name LIKE '%Time'
            THEN 'Дата та час події'
            WHEN c.name LIKE '%Email' 
            THEN 'Електронна адреса'
            WHEN c.name LIKE '%Phone' 
            THEN 'Номер телефону'
            WHEN c.name LIKE '%Status' OR c.name LIKE '%State'
            THEN 'Статус або стан об''єкта'  
            WHEN c.name LIKE '%Amount' OR c.name LIKE '%Price' OR c.name LIKE '%Cost'
            THEN 'Грошова сума'
            WHEN c.name LIKE '%Count' OR c.name LIKE '%Quantity'
            THEN 'Кількість або лічильник'
            WHEN c.name LIKE '%Flag' OR c.name LIKE 'Is%'
            THEN 'Логічний прапор (так/ні)'
            ELSE 'Колонка потребує додавання опису'
        END as SuggestedDescription,
        tp.name as DataType,
        c.max_length,
        c.is_nullable
    FROM sys.tables t
    JOIN sys.columns c ON t.object_id = c.object_id
    JOIN sys.types tp ON c.user_type_id = tp.user_type_id
    WHERE t.schema_id = SCHEMA_ID('dbo')
)
SELECT 
    SchemaName,
    TableName, 
    ColumnName,
    SuggestedDescription + 
    CASE WHEN is_nullable = 1 THEN ' (може бути пустим)' ELSE ' (обов''язковий)' END +
    ' [' + DataType + 
    CASE WHEN max_length > 0 AND DataType IN ('varchar', 'nvarchar', 'char', 'nchar') 
         THEN '(' + CAST(max_length as VARCHAR(10)) + ')' 
         ELSE '' 
    END + ']' as FullDescription
FROM ColumnDescriptions
ORDER BY SchemaName, TableName, ColumnName;
```

### **Сценарій 4: Валідація та перевірка документації**

```sql
-- Звіт про стан документування
WITH DocumentationStatus AS (
    -- Таблиці без описів
    SELECT 
        'TABLE' as ObjectType,
        OBJECT_SCHEMA_NAME(t.object_id) as SchemaName, 
        OBJECT_NAME(t.object_id) as ObjectName,
        NULL as SubObjectName,
        CASE WHEN ep.value IS NULL THEN 'Відсутній опис' ELSE 'Документовано' END as Status
    FROM sys.tables t
    LEFT JOIN sys.extended_properties ep ON t.object_id = ep.major_id 
        AND ep.minor_id = 0 AND ep.name = 'MS_Description'
    
    UNION ALL
    
    -- Колонки без описів  
    SELECT 
        'COLUMN',
        OBJECT_SCHEMA_NAME(t.object_id),
        OBJECT_NAME(t.object_id), 
        c.name,
        CASE WHEN ep.value IS NULL THEN 'Відсутній опис' ELSE 'Документовано' END
    FROM sys.tables t
    JOIN sys.columns c ON t.object_id = c.object_id  
    LEFT JOIN sys.extended_properties ep ON t.object_id = ep.major_id 
        AND c.column_id = ep.minor_id AND ep.name = 'MS_Description'
        
    UNION ALL
    
    -- Процедури без описів
    SELECT 
        'PROCEDURE',
        OBJECT_SCHEMA_NAME(p.object_id),
        OBJECT_NAME(p.object_id),
        NULL,
        CASE WHEN ep.value IS NULL THEN 'Відсутній опис' ELSE 'Документовано' END
    FROM sys.procedures p
    LEFT JOIN sys.extended_properties ep ON p.object_id = ep.major_id 
        AND ep.minor_id = 0 AND ep.name = 'MS_Description'
)
SELECT 
    ObjectType,
    COUNT(*) as TotalObjects,
    SUM(CASE WHEN Status = 'Документовано' THEN 1 ELSE 0 END) as DocumentedObjects,
    SUM(CASE WHEN Status = 'Відсутній опис' THEN 1 ELSE 0 END) as UndocumentedObjects,
    CAST(SUM(CASE WHEN Status = 'Документовано' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as DECIMAL(5,2)) as DocumentationPercentage
FROM DocumentationStatus  
GROUP BY ObjectType
ORDER BY DocumentationPercentage DESC;
```

### **Сценарій 5: Експорт документації**

```sql
-- Експорт повної документації для генерації звітів
SELECT 
    'TABLE' as ObjectType,
    t.SchemaName,
    t.ObjectName, 
    NULL as SubObjectName,
    t.Description,
    NULL as DataType,
    NULL as IsNullable
FROM (
    SELECT 
        OBJECT_SCHEMA_NAME(tb.object_id) as SchemaName,
        OBJECT_NAME(tb.object_id) as ObjectName,
        CAST(ep.value as NVARCHAR(MAX)) as Description
    FROM sys.tables tb
    LEFT JOIN sys.extended_properties ep ON tb.object_id = ep.major_id 
        AND ep.minor_id = 0 AND ep.name = 'MS_Description'
) t

UNION ALL

SELECT 
    'COLUMN',
    c.SchemaName,
    c.ObjectName,
    c.ColumnName,
    c.Description, 
    c.DataType,
    c.IsNullable
FROM (
    SELECT 
        OBJECT_SCHEMA_NAME(tb.object_id) as SchemaName,
        OBJECT_NAME(tb.object_id) as ObjectName,
        cl.name as ColumnName,
        CAST(ep.value as NVARCHAR(MAX)) as Description,
        tp.name + CASE 
            WHEN tp.name IN ('varchar', 'nvarchar', 'char', 'nchar') 
            THEN '(' + CASE WHEN cl.max_length = -1 THEN 'MAX' ELSE CAST(cl.max_length as VARCHAR(10)) END + ')'
            WHEN tp.name IN ('decimal', 'numeric')
            THEN '(' + CAST(cl.precision as VARCHAR(10)) + ',' + CAST(cl.scale as VARCHAR(10)) + ')'
            ELSE ''
        END as DataType,
        CASE WHEN cl.is_nullable = 1 THEN 'YES' ELSE 'NO' END as IsNullable
    FROM sys.tables tb
    JOIN sys.columns cl ON tb.object_id = cl.object_id
    JOIN sys.types tp ON cl.user_type_id = tp.user_type_id
    LEFT JOIN sys.extended_properties ep ON tb.object_id = ep.major_id 
        AND cl.column_id = ep.minor_id AND ep.name = 'MS_Description'
) c

ORDER BY ObjectType, SchemaName, ObjectName, SubObjectName;
```

---

## Інтеграція з інструментами розробки

### **SQL Server Management Studio (SSMS)**
Extended Properties автоматично відображаються в:
- Object Explorer Details (колонка Description)
- Properties діалогах об'єктів  
- Generate Scripts Wizard (опція Include Extended Properties)

### **Azure Data Studio**
Розширення для відображення описів:
- Schema Compare з підтримкою Extended Properties
- Database Documentation генератор

### **Visual Studio SQL Server Data Tools (SSDT)**
- Підтримка Extended Properties в Database Projects
- Автоматичне включення в схему порівняння
- Генерація документації з описами

### **Автоматизація через PowerShell**
```powershell
# Скрипт для експорту документації в Excel
Import-Module SqlServer

$connectionString = "Server=localhost;Database=MyDB;Integrated Security=true"
$query = @"
SELECT 
    ObjectType, SchemaName, ObjectName, SubObjectName, 
    Description, DataType, IsNullable
FROM util.GetAllDocumentation()
ORDER BY ObjectType, SchemaName, ObjectName
"@

$data = Invoke-Sqlcmd -ConnectionString $connectionString -Query $query
$data | Export-Excel -Path "C:\Reports\DatabaseDocumentation.xlsx" -AutoSize -TableStyle Medium2
```

**pure-utiles**

```sql
util.help
GO
--OR
util.help keyword
```
# procedures
## `errorHandler`

  * @attachment NVARCHAR(MAX) = NULL - додаткова інформація або повідомлення для додавання разом з помилкою

Універсальна процедура обробки помилок, яка отримує системну інформацію про помилку, записує інформацію про неї, 
може надіслати на електронну пошту. Записує помилки в таблицю util.ErrorLog і повертає детальну інформацію.
Процедура може використовувати для помилок, отриманих із блоку CATCH або для відображення стану.
### Usage

```sql
BEGIN TRY
    -- Ваш код
END TRY
BEGIN CATCH
    EXEC util.errorHandler @attachment = 'Додаткова інформація про контекст';
END CATCH
```

## `help`

  * @keyword sysname = NULL - ключове слово для фільтрації результатів (NULL = всі об'єкти)

Процедура довідки, яка виводить інформацію про доступні об'єкти в схемі util.
Показує список процедур, функцій та їх описи з розширених властивостей.
### Usage

```sql
-- Показати всю довідку
EXEC util.help;
-- Показати довідку за ключовим словом
EXEC util.help 'metadata';
```

## `indexesSetConventionNames`

  * @table NVARCHAR(128) = NULL - назва таблиці для перейменування індексів (NULL = всі таблиці)
  * @index NVARCHAR(128) = NULL - назва конкретного індексу (NULL = всі індекси)
  * @output TINYINT = 1 - виводити генеровані SQL команди (1) або тільки виконувати (0)

Перейменовує індекси таблиць за стандартними конвенціями найменування, генеруючи та виконуючи SQL команди.
### Usage

```sql
-- Перейменувати всі індекси таблиці з виводом команд
EXEC util.indexesSetConventionNames @table = 'myTable', @output = 1;
-- Перейменувати конкретний індекс без виводу
EXEC util.indexesSetConventionNames @table = 'myTable', @index = 'oldIndexName', @output = 0;
```

## `metadataSetColumnDescription`
Встановлює опис для колонки таблиці або представлення через розширені властивості MS_Description.
Процедура автоматично визначає схему та тип об'єкта, а потім встановлює опис для вказаної колонки.
### Usage

```sql
```sql
EXEC util.metadataSetColumnDescription 'myTable', 'myColumn', 'Опис колонки';
EXEC util.metadataSetColumnDescription 'dbo.users', 'user_id', 'Унікальний ідентифікатор користувача';
```
```

## `metadataSetDataspaceDescription`

  * @dataspace NVARCHAR(128) - назва простору даних
  * @description NVARCHAR(MAX) - текст опису для простору даних

Встановлює опис для простору даних (файлової групи або схеми розділення) через розширені властивості MS_Description.
### Usage

```sql
-- Встановити опис для файлової групи
EXEC util.metadataSetDataspaceDescription @dataspace = 'PRIMARY', @description = 'Основна файлова група';
-- Встановити опис для схеми розділення
EXEC util.metadataSetDataspaceDescription @dataspace = 'MyPartitionScheme', @description = 'Схема розділення по датах';
```

## `metadataSetExtendedProperty`

  * @name NVARCHAR(128) - назва розширеної властивості
  * @value NVARCHAR(MAX) - значення властивості
  * @level0type NVARCHAR(128) = NULL - тип об'єкта рівня 0 (наприклад, 'SCHEMA')
  * @level0name NVARCHAR(128) = NULL - назва об'єкта рівня 0
  * @level1type NVARCHAR(128) = NULL - тип об'єкта рівня 1 (наприклад, 'TABLE')
  * @level1name NVARCHAR(128) = NULL - назва об'єкта рівня 1
  * @level2type NVARCHAR(128) = NULL - тип об'єкта рівня 2 (наприклад, 'COLUMN')
  * @level2name NVARCHAR(128) = NULL - назва об'єкта рівня 2

Універсальна процедура для встановлення розширених властивостей на різних рівнях ієрархії об'єктів бази даних.
Підтримує встановлення властивостей для об'єктів на рівні схеми, таблиці, колонки тощо.
Перед оновленням існуючих властивостей створює їх резервну копію з timestamps.
### Usage

```sql
-- Встановити властивість для таблиці
EXEC util.metadataSetExtendedProperty @name = 'MS_Description', @value = 'Опис таблиці',
    @level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'myTable';
-- Встановити властивість для колонки
EXEC util.metadataSetExtendedProperty @name = 'MS_Description', @value = 'Опис колонки',
    @level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'myTable',
    @level2type = 'COLUMN', @level2name = 'myColumn';
```

## `metadataSetFilegroupDescription`

  * @filegroup NVARCHAR(128) - назва файлової групи
  * @description NVARCHAR(MAX) - текст опису для файлової групи

Встановлює опис для файлової групи через розширені властивості MS_Description.
### Usage

```sql
-- Встановити опис для файлової групи
EXEC util.metadataSetFilegroupDescription @filegroup = 'PRIMARY', @description = 'Основна файлова група системи';
-- Встановити опис для додаткової файлової групи
EXEC util.metadataSetFilegroupDescription @filegroup = 'DATA_FG', @description = 'Файлова група для користувацьких даних';
```

## `metadataSetFunctionDescription`

  * @function NVARCHAR(128) - назва функції
  * @description NVARCHAR(MAX) - текст опису для функції

Встановлює опис для функції через розширені властивості MS_Description.
### Usage

```sql
-- Встановити опис для скалярної функції
EXEC util.metadataSetFunctionDescription @function = 'dbo.MyScalarFunction', @description = 'Функція розрахунку значення';
-- Встановити опис для табличної функції
EXEC util.metadataSetFunctionDescription @function = 'dbo.MyTableFunction', @description = 'Функція повертає набір рядків';
```

## `metadataSetIndexDescription`

  * @major NVARCHAR(128) - назва таблиці або object_id
  * @index NVARCHAR(128) - назва індексу
  * @description NVARCHAR(MAX) - текст опису для індексу

Встановлює опис для індексу через розширені властивості MS_Description.
### Usage

```sql
-- Встановити опис для індексу
EXEC util.metadataSetIndexDescription @major = 'dbo.myTable', @index = 'IX_myTable_Column1', @description = 'Індекс для швидкого пошуку по Column1';
-- Встановити опис для первинного ключа
EXEC util.metadataSetIndexDescription @major = 'dbo.myTable', @index = 'PK_myTable', @description = 'Первинний ключ таблиці';
```

## `metadataSetParameterDescription`

  * @major NVARCHAR(128) - назва процедури або функції
  * @parameter NVARCHAR(128) - назва параметра
  * @description NVARCHAR(MAX) - текст опису для параметра

Встановлює опис для параметра процедури або функції через розширені властивості MS_Description.
### Usage

```sql
-- Встановити опис для параметра процедури
EXEC util.metadataSetParameterDescription @major = 'dbo.myProcedure', @parameter = '@inputParam', @description = 'Вхідний параметр для фільтрації';
-- Встановити опис для параметра функції
EXEC util.metadataSetParameterDescription @major = 'dbo.myFunction', @parameter = '@searchValue', @description = 'Значення для пошуку в таблиці';
```

## `metadataSetProcedureDescription`

  * @procedure NVARCHAR(128) - назва процедури
  * @description NVARCHAR(MAX) - текст опису для процедури

Встановлює опис для збереженої процедури через розширені властивості MS_Description.
### Usage

```sql
-- Встановити опис для процедури
EXEC util.metadataSetProcedureDescription @procedure = 'dbo.myProcedure', @description = 'Процедура для обробки користувацьких даних';
-- Встановити опис для системної процедури
EXEC util.metadataSetProcedureDescription @procedure = 'util.errorHandler', @description = 'Універсальний обробник помилок';
```

## `metadataSetSchemaDescription`

  * @schema NVARCHAR(128) - назва схеми
  * @description NVARCHAR(MAX) - текст опису для схеми

Встановлює опис для схеми бази даних через розширені властивості MS_Description.
### Usage

```sql
-- Встановити опис для користувацької схеми
EXEC util.metadataSetSchemaDescription @schema = 'sales', @description = 'Схема даних продажів';
-- Встановити опис для службової схеми
EXEC util.metadataSetSchemaDescription @schema = 'util', @description = 'Схема утилітарних функцій та процедур';
```

## `metadataSetTableDescription`

  * @description NVARCHAR(MAX) - текст опису для таблиці
  * @table NVARCHAR(128) - назва таблиці

Встановлює опис для таблиці через розширені властивості MS_Description.
### Usage

```sql
-- Встановити опис для користувацької таблиці
EXEC util.metadataSetTableDescription @table = 'dbo.Customers', @description = 'Таблиця інформації про клієнтів';
-- Встановити опис для системної таблиці
EXEC util.metadataSetTableDescription @table = 'util.ErrorLog', @description = 'Журнал помилок системи';
```

## `metadataSetTriggerDescription`

  * @trigger NVARCHAR(128) - назва тригера
  * @description NVARCHAR(MAX) - текст опису для тригера

Встановлює опис для тригера через розширені властивості MS_Description.
### Usage

```sql
-- Встановити опис для тригера INSERT
EXEC util.metadataSetTriggerDescription @trigger = 'dbo.tr_Customers_Insert', @description = 'Тригер для логування додавання нових клієнтів';
-- Встановити опис для тригера UPDATE
EXEC util.metadataSetTriggerDescription @trigger = 'dbo.tr_Orders_Update', @description = 'Тригер для перевірки бізнес-правил при оновленні замовлень';
```

## `metadataSetViewDescription`

  * @view NVARCHAR(128) - назва представлення
  * @description NVARCHAR(MAX) - текст опису для представлення

Встановлює опис для представлення (view) через розширені властивості MS_Description.
### Usage

```sql
-- Встановити опис для представлення
EXEC util.metadataSetViewDescription @view = 'dbo.vw_ActiveCustomers', @description = 'Представлення активних клієнтів з основною інформацією';
-- Встановити опис для складного представлення
EXEC util.metadataSetViewDescription @view = 'dbo.vw_SalesReport', @description = 'Звіт продажів з агрегованими даними по періодах';
```

## `modulesSetDescriptionFromComments`

  * @object NVARCHAR(128) - назва або ID об'єкта модуля для обробки

Процедура для автоматичного встановлення описів об'єктів на основі коментарів у коді модулів.
Використовує функцію modulesGetDescriptionFromComments для витягання описів з коментарів
та генерує команди для встановлення розширених властивостей.
### Usage

```sql
-- Встановити опис для конкретного об'єкта
EXEC util.modulesSetDescriptionFromComments 'util.errorHandler'
-- Встановити опис для об'єкта за ID
EXEC util.modulesSetDescriptionFromComments '123456789'
```

## `modulesSetDescriptionFromCommentsLegacy`

  * @object NVARCHAR(128) - назва об'єкта для обробки
  * @OnlyEmpty BIT = 1 - встановлювати описи тільки для об'єктів без існуючих описів (1) або для всіх (0)

Встановлює описи для об'єктів бази даних, витягуючи їх з коментарів у вихідному коді модулів.
Автоматично аналізує коментарі типу "-- Description:" та встановлює відповідні розширені властивості.
### Usage

```sql
-- Встановити описи з коментарів для конкретного об'єкта
EXEC util.modulesSetDescriptionFromComments @object = 'myProcedure', @OnlyEmpty = 1;
-- Оновити описи для всіх об'єктів навіть якщо вони вже існують
EXEC util.modulesSetDescriptionFromComments @object = 'myFunction', @OnляEmpty = 0;
```

## `xeCopyModulesToTable`

  * @scope NVARCHAR(128) - скоуп або тип модулів для копіювання

Процедура для копіювання модулів з Extended Events у таблицю для подальшого аналізу та зберігання.
Читає дані з XE файлів, обробляє їх та записує в таблиці виконання модулів з відповідним скоупом.
### Usage

```sql
-- Копіювати модулі для SSIS
EXEC util.xeCopyModulesToTable 'SSIS';
-- Копіювати модулі для користувачів
EXEC util.xeCopyModulesToTable 'Users'; 
```
# functions
## `indexesGetConventionNames`

  * @object NVARCHAR(128) = NULL - Назва таблиці для генерації назв індексів (NULL = усі таблиці)
  * @index NVARCHAR(128) = NULL - Назва конкретного індексу (NULL = усі індекси)

Генерує стандартизовані назви індексів відповідно до конвенцій найменування.
Функція аналізує існуючі індекси і пропонує нові назви за встановленими стандартами.
### Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- IndexName NVARCHAR(128) - Поточна назва індексу
- NewIndexName NVARCHAR(128) - Рекомендована назва згідно конвенцій
- IndexType NVARCHAR(60) - Тип індексу
### Usage

```sql
-- Отримати рекомендовані назви для всіх індексів конкретної таблиці
SELECT * FROM util.indexesGetConventionNames('myTable', NULL);
-- Отримати рекомендовану назву для конкретного індексу
SELECT * FROM util.indexesGetConventionNames('myTable', 'myIndex');
```

## `indexesGetMissing`

  * @object NVARCHAR(128) = NULL - Назва таблиці для аналізу відсутніх індексів (NULL = усі таблиці)

Знаходить відсутні індекси, які рекомендує SQL Server для покращення продуктивності запитів.
Функція аналізує DMV sys.dm_db_missing_index_* для визначення потенційно корисних індексів.
### Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- MissingIndexId INT - ID відсутнього індексу
- IndexAdvantage FLOAT - Оцінка переваги створення індексу (чим більше, тим краще)
- UserSeeks BIGINT - Кількість пошуків, які б скористалися цим індексом
- UserScans BIGINT - Кількість сканувань, які б скористалися цим індексом
- LastUserSeek DATETIME - Час останнього пошуку
- LastUserScan DATETIME - Час останнього сканування
- AvgTotalUserCost FLOAT - Середня вартість користувацьких запитів
- AvgUserImpact FLOAT - Середній відсоток покращення продуктивності
- SystemSeeks BIGINT - Кількість системних пошуків
- SystemScans BIGINT - Кількість системних сканувань
- EqualityColumns NVARCHAR(4000) - Колонки для умов рівності (WHERE col = value)
- InequalityColumns NVARCHAR(4000) - Колонки для умов нерівності (WHERE col > value)
- IncludedColumns NVARCHAR(4000) - Колонки для включення в індекс (INCLUDE)
- CreateIndexStatement NVARCHAR(MAX) - Готовий DDL для створення індексу
### Usage

```sql
-- Знайти всі відсутні індекси в базі даних
SELECT * FROM util.indexesGetMissing(NULL)
ORDER BY IndexAdvantage DESC;
-- Знайти відсутні індекси для конкретної таблиці
SELECT * FROM util.indexesGetMissing('MyTable')
ORDER BY IndexAdvantage DESC;
-- Топ-10 найбільш корисних відсутніх індексів
SELECT TOP 10 SchemaName, TableName, IndexAdvantage, CreateIndexStatement
FROM util.indexesGetMissing(NULL)
ORDER BY IndexAdvantage DESC;
-- Відсутні індекси з високим впливом на продуктивність
SELECT * FROM util.indexesGetMissing(NULL)
WHERE AvgUserImpact > 80
ORDER BY IndexAdvantage DESC;
```

## `indexesGetScript`

  * @table NVARCHAR(128) = NULL - Назва таблиці для генерації скриптів індексів (NULL = усі таблиці)
  * @index NVARCHAR(128) = NULL - Назва конкретного індексу (NULL = усі індекси)

Генерує DDL скрипти для створення індексів на основі існуючих індексів таблиць.
Функція формує повні CREATE INDEX інструкції включаючи всі налаштування індексу.
### Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- IndexName NVARCHAR(128) - Назва індексу
- CreateScript NVARCHAR(MAX) - DDL скрипт для створення індексу
### Usage

```sql
-- Згенерувати скрипти для всіх індексів конкретної таблиці
SELECT * FROM util.indexesGetScript('myTable', NULL);
-- Згенерувати скрипт для конкретного індексу
SELECT * FROM util.indexesGetScript('myTable', 'myIndex');
```

## `indexesGetScriptConventionRename`

  * @table NVARCHAR(128) = NULL - Назва таблиці для генерації скриптів перейменування (NULL = усі таблиці)
  * @index NVARCHAR(128) = NULL - Назва конкретного індексу (NULL = усі індекси)

Генерує скрипти для перейменування індексів відповідно до стандартних конвенцій найменування.
Функція створює EXEC sp_rename команди для зміни назв індексів на рекомендовані.
### Returns
TABLE - Повертає таблицю з колонками:
- RenameScript NVARCHAR(MAX) - SQL скрипт для перейменування індексу
### Usage

```sql
-- Згенерувати скрипти перейменування для всіх індексів таблиці
SELECT * FROM util.indexesGetScriptConventionRename('myTable', NULL);
-- Згенерувати скрипт перейменування для конкретного індексу
SELECT * FROM util.indexesGetScriptConventionRename('myTable', 'myIndex');
```

## `indexesGetSpaceUsed`

  * @object NVARCHAR(128) = NULL - Назва таблиці або її ID для аналізу індексів (NULL = усі таблиці)

Повертає стислу статистику використання дискового простору індексами таблиці з групуванням по індексах.
Функція використовує util.indexesGetSpaceUsedDetailed та агрегує дані по всіх партиціях кожного індексу.
### Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - ID об'єкта таблиці
- indexId INT - ID індексу
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- IndexName NVARCHAR(128) - Назва індексу
- IndexType NVARCHAR(60) - Тип індексу
- TotalSizeMB BIGINT - Загальний розмір індексу в КБ (сума по всіх партиціях)
- UsedSizeMB BIGINT - Використовуваний розмір в КБ (сума по всіх партиціях)
- UnusedSizeMB BIGINT - Невикористовуваний розмір в КБ (сума по всіх партиціях)
- RowsCount BIGINT - Загальна кількість рядків в індексі (сума по всіх партиціях)
- DataCompression NVARCHAR(60) - Тип стиснення даних
### Usage

```sql
-- Стисла статистика по всіх індексах таблиці
SELECT * FROM util.indexesGetSpaceUsed('MyTable');
-- Знайти найбільші індекси
SELECT * FROM util.indexesGetSpaceUsed('MyTable') 
ORDER BY TotalSizeMB DESC;
-- Порівняти ефективність використання простору
SELECT IndexName, TotalSizeMB, RowsCount, 
       CASE WHEN RowsCount > 0 THEN TotalSizeMB / RowsCount ELSE 0 END AS AvgMBPerRow
FROM util.indexesGetSpaceUsed('MyTable')
ORDER BY AvgMBPerRow DESC;
-- Аналіз всіх індексів у базі даних
SELECT * FROM util.indexesGetSpaceUsed(NULL)
ORDER BY TotalSizeMB DESC;
```

## `indexesGetSpaceUsedDetailed`

  * @object NVARCHAR(128) - Назва таблиці або її ID для аналізу індексів

Повертає детальну статистику використання дискового простору індексами таблиці по партиціях.
Функція показує інформацію для кожної партиції окремо, включаючи дані про партиціонування та стиснення.
### Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- IndexName NVARCHAR(128) - Назва індексу
- IndexType NVARCHAR(60) - Тип індексу
- PartitionNumber INT - Номер партиції
- PartitionFunction NVARCHAR(128) - Функція партиціонування
- BoundaryValue SQL_VARIANT - Граничне значення партиції
- TotalSizeKB BIGINT - Розмір партиції в КБ
- UsedSizeKB BIGINT - Використовуваний розмір в КБ
- UnusedSizeKB BIGINT - Невикористовуваний розмір в КБ
- RowsCount BIGINT - Кількість рядків у партиції
- DataCompression NVARCHAR(60) - Тип стиснення даних
### Usage

```sql
-- Детальна статистика по партиціях всіх індексів таблиці
SELECT * FROM util.indexesGetSpaceUsedDetailed('MyTable');
-- Знайти найбільші партиції
SELECT * FROM util.indexesGetSpaceUsedDetailed('MyTable') 
ORDER BY TotalSizeKB DESC;
-- Аналіз стиснення даних по партиціях
SELECT * FROM util.indexesGetSpaceUsedDetailed('MyTable')
WHERE DataCompression <> 'NONE';
```

## `indexesGetUnused`

  * @object NVARCHAR(128) = NULL - Назва таблиці для аналізу індексів (NULL = усі таблиці)

Знаходить невикористовувані індекси в базі даних на основі статистики використання.
Функція аналізує DMV sys.dm_db_index_usage_stats для визначення індексів, які не використовувались
для операцій читання (seeks, scans, lookups) або використовувались тільки для операцій запису.
### Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- IndexName NVARCHAR(128) - Назва індексу
- IndexType NVARCHAR(60) - Тип індексу
- UserSeeks BIGINT - Кількість пошуків користувачами
- UserScans BIGINT - Кількість сканувань користувачами
- UserLookups BIGINT - Кількість пошуків ключів користувачами
- UserUpdates BIGINT - Кількість оновлень користувачами
- LastUserSeek DATETIME - Час останнього пошуку
- LastUserScan DATETIME - Час останнього сканування
- LastUserLookup DATETIME - Час останнього пошуку ключа
- LastUserUpdate DATETIME - Час останнього оновлення
- UnusedReason NVARCHAR(200) - Причина віднесення до невикористовуваних
### Usage

```sql
-- Знайти всі невикористовувані індекси в базі даних
SELECT * FROM util.indexesGetUnused(NULL);
-- Знайти невикористовувані індекси конкретної таблиці
SELECT * FROM util.indexesGetUnused('myTable');
-- Знайти індекси з тільки операціями запису
SELECT * FROM util.indexesGetUnused(NULL) WHERE UnusedReason LIKE '%тільки запис%';
```

## `metadataGetAnyId`

  * @object NVARCHAR(128) - назва об'єкта
  * @class NVARCHAR(128) = 1 - клас об'єкта (число або текстова назва класу)
  * @minorName NVARCHAR(128) = NULL - додаткова назва для складних об'єктів (наприклад, колонка або індекс)

Універсальна функція для отримання ID будь-якого об'єкта бази даних залежно від його класу. 
Підтримує різні типи об'єктів: таблиці, колонки, індекси, схеми, користувачів, файли та інші.
### Returns
INT - ідентифікатор об'єкта відповідного типу або NULL якщо об'єкт не знайдено
### Usage

```sql
-- Отримати object_id таблиці
SELECT util.metadataGetAnyId('dbo.MyTable', 'OBJECT');
-- Отримати column_id колонки
SELECT util.metadataGetAnyId('dbo.MyTable', 'OBJECT', 'MyColumn');
```

## `metadataGetAnyName`

  * @majorId INT - основний ідентифікатор об'єкта
  * @minorId INT = 0 - додатковий ідентифікатор (для колонок, індексів, параметрів)
  * @class NVARCHAR(128) = '1' - клас об'єкта (число або текстова назва)

Універсальна функція для отримання імені будь-якого об'єкта бази даних за його ID та класом.
Дозволяє отримувати імена для різних типів об'єктів залежно від їх класу.
### Returns
NVARCHAR(128) - ім'я відповідного об'єкта
### Usage

```sql
-- Отримати ім'я таблиці за object_id
SELECT util.metadataGetAnyName(OBJECT_ID('dbo.MyTable'), 0, '1');
-- Отримати ім'я колонки
SELECT util.metadataGetAnyName(OBJECT_ID('dbo.MyTable'), 1, '1');
```

## `metadataGetCertificateName`

  * @majorId INT - ідентифікатор сертифіката (certificate_id)

Отримує ім'я сертифіката за його ідентифікатором з системного каталогу.
### Returns
NVARCHAR(128) - ім'я сертифіката в квадратних дужках або NULL якщо не знайдено
### Usage

```sql
-- Отримати ім'я сертифіката за ID
SELECT util.metadataGetCertificateName(1);
```

## `metadataGetClassByName`

  * @className NVARCHAR(128) - текстова назва класу об'єкта

Повертає числовий код класу об'єкта за його текстовою назвою.
Використовується для перетворення людських назв класів в системні коди.
### Returns
TINYINT - числовий код класу (0-База даних, 1-Об'єкт/Колонка, 2-Параметр, тощо) або NULL для невідомого класу
### Usage

```sql
-- Отримати код класу за назвою
SELECT util.metadataGetClassByName('OBJECT_OR_COLUMN');
SELECT util.metadataGetClassByName('INDEX');
```

## `metadataGetClassName`

  * @class TINYINT - числовий код класу об'єкта

Повертає текстову назву класу об'єкта за його числовим кодом.
Зворотна функція до metadataGetClassByName.
### Returns
NVARCHAR(128) - текстова назва класу або NULL для невідомого коду
### Usage

```sql
-- Отримати назву класу за кодом
SELECT util.metadataGetClassName(1); -- OBJECT_OR_COLUMN
SELECT util.metadataGetClassName(3); -- SCHEMA
```

## `metadataGetColumnId`

  * @major NVARCHAR(128) - назва об'єкта (таблиця/представлення) або object_id
  * @column NVARCHAR(128) - назва стовпця для якого шукати ідентифікатор

Отримує column_id для заданого стовпця в таблиці або представленні. 
Підтримує передачу як назви об'єкта, так і числового ідентифікатора таблиці.
### Returns
INT - ідентифікатор стовпця (column_id) або NULL якщо стовпець не знайдено
### Usage

```sql
SELECT util.metadataGetColumnId('dbo.MyTable', 'MyColumn');
-- Отримати column_id для стовпця MyColumn в таблиці dbo.MyTable
```

## `metadataGetColumnName`

  * @major NVARCHAR(128) - назва таблиці або object_id
  * @columnId INT - ідентифікатор стовпця (column_id)

Отримує ім'я стовпця за ідентифікатором таблиці та ідентифікатором стовпця.
### Returns
NVARCHAR(128) - ім'я стовпця в квадратних дужках або NULL якщо не знайдено
### Usage

```sql
SELECT util.metadataGetColumnName('dbo.MyTable', 1);
-- Отримати ім'я стовпця за його column_id
```

## `metadataGetColumns`

  * @object NVARCHAR(128) = NULL - назва об'єкта або NULL для всіх таблиць

Отримує детальну інформацію про всі стовпці таблиці або представлення.
### Returns
Таблиця з колонками: column_id, name, system_type_name, max_length, precision, scale, is_nullable, is_identity
### Usage

```sql
SELECT * FROM util.metadataGetColumns('dbo.MyTable');
-- Отримати інформацію про всі стовпці таблиці
```

## `metadataGetDataspaceId`

  * @dataSpace NVARCHAR(128) - назва простору даних

Отримує ідентифікатор простору даних (data space) за його назвою.
Підтримує файлові групи та схеми розділення.
### Returns
INT - ідентифікатор простору даних або NULL якщо не знайдено
### Usage

```sql
-- Отримати ID файлової групи
SELECT util.metadataGetDataspaceId('PRIMARY');
-- Отримати ID схеми розділення
SELECT util.metadataGetDataspaceId('MyPartitionScheme');
```

## `metadataGetDataspaceName`

  * @dataSpaceId INT - ідентифікатор простору даних

Отримує назву простору даних (data space) за його ідентифікатором.
Повертає назву в квадратних дужках для безпечного використання в SQL.
### Returns
NVARCHAR(128) - назва простору даних в квадратних дужках або NULL якщо не знайдено
### Usage

```sql
-- Отримати назву файлової групи за ID
SELECT util.metadataGetDataspaceName(1);
-- Отримати назву схеми розділення за ID
SELECT util.metadataGetDataspaceName(65537);
```

## `metadataGetDescriptions`

  * @major NVARCHAR(128) - основний об'єкт для пошуку описів
  * @minor NVARCHAR(128) - додатковий об'єкт (колонка, параметр тощо)

Отримує описи (extended properties) для об'єктів бази даних за заданими критеріями.
Працює з розширеними властивостями типу MS_Description.
### Returns
TABLE - Повертає таблицю з колонками:
- majorId INT - ідентифікатор основного об'єкта
- minorId INT - ідентифікатор додаткового об'єкта
- class TINYINT - клас об'єкта
- description NVARCHAR(MAX) - текст опису
### Usage

```sql
-- Отримати описи для конкретної таблиці та її колонок
SELECT * FROM util.metadataGetDescriptions('myTable', 'myColumn');
```

## `metadataGetExtendedProperiesValues`

  * @major NVARCHAR(128) = NULL - основний об'єкт для пошуку (NULL = всі)
  * @minor NVARCHAR(128) = NULL - додатковий об'єкт (NULL = всі)
  * @property NVARCHAR(128) = NULL - назва властивості (NULL = всі властивості)

Отримує значення розширених властивостей (extended properties) для об'єктів бази даних.
Дозволяє фільтрувати по об'єктах та типах властивостей.
### Returns
TABLE - Повертає таблицю з колонками:
- majorName NVARCHAR(128) - назва основного об'єкта
- minorName NVARCHAR(128) - назва додаткового об'єкта
- propertyName NVARCHAR(128) - назва властивості
- propertyValue NVARCHAR(MAX) - значення властивості
- class TINYINT - клас об'єкта
### Usage

```sql
-- Отримати всі розширені властивості для таблиці
SELECT * FROM util.metadataGetExtendedProperiesValues('myTable', NULL, NULL);
-- Отримати значення конкретної властивості
SELECT * FROM util.metadataGetExtendedProperiesValues('myTable', 'myColumn', 'MS_Description');
```

## `metadataGetIndexes`

  * @object NVARCHAR(128) = NULL - назва таблиці для отримання індексів (NULL = всі таблиці)

Отримує детальну інформацію про індекси для заданих таблиць.
Включає основні характеристики індексів та їх стан.
### Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор таблиці
- index_id INT - ідентифікатор індексу
- name NVARCHAR(128) - назва індексу
- type_desc NVARCHAR(60) - тип індексу
- is_unique BIT - чи унікальний індекс
- is_primary_key BIT - чи первинний ключ
### Usage

```sql
-- Отримати всі індекси конкретної таблиці
SELECT * FROM util.metadataGetIndexes('myTable');
-- Отримати індекси всіх таблиць
SELECT * FROM util.metadataGetIndexes(NULL);
```

## `metadataGetIndexId`

  * @object NVARCHAR(128) - назва таблиці або object_id
  * @indexName NVARCHAR(128) - назва індексу

Отримує ідентифікатор індексу за назвою табліці та назвою індексу.
### Returns
INT - ідентифікатор індексу або NULL якщо не знайдено
### Usage

```sql
-- Отримати ID індексу за назвами
SELECT util.metadataGetIndexId('myTable', 'IX_myTable_Column1');
-- Використовуючи object_id таблиці
SELECT util.metadataGetIndexId('1234567890', 'IX_myTable_Column1');
```

## `metadataGetIndexName`

  * @major NVARCHAR(128) - назва таблиці або object_id
  * @indexId INT - ідентифікатор індексу

Отримує назву індексу за ідентифікатором таблиці та ідентифікатором індексу.
### Returns
NVARCHAR(128) - повна назва індексу у форматі "схема.таблиця (індекс)" або NULL якщо не знайдено
### Usage

```sql
-- Отримати назву індексу за ID
SELECT util.metadataGetIndexName('myTable', 2);
-- Використовуючи object_id таблиці
SELECT util.metadataGetIndexName('1234567890', 2);
```

## `metadataGetObjectName`

  * @majorId INT - ідентифікатор об'єкта (object_id)

Отримує повну назву об'єкта бази даних за його ідентифікатором.
Повертає назву у форматі "схема.об'єкт" в квадратних дужках.
### Returns
NVARCHAR(128) - повну назву об'єкта у форматі "[схема].[об'єкт]" або NULL якщо не знайдено
### Usage

```sql
-- Отримати назву об'єкта за його ID
SELECT util.metadataGetObjectName(OBJECT_ID('dbo.myTable'));
-- Використовуючи числовий ID
SELECT util.metadataGetObjectName(1234567890);
```

## `metadataGetObjectsType`

  * @object NVARCHAR(128) = NULL - назва об'єкта або список назв через кому (NULL = всі об'єкти)

Отримує інформацію про тип об'єктів бази даних з можливістю фільтрації.
Підтримує як окремі об'єкти, так і список через кому.
### Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - ідентифікатор об'єкта
- objectName NVARCHAR(128) - назва об'єкта
- objectType NVARCHAR(60) - тип об'єкта
### Usage

```sql
-- Отримати тип конкретного об'єкта
SELECT * FROM util.metadataGetObjectsType('myTable');
-- Отримати типи кількох об'єктів
SELECT * FROM util.metadataGetObjectsType('myTable,myView,myProcedure');
```

## `metadataGetObjectType`

  * @object NVARCHAR(128) - назва об'єкта бази даних

Отримує тип об'єкта бази даних за його назвою.
Спрощена версія metadataGetObjectsType для отримання одного значення.
### Returns
NVARCHAR(60) - тип об'єкта (наприклад, 'U' для таблиці, 'P' для процедури, 'FN' для функції)
### Usage

```sql
-- Отримати тип об'єкта
SELECT util.metadataGetObjectType('myTable');
-- Перевірити чи є об'єкт таблицею
SELECT CASE WHEN util.metadataGetObjectType('myTable') = 'U' THEN 'Table' ELSE 'Not Table' END;
```

## `metadataGetParameterId`

  * @object NVARCHAR(128) - назва або ID об'єкта бази даних
  * @parameterName NVARCHAR(128) - назва параметра

Отримує ідентифікатор параметра для вказаного об'єкта бази даних.
### Returns
INT - ідентифікатор параметра або NULL якщо параметр не знайдено
### Usage

```sql
-- Отримати ID параметра процедури
SELECT util.metadataGetParameterId('myProcedure', '@param1');
-- Використовуючи object_id
SELECT util.metadataGetParameterId('1234567890', '@param1');
```

## `metadataGetParameters`

  * @object NVARCHAR(128) = NULL - Назва об'єкта або object_id для отримання параметрів (NULL = всі об'єкти)

Повертає детальну інформацію про параметри для вказаної збереженої процедури або функції, 
включаючи назви параметрів, типи даних, напрямки та значення за замовчуванням. 
Виключає системні параметри без імені.
### Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - Ідентифікатор об'єкта
- schemaName NVARCHAR(128) - Назва схеми
- objectName NVARCHAR(128) - Назва об'єкта
- parameterId INT - Ідентифікатор параметра
- parameterName NVARCHAR(128) - Назва параметра
### Usage

```sql
-- Отримати параметри конкретної процедури
SELECT * FROM util.metadataGetParameters('util.errorHandler');
-- Отримати параметри всіх об'єктів
SELECT * FROM util.metadataGetParameters(DEFAULT);
```

## `metadataGetPartitionFunctionId`

  * @function NVARCHAR(128) - назва функції розділення

Отримує ідентифікатор функції розділення за її назвою.
### Returns
INT - ідентифікатор функції розділення або NULL якщо не знайдено
### Usage

```sql
-- Отримати ID функції розділення
SELECT util.metadataGetPartitionFunctionId('myPartitionFunction');
```

## `metadataGetPartitionFunctionName`

  * @functionId INT - ідентифікатор функції розділення

Отримує назву функції розділення за її ідентифікатором.
### Returns
NVARCHAR(128) - назва функції розділення в квадратних дужках або NULL якщо не знайдено
### Usage

```sql
-- Отримати назву функції розділення за ID
SELECT util.metadataGetPartitionFunctionName(1);
```

## `metadataGetRequiredPermission`

  * @object NVARCHAR(128) - повне ім'я об'єкта у форматі [схема].[ім'я] або просто ім'я

Визначає об'єкти, для яких потрібні додаткові права при виконанні заданого об'єкта (процедури, функції).
Аналізує залежності через sys.sql_expression_dependencies та виявляє:
1. Об'єкти з інших баз даних (завжди потребують прав)
2. Об'єкти з різними власниками схем (можуть потребувати додаткових прав)
### Returns
TABLE - Повертає таблицю з колонками:
- ObjectName NVARCHAR(MAX) - повне ім'я об'єкта, який потребує додаткових прав
- PermissionReason NVARCHAR(200) - причина, чому потрібні додаткові права
- DatabaseName NVARCHAR(128) - назва бази даних об'єкта
- SchemaName NVARCHAR(128) - назва схеми об'єкта
- EntityName NVARCHAR(128) - назва об'єкта
- SchemaOwner NVARCHAR(128) - власник схеми об'єкта
### Usage

```sql
-- Перевірити права для конкретної процедури
SELECT * FROM util.metadataGetRequiredPermission('util.myselfGetHistory');
-- Аналіз прав для процедури з повним іменем
SELECT * FROM util.metadataGetRequiredPermission('[util].[errorHandler]');
-- Групування по причинах
SELECT PermissionReason, COUNT(*) AS ObjectCount
FROM util.metadataGetRequiredPermission('util.myselfGetHistory')
GROUP BY PermissionReason;
```

## `modulesFindCommentsPositions`

  * @objectId INT = NULL - ідентифікатор об'єкта для пошуку коментарів (NULL = усі об'єкти)

Знаходить позиції всіх коментарів (багаторядкових та однорядкових) у модулях бази даних.
Об'єднує результати з функцій пошуку багаторядкових та однорядкових коментарів.
### Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку коментаря
- endPosition INT - позиція кінця коментаря
### Usage

```sql
-- Знайти всі коментарі в конкретному об'єкті
SELECT * FROM util.modulesFindCommentsPositions(OBJECT_ID('myProc'));
-- Знайти всі коментарі в усіх об'єктах
SELECT * FROM util.modulesFindCommentsPositions(NULL);
```

## `modulesFindInlineCommentsPositions`

  * @objectId INT = NULL - ідентифікатор об'єкта для пошуку коментарів (NULL = усі об'єкти)

Знаходить позиції однорядкових коментарів (що починаються з '--') у модулях бази даних.
### Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку коментаря
- endPosition INT - позиція кінця коментаря
### Usage

```sql
-- Знайти однорядкові коментарі в конкретному об'єкті
SELECT * FROM util.modulesFindInlineCommentsPositions(OBJECT_ID('myProc'));
```

## `modulesFindLinesPositions`

  * @objectId INT = NULL - ідентифікатор об'єкта для пошуку рядків (NULL = усі об'єкти)

Знаходить позиції всіх рядків у модулях бази даних, включаючи перший рядок.
Нумерує рядки та визначає їх початкові та кінцеві позиції.
### Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку рядка
- endPosition INT - позиція кінця рядка
- lineNumber INT - номер рядка
### Usage

```sql
-- Знайти всі рядки в конкретному об'єкті
SELECT * FROM util.modulesFindLinesPositions(OBJECT_ID('myProc'));
```

## `modulesFindMultilineCommentsPositions`
Знаходить позиції багаторядкових коментарів ( ... 
## `modulesFindSimilar`

  * @objectId INT = NULL - ідентифікатор об'єкта для порівняння

Знаходить схожі SQL модулі в базі даних на основі аналізу їх коду.
Використовує алгоритм нормалізації тексту, токенізації та хешування для порівняння подібності між модулями.
### Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - ідентифікатор оригінального об'єкта
- similarObjectId INT - ідентифікатор схожого об'єкта  
- similarityPercent FLOAT - відсоток схожості між об'єктами
### Usage

```sql
SELECT * FROM util.modulesFindSimilar(NULL);
-- Знайти всі схожі модулі в базі даних
```

## `modulesGetCreateLineNumber`

  * @objectId INT = NULL - ідентифікатор об'єкта модуля (функція, процедура, тригер)

Повертає номер рядка, де знаходиться оператор CREATE для заданого об'єкта модуля.
Функція аналізує текст модуля та знаходить перший рядок що починається з "CREATE".
### Returns
TABLE:
- objectId INT - ідентифікатор об'єкта
- lineNumber INT - номер рядка з оператором CREATE
### Usage

```sql
-- Знайти номер рядка з CREATE для всіх об'єктів
SELECT * FROM util.modulesGetCreateLineNumber(DEFAULT)
-- Знайти номер рядка з CREATE для конкретного об'єкта
SELECT * FROM util.modulesGetCreateLineNumber(OBJECT_ID('util.errorHandler'))
```

## `modulesGetDescriptionFromComments`

  * @objectId INT = NULL - ідентифікатор об'єкта модуля (NULL для всіх об'єктів)

Витягує опис з коментарів модулів (функцій, процедур, тригерів) та форматує його для встановлення 
як розширену властивість. Функція аналізує багаторядкові коментарі що знаходяться перед оператором CREATE
та витягує з них структурований опис.
### Returns
TABLE:
- objectId INT - ідентифікатор об'єкта
- objectType NVARCHAR(128) - тип об'єкта (FUNCTION, PROCEDURE, TRIGGER)
- minor INT - мінорний ідентифікатор (завжди 0 для модулів)
- description NVARCHAR(MAX) - відформатований опис з коментарів
### Usage

```sql
-- Отримати опис для всіх модулів
SELECT * FROM util.modulesGetDescriptionFromComments(DEFAULT)
-- Отримати опис для конкретного модуля
SELECT * FROM util.modulesGetDescriptionFromComments(OBJECT_ID('util.errorHandler'))
```

## `modulesGetDescriptionFromCommentsLegacy`

  * @object NVARCHAR(128) = NULL - назва об'єкта для пошуку описів (NULL = усі об'єкти)

Витягує описи об'єктів з коментарів у вихідному коді модулів, шукаючи рядки що починаються з '-- Description:'.
### Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - ідентифікатор об'єкта
- schemaName NVARCHAR(128) - назва схеми
- objectName NVARCHAR(128) - назва об'єкта
- description NVARCHAR(MAX) - витягнутий опис з коментарів
### Usage

```sql
-- Витягти описи з коментарів для конкретного об'єкта
SELECT * FROM util.modulesGetDescriptionFromComments('myProc');
-- Витягти описи для всіх об'єктів
SELECT * FROM util.modulesGetDescriptionFromComments(NULL);
```

## `modulesRecureSearchForOccurrences`

  * @searchFor NVARCHAR(64) - рядок для пошуку в тексті визначень модулів
  * @options TINYINT - бітові опції пошуку: (2): пропускати входження перед '.' або '].',  (4): шукати тільки цілі слова (не частини слів), (8): пропускати входження в quoted names ([...])

Рекурсивно шукає всі входження заданого рядка у визначеннях модулів бази даних (stored procedures, functions, views, triggers).
Використовує CTE для знаходження всіх позицій входження з можливістю фільтрації за опціями.
### Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта модуля (sys.objects.object_id)
- occurrencePosition INT - позиція входження в тексті визначення (1-based)
## `modulesRecureSearchStartEndPositions`

  * @startValue NVARCHAR(32) - початкове значення для пошуку
  * @endValue NVARCHAR(32) - кінцеве значення для пошуку

Рекурсивно шукає позиції початку та кінця блоків у модулях за заданими початковим та кінцевим значеннями.
Спрощена версія функції modulesRecureSearchStartEndPositionsExtended.
### Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку блоку
- endPosition INT - позиція кінця блоку
### Usage

```sql
-- Знайти блоки BEGIN...END
SELECT * FROM util.modulesRecureSearchStartEndPositions('BEGIN', 'END');
-- Знайти блоки IF...END IF  
SELECT * FROM util.modulesRecureSearchStartEndPositions('IF', 'END IF');
```

## `modulesRecureSearchStartEndPositionsExtended`

  * @startValue NVARCHAR(32) - початкове значення для пошуку
  * @endValue NVARCHAR(32) - кінцеве значення для пошуку
  * @replaceCRwithLF BIT = 0 - замінити CR на LF (1) або залишити як є (0)
  * @objectID INT = NULL - ідентифікатор конкретного об'єкта (NULL = усі об'єкти)

Розширена функція рекурсивного пошуку позицій початку та кінця блоків у модулях з додатковими опціями.
Підтримує обробку символів переносу рядків та фільтрацію по конкретних об'єктах.
### Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку блоку
- endPosition INT - позиція кінця блоку
### Usage

```sql
-- Знайти коментарі з нормалізацією переносів рядків
SELECT * FROM util.modulesRecureSearchStartEndPositionsExtended('', '
```

## `modulesSplitToLines`

  * @object NVARCHAR(128) - назва або ID об'єкта для розбиття на рядки (NULL = усі об'єкти)
  * @skipEmpty BIT = 1 - пропускати порожні рядки (1 = так, 0 = включати порожні рядки)

Розбиває визначення модулів (процедур, функцій, тригерів) на окремі рядки з нумерацією для подальшого аналізу.
Функція обробляє текст з sys.sql_modules, замінює табуляції на пробіли та може пропускати порожні рядки.
### Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - ідентифікатор об'єкта модуля
- line NVARCHAR(MAX) - текст рядка (з обрізаними пробілами та заміненими табуляціями)
- lineNumber INT - номер рядка в модулі (порядковий номер)
### Usage

```sql
-- Розбити конкретний модуль на рядки (без порожніх)
SELECT * FROM util.modulesSplitToLines('util.errorHandler', 1);
-- Розбити модуль включаючи порожні рядки
SELECT * FROM util.modulesSplitToLines('util.errorHandler', 0);
-- Розбити всі модулі в базі даних
SELECT * FROM util.modulesSplitToLines(NULL, 1);
-- Знайти рядки з CREATE в модулі
SELECT * FROM util.modulesSplitToLines('util.errorHandler', 1)
WHERE line LIKE 'CREATE%';
```

## `myselfActiveIndexCreation`
Відстежує прогрес активного створення індексів поточним користувачем.
Функція моніторить операції CREATE INDEX та показує детальну інформацію про їх виконання в реальному часі.
### Returns
TABLE - Повертає таблицю з колонками:
- sessionId INT - Ідентифікатор сесії
- pysicalOperatorName NVARCHAR - Назва фізичного оператора
- CurrentStep NVARCHAR - Поточний крок виконання
- TotalRows BIGINT - Загальна кількість рядків для обробки
- RowsProcessed BIGINT - Кількість оброблених рядків
- RowsLeft BIGINT - Кількість рядків що залишились
- ElapsedSeconds DECIMAL - Час виконання в секундах
- currentStatement NVARCHAR - Поточна T-SQL команда CREATE INDEX
### Usage

```sql
-- Відстежити прогрес всіх активних операцій створення індексів
SELECT * FROM util.myselfActiveIndexCreation();
```

## `stringFindCommentsPositions`
Знаходить позиції всіх коментарів (багаторядкових та однорядкових) у переданому тексті.
Об'єднує результати пошуку багаторядкових коментарів  
## `stringFindInlineCommentsPositions`

  * @string NVARCHAR(MAX) - текст для аналізу коментарів
  * @replaceCRwithLF BIT = 1 - замінювати CR на LF для нормалізації переносів рядків

Знаходить позиції однорядкових коментарів (що починаються з '--') у переданому тексті.
### Returns
TABLE - Повертає таблицю з колонками:
- startPosition INT - позиція початку коментаря
- endPosition INT - позиція кінця коментаря
## `stringFindLinesPositions`

  * @string NVARCHAR(MAX) - текст для аналізу позицій рядків
  * @replaceCRwithLF BIT = 1 - замінювати CR на LF для нормалізації переносів рядків

Знаходить позиції всіх рядків у переданому тексті, включаючи перший рядок.
Нумерує рядки та визначає їх початкові та кінцеві позиції.
### Returns
TABLE - Повертає таблицю з колонками:
- startPosition INT - позиція початку рядка
- endPosition INT - позиція кінця рядка
- lineNumber INT - номер рядка
## `stringFindMultilineCommentsPositions`
Знаходить позиції багаторядкових коментарів ( ... 
## `stringGetCreateLineNumber`

  * @string NVARCHAR(MAX) - текст для аналізу (SQL скрипт або код)
  * @skipEmpty BIT = 1 - пропускати порожні рядки при нумерації (1 = пропускати, 0 = не пропускати)

Знаходить номер рядка де розташована перша інструкція CREATE у переданому тексті.
Функція корисна для аналізу SQL скриптів та визначення початку створення об'єктів.
### Returns
TABLE - Повертає таблицю з колонкою:
- lineNumber INT - номер рядка де знайдена перша інструкція CREATE
### Usage

```sql
-- Знайти рядок з CREATE в SQL коді
DECLARE @sql NVARCHAR(MAX) = 'GO
-- Коментар
CREATE OR ALTER PROCEDURE dbo.Test
AS BEGIN
  SELECT 1
END'
SELECT * FROM util.stringGetCreateLineNumber(@sql, 1);
-- Результат: lineNumber = 3 (якщо пропускаємо порожні рядки)
```

## `stringGetCreateTempScript`

  * @query NVARCHAR(MAX) - SQL запит для аналізу структури результуючого набору
  * @tablename NVARCHAR(128) = NULL - ім'я створюваної таблиці (default: #temp)  
  * @params NVARCHAR(MAX) = NULL - декларація параметрів запиту у форматі sp_executesql

Scalar функція-обгортка для генерації DDL скрипту на основі аналізу SQL запиту.
Викликає inline функцію util.stringGetCreateTempScriptInline і повертає результат як скалярне значення.
Підтримує параметризовані запити через декларацію @params.
### Returns
NVARCHAR(MAX) - готовий до виконання CREATE TABLE скрипт
### Usage

```sql
SELECT util.stringGetCreateTempScript('SELECT * FROM util.indexesGetMissing(DEFAULT)',DEFAULT,DEFAULT)
```

## `stringGetCreateTempScriptInline`

  * @query NVARCHAR(MAX) - SQL запит для аналізу структури результуючого набору
  * @tablename NVARCHAR(128) = NULL - назва створюваної тимчасової таблиці (default: #temp)
  * @params NVARCHAR(MAX) = NULL - рядок декларації параметрів у форматі sp_executesql

Inline table-valued функція для аналізу SQL запиту та генерації відповідного CREATE TABLE DDL.
Використовує sys.dm_exec_describe_first_result_set з підтримкою параметризованих запитів.
Автоматично визначає типи даних, nullable constraints та форматує результуючий скрипт.
### Returns
TABLE - табличний результат з єдиною колонкою:
- createScript NVARCHAR(MAX) - форматований CREATE TABLE скрипт з переносами рядків
### Usage

```sql
SELECT * FROM util.stringGetCreateTempScriptInline('SELECT * FROM util.indexesGetMissing(DEFAULT)',DEFAULT,DEFAULT)
```

## `stringRecureSearchForOccurrences`

  * @string NVARCHAR(MAX) - текст для пошуку входжень
  * @searchFor NVARCHAR(64) - рядок для пошуку в тексті
  * @options TINYINT - бітові опції пошуку: (2): пропускати входження перед '.' або '].',  (4): шукати тільки цілі слова (не частини слів), (8): пропускати входження в quoted names ([...])

Рекурсивно шукає всі входження заданого рядка у переданому тексті.
Використовує CTE для знаходження всіх позицій входження з можливістю фільтрації за опціями.
### Returns
TABLE - Повертає таблицю з колонками:
- occurrencePosition INT - позиція входження в тексті (1-based)
## `stringRecureSearchStartEndPositionsExtended`

  * @string NVARCHAR(MAX) - текстовий рядок для пошуку
  * @startValue NVARCHAR(32) - початкове значення для пошуку
  * @endValue NVARCHAR(32) - кінцеве значення для пошуку
  * @replaceCRwithLF BIT = 0 - замінити CR на LF (1) або залишити як є (0)

Розширена функція рекурсивного пошуку позицій початку та кінця блоків у текстовому рядку з додатковими опціями.
Підтримує обробку символів переносу рядків для довільного тексту.
## `stringSplitMultiLineComment`

  * @string NVARCHAR(MAX) - Багаторядковий коментар для розбору

Розбирає багаторядковий коментар і повертає структуровану інформацію по секціях.
Функція аналізує коментарі за стандартним форматом документації та виділяє основні секції.
### Returns
TABLE - Повертає таблицю з колонками:
- description NVARCHAR(MAX) - Весь рядок для параметра або опису
- minor NVARCHAR(128) - NULL для загального опису, перше слово для # Parameters/# Columns
- returns NVARCHAR(MAX) - NULL для процедур, опис повернення для функцій
- usage NVARCHAR(MAX) - Приклади використання
### Usage

```sql
-- Розібрати коментар функції
SELECT * FROM util.stringMultiLineComment(@commentString);
-- Отримати тільки опис параметрів
SELECT * FROM util.stringMultiLineComment(@commentString) WHERE minor IS NOT NULL;
```

## `stringSplitToLines`

  * @string NVARCHAR(MAX) - текстовий рядок для розбиття на рядки
  * @skipEmpty BIT = 1 - пропускати порожні рядки (1 = так, 0 = включати порожні рядки)

Розбиває текстовий рядок на окремі рядки з нумерацією для подальшого аналізу.
Функція обробляє будь-який текст, замінює табуляції на пробіли та може пропускати порожні рядки.
### Returns
TABLE - Повертає таблицю з колонками:
- line NVARCHAR(MAX) - текст рядка (з обрізаними пробілами та заміненими табуляціями)
- lineNumber INT - номер рядка (порядковий номер)
## `tablesGetIndexedColumns`

  * @object NVARCHAR(128) = NULL - назва таблиці для аналізу індексованих колонок (NULL = усі таблиці)

Повертає інформацію про індексовані колонки таблиць, показуючи які колонки є першими в індексах.
Функція аналізує всі індекси та показує колонки, які є першими (key_ordinal = 1) в кожному індексі.
### Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - назва схеми
- TableName NVARCHAR(128) - назва таблиці
- ColumnName NVARCHAR(128) - назва колонки
- IndexName NVARCHAR(128) - назва індексу
- IndexType NVARCHAR(60) - тип індексу
- IsUnique BIT - чи є індекс унікальним
- IsPrimaryKey BIT - чи є індекс первинним ключем
- IsUniqueConstraint BIT - чи є індекс унікальним обмеженням
- KeyOrdinal TINYINT - позиція колонки в ключі індексу
- PartitionOrdinal TINYINT - позиція колонки в схемі партиціонування
- IsIncludedColumn BIT - чи є колонка включеною (INCLUDE)
### Usage

```sql
-- Показати всі індексовані колонки в базі даних
SELECT * FROM util.tablesGetIndexedColumns(NULL)
ORDER BY SchemaName, TableName, ColumnName;
-- Показати індексовані колонки конкретної таблиці
SELECT * FROM util.tablesGetIndexedColumns('MyTable')
ORDER BY ColumnName;
-- Знайти колонки, які є першими в індексах
SELECT DISTINCT SchemaName, TableName, ColumnName
FROM util.tablesGetIndexedColumns(NULL)
WHERE KeyOrdinal = 1
ORDER BY SchemaName, TableName, ColumnName;
-- Аналіз покриття колонок індексами
SELECT SchemaName, TableName, ColumnName, COUNT(*) AS IndexCount
FROM util.tablesGetIndexedColumns('MyTable')
GROUP BY SchemaName, TableName, ColumnName
ORDER BY IndexCount DESC;
```

## `tablesGetScript`

  * @table NVARCHAR(128) = NULL - назва таблиці для генерації скрипта (NULL = усі таблиці)

Генерує повний DDL скрипт для створення таблиці, включаючи колонки, типи даних, обмеження та індекси.
### Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - назва схеми
- TableName NVARCHAR(128) - назва таблиці
- CreateScript NVARCHAR(MAX) - повний DDL скрипт для створення таблиці
### Usage

```sql
-- Згенерувати скрипт для конкретної таблиці
SELECT * FROM util.tablesGetScript('myTable');
-- Згенерувати скрипти для всіх таблиць
SELECT * FROM util.tablesGetScript(NULL);
```

## `xeGetErrors`

  * @minEventTime DATETIME2(7) - мінімальний час події для фільтрації (NULL = всі події)

Таблично-значуща функція для отримання даних про помилки з Extended Events.
Читає дані з системних сесій XE та повертає їх у структурованому вигляді для аналізу.
### Returns
TABLE - Повертає таблицю з колонками:
- EventTime DATETIME2(7) - час події
- ErrorNumber INT - номер помилки
- Severity INT - рівень серйозності
- State INT - стан помилки
- Message NVARCHAR(4000) - текст повідомлення про помилку
- DatabaseName NVARCHAR(128) - назва бази даних
- ClientHostname NVARCHAR(128) - ім'я хоста клієнта
- ClientAppName NVARCHAR(128) - назва додатку клієнта
- ServerPrincipalName NVARCHAR(128) - ім'я принципала сервера
- SqlText NVARCHAR(MAX) - SQL текст
- TsqlFrame NVARCHAR(MAX) - T-SQL фрейм
- TsqlStack NVARCHAR(MAX) - T-SQL стек
- FileName NVARCHAR(260) - ім'я файлу XE
- FileOffset BIGINT - зміщення у файлі
## `xeGetLogsPath`

  * @sessionName NVARCHAR(128) = NULL - назва XE сесії (частина 'utils' буде видалена з назви)

Формує шлях до директорії логів Extended Events на основі розташування SQL Server error log.
Функція створює стандартизований шлях для збереження файлів XE сесій у підпапці util.
### Returns
NVARCHAR(260) - повний шлях до директорії логів для відповідної сесії
### Usage

```sql
-- Отримати базовий шлях до логів
SELECT util.xeGetLogsPath(NULL);
-- Отримати шлях для конкретної сесії
SELECT util.xeGetLogsPath('utilsErrors');
-- Результат буде наприклад: C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Log\util\Errors```
 
# pure-utiles

```sql
util.help
GO
--OR
util.help keyword
```

## Ключові можливості
### Error
* обробка помилок - [errorHandler](#errorhandler)
* відстеження помилок засобами SQL Server eXtended Events - [xeGetErrors](#xegeterrors)

### MS_Description
* автоматичне заповнення `MS_Description`, і тому числі для параметрів і колонок, з багаторядкового коментаря - [modulesSetDescriptionFromComments](#modulessetdescriptionfromcomments)
* автоматичне заповнення `MS_Description`, для старих процедури (`--Description:`) - [modulesSetDescriptionFromCommentsLegacy](#modulessetdescriptionfromcommentslegacy)
* отримання `MS_Description` - [metadataGetDescriptions](#metadatagetdescriptions) 

### DDL history
* [myselfGetHistory](#myselfgethistory)
* [objectGetHistory](#objectgethistory)

### Indexes
* Пошку безкорисних, та бракуючих 
    * [indexesGetUnused](#indexesgetunused)
    * [indexesGetMissing](#indexesgetmissing)
* Переіменування - [indexesSetConventionNames](#indexessetconventionnames)
* Спостереження за процессом створення - [myselfActiveIndexCreation](#myselfactiveindexcreation)
* Розмір індексів - [indexesGetSpaceUsed](#indexesgetspaceused)
* .. детальність до файлів - [indexesGetSpaceUsedDetailed](#indexesgetspaceuseddetailed)

### Script
* Скриптування індексів - [indexesGetScript](#indexesgetscript)
* і таблиць - [tablesGetScript](#tablesgetscript)

### Permission
* Отримання списку привілей потрібних для виконання модуля - [metadataGetRequiredPermission](#metadatagetrequiredpermission)

## Procedures
- [errorHandler](#errorhandler)
- [indexesSetConventionNames](#indexessetconventionnames)
- [metadataSetColumnDescription](#metadatasetcolumndescription)
- [metadataSetDataspaceDescription](#metadatasetdataspacedescription)
- [metadataSetExtendedProperty](#metadatasetextendedproperty)
- [metadataSetFilegroupDescription](#metadatasetfilegroupdescription)
- [metadataSetFunctionDescription](#metadatasetfunctiondescription)
- [metadataSetIndexDescription](#metadatasetindexdescription)
- [metadataSetParameterDescription](#metadatasetparameterdescription)
- [metadataSetProcedureDescription](#metadatasetproceduredescription)
- [metadataSetSchemaDescription](#metadatasetschemadescription)
- [metadataSetTableDescription](#metadatasettabledescription)
- [metadataSetTriggerDescription](#metadatasettriggerdescription)
- [metadataSetViewDescription](#metadatasetviewdescription)
- [modulesSetDescriptionFromComments](#modulessetdescriptionfromcomments)
- [modulesSetDescriptionFromCommentsLegacy](#modulessetdescriptionfromcommentslegacy)

## Functions
- [indexesGetConventionNames](#indexesgetconventionnames)
- [indexesGetMissing](#indexesgetmissing)
- [indexesGetScript](#indexesgetscript)
- [indexesGetScriptConventionRename](#indexesgetscriptconventionrename)
- [indexesGetSpaceUsed](#indexesgetspaceused)
- [indexesGetSpaceUsedDetailed](#indexesgetspaceuseddetailed)
- [indexesGetUnused](#indexesgetunused)
- [metadataGetAnyId](#metadatagetanyid)
- [metadataGetAnyName](#metadatagetanyname)
- [metadataGetCertificateName](#metadatagetcertificatename)
- [metadataGetClassByName](#metadatagetclassbyname)
- [metadataGetClassName](#metadatagetclassname)
- [metadataGetColumnId](#metadatagetcolumnid)
- [metadataGetColumnName](#metadatagetcolumnname)
- [metadataGetColumns](#metadatagetcolumns)
- [metadataGetDataspaceId](#metadatagetdataspaceid)
- [metadataGetDataspaceName](#metadatagetdataspacename)
- [metadataGetDescriptions](#metadatagetdescriptions)
- [metadataGetExtendedProperiesValues](#metadatagetextendedproperiesvalues)
- [metadataGetIndexes](#metadatagetindexes)
- [metadataGetIndexId](#metadatagetindexid)
- [metadataGetIndexName](#metadatagetindexname)
- [metadataGetObjectName](#metadatagetobjectname)
- [metadataGetObjectsType](#metadatagetobjectstype)
- [metadataGetObjectType](#metadatagetobjecttype)
- [metadataGetParameterId](#metadatagetparameterid)
- [metadataGetParameters](#metadatagetparameters)
- [metadataGetPartitionFunctionId](#metadatagetpartitionfunctionid)
- [metadataGetPartitionFunctionName](#metadatagetpartitionfunctionname)
- [metadataGetRequiredPermission](#metadatagetrequiredpermission)
- [modulesFindCommentsPositions](#modulesfindcommentspositions)
- [modulesFindInlineCommentsPositions](#modulesfindinlinecommentspositions)
- [modulesFindLinesPositions](#modulesfindlinespositions)
- [modulesFindMultilineCommentsPositions](#modulesfindmultilinecommentspositions)
- [modulesGetCreateLineNumber](#modulesgetcreatelinenumber)
- [modulesGetDescriptionFromComments](#modulesgetdescriptionfromcomments)
- [modulesGetDescriptionFromCommentsLegacy](#modulesgetdescriptionfromcommentslegacy)
- [modulesRecureSearchForOccurrences](#modulesrecuresearchforoccurrences)
- [modulesRecureSearchStartEndPositions](#modulesrecuresearchstartendpositions)
- [modulesRecureSearchStartEndPositionsExtended](#modulesrecuresearchstartendpositionsextended)
- [modulesSplitToLines](#modulessplittolines)
- [myselfActiveIndexCreation](#myselfactiveindexcreation)
- [myselfGetHistory](#myselfgethistory)
- [objectGetHistory](#objectgethistory)
- [stringSplitMultiLineComment](#stringsplitmultilinecomment)
- [tablesGetIndexedColumns](#tablesgetindexedcolumns)
- [tablesGetScript](#tablesgetscript)
- [xeGetErrors](#xegeterrors)

---

## *procedure* `errorHandler`

    * @attachment NVARCHAR(MAX) = NULL - додаткова інформація або повідомлення для додавання разом з помилкою

Універсальна процедура обробки помилок, яка отримує системну інформацію про помилку, записує інформацію про неї, 
може надіслати на електронну пошту. Записує помилки в таблицю util.ErrorLog і повертає детальну інформацію.
Процедура може використовувати для помилок, отриманих із блоку CATCH або для відображення стану.
# Returns
Нічого не повертає. Записує інформацію про помилку в таблицю util.ErrorLog.
В разі використання поза блоком CATCH, повертає інформацію про поточний стан через SELECT.
# Usage

```sql
BEGIN TRY
    -- Ваш код
END TRY
BEGIN CATCH
    EXEC util.errorHandler @attachment = 'Додаткова інформація про контекст';
END CATCH
```

## *procedure* `indexesSetConventionNames`

    * @table NVARCHAR(128) = NULL - назва таблиці для перейменування індексів (NULL = усі таблиці)
    * @index NVARCHAR(128) = NULL - назва конкретного індексу (NULL = усі індекси)
    * @output TINYINT = 1 - виводити результати (1) або тільки виконувати (0)

Перейменовує індекси відповідно до стандартних конвенцій найменування, генеруючи та виконуючи SQL скрипти.
# Returns
Виконує перейменування індексів і може виводити результати залежно від параметра @output
# Usage

```sql
-- Перейменувати всі індекси таблиці з виведенням результатів
EXEC util.indexesSetConventionNames @table = 'myTable', @output = 1;
-- Перейменувати конкретний індекс без виведення
EXEC util.indexesSetConventionNames @table = 'myTable', @index = 'oldIndexName', @output = 0;
```

## *procedure* `metadataSetColumnDescription`

    * @object NVARCHAR(128) - назва таблиці або представлення
    * @column NVARCHAR(128) - назва колонки
    * @description NVARCHAR(MAX) - текст опису для колонки

Встановлює опис для колонки таблиці чи представлення через розширені властивості MS_Description.
# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для колонки
# Usage

```sql
-- Встановити опис для колонки таблиці
EXEC util.metadataSetColumnDescription @object = 'myTable', @column = 'myColumn', @description = 'Опис колонки';
-- Встановити опис для колонки представлення
EXEC util.metadataSetColumnDescription @object = 'myView', @column = 'calculatedColumn', @description = 'Розрахункова колонка';
```

## *procedure* `metadataSetDataspaceDescription`

    * @dataspace NVARCHAR(128) - назва простору даних
    * @description NVARCHAR(MAX) - текст опису для простору даних

Встановлює опис для простору даних (файлової групи або схеми розділення) через розширені властивості MS_Description.
# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для простору даних
# Usage

```sql
-- Встановити опис для файлової групи
EXEC util.metadataSetDataspaceDescription @dataspace = 'PRIMARY', @description = 'Основна файлова група';
-- Встановити опис для схеми розділення
EXEC util.metadataSetDataspaceDescription @dataspace = 'MyPartitionScheme', @description = 'Схема розділення по датах';
```

## *procedure* `metadataSetExtendedProperty`

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
# Returns
Нічого не повертає. Встановлює або оновлює розширену властивість
# Usage

```sql
-- Встановити властивість для таблиці
EXEC util.metadataSetExtendedProperty @name = 'MS_Description', @value = 'Опис таблиці',
        @level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'myTable';
-- Встановити властивість для колонки
EXEC util.metadataSetExtendedProperty @name = 'MS_Description', @value = 'Опис колонки',
        @level0type = 'SCHEMA', @level0name = 'dbo', @level1type = 'TABLE', @level1name = 'myTable',
        @level2type = 'COLUMN', @level2name = 'myColumn';
```

## *procedure* `metadataSetFilegroupDescription`

    * @filegroup NVARCHAR(128) - назва файлової групи
    * @description NVARCHAR(MAX) - текст опису для файлової групи

Встановлює опис для файлової групи через розширені властивості MS_Description.
# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для файлової групи
# Usage

```sql
-- Встановити опис для файлової групи
EXEC util.metadataSetFilegroupDescription @filegroup = 'PRIMARY', @description = 'Основна файлова група системи';
-- Встановити опис для додаткової файлової групи
EXEC util.metadataSetFilegroupDescription @filegroup = 'DATA_FG', @description = 'Файлова група для користувацьких даних';
```

## *procedure* `metadataSetFunctionDescription`

    * @function NVARCHAR(128) - назва функції
    * @description NVARCHAR(MAX) - текст опису для функції

Встановлює опис для функції через розширені властивості MS_Description.
# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для функції
# Usage

```sql
-- Встановити опис для скалярної функції
EXEC util.metadataSetFunctionDescription @function = 'dbo.MyScalarFunction', @description = 'Функція розрахунку значення';
-- Встановити опис для табличної функції
EXEC util.metadataSetFunctionDescription @function = 'dbo.MyTableFunction', @description = 'Функція повертає набір рядків';
```

## *procedure* `metadataSetIndexDescription`

    * @major NVARCHAR(128) - назва таблиці або object_id
    * @index NVARCHAR(128) - назва індексу
    * @description NVARCHAR(MAX) - текст опису для індексу

Встановлює опис для індексу через розширені властивості MS_Description.
# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для індексу
# Usage

```sql
-- Встановити опис для індексу
EXEC util.metadataSetIndexDescription @major = 'dbo.myTable', @index = 'IX_myTable_Column1', @description = 'Індекс для швидкого пошуку по Column1';
-- Встановити опис для первинного ключа
EXEC util.metadataSetIndexDescription @major = 'dbo.myTable', @index = 'PK_myTable', @description = 'Первинний ключ таблиці';
```

## *procedure* `metadataSetParameterDescription`

    * @major NVARCHAR(128) - назва процедури або функції
    * @parameter NVARCHAR(128) - назва параметра
    * @description NVARCHAR(MAX) - текст опису для параметра

Встановлює опис для параметра процедури або функції через розширені властивості MS_Description.
# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для параметра
# Usage

```sql
-- Встановити опис для параметра процедури
EXEC util.metadataSetParameterDescription @major = 'dbo.myProcedure', @parameter = '@inputParam', @description = 'Вхідний параметр для фільтрації';
-- Встановити опис для параметра функції
EXEC util.metadataSetParameterDescription @major = 'dbo.myFunction', @parameter = '@searchValue', @description = 'Значення для пошуку в таблиці';
```

## *procedure* `metadataSetProcedureDescription`

    * @procedure NVARCHAR(128) - назва процедури
    * @description NVARCHAR(MAX) - текст опису для процедури

Встановлює опис для збереженої процедури через розширені властивості MS_Description.
# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для процедури
# Usage

```sql
-- Встановити опис для процедури
EXEC util.metadataSetProcedureDescription @procedure = 'dbo.myProcedure', @description = 'Процедура для обробки користувацьких даних';
-- Встановити опис для системної процедури
EXEC util.metadataSetProcedureDescription @procedure = 'util.errorHandler', @description = 'Універсальний обробник помилок';
```

## *procedure* `metadataSetSchemaDescription`

    * @schema NVARCHAR(128) - назва схеми
    * @description NVARCHAR(MAX) - текст опису для схеми

Встановлює опис для схеми бази даних через розширені властивості MS_Description.
# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для схеми
# Usage

```sql
-- Встановити опис для користувацької схеми
EXEC util.metadataSetSchemaDescription @schema = 'sales', @description = 'Схема даних продажів';
-- Встановити опис для службової схеми
EXEC util.metadataSetSchemaDescription @schema = 'util', @description = 'Схема утилітарних функцій та процедур';
```

## *procedure* `metadataSetTableDescription`

    * @table NVARCHAR(128) - назва таблиці
    * @description NVARCHAR(MAX) - текст опису для таблиці

Встановлює опис для таблиці через розширені властивості MS_Description.
# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для таблиці
# Usage

```sql
-- Встановити опис для користувацької таблиці
EXEC util.metadataSetTableDescription @table = 'dbo.Customers', @description = 'Таблиця інформації про клієнтів';
-- Встановити опис для системної таблиці
EXEC util.metadataSetTableDescription @table = 'util.ErrorLog', @description = 'Журнал помилок системи';
```

## *procedure* `metadataSetTriggerDescription`

    * @trigger NVARCHAR(128) - назва тригера
    * @description NVARCHAR(MAX) - текст опису для тригера

Встановлює опис для тригера через розширені властивості MS_Description.
# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для тригера
# Usage

```sql
-- Встановити опис для тригера INSERT
EXEC util.metadataSetTriggerDescription @trigger = 'dbo.tr_Customers_Insert', @description = 'Тригер для логування додавання нових клієнтів';
-- Встановити опис для тригера UPDATE
EXEC util.metadataSetTriggerDescription @trigger = 'dbo.tr_Orders_Update', @description = 'Тригер для перевірки бізнес-правил при оновленні замовлень';
```

## *procedure* `metadataSetViewDescription`

    * @view NVARCHAR(128) - назва представлення
    * @description NVARCHAR(MAX) - текст опису для представлення

Встановлює опис для представлення (view) через розширені властивості MS_Description.
# Returns
Нічого не повертає. Встановлює розширену властивість MS_Description для представлення
# Usage

```sql
-- Встановити опис для представлення
EXEC util.metadataSetViewDescription @view = 'dbo.vw_ActiveCustomers', @description = 'Представлення активних клієнтів з основною інформацією';
-- Встановити опис для складного представлення
EXEC util.metadataSetViewDescription @view = 'dbo.vw_SalesReport', @description = 'Звіт продажів з агрегованими даними по періодах';
```

## *procedure* `modulesSetDescriptionFromComments`

    * @object NVARCHAR(128) - назва або ID об'єкта модуля для обробки

Процедура для автоматичного встановлення описів об'єктів на основі коментарів у коді модулів.
Використовує функцію modulesGetDescriptionFromComments для витягання описів з коментарів
та генерує команди для встановлення розширених властивостей.
# Returns
Виводить на екран згенеровані команди EXEC для встановлення описів
# Usage

```sql
-- Встановити опис для конкретного об'єкта
EXEC util.modulesSetDescriptionFromComments 'util.errorHandler'
-- Встановити опис для об'єкта за ID
EXEC util.modulesSetDescriptionFromComments '123456789'
```

## *procedure* `modulesSetDescriptionFromCommentsLegacy`

    * @object NVARCHAR(128) - назва об'єкта для обробки
    * @OnlyEmpty BIT = 1 - встановлювати описи тільки для об'єктів без існуючих описів (1) або для всіх (0)

Встановлює описи для об'єктів бази даних, витягуючи їх з коментарів у вихідному коді модулів.
Автоматично аналізує коментарі типу "-- Description:" та встановлює відповідні розширені властивості.
# Returns
Нічого не повертає. Встановлює розширені властивості MS_Description на основі коментарів
# Usage

```sql
-- Встановити описи з коментарів для конкретного об'єкта
EXEC util.modulesSetDescriptionFromComments @object = 'myProcedure', @OnlyEmpty = 1;
-- Оновити описи для всіх об'єктів навіть якщо вони вже існують
EXEC util.modulesSetDescriptionFromComments @object = 'myFunction', @OnlyEmpty = 0;
```

## *function* `indexesGetConventionNames`

    * @object NVARCHAR(128) = NULL - Назва таблиці для генерації назв індексів (NULL = усі таблиці)
    * @index NVARCHAR(128) = NULL - Назва конкретного індексу (NULL = усі індекси)

Генерує стандартизовані назви індексів відповідно до конвенцій найменування.
Функція аналізує існуючі індекси і пропонує нові назви за встановленими стандартами.
# Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- IndexName NVARCHAR(128) - Поточна назва індексу
- NewIndexName NVARCHAR(128) - Рекомендована назва згідно конвенцій
- IndexType NVARCHAR(60) - Тип індексу
# Usage

```sql
-- Отримати рекомендовані назви для всіх індексів конкретної таблиці
SELECT * FROM util.indexesGetConventionNames('myTable', NULL);
-- Отримати рекомендовану назву для конкретного індексу
SELECT * FROM util.indexesGetConventionNames('myTable', 'myIndex');
```

## *function* `indexesGetMissing`

    * @object NVARCHAR(128) = NULL - Назва таблиці для аналізу відсутніх індексів (NULL = усі таблиці)

Знаходить відсутні індекси, які рекомендує SQL Server для покращення продуктивності запитів.
Функція аналізує DMV sys.dm_db_missing_index_* для визначення потенційно корисних індексів.
# Returns
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
# Usage

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

## *function* `indexesGetScript`

    * @table NVARCHAR(128) = NULL - Назва таблиці для генерації скриптів індексів (NULL = усі таблиці)
    * @index NVARCHAR(128) = NULL - Назва конкретного індексу (NULL = усі індекси)

Генерує DDL скрипти для створення індексів на основі існуючих індексів таблиць.
Функція формує повні CREATE INDEX інструкції включаючи всі налаштування індексу.
# Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - Назва схеми
- TableName NVARCHAR(128) - Назва таблиці
- IndexName NVARCHAR(128) - Назва індексу
- CreateScript NVARCHAR(MAX) - DDL скрипт для створення індексу
# Usage

```sql
-- Згенерувати скрипти для всіх індексів конкретної таблиці
SELECT * FROM util.indexesGetScript('myTable', NULL);
-- Згенерувати скрипт для конкретного індексу
SELECT * FROM util.indexesGetScript('myTable', 'myIndex');
```

## *function* `indexesGetScriptConventionRename`

    * @table NVARCHAR(128) = NULL - Назва таблиці для генерації скриптів перейменування (NULL = усі таблиці)
    * @index NVARCHAR(128) = NULL - Назва конкретного індексу (NULL = усі індекси)

Генерує скрипти для перейменування індексів відповідно до стандартних конвенцій найменування.
Функція створює EXEC sp_rename команди для зміни назв індексів на рекомендовані.
# Returns
TABLE - Повертає таблицю з колонками:
- RenameScript NVARCHAR(MAX) - SQL скрипт для перейменування індексу
# Usage

```sql
-- Згенерувати скрипти перейменування для всіх індексів таблиці
SELECT * FROM util.indexesGetScriptConventionRename('myTable', NULL);
-- Згенерувати скрипт перейменування для конкретного індексу
SELECT * FROM util.indexesGetScriptConventionRename('myTable', 'myIndex');
```

## *function* `indexesGetSpaceUsed`

    * @object NVARCHAR(128) = NULL - Назва таблиці або її ID для аналізу індексів (NULL = усі таблиці)

Повертає стислу статистику використання дискового простору індексами таблиці з групуванням по індексах.
Функція використовує util.indexesGetSpaceUsedDetailed та агрегує дані по всіх партиціях кожного індексу.
# Returns
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
# Usage

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

## *function* `indexesGetSpaceUsedDetailed`

    * @object NVARCHAR(128) - Назва таблиці або її ID для аналізу індексів

Повертає детальну статистику використання дискового простору індексами таблиці по партиціях.
Функція показує інформацію для кожної партиції окремо, включаючи дані про партиціонування та стиснення.
# Returns
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
# Usage

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

## *function* `indexesGetUnused`

    * @object NVARCHAR(128) = NULL - Назва таблиці для аналізу індексів (NULL = усі таблиці)

Знаходить невикористовувані індекси в базі даних на основі статистики використання.
Функція аналізує DMV sys.dm_db_index_usage_stats для визначення індексів, які не використовувались
для операцій читання (seeks, scans, lookups) або використовувались тільки для операцій запису.
# Returns
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
# Usage

```sql
-- Знайти всі невикористовувані індекси в базі даних
SELECT * FROM util.indexesGetUnused(NULL);
-- Знайти невикористовувані індекси конкретної таблиці
SELECT * FROM util.indexesGetUnused('myTable');
-- Знайти індекси з тільки операціями запису
SELECT * FROM util.indexesGetUnused(NULL) WHERE UnusedReason LIKE '%тільки запис%';
```

## *function* `metadataGetAnyId`

    * @object NVARCHAR(128) - назва об'єкта
    * @class NVARCHAR(128) = 1 - клас об'єкта (число або текстова назва класу)
    * @minorName NVARCHAR(128) = NULL - додаткова назва для складних об'єктів (наприклад, колонка або індекс)

Універсальна функція для отримання ID будь-якого об'єкта бази даних залежно від його класу. 
Підтримує різні типи об'єктів: таблиці, колонки, індекси, схеми, користувачів, файли та інші.
# Returns
INT - ідентифікатор об'єкта відповідного типу або NULL якщо об'єкт не знайдено
# Usage

```sql
-- Отримати object_id таблиці
SELECT util.metadataGetAnyId('dbo.MyTable', 'OBJECT');
-- Отримати column_id колонки
SELECT util.metadataGetAnyId('dbo.MyTable', 'OBJECT', 'MyColumn');
```

## *function* `metadataGetAnyName`

    * @majorId INT - основний ідентифікатор об'єкта
    * @minorId INT = 0 - додатковий ідентифікатор (для колонок, індексів, параметрів)
    * @class NVARCHAR(128) = '1' - клас об'єкта (число або текстова назва)

Універсальна функція для отримання імені будь-якого об'єкта бази даних за його ID та класом.
Дозволяє отримувати імена для різних типів об'єктів залежно від їх класу.
# Returns
NVARCHAR(128) - ім'я відповідного об'єкта
# Usage

```sql
-- Отримати ім'я таблиці за object_id
SELECT util.metadataGetAnyName(OBJECT_ID('dbo.MyTable'), 0, '1');
-- Отримати ім'я колонки
SELECT util.metadataGetAnyName(OBJECT_ID('dbo.MyTable'), 1, '1');
```

## *function* `metadataGetCertificateName`

    * @majorId INT - ідентифікатор сертифіката (certificate_id)

Отримує ім'я сертифіката за його ідентифікатором з системного каталогу.
# Returns
NVARCHAR(128) - ім'я сертифіката в квадратних дужках або NULL якщо не знайдено
# Usage

```sql
-- Отримати ім'я сертифіката за ID
SELECT util.metadataGetCertificateName(1);
```

## *function* `metadataGetClassByName`

    * @className NVARCHAR(128) - текстова назва класу об'єкта

Повертає числовий код класу об'єкта за його текстовою назвою.
Використовується для перетворення людських назв класів в системні коди.
# Returns
TINYINT - числовий код класу (0-База даних, 1-Об'єкт/Колонка, 2-Параметр, тощо) або NULL для невідомого класу
# Usage

```sql
-- Отримати код класу за назвою
SELECT util.metadataGetClassByName('OBJECT_OR_COLUMN');
SELECT util.metadataGetClassByName('INDEX');
```

## *function* `metadataGetClassName`

    * @class TINYINT - числовий код класу об'єкта

Повертає текстову назву класу об'єкта за його числовим кодом.
Зворотна функція до metadataGetClassByName.
# Returns
NVARCHAR(128) - текстова назва класу або NULL для невідомого коду
# Usage

```sql
-- Отримати назву класу за кодом
SELECT util.metadataGetClassName(1); -- OBJECT_OR_COLUMN
SELECT util.metadataGetClassName(3); -- SCHEMA
```

## *function* `metadataGetColumnId`

    * @major NVARCHAR(128) - назва об'єкта (таблиця/представлення) або object_id
    * @column NVARCHAR(128) - назва стовпця для якого шукати ідентифікатор

Отримує column_id для заданого стовпця в таблиці або представленні. 
Підтримує передачу як назви об'єкта, так і числового ідентифікатора таблиці.
# Returns
INT - ідентифікатор стовпця (column_id) або NULL якщо стовпець не знайдено
# Usage

```sql
SELECT util.metadataGetColumnId('dbo.MyTable', 'MyColumn');
-- Отримати column_id для стовпця MyColumn в таблиці dbo.MyTable
```

## *function* `metadataGetColumnName`

    * @columnId INT - ідентифікатор стовпця (column_id)
    * @major NVARCHAR(128) - назва таблиці або object_id

Отримує ім'я стовпця за ідентифікатором таблиці та ідентифікатором стовпця.
# Returns
NVARCHAR(128) - ім'я стовпця в квадратних дужках або NULL якщо не знайдено
# Usage

```sql
SELECT util.metadataGetColumnName('dbo.MyTable', 1);
-- Отримати ім'я стовпця за його column_id
```

## *function* `metadataGetColumns`

    * @object NVARCHAR(128) = NULL - назва об'єкта або NULL для всіх таблиць

Отримує детальну інформацію про всі стовпці таблиці або представлення.
# Returns
Таблиця з колонками: column_id, name, system_type_name, max_length, precision, scale, is_nullable, is_identity
# Usage

```sql
SELECT * FROM util.metadataGetColumns('dbo.MyTable');
-- Отримати інформацію про всі стовпці таблиці
```

## *function* `metadataGetDataspaceId`

    * @dataSpace NVARCHAR(128) - назва простору даних

Отримує ідентифікатор простору даних (data space) за його назвою.
Підтримує файлові групи та схеми розділення.
# Returns
INT - ідентифікатор простору даних або NULL якщо не знайдено
# Usage

```sql
-- Отримати ID файлової групи
SELECT util.metadataGetDataspaceId('PRIMARY');
-- Отримати ID схеми розділення
SELECT util.metadataGetDataspaceId('MyPartitionScheme');
```

## *function* `metadataGetDataspaceName`

    * @dataSpaceId INT - ідентифікатор простору даних

Отримує назву простору даних (data space) за його ідентифікатором.
Повертає назву в квадратних дужках для безпечного використання в SQL.
# Returns
NVARCHAR(128) - назва простору даних в квадратних дужках або NULL якщо не знайдено
# Usage

```sql
-- Отримати назву файлової групи за ID
SELECT util.metadataGetDataspaceName(1);
-- Отримати назву схеми розділення за ID
SELECT util.metadataGetDataspaceName(65537);
```

## *function* `metadataGetDescriptions`

    * @major NVARCHAR(128) - основний об'єкт для пошуку описів
    * @minor NVARCHAR(128) - додатковий об'єкт (колонка, параметр тощо)

Отримує описи (extended properties) для об'єктів бази даних за заданими критеріями.
Працює з розширеними властивостями типу MS_Description.
# Returns
TABLE - Повертає таблицю з колонками:
- majorId INT - ідентифікатор основного об'єкта
- minorId INT - ідентифікатор додаткового об'єкта
- class TINYINT - клас об'єкта
- description NVARCHAR(MAX) - текст опису
# Usage

```sql
-- Отримати описи для конкретної таблиці та її колонок
SELECT * FROM util.metadataGetDescriptions('myTable', 'myColumn');
```

## *function* `metadataGetExtendedProperiesValues`

    * @major NVARCHAR(128) = NULL - основний об'єкт для пошуку (NULL = всі)
    * @minor NVARCHAR(128) = NULL - додатковий об'єкт (NULL = всі)
    * @property NVARCHAR(128) = NULL - назва властивості (NULL = всі властивості)

Отримує значення розширених властивостей (extended properties) для об'єктів бази даних.
Дозволяє фільтрувати по об'єктах та типах властивостей.
# Returns
TABLE - Повертає таблицю з колонками:
- majorName NVARCHAR(128) - назва основного об'єкта
- minorName NVARCHAR(128) - назва додаткового об'єкта
- propertyName NVARCHAR(128) - назва властивості
- propertyValue NVARCHAR(MAX) - значення властивості
- class TINYINT - клас об'єкта
# Usage

```sql
-- Отримати всі розширені властивості для таблиці
SELECT * FROM util.metadataGetExtendedProperiesValues('myTable', NULL, NULL);
-- Отримати значення конкретної властивості
SELECT * FROM util.metadataGetExtendedProperiesValues('myTable', 'myColumn', 'MS_Description');
```

## *function* `metadataGetIndexes`

    * @object NVARCHAR(128) = NULL - назва таблиці для отримання індексів (NULL = всі таблиці)

Отримує детальну інформацію про індекси для заданих таблиць.
Включає основні характеристики індексів та їх стан.
# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор таблиці
- index_id INT - ідентифікатор індексу
- name NVARCHAR(128) - назва індексу
- type_desc NVARCHAR(60) - тип індексу
- is_unique BIT - чи унікальний індекс
- is_primary_key BIT - чи первинний ключ
# Usage

```sql
-- Отримати всі індекси конкретної таблиці
SELECT * FROM util.metadataGetIndexes('myTable');
-- Отримати індекси всіх таблиць
SELECT * FROM util.metadataGetIndexes(NULL);
```

## *function* `metadataGetIndexId`

    * @object NVARCHAR(128) - назва таблиці або object_id
    * @indexName NVARCHAR(128) - назва індексу

Отримує ідентифікатор індексу за назвою табліці та назвою індексу.
# Returns
INT - ідентифікатор індексу або NULL якщо не знайдено
# Usage

```sql
-- Отримати ID індексу за назвами
SELECT util.metadataGetIndexId('myTable', 'IX_myTable_Column1');
-- Використовуючи object_id таблиці
SELECT util.metadataGetIndexId('1234567890', 'IX_myTable_Column1');
```

## *function* `metadataGetIndexName`

    * @major NVARCHAR(128) - назва таблиці або object_id
    * @indexId INT - ідентифікатор індексу

Отримує назву індексу за ідентифікатором таблиці та ідентифікатором індексу.
# Returns
NVARCHAR(128) - повна назва індексу у форматі "схема.таблиця (індекс)" або NULL якщо не знайдено
# Usage

```sql
-- Отримати назву індексу за ID
SELECT util.metadataGetIndexName('myTable', 2);
-- Використовуючи object_id таблиці
SELECT util.metadataGetIndexName('1234567890', 2);
```

## *function* `metadataGetObjectName`

    * @majorId INT - ідентифікатор об'єкта (object_id)

Отримує повну назву об'єкта бази даних за його ідентифікатором.
Повертає назву у форматі "схема.об'єкт" в квадратних дужках.
# Returns
NVARCHAR(128) - повну назву об'єкта у форматі "[схема].[об'єкт]" або NULL якщо не знайдено
# Usage

```sql
-- Отримати назву об'єкта за його ID
SELECT util.metadataGetObjectName(OBJECT_ID('dbo.myTable'));
-- Використовуючи числовий ID
SELECT util.metadataGetObjectName(1234567890);
```

## *function* `metadataGetObjectsType`

    * @object NVARCHAR(128) = NULL - назва об'єкта або список назв через кому (NULL = всі об'єкти)

Отримує інформацію про тип об'єктів бази даних з можливістю фільтрації.
Підтримує як окремі об'єкти, так і список через кому.
# Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - ідентифікатор об'єкта
- objectName NVARCHAR(128) - назва об'єкта
- objectType NVARCHAR(60) - тип об'єкта
# Usage

```sql
-- Отримати тип конкретного об'єкта
SELECT * FROM util.metadataGetObjectsType('myTable');
-- Отримати типи кількох об'єктів
SELECT * FROM util.metadataGetObjectsType('myTable,myView,myProcedure');
```

## *function* `metadataGetObjectType`

    * @object NVARCHAR(128) - назва об'єкта бази даних

Отримує тип об'єкта бази даних за його назвою.
Спрощена версія metadataGetObjectsType для отримання одного значення.
# Returns
NVARCHAR(60) - тип об'єкта (наприклад, 'U' для таблиці, 'P' для процедури, 'FN' для функції)
# Usage

```sql
-- Отримати тип об'єкта
SELECT util.metadataGetObjectType('myTable');
-- Перевірити чи є об'єкт таблицею
SELECT CASE WHEN util.metadataGetObjectType('myTable') = 'U' THEN 'Table' ELSE 'Not Table' END;
```

## *function* `metadataGetParameterId`

    * @object NVARCHAR(128) - назва або ID об'єкта бази даних
    * @parameterName NVARCHAR(128) - назва параметра

Отримує ідентифікатор параметра для вказаного об'єкта бази даних.
# Returns
INT - ідентифікатор параметра або NULL якщо параметр не знайдено
# Usage

```sql
-- Отримати ID параметра процедури
SELECT util.metadataGetParameterId('myProcedure', '@param1');
-- Використовуючи object_id
SELECT util.metadataGetParameterId('1234567890', '@param1');
```

## *function* `metadataGetParameters`

    * @object NVARCHAR(128) = NULL - Назва об'єкта або object_id для отримання параметрів (NULL = всі об'єкти)

Повертає детальну інформацію про параметри для вказаної збереженої процедури або функції, 
включаючи назви параметрів, типи даних, напрямки та значення за замовчуванням. 
Виключає системні параметри без імені.
# Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - Ідентифікатор об'єкта
- schemaName NVARCHAR(128) - Назва схеми
- objectName NVARCHAR(128) - Назва об'єкта
- parameterId INT - Ідентифікатор параметра
- parameterName NVARCHAR(128) - Назва параметра
# Usage

```sql
-- Отримати параметри конкретної процедури
SELECT * FROM util.metadataGetParameters('util.errorHandler');
-- Отримати параметри всіх об'єктів
SELECT * FROM util.metadataGetParameters(DEFAULT);
```

## *function* `metadataGetPartitionFunctionId`

    * @function NVARCHAR(128) - назва функції розділення

Отримує ідентифікатор функції розділення за її назвою.
# Returns
INT - ідентифікатор функції розділення або NULL якщо не знайдено
# Usage

```sql
-- Отримати ID функції розділення
SELECT util.metadataGetPartitionFunctionId('myPartitionFunction');
```

## *function* `metadataGetPartitionFunctionName`

    * @functionId INT - ідентифікатор функції розділення

Отримує назву функції розділення за її ідентифікатором.
# Returns
NVARCHAR(128) - назва функції розділення в квадратних дужках або NULL якщо не знайдено
# Usage

```sql
-- Отримати назву функції розділення за ID
SELECT util.metadataGetPartitionFunctionName(1);
```

## *function* `metadataGetRequiredPermission`

    * @object NVARCHAR(128) - повне ім'я об'єкта у форматі [схема].[ім'я] або просто ім'я

Визначає об'єкти, для яких потрібні додаткові права при виконанні заданого об'єкта (процедури, функції).
Аналізує залежності через sys.sql_expression_dependencies та виявляє:
1. Об'єкти з інших баз даних (завжди потребують прав)
2. Об'єкти з різними власниками схем (можуть потребувати додаткових прав)
# Returns
TABLE - Повертає таблицю з колонками:
- ObjectName NVARCHAR(MAX) - повне ім'я об'єкта, який потребує додаткових прав
- PermissionReason NVARCHAR(200) - причина, чому потрібні додаткові права
- DatabaseName NVARCHAR(128) - назва бази даних об'єкта
- SchemaName NVARCHAR(128) - назва схеми об'єкта
- EntityName NVARCHAR(128) - назва об'єкта
- SchemaOwner NVARCHAR(128) - власник схеми об'єкта
# Usage

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

## *function* `modulesFindCommentsPositions`

    * @objectId INT = NULL - ідентифікатор об'єкта для пошуку коментарів (NULL = усі об'єкти)

Знаходить позиції всіх коментарів (багаторядкових та однорядкових) у модулях бази даних.
Об'єднує результати з функцій пошуку багаторядкових та однорядкових коментарів.
# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку коментаря
- endPosition INT - позиція кінця коментаря
# Usage

```sql
-- Знайти всі коментарі в конкретному об'єкті
SELECT * FROM util.modulesFindCommentsPositions(OBJECT_ID('myProc'));
-- Знайти всі коментарі в усіх об'єктах
SELECT * FROM util.modulesFindCommentsPositions(NULL);
```

## *function* `modulesFindInlineCommentsPositions`

    * @objectId INT = NULL - ідентифікатор об'єкта для пошуку коментарів (NULL = усі об'єкти)

Знаходить позиції однорядкових коментарів (що починаються з '--') у модулях бази даних.
# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку коментаря
- endPosition INT - позиція кінця коментаря
# Usage

```sql
-- Знайти однорядкові коментарі в конкретному об'єкті
SELECT * FROM util.modulesFindInlineCommentsPositions(OBJECT_ID('myProc'));
```

## *function* `modulesFindLinesPositions`

    * @objectId INT = NULL - ідентифікатор об'єкта для пошуку рядків (NULL = усі об'єкти)

Знаходить позиції всіх рядків у модулях бази даних, включаючи перший рядок.
Нумерує рядки та визначає їх початкові та кінцеві позиції.
# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку рядка
- endPosition INT - позиція кінця рядка
- lineNumber INT - номер рядка
# Usage

```sql
-- Знайти всі рядки в конкретному об'єкті
SELECT * FROM util.modulesFindLinesPositions(OBJECT_ID('myProc'));
```

## *function* `modulesFindMultilineCommentsPositions`
Знаходить позиції багаторядкових коментарів ( ... 
## *function* `modulesGetCreateLineNumber`

    * @objectId INT = NULL - ідентифікатор об'єкта модуля (функція, процедура, тригер)

Повертає номер рядка, де знаходиться оператор CREATE для заданого об'єкта модуля.
Функція аналізує текст модуля та знаходить перший рядок що починається з "CREATE".
# Returns
TABLE:
- objectId INT - ідентифікатор об'єкта
- lineNumber INT - номер рядка з оператором CREATE
# Usage

```sql
-- Знайти номер рядка з CREATE для всіх об'єктів
SELECT * FROM util.modulesGetCreateLineNumber(DEFAULT)
-- Знайти номер рядка з CREATE для конкретного об'єкта
SELECT * FROM util.modulesGetCreateLineNumber(OBJECT_ID('util.errorHandler'))
```

## *function* `modulesGetDescriptionFromComments`

    * @objectId INT = NULL - ідентифікатор об'єкта модуля (NULL для всіх об'єктів)

Витягує опис з коментарів модулів (функцій, процедур, тригерів) та форматує його для встановлення 
як розширену властивість. Функція аналізує багаторядкові коментарі що знаходяться перед оператором CREATE
та витягує з них структурований опис.
# Returns
TABLE:
- objectId INT - ідентифікатор об'єкта
- objectType NVARCHAR(128) - тип об'єкта (FUNCTION, PROCEDURE, TRIGGER)
- minor INT - мінорний ідентифікатор (завжди 0 для модулів)
- description NVARCHAR(MAX) - відформатований опис з коментарів
# Usage

```sql
-- Отримати опис для всіх модулів
SELECT * FROM util.modulesGetDescriptionFromComments(DEFAULT)
-- Отримати опис для конкретного модуля
SELECT * FROM util.modulesGetDescriptionFromComments(OBJECT_ID('util.errorHandler'))
```

## *function* `modulesGetDescriptionFromCommentsLegacy`

    * @object NVARCHAR(128) = NULL - назва об'єкта для пошуку описів (NULL = усі об'єкти)

Витягує описи об'єктів з коментарів у вихідному коді модулів, шукаючи рядки що починаються з '-- Description:'.
# Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - ідентифікатор об'єкта
- schemaName NVARCHAR(128) - назва схеми
- objectName NVARCHAR(128) - назва об'єкта
- description NVARCHAR(MAX) - витягнутий опис з коментарів
# Usage

```sql
-- Витягти описи з коментарів для конкретного об'єкта
SELECT * FROM util.modulesGetDescriptionFromComments('myProc');
-- Витягти описи для всіх об'єктів
SELECT * FROM util.modulesGetDescriptionFromComments(NULL);
```

## *function* `modulesRecureSearchForOccurrences`

    * @searchFor NVARCHAR(64) - рядок для пошуку в тексті визначень модулів
    * @options TINYINT - бітові опції пошуку: (2): пропускати входження перед '.' або '].',  (4): шукати тільки цілі слова (не частини слів), (8): пропускати входження в quoted names ([...])

Рекурсивно шукає всі входження заданого рядка у визначеннях модулів бази даних (stored procedures, functions, views, triggers).
Використовує CTE для знаходження всіх позицій входження з можливістю фільтрації за опціями.
# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта модуля (sys.objects.object_id)
- occurrencePosition INT - позиція входження в тексті визначення (1-based)
## *function* `modulesRecureSearchStartEndPositions`

    * @startValue NVARCHAR(32) - початкове значення для пошуку
    * @endValue NVARCHAR(32) - кінцеве значення для пошуку

Рекурсивно шукає позиції початку та кінця блоків у модулях за заданими початковим та кінцевим значеннями.
Спрощена версія функції modulesRecureSearchStartEndPositionsExtended.
# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку блоку
- endPosition INT - позиція кінця блоку
# Usage

```sql
-- Знайти блоки BEGIN...END
SELECT * FROM util.modulesRecureSearchStartEndPositions('BEGIN', 'END');
-- Знайти блоки IF...END IF  
SELECT * FROM util.modulesRecureSearchStartEndPositions('IF', 'END IF');
```

## *function* `modulesRecureSearchStartEndPositionsExtended`

    * @startValue NVARCHAR(32) - початкове значення для пошуку
    * @endValue NVARCHAR(32) - кінцеве значення для пошуку
    * @replaceCRwithLF BIT = 0 - замінити CR на LF (1) або залишити як є (0)
    * @objectID INT = NULL - ідентифікатор конкретного об'єкта (NULL = усі об'єкти)

Розширена функція рекурсивного пошуку позицій початку та кінця блоків у модулях з додатковими опціями.
Підтримує обробку символів переносу рядків та фільтрацію по конкретних об'єктах.
# Returns
TABLE - Повертає таблицю з колонками:
- object_id INT - ідентифікатор об'єкта
- startPosition INT - позиція початку блоку
- endPosition INT - позиція кінця блоку
# Usage

```sql
-- Знайти коментарі з нормалізацією переносів рядків
SELECT * FROM util.modulesRecureSearchStartEndPositionsExtended('', '
```

## *function* `modulesSplitToLines`

    * @object NVARCHAR(128) - назва або ID об'єкта для розбиття на рядки (NULL = усі об'єкти)
    * @skipEmpty BIT = 1 - пропускати порожні рядки (1 = так, 0 = включати порожні рядки)

Розбиває визначення модулів (процедур, функцій, тригерів) на окремі рядки з нумерацією для подальшого аналізу.
Функція обробляє текст з sys.sql_modules, замінює табуляції на пробіли та може пропускати порожні рядки.
# Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - ідентифікатор об'єкта модуля
- line NVARCHAR(MAX) - текст рядка (з обрізаними пробілами та заміненими табуляціями)
- lineNumber INT - номер рядка в модулі (порядковий номер)
# Usage

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

## *function* `myselfActiveIndexCreation`
Відстежує прогрес активного створення індексів поточним користувачем.
Функція моніторить операції CREATE INDEX та показує детальну інформацію про їх виконання в реальному часі.
# Returns
TABLE - Повертає таблицю з колонками:
- sessionId INT - Ідентифікатор сесії
- pysicalOperatorName NVARCHAR - Назва фізичного оператора
- CurrentStep NVARCHAR - Поточний крок виконання
- TotalRows BIGINT - Загальна кількість рядків для обробки
- RowsProcessed BIGINT - Кількість оброблених рядків
- RowsLeft BIGINT - Кількість рядків що залишились
- ElapsedSeconds DECIMAL - Час виконання в секундах
- currentStatement NVARCHAR - Поточна T-SQL команда CREATE INDEX
# Usage

```sql
-- Відстежити прогрес всіх активних операцій створення індексів
SELECT * FROM util.myselfActiveIndexCreation();
```

## *function* `myselfGetHistory`

    * @startTime DATETIME - початковий час для фільтрації подій (NULL = всі події)

Отримує історію подій аудиту для поточного користувача (ORIGINAL_LOGIN()).
Функція фільтрує записи з таблиці подій за логіном користувача та опціонально за часом.
# Returns
TABLE - Повертає таблицю з колонками:
- eventType NVARCHAR - тип події аудиту
- postTime DATETIME - час події
- SPID INT - ідентифікатор процесу сервера
- serverName NVARCHAR - ім'я сервера
- loginName NVARCHAR - ім'я логіну
- userName NVARCHAR - ім'я користувача
- roleName NVARCHAR - ім'я ролі
- databaseName NVARCHAR - назва бази даних
- schemaName NVARCHAR - назва схеми
- objectName NVARCHAR - назва об'єкта
- objectType NVARCHAR - тип об'єкта
- loginType NVARCHAR - тип логіну
- targetObjectName NVARCHAR - назва цільового об'єкта
- targetObjectType NVARCHAR - тип цільового об'єкта
- propertyName NVARCHAR - назва властивості
- propertyValue NVARCHAR - значення властивості
- parameters NVARCHAR - параметри команди
- tsql_command NVARCHAR - текст T-SQL команди
## *function* `objectGetHistory`

    * @object NVARCHAR(128) - Назва об'єкта для отримання історії
    * @startTime DATETIME2 = NULL - Початковий час для фільтрації подій (NULL = всі події)

Отримує історію змін та активності для конкретного об'єкта бази даних.
Функція повертає всі події, пов'язані з вказаним об'єктом, виконані поточним користувачем.
# Returns
TABLE - Повertає таблицю з колонками:
- eventType NVARCHAR - Тип події
- postTime DATETIME - Час публікації події
- SPID INT - Ідентифікатор сесії
- serverName NVARCHAR - Назва сервера
- loginName NVARCHAR - Ім'я користувача для входу
- userName NVARCHAR - Ім'я користувача
- roleName NVARCHAR - Назва ролі
- databaseName NVARCHAR - Назва бази даних
- schemaName NVARCHAR - Назва схеми
- objectName NVARCHAR - Назва об'єкта
- objectType NVARCHAR - Тип об'єкта
- loginType NVARCHAR - Тип входу
- targetObjectName NVARCHAR - Назва цільового об'єкта
- targetObjectType NVARCHAR - Тип цільового об'єкта
- propertyName NVARCHAR - Назва властивості
- propertyValue NVARCHAR - Значення властивості
- parameters NVARCHAR - Параметри
- tsql_command NVARCHAR - T-SQL команда
# Usage

```sql
-- Отримати всю історію змін таблиці
SELECT * FROM util.objectGetHistory('myTable', NULL);
-- Отримати історію змін за останню добу
SELECT * FROM util.objectGetHistory('myTable', DATEADD(day, -1, GETDATE()));
```

## *function* `stringSplitMultiLineComment`

    * @string NVARCHAR(MAX) - Багаторядковий коментар для розбору

Розбирає багаторядковий коментар і повертає структуровану інформацію по секціях.
Функція аналізує коментарі за стандартним форматом документації та виділяє основні секції.
# Returns
TABLE - Повертає таблицю з колонками:
- description NVARCHAR(MAX) - Весь рядок для параметра або опису
- minor NVARCHAR(128) - NULL для загального опису, перше слово для # Parameters/# Columns
- returns NVARCHAR(MAX) - NULL для процедур, опис повернення для функцій
- usage NVARCHAR(MAX) - Приклади використання
# Usage

```sql
-- Розібрати коментар функції
SELECT * FROM util.stringMultiLineComment(@commentString);
-- Отримати тільки опис параметрів
SELECT * FROM util.stringMultiLineComment(@commentString) WHERE minor IS NOT NULL;
```

## *function* `tablesGetIndexedColumns`

    * @object NVARCHAR(128) = NULL - назва таблиці для аналізу індексованих колонок (NULL = усі таблиці)

Повертає інформацію про індексовані колонки таблиць, показуючи які колонки є першими в індексах.
Функція аналізує всі індекси та показує колонки, які є першими (key_ordinal = 1) в кожному індексі.
# Returns
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
# Usage

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

## *function* `tablesGetScript`

    * @table NVARCHAR(128) = NULL - назва таблиці для генерації скрипта (NULL = усі таблиці)

Генерує повний DDL скрипт для створення таблиці, включаючи колонки, типи даних, обмеження та індекси.
# Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - назва схеми
- TableName NVARCHAR(128) - назва таблиці
- CreateScript NVARCHAR(MAX) - повний DDL скрипт для створення таблиці
# Usage

```sql
-- Згенерувати скрипт для конкретної таблиці
SELECT * FROM util.tablesGetScript('myTable');
-- Згенерувати скрипти для всіх таблиць
SELECT * FROM util.tablesGetScript(NULL);
```

## *function* `xeGetErrors`

    * @minEventTime DATETIME2(7) - мінімальний час події для фільтрації (NULL = всі події)

Таблично-значуща функція для отримання даних про помилки з Extended Events.
Читає дані з системних сесій XE та повертає їх у структурованому вигляді для аналізу.
# Returns
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

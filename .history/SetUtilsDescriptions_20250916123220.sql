-- =============================================================================
-- Скрипт для додавання описів до всіх об'єктів проекту utils
-- Створено: 2025-09-16
-- Призначення: Встановлення українських описів для схеми, функцій, процедур, таблиць та їх параметрів
-- =============================================================================

USE [DWH]; -- Або потрібна база даних
GO

-- =============================================================================
-- 1. ОПИС СХЕМИ
-- =============================================================================

EXEC util.metadataSetSchemaDescription 
    @schema = 'util',
    @description = N'Схема утилітарних функцій та процедур для роботи з метаданими, модулями та індексами бази даних';

-- =============================================================================
-- 2. ОПИСИ ФУНКЦІЙ ДЛЯ РОБОТИ З МЕТАДАНИМИ
-- =============================================================================

-- Функції для отримання ідентифікаторів
EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetAnyId',
    @description = N'Універсальна функція для отримання ідентифікатора будь-якого об''єкта бази даних за його іменем та класом об''єкта. Приклад: SELECT util.metadataGetAnyId(''dbo.Users'', ''1'') -- отримати ID таблиці, SELECT util.metadataGetAnyId(''dbo.Users'', ''1'', ''UserName'') -- отримати ID стовпця. Повертає: INT - ідентифікатор об''єкта або NULL якщо об''єкт не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetColumnId',
    @description = N'Отримує ідентифікатор стовпця таблиці за ідентифікатором таблиці та іменем стовпця. Приклад: SELECT util.metadataGetColumnId(OBJECT_ID(''dbo.Users''), ''UserName''). Повертає: INT - column_id стовпця з sys.columns або NULL якщо стовпець не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetIndexId',
    @description = N'Отримує ідентифікатор індексу за іменем таблиці та іменем індексу. Приклад: SELECT util.metadataGetIndexId(''dbo.Users'', ''IX_Users_Email''). Повертає: INT - index_id індексу з sys.indexes або NULL якщо індекс не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetParameterId',
    @description = N'Отримує ідентифікатор параметра процедури або функції за іменем об''єкта та іменем параметра. Приклад: SELECT util.metadataGetParameterId(''dbo.GetUserById'', ''@UserId''). Повертає: INT - parameter_id параметра з sys.parameters або NULL якщо параметр не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetDataspaceId',
    @description = N'Отримує ідентифікатор простору даних (dataspace) за його іменем. Приклад: SELECT util.metadataGetDataspaceId(''PRIMARY''). Повертає: INT - data_space_id з sys.data_spaces або NULL якщо простір даних не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetPartitionFunctionId',
    @description = N'Отримує ідентифікатор функції розділення (partition function) за її іменем. Приклад: SELECT util.metadataGetPartitionFunctionId(''pf_DateRange''). Повертає: INT - function_id з sys.partition_functions або NULL якщо функція не знайдена';

-- Функції для отримання імен
EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetAnyName',
    @description = N'Універсальна функція для отримання імені будь-якого об''єкта бази даних за його ідентифікатором та класом об''єкта. Приклад: SELECT util.metadataGetAnyName(12345, ''1'') -- отримати ім''я таблиці за ID. Повертає: NVARCHAR(128) - ім''я об''єкта або NULL якщо об''єкт не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetObjectName',
    @description = N'Отримує повне ім''я об''єкта (схема.об''єкт) за його ідентифікатором. Приклад: SELECT util.metadataGetObjectName(OBJECT_ID(''dbo.Users'')). Повертає: NVARCHAR(128) - повне ім''я об''єкта у форматі [schema].[object] або NULL якщо об''єкт не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetColumnName',
    @description = N'Отримує ім''я стовпця за ідентифікатором таблиці та ідентифікатором стовпця. Приклад: SELECT util.metadataGetColumnName(OBJECT_ID(''dbo.Users''), 1). Повертає: NVARCHAR(128) - ім''я стовпця або NULL якщо стовпець не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetIndexName',
    @description = N'Отримує ім''я індексу за ідентифікатором таблиці та ідентифікатором індексу. Приклад: SELECT util.metadataGetIndexName(OBJECT_ID(''dbo.Users''), 2). Повертає: NVARCHAR(128) - ім''я індексу або NULL якщо індекс не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetParameterName',
    @description = N'Отримує ім''я параметра за ідентифікатором об''єкта та ідентифікатором параметра. Приклад: SELECT util.metadataGetParameterName(OBJECT_ID(''dbo.GetUserById''), 1). Повертає: NVARCHAR(128) - ім''я параметра включаючи @ або NULL якщо параметр не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetCertificateName',
    @description = N'Отримує ім''я сертифіката за його ідентифікатором. Приклад: SELECT util.metadataGetCertificateName(1). Повертає: NVARCHAR(128) - ім''я сертифіката або NULL якщо сертифікат не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetDataspaceName',
    @description = N'Отримує ім''я простору даних за його ідентифікатором. Приклад: SELECT util.metadataGetDataspaceName(1). Повертає: NVARCHAR(128) - ім''я файлової групи або NULL якщо простір даних не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetPartitionFunctionName',
    @description = N'Отримує ім''я функції розділення за її ідентифікатором. Приклад: SELECT util.metadataGetPartitionFunctionName(65536). Повертає: NVARCHAR(128) - ім''я функції розділення або NULL якщо функція не знайдена';

-- Функції для класифікації об'єктів
EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetClassByName',
    @description = N'Отримує числовий код класу об''єкта за його текстовим описом. Приклад: SELECT util.metadataGetClassByName(''OBJECT_OR_COLUMN'') -- поверне 1. Повертає: INT - код класу (0-База даних, 1-Об''єкт/стовпець, 2-Індекс, 3-Схема, 4-Користувач, 7-Тип, 20-Простір даних, 21-Функція розділення, 22-Файл, 25-Сертифікат) або NULL для невідомого класу';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetClassName',
    @description = N'Отримує текстовий опис класу об''єкта за його числовим кодом. Приклад: SELECT util.metadataGetClassName(1) -- поверне ''OBJECT_OR_COLUMN''. Повертає: NVARCHAR(128) - назва класу об''єкта або NULL для невідомого коду';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetObjectType',
    @description = N'Отримує тип об''єкта за його ідентифікатором. Приклад: SELECT util.metadataGetObjectType(OBJECT_ID(''dbo.Users'')). Повертає: NVARCHAR(60) - опис типу об''єкта (наприклад, ''USER_TABLE'', ''SQL_STORED_PROCEDURE'', ''SQL_SCALAR_FUNCTION'') або NULL якщо об''єкт не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetObjectsType',
    @description = N'Отримує список типів об''єктів, що існують у базі даних. Приклад: SELECT * FROM util.metadataGetObjectsType(). Повертає таблицю: type CHAR(2), type_desc NVARCHAR(60) - всі типи об''єктів з sys.objects';

-- Функції для роботи з додатковими властивостями
EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetDescriptions',
    @description = N'Отримує всі описи (extended properties) об''єктів бази даних. Приклад: SELECT * FROM util.metadataGetDescriptions(). Повертає таблицю: objtype NVARCHAR(128), objname NVARCHAR(261), name NVARCHAR(128), value SQL_VARIANT - всі extended properties в базі даних';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetExtendedProperiesValues',
    @description = N'Отримує значення розширених властивостей для конкретного об''єкта. Приклад: SELECT * FROM util.metadataGetExtendedProperiesValues(''dbo.Users'', ''1''). Повертає таблицю: name NVARCHAR(128), value SQL_VARIANT - extended properties для вказаного об''єкта';

-- Функції для роботи з колекціями об'єктів
EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetColumns',
    @description = N'Отримує інформацію про всі стовпці таблиці або представлення. Приклад: SELECT * FROM util.metadataGetColumns(''dbo.Users''). Повертає таблицю: column_id INT, name NVARCHAR(128), system_type_name NVARCHAR(256), max_length SMALLINT, precision TINYINT, scale TINYINT, is_nullable BIT, is_identity BIT - детальна інформація про стовпці';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetParameters',
    @description = N'Отримує інформацію про всі параметри процедури або функції. Приклад: SELECT * FROM util.metadataGetParameters(''dbo.GetUserById''). Повертає таблицу: parameter_id INT, name NVARCHAR(128), system_type_name NVARCHAR(256), max_length SMALLINT, precision TINYINT, scale TINYINT, is_output BIT - інформація про параметри об''єкта';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.metadataGetIndexes',
    @description = N'Отримує інформацію про всі індекси таблиці. Приклад: SELECT * FROM util.metadataGetIndexes(''dbo.Users''). Повертає таблицю: index_id INT, name NVARCHAR(128), type_desc NVARCHAR(60), is_unique BIT, is_primary_key BIT, columns NVARCHAR(MAX) - детальна інформація про індекси таблиці';

-- =============================================================================
-- 3. ОПИСИ ФУНКЦІЙ ДЛЯ РОБОТИ З ІНДЕКСАМИ
-- =============================================================================

EXEC util.metadataSetFunctionDescription 
    @function = 'util.indexesGetScript',
    @description = N'Генерує SQL-скрипт для створення індексу з усіма його властивостями. Приклад: SELECT * FROM util.indexesGetScript(''dbo.Users'', ''IX_Users_Email''). Повертає таблицю: createScript NVARCHAR(MAX) - готовий SQL-скрипт для створення індексу з усіма параметрами (ключові стовпці, включені стовпці, фільтри, опції)';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.indexesGetConventionNames',
    @description = N'Отримує рекомендовані імена індексів згідно з прийнятими конвенціями іменування. Приклад: SELECT * FROM util.indexesGetConventionNames(''dbo.Users''). Повертає таблицю: current_name NVARCHAR(128), recommended_name NVARCHAR(128), reason NVARCHAR(MAX) - поточні та рекомендовані імена індексів';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.indexesGetScriptConventionRename',
    @description = N'Генерує SQL-скрипт для перейменування індексів згідно з конвенціями іменування. Приклад: SELECT * FROM util.indexesGetScriptConventionRename(''dbo.Users''). Повертає таблицю: renameScript NVARCHAR(MAX) - готові команди sp_rename для перейменування індексів';

-- =============================================================================
-- 4. ОПИСИ ФУНКЦІЙ ДЛЯ РОБОТИ З МОДУЛЯМИ
-- =============================================================================

EXEC util.metadataSetFunctionDescription 
    @function = 'util.modulesSplitToLines',
    @description = N'Розбиває текст модуля (процедури, функції, тригера) на окремі рядки для аналізу. Приклад: SELECT * FROM util.modulesSplitToLines(''dbo.GetUserById'', 1). Повертає таблицю: object_id INT, line NVARCHAR(MAX), lineNumber BIGINT - кожен рядок коду з номером рядка';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.modulesFindLinesPositions',
    @description = N'Знаходить позиції початку та кінця рядків у тексті модуля. Приклад: SELECT * FROM util.modulesFindLinesPositions(''dbo.GetUserById''). Повертає таблицю: lineNumber INT, startPosition INT, endPosition INT - позиції кожного рядка в тексті модуля';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.modulesFindCommentsPositions',
    @description = N'Знаходить позиції всіх коментарів (однорядкових та багаторядкових) у тексті модуля. Приклад: SELECT * FROM util.modulesFindCommentsPositions(''dbo.GetUserById''). Повертає таблицю: commentType NVARCHAR(10), startPosition INT, endPosition INT, commentText NVARCHAR(MAX) - всі коментарі з їх позиціями';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.modulesFindInlineCommentsPositions',
    @description = N'Знаходить позиції однорядкових коментарів у тексті модуля. Приклад: SELECT * FROM util.modulesFindInlineCommentsPositions(''dbo.GetUserById''). Повертає таблицю: startPosition INT, endPosition INT, commentText NVARCHAR(MAX) - однорядкові коментарі (--) з позиціями';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.modulesFindMultilineCommentsPositions',
    @description = N'Знаходить позиції багаторядкових коментарів у тексті модуля. Приклад: SELECT * FROM util.modulesFindMultilineCommentsPositions(''dbo.GetUserById''). Повертає таблицю: startPosition INT, endPosition INT, commentText NVARCHAR(MAX) - багаторядкові коментарі (/* */) з позиціями';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.modulesGetDescriptionFromComments',
    @description = N'Витягує опис модуля з коментарів у його коді. Приклад: SELECT util.modulesGetDescriptionFromComments(''dbo.GetUserById''). Повертає: NVARCHAR(MAX) - текст опису, витягнутий з коментарів модуля, або NULL якщо опис не знайдено';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.modulesRecureSearchForOccurrences',
    @description = N'Рекурсивно шукає всі входження заданого шаблону у тексті модуля. Приклад: SELECT * FROM util.modulesRecureSearchForOccurrences(''dbo.GetUserById'', ''SELECT''). Повертає таблицю: occurrence INT, startPosition INT, endPosition INT - позиції всіх входжень шаблону';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.modulesRecureSearchStartEndPositions',
    @description = N'Рекурсивно знаходить позиції початку та кінця заданих шаблонів у тексті. Приклад: SELECT * FROM util.modulesRecureSearchStartEndPositions(''text'', ''BEGIN'', ''END''). Повертає таблицю: blockNumber INT, startPosition INT, endPosition INT - позиції парних блоків BEGIN-END';

EXEC util.metadataSetFunctionDescription 
    @function = 'util.modulesRecureSearchStartEndPositionsExtended',
    @description = N'Розширена версія рекурсивного пошуку позицій з додатковими опціями. Приклад: SELECT * FROM util.modulesRecureSearchStartEndPositionsExtended(''text'', ''BEGIN'', ''END'', 1, 0). Повертає таблицю: blockNumber INT, nestingLevel INT, startPosition INT, endPosition INT, blockContent NVARCHAR(MAX) - детальна інформація про вкладені блоки';

-- =============================================================================
-- 5. ОПИСИ ФУНКЦІЙ ДЛЯ РОБОТИ З ТАБЛИЦЯМИ
-- =============================================================================

EXEC util.metadataSetFunctionDescription 
    @function = 'util.tablesGetScript',
    @description = N'Генерує SQL-скрипт для створення таблиці з усіма її стовпцями, обмеженнями та індексами. Приклад: SELECT * FROM util.tablesGetScript(''dbo.Users''). Повертає таблицю: scriptType NVARCHAR(50), scriptOrder INT, sqlScript NVARCHAR(MAX) - послідовність скриптів для повного відтворення структури таблиці (CREATE TABLE, індекси, обмеження, тригери)';

-- =============================================================================
-- 6. ОПИСИ ПРОЦЕДУР ДЛЯ ВСТАНОВЛЕННЯ ОПИСІВ
-- =============================================================================

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.metadataSetExtendedProperty',
    @description = N'Універсальна процедура для встановлення розширених властивостей (extended properties) для об''єктів бази даних. Приклад: EXEC util.metadataSetExtendedProperty @name=''MS_Description'', @value=''Опис таблиці'', @level0type=''SCHEMA'', @level0name=''dbo'', @level1type=''TABLE'', @level1name=''Users''';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.metadataSetSchemaDescription',
    @description = N'Встановлює опис для схеми бази даних. Приклад: EXEC util.metadataSetSchemaDescription @schema=''dbo'', @description=''Основна схема бази даних''';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.metadataSetTableDescription',
    @description = N'Встановлює опис для таблиці. Приклад: EXEC util.metadataSetTableDescription @table=''dbo.Users'', @description=''Таблиця користувачів системи''';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.metadataSetViewDescription',
    @description = N'Встановлює опис для представлення (view). Приклад: EXEC util.metadataSetViewDescription @view=''dbo.vw_ActiveUsers'', @description=''Представлення активних користувачів''';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.metadataSetFunctionDescription',
    @description = N'Встановлює опис для функції. Приклад: EXEC util.metadataSetFunctionDescription @function=''dbo.GetUserFullName'', @description=''Повертає повне ім''''я користувача''';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.metadataSetProcedureDescription',
    @description = N'Встановлює опис для збереженої процедури. Приклад: EXEC util.metadataSetProcedureDescription @procedure=''dbo.GetUserById'', @description=''Отримує інформацію про користувача за ID''';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.metadataSetTriggerDescription',
    @description = N'Встановлює опис для тригера. Приклад: EXEC util.metadataSetTriggerDescription @trigger=''tr_Users_Audit'', @description=''Тригер аудиту змін у таблиці користувачів''';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.metadataSetColumnDescription',
    @description = N'Встановлює опис для стовпця таблиці або представлення. Приклад: EXEC util.metadataSetColumnDescription @table=''dbo.Users'', @column=''Email'', @description=''Електронна пошта користувача''';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.metadataSetParameterDescription',
    @description = N'Встановлює опис для параметра процедури або функції. Приклад: EXEC util.metadataSetParameterDescription @major=''dbo.GetUserById'', @parameter=''@UserId'', @description=''Ідентифікатор користувача''';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.metadataSetIndexDescription',
    @description = N'Встановлює опис для індексу. Приклад: EXEC util.metadataSetIndexDescription @table=''dbo.Users'', @index=''IX_Users_Email'', @description=''Індекс для швидкого пошуку за email''';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.metadataSetDataspaceDescription',
    @description = N'Встановлює опис для простору даних (filegroup). Приклад: EXEC util.metadataSetDataspaceDescription @dataspace=''PRIMARY'', @description=''Основна файлова група''';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.metadataSetFilegroupDescription',
    @description = N'Встановлює опис для файлової групи. Приклад: EXEC util.metadataSetFilegroupDescription @filegroup=''FG_Data'', @description=''Файлова група для даних''';

-- =============================================================================
-- 7. ОПИСИ ІНШИХ ПРОЦЕДУР
-- =============================================================================

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.errorHandler',
    @description = N'Універсальний обробник помилок для логування та обробки винятків. Приклад: EXEC util.errorHandler @ErrorMessage=''Помилка обробки'', @ErrorSeverity=16';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.indexesSetConventionNames',
    @description = N'Перейменовує індекси згідно з прийнятими конвенціями іменування. Приклад: EXEC util.indexesSetConventionNames @table=''dbo.Users'', @execute=1';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.modulesSetDescriptionFromComments',
    @description = N'Автоматично встановлює описи для модулів, витягуючи їх з коментарів у коді. Приклад: EXEC util.modulesSetDescriptionFromComments @object=''dbo.GetUserById'', @execute=1';

EXEC util.metadataSetProcedureDescription 
    @procedure = 'util.xeErrorsToTable',
    @description = N'Переносить дані про помилки з розширених подій (Extended Events) до таблиці для аналізу. Приклад: EXEC util.xeErrorsToTable @sessionName=''system_health'', @maxRecords=1000';

-- =============================================================================
-- 8. ОПИСИ ТАБЛИЦЬ
-- =============================================================================

EXEC util.metadataSetTableDescription 
    @table = 'util.errorLog',
    @description = N'Таблиця для логування помилок та винятків системи';

EXEC util.metadataSetTableDescription 
    @table = 'util.xeErrorLog',
    @description = N'Таблиця для зберігання даних про помилки з розширених подій (Extended Events)';

-- =============================================================================
-- 9. ОПИСИ ПАРАМЕТРІВ ОСНОВНИХ ФУНКЦІЙ
-- =============================================================================

-- Параметри для metadataGetAnyId
EXEC util.metadataSetParameterDescription 
    @major = 'util.metadataGetAnyId',
    @parameter = '@object',
    @description = N'Ім''я об''єкта для якого потрібно отримати ідентифікатор';

EXEC util.metadataSetParameterDescription 
    @major = 'util.metadataGetAnyId',
    @parameter = '@class',
    @description = N'Клас об''єкта (число або текстовий опис): 0-База даних, 1-Об''єкт, 2-Індекс, 3-Схема, 4-Користувач, 7-Тип, 20-Простір даних, 21-Функція розділення, 22-Файл, 25-Сертифікат';

EXEC util.metadataSetParameterDescription 
    @major = 'util.metadataGetAnyId',
    @parameter = '@minorName',
    @description = N'Додаткове ім''я для складних об''єктів (наприклад, ім''я стовпця для таблиці)';

-- Параметри для modulesSplitToLines
EXEC util.metadataSetParameterDescription 
    @major = 'util.modulesSplitToLines',
    @parameter = '@object',
    @description = N'Ім''я або ідентифікатор модуля (процедури, функції, тригера) для розбиття на рядки';

EXEC util.metadataSetParameterDescription 
    @major = 'util.modulesSplitToLines',
    @parameter = '@skipEmpty',
    @description = N'Прапорець (0/1) - чи пропускати пусті рядки при розбитті тексту';

-- Параметри для процедур встановлення описів
EXEC util.metadataSetParameterDescription 
    @major = 'util.metadataSetFunctionDescription',
    @parameter = '@function',
    @description = N'Ім''я функції для якої встановлюється опис';

EXEC util.metadataSetParameterDescription 
    @major = 'util.metadataSetFunctionDescription',
    @parameter = '@description',
    @description = N'Текст опису функції';

EXEC util.metadataSetParameterDescription 
    @major = 'util.metadataSetProcedureDescription',
    @parameter = '@procedure',
    @description = N'Ім''я процедури для якої встановлюється опис';

EXEC util.metadataSetParameterDescription 
    @major = 'util.metadataSetProcedureDescription',
    @parameter = '@description',
    @description = N'Текст опису процедури';

EXEC util.metadataSetParameterDescription 
    @major = 'util.metadataSetParameterDescription',
    @parameter = '@major',
    @description = N'Ім''я процедури або функції, що містить параметр';

EXEC util.metadataSetParameterDescription 
    @major = 'util.metadataSetParameterDescription',
    @parameter = '@parameter',
    @description = N'Ім''я параметра для якого встановлюється опис';

EXEC util.metadataSetParameterDescription 
    @major = 'util.metadataSetParameterDescription',
    @parameter = '@description',
    @description = N'Текст опису параметра';

-- =============================================================================
-- КІНЕЦЬ СКРИПТА
-- =============================================================================

PRINT N'Скрипт успішно виконано. Усі об''єкти проекту utils отримали українські описи.';
GO
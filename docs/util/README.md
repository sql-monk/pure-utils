# Схема util - Огляд можливостей

Схема `util` містить утилітарні функції та процедури для роботи з SQL Server. Це потужна бібліотека інструментів для розробників і адміністраторів баз даних.

## Категорії функціоналу

### 1. DESCRIPTION & MS_DESCRIPTION (15 об'єктів)
Система автоматичного та ручного документування об'єктів бази даних через Extended Properties.

**Автоматичне витягнення описів:**
- `modulesGetDescriptionFromComments` - витягує описи з багаторядкових коментарів
- `modulesGetDescriptionFromCommentsLegacy` - витягує описи зі старого формату
- `stringSplitMultiLineComment` - парсить структуровані коментарі
- `modulesSetDescriptionFromComments` - автоматично встановлює описи
- `modulesSetDescriptionFromCommentsLegacy` - для старого формату

**Ручне встановлення описів (12 процедур):**
- `metadataSetTableDescription` - описи таблиць
- `metadataSetColumnDescription` - описи колонок
- `metadataSetProcedureDescription` - описи процедур
- `metadataSetFunctionDescription` - описи функцій
- `metadataSetViewDescription` - описи представлень
- `metadataSetTriggerDescription` - описи тригерів
- `metadataSetParameterDescription` - описи параметрів
- `metadataSetIndexDescription` - описи індексів
- `metadataSetSchemaDescription` - описи схем
- `metadataSetDataspaceDescription` - описи просторів даних
- `metadataSetFilegroupDescription` - описи файлових груп
- `metadataSetExtendedProperty` - універсальна процедура

**Отримання описів:**
- `metadataGetDescriptions` - отримання описів об'єктів
- `metadataGetExtendedProperiesValues` - читання розширених властивостей

### 2. OBJECTS & METADATA (25+ функцій)
Універсальні функції для роботи з метаданими об'єктів бази даних.

**Основні функції:**
- `metadataGetObjectName` - отримання назви об'єкта за ID
- `metadataGetObjectType` - тип об'єкта за назвою
- `metadataGetObjectsType` - типи кількох об'єктів
- `metadataGetAnyId` - універсальне отримання ID будь-якого об'єкта
- `metadataGetAnyName` - універсальне отримання назви будь-якого об'єкта

**Класифікація об'єктів:**
- `metadataGetClassByName` - код класу за назвою
- `metadataGetClassName` - назва класу за кодом

**Спеціалізовані функції:**
- `metadataGetCertificateName` - імена сертифікатів
- `metadataGetDataspaceId` / `metadataGetDataspaceName` - простори даних
- `metadataGetPartitionFunctionId` / `metadataGetPartitionFunctionName` - функції розділення
- `metadataGetRequiredPermission` - аналіз необхідних прав доступу

### 3. PARAMETERS (6 функцій)
Функції для роботи з параметрами процедур та функцій.

- `metadataGetParameters` - детальна інформація про параметри
- `metadataGetParameterId` - ID параметра за назвою
- `metadataGetParameterName` - назва параметра за ID
- `mcpGetObjectParameters` - параметри для MCP інтеграції

### 4. COLUMNS (8 функцій)
Функції для роботи з колонками таблиць.

- `metadataGetColumns` - детальна інформація про колонки
- `metadataGetColumnId` - ID колонки за назвою
- `metadataGetColumnName` - назва колонки за ID
- `tablesGetIndexedColumns` - аналіз індексованих колонок

### 5. STRING & TEXT PROCESSING (12+ функцій)
Потужні інструменти для обробки тексту та коду SQL.

**Розбиття тексту:**
- `stringSplitToLines` - розбиття тексту на рядки
- `modulesSplitToLines` - розбиття коду модулів на рядки
- `stringSplitMultiLineComment` - парсинг багаторядкових коментарів

**Пошук позицій:**
- `stringFindCommentsPositions` - всі коментарі в тексті
- `stringFindInlineCommentsPositions` - однорядкові коментарі
- `stringFindLinesPositions` - позиції всіх рядків
- `stringFindMultilineCommentsPositions` - багаторядкові коментарі
- `stringGetCreateLineNumber` - рядок з CREATE

**Рекурсивний пошук:**
- `stringRecureSearchForOccurrences` - пошук входжень в тексті
- `stringRecureSearchStartEndPositionsExtended` - пошук блоків

### 6. SCRIPT GENERATION (8+ функцій)
Генерація DDL скриптів для різних об'єктів.

**Скрипти індексів:**
- `indexesGetScript` - DDL для створення індексів
- `indexesGetScriptConventionRename` - скрипти перейменування індексів
- `indexesGetConventionNames` - рекомендовані назви індексів

**Скрипти таблиць:**
- `tablesGetScript` - повний DDL таблиці

**Скрипти об'єктів з залежностями:**
- `objectScriptWithDependencies` - генерація скриптів з урахуванням залежностей

### 7. TEMP TABLES (4 функції)
Автоматичне створення тимчасових таблиць на основі аналізу SQL запитів.

**Inline функції:**
- `stringGetCreateTempScriptInline` - аналіз SQL запиту з поверненням TABLE
- `objectGetCreateTempScriptInline` - для процедур та функцій

**Scalar функції:**
- `stringGetCreateTempScript` - аналіз SQL запиту з поверненням скрипту
- `objectGetCreateTempScript` - для процедур та функцій

### 8. MODULES & CODE ANALYSIS (18+ функцій)
Інструменти для аналізу коду SQL модулів.

**Пошук у модулях:**
- `modulesFindCommentsPositions` - позиції коментарів
- `modulesFindInlineCommentsPositions` - позиції однорядкових коментарів
- `modulesFindMultilineCommentsPositions` - позиції багаторядкових коментарів
- `modulesFindLinesPositions` - позиції рядків
- `modulesFindSimilar` - пошук схожих модулів

**Аналіз модулів:**
- `modulesGetCreateLineNumber` - номер рядка з CREATE
- `modulesGetDescriptionFromComments` - витягування описів з коментарів
- `modulesRecureSearchForOccurrences` - рекурсивний пошук в модулях
- `modulesRecureSearchStartEndPositions` - пошук блоків в модулях

### 9. ERROR HANDLING (3 об'єкти)
Система обробки та логування помилок.

- `errorHandler` - універсальний обробник помилок
- `errorLog` - таблиця для збереження помилок
- `help` - довідкова система по Pure Utils

### 10. EXTENDED EVENTS (XE) (15+ об'єктів)
Система моніторингу через Extended Events.

**XE Сесії:**
- `utilsErrors` - збір критичних помилок
- `utilsModulesUsers` - моніторинг виконання модулів користувачами
- `utilsModulesFaust` - спеціальний моніторинг Faust користувачів
- `utilsModulesSSIS` - відстеження SSIS пакетів

**Функції для читання XE:**
- `xeGetErrors` - читання помилок з XE файлів
- `xeGetTargetFile` - інформація про поточні файли сесій
- `xeGetLogsPath` - генерація шляхів до логів

**Процедури обробки:**
- `xeCopyModulesToTable` - копіювання даних з XE у таблиці

**Таблиці зберігання:**
- `executionModulesUsers` - дані виконання модулів користувачами
- `executionModulesFaust` - дані виконання Faust користувачами
- `executionModulesSSIS` - дані виконання SSIS
- `executionSqlText` - кеш унікальних SQL текстів
- `xeOffsets` - позиції читання XE файлів

### 11. EXTENDED PROPERTIES (12 процедур)
Процедури для роботи з розширеними властивостями об'єктів.

Див. категорію "DESCRIPTION & MS_DESCRIPTION" вище.

### 12. INDEXES (10+ функцій/процедур)
Комплексні інструменти для роботи з індексами.

**Генерація скриптів:**
- `indexesGetScript` - генерація DDL скриптів індексів
- `indexesGetConventionNames` - рекомендовані назви за конвенціями
- `indexesGetScriptConventionRename` - скрипти перейменування
- `indexesSetConventionNames` - процедура перейменування

**Аналіз індексів:**
- `indexesGetMissing` - аналіз відсутніх індексів
- `indexesGetUnused` - пошук невикористовуваних індексів
- `indexesGetDuplicates` - виявлення дублікатів індексів
- `indexesGetSpaceUsed` - використання дискового простору
- `indexesGetSpaceUsedDetailed` - детальна статистика по партиціях

**Метадані індексів:**
- `metadataGetIndexes` - інформація про індекси
- `metadataGetIndexId` - ID індексу
- `metadataGetIndexName` - назва індексу

### 13. TABLES (4+ функції)
Функції для роботи з таблицями.

- `tablesGetScript` - повний DDL скрипт таблиці
- `tablesGetIndexedColumns` - аналіз індексованих колонок
- `tablesGetConstraints` - інформація про обмеження
- `tablesGetDependencies` - залежності таблиці

### 14. EXECUTION MONITORING (8+ функцій/представлень)
Моніторинг виконання запитів та продуктивності.

**Функції моніторингу:**
- `getActiveQueries` - поточні активні запити
- `getLongRunningQueries` - довготривалі операції
- `getBlockedProcesses` - заблоковані процеси
- `myselfActiveIndexCreation` - прогрес створення індексів

**Представлення:**
- `viewExecutionPlans` - плани виконання
- `viewResourceUsage` - використання ресурсів
- `viewQueryStats` - статистика запитів
- `viewExecutionModulesUsers` - статистика виконання модулів

**Процедури:**
- `executionSearchPlanByHandle` - пошук плану за handle
- `executionSearchPlanByObjectName` - пошук плану за назвою об'єкта

### 15. PERMISSIONS (2 функції)
Аналіз дозволів та прав доступу.

- `permissionsGetUserRights` - права конкретного користувача
- `permissionsGetObjectAccess` - доступ до об'єкта
- `metadataGetRequiredPermission` - аналіз необхідних прав

### 16. MCP INTEGRATION (10+ функцій)
Функції для інтеграції з Model Context Protocol.

- `mcpBuildParameterJson` - побудова JSON параметра для MCP
- `mcpBuildToolJson` - побудова JSON tool для MCP
- `mcpGetObjectParameters` - отримання параметрів об'єкта для MCP
- `mcpMapSqlTypeToJsonType` - маппінг SQL типів на JSON типи

## Приклади використання

### Автоматичне документування
```sql
-- Встановити описи з коментарів у коді
EXEC util.modulesSetDescriptionFromComments 'dbo.MyProcedure';

-- Отримати всі описи об'єкта
SELECT * FROM util.metadataGetDescriptions('dbo.Users', NULL);
```

### Робота з індексами
```sql
-- Знайти відсутні індекси
SELECT * FROM util.indexesGetMissing('dbo.Orders')
ORDER BY IndexAdvantage DESC;

-- Перейменувати індекси за конвенціями
EXEC util.indexesSetConventionNames @table = 'dbo.Orders', @output = 1;
```

### Генерація скриптів
```sql
-- Згенерувати DDL таблиці
SELECT createScript FROM util.tablesGetScript('dbo.Users');

-- Створити temp таблицю з результату запиту
DECLARE @script NVARCHAR(MAX) = util.stringGetCreateTempScript(
    'SELECT * FROM dbo.Orders WHERE OrderDate > GETDATE()-30',
    '#RecentOrders',
    NULL
);
EXEC sp_executesql @script;
```

### Обробка помилок
```sql
BEGIN TRY
    -- Ваш код
END TRY
BEGIN CATCH
    EXEC util.errorHandler @attachment = 'Контекст операції';
END CATCH
```

### Аналіз коду
```sql
-- Знайти схожі модулі
SELECT * FROM util.modulesFindSimilar(OBJECT_ID('dbo.MyProc'))
WHERE similarityPercent > 80;

-- Розібрати модуль на рядки
SELECT * FROM util.modulesSplitToLines('dbo.MyProc', 1)
WHERE line LIKE '%SELECT%';
```

## Див. також

- [Повний список об'єктів util](objects-list.md)
- [Детальна документація по кожному об'єкту](detailed/)
- [Документація по схемі mcp](../mcp/README.md)
- [Інструкції по розгортанню](../deploy.md)

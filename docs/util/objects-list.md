# Схема util - Повний список об'єктів

Повний перелік всіх об'єктів схеми `util` з короткими описами, організований за типами.

## Статистика

- **Функції:** 73
- **Процедури:** 21
- **Таблиці:** 9
- **Представлення (Views):** 4
- **Всього:** 107 об'єктів

---

## Функції (Functions)

### Індекси (Indexes)

| Назва | Опис |
|-------|------|
| `indexesGetConventionNames` | Генерує стандартизовані назви індексів відповідно до конвенцій |
| `indexesGetMissing` | Знаходить відсутні індекси на основі рекомендацій SQL Server |
| `indexesGetScript` | Генерує DDL скрипти для створення індексів |
| `indexesGetScriptConventionRename` | Генерує скрипти для перейменування індексів за конвенціями |
| `indexesGetSpaceUsed` | Статистика використання дискового простору індексами |
| `indexesGetSpaceUsedDetailed` | Детальна статистика використання простору по партиціях |
| `indexesGetUnused` | Знаходить невикористовувані індекси |

### Таблиці (Tables)

| Назва | Опис |
|-------|------|
| `tablesGetIndexedColumns` | Інформація про індексовані колонки таблиць |
| `tablesGetScript` | Генерує повний DDL скрипт для створення таблиці |
| `tablesGetUnused` | Знаходить невикористовувані таблиці |

### Партиціонування (Partitioning)

| Назва | Опис |
|-------|------|
| `partitionFunctionsGetScript` | Генерує DDL для partition functions |
| `partitionSchemesGetScript` | Генерує DDL для partition schemes |

### Метадані об'єктів (Object Metadata)

| Назва | Опис |
|-------|------|
| `metadataGetAnyId` | Універсальне отримання ID будь-якого об'єкта |
| `metadataGetAnyName` | Універсальне отримання назви будь-якого об'єкта |
| `metadataGetCertificateName` | Отримує ім'я сертифіката за ID |
| `metadataGetClassByName` | Повертає числовий код класу об'єкта за назвою |
| `metadataGetClassName` | Повертає назву класу об'єкта за кодом |
| `metadataGetObjectName` | Отримує повну назву об'єкта за ID |
| `metadataGetObjectType` | Отримує тип об'єкта за назвою |
| `metadataGetObjectsType` | Інформація про типи кількох об'єктів |

### Колонки (Columns)

| Назва | Опис |
|-------|------|
| `metadataGetColumnId` | Отримує column_id для заданої колонки |
| `metadataGetColumnName` | Отримує ім'я колонки за ID |
| `metadataGetColumns` | Детальна інформація про колонки таблиці |

### Індекси - Метадані (Index Metadata)

| Назва | Опис |
|-------|------|
| `metadataGetIndexId` | Отримує ID індексу |
| `metadataGetIndexName` | Отримує назву індексу за ID |
| `metadataGetIndexes` | Детальна інформація про індекси таблиці |

### Параметри (Parameters)

| Назва | Опис |
|-------|------|
| `metadataGetParameterId` | Отримує ID параметра |
| `metadataGetParameterName` | Отримує назву параметра за ID |
| `metadataGetParameters` | Детальна інформація про параметри процедур/функцій |

### Простори даних (Data Spaces)

| Назва | Опис |
|-------|------|
| `metadataGetDataspaceId` | Отримує ID простору даних |
| `metadataGetDataspaceName` | Отримує назву простору даних за ID |
| `metadataGetPartitionFunctionId` | Отримує ID функції розділення |
| `metadataGetPartitionFunctionName` | Отримує назву функції розділення за ID |

### Описи та властивості (Descriptions & Properties)

| Назва | Опис |
|-------|------|
| `metadataGetDescriptions` | Отримує описи об'єктів з extended properties |
| `metadataGetExtendedProperiesValues` | Отримує значення розширених властивостей |

### Права доступу (Permissions)

| Назва | Опис |
|-------|------|
| `metadataGetRequiredPermission` | Визначає необхідні права доступу для об'єкта |

### Аналіз модулів - Пошук (Module Analysis - Search)

| Назва | Опис |
|-------|------|
| `modulesFindCommentsPositions` | Знаходить позиції всіх коментарів у модулях |
| `modulesFindInlineCommentsPositions` | Знаходить позиції однорядкових коментарів |
| `modulesFindLinesPositions` | Знаходить позиції всіх рядків у модулях |
| `modulesFindMultilineCommentsPositions` | Знаходить позиції багаторядкових коментарів |
| `modulesFindSimilar` | Знаходить схожі SQL модулі |

### Аналіз модулів - Обробка (Module Analysis - Processing)

| Назва | Опис |
|-------|------|
| `modulesGetCreateLineNumber` | Повертає номер рядка з оператором CREATE |
| `modulesGetDescriptionFromComments` | Витягує описи з коментарів модулів |
| `modulesGetDescriptionFromCommentsLegacy` | Витягує описи зі старого формату коментарів |
| `modulesSplitToLines` | Розбиває модулі на окремі рядки |

### Аналіз модулів - Рекурсивний пошук (Module Analysis - Recursive Search)

| Назва | Опис |
|-------|------|
| `modulesRecureSearchForOccurrences` | Рекурсивно шукає входження в модулях |
| `modulesRecureSearchInvalidReferences` | Знаходить невалідні посилання в модулях |
| `modulesRecureSearchStartEndPositions` | Рекурсивний пошук блоків у модулях |
| `modulesRecureSearchStartEndPositionsExtended` | Розширений рекурсивний пошук блоків |

### Обробка тексту - Пошук (String Processing - Search)

| Назва | Опис |
|-------|------|
| `stringFindCommentsPositions` | Знаходить позиції всіх коментарів у тексті |
| `stringFindInlineCommentsPositions` | Знаходить позиції однорядкових коментарів |
| `stringFindLinesPositions` | Знаходить позиції всіх рядків у тексті |
| `stringFindMultilineCommentsPositions` | Знаходить позиції багаторядкових коментарів |

### Обробка тексту - Розбиття (String Processing - Splitting)

| Назва | Опис |
|-------|------|
| `stringGetCreateLineNumber` | Знаходить номер рядка з інструкцією CREATE |
| `stringSplitMultiLineComment` | Розбирає багаторядковий коментар на секції |
| `stringSplitToLines` | Розбиває текст на окремі рядки |

### Обробка тексту - Рекурсивний пошук (String Processing - Recursive)

| Назва | Опис |
|-------|------|
| `stringRecureSearchForOccurrences` | Рекурсивно шукає входження в тексті |
| `stringRecureSearchStartEndPositionsExtended` | Розширений рекурсивний пошук блоків |

### Тимчасові таблиці (Temporary Tables)

| Назва | Опис |
|-------|------|
| `stringGetCreateTempScript` | Генерує CREATE TABLE скрипт з SQL запиту (scalar) |
| `stringGetCreateTempScriptInline` | Генерує CREATE TABLE скрипт з SQL запиту (table) |

### Extended Events (XE)

| Назва | Опис |
|-------|------|
| `xeGetErrors` | Читає помилки з Extended Events файлів |
| `xeGetLogsPath` | Формує шлях до директорії XE логів |
| `xeGetModules` | Отримує дані про виконання модулів з XE |
| `xeGetTargetFile` | Інформація про поточні файли XE сесій |

### Історія та аудит (History & Audit)

| Назва | Опис |
|-------|------|
| `myselfGetHistory` | Історія дій поточного користувача |
| `objectGetHistory` | Історія змін об'єкта |

### Моніторинг виконання (Execution Monitoring)

| Назва | Опис |
|-------|------|
| `myselfActiveIndexCreation` | Відстежує прогрес створення індексів |

### Jobs (SQL Agent)

| Назва | Опис |
|-------|------|
| `jobsGetNameByAppName` | Отримує назву job за назвою додатку (scalar) |
| `jobsGetNameByAppNameInline` | Отримує назву job за назвою додатку (table) |

### MCP Integration

| Назва | Опис |
|-------|------|
| `mcpBuildParameterJson` | Побудова JSON параметра для MCP |
| `mcpBuildToolJson` | Побудова JSON tool для MCP |
| `mcpGetObjectParameters` | Отримання параметрів об'єкта для MCP |
| `mcpMapSqlTypeToJsonType` | Маппінг SQL типів на JSON типи |

---

## Процедури (Procedures)

### Описи об'єктів (Object Descriptions)

| Назва | Опис |
|-------|------|
| `metadataSetColumnDescription` | Встановлює опис для колонки |
| `metadataSetDataspaceDescription` | Встановлює опис для простору даних |
| `metadataSetExtendedProperty` | Універсальна процедура для встановлення властивостей |
| `metadataSetFilegroupDescription` | Встановлює опис для файлової групи |
| `metadataSetFunctionDescription` | Встановлює опис для функції |
| `metadataSetIndexDescription` | Встановлює опис для індексу |
| `metadataSetParameterDescription` | Встановлює опис для параметра |
| `metadataSetProcedureDescription` | Встановлює опис для процедури |
| `metadataSetSchemaDescription` | Встановлює опис для схеми |
| `metadataSetTableDescription` | Встановлює опис для таблиці |
| `metadataSetTriggerDescription` | Встановлює опис для тригера |
| `metadataSetViewDescription` | Встановлює опис для представлення |

### Автоматичне документування (Auto Documentation)

| Назва | Опис |
|-------|------|
| `modulesSetDescriptionFromComments` | Автоматично встановлює описи з коментарів |
| `modulesSetDescriptionFromCommentsLegacy` | Встановлює описи зі старого формату коментарів |

### Індекси - Управління (Index Management)

| Назва | Опис |
|-------|------|
| `indexesSetConventionNames` | Перейменовує індекси за стандартними конвенціями |

### Генерація скриптів (Script Generation)

| Назва | Опис |
|-------|------|
| `objectScriptWithDependencies` | Генерує скрипт об'єкта з усіма залежностями |

### Обробка помилок (Error Handling)

| Назва | Опис |
|-------|------|
| `errorHandler` | Універсальний обробник помилок з логуванням |

### Extended Events (XE)

| Назва | Опис |
|-------|------|
| `xeCopyModulesToTable` | Копіює дані з XE файлів у таблиці |

### Моніторинг виконання (Execution Monitoring)

| Назва | Опис |
|-------|------|
| `executionSearchPlanByHandle` | Пошук плану виконання за handle |
| `executionSearchPlanByObjectName` | Пошук плану виконання за назвою об'єкта |

### Довідка (Help)

| Назва | Опис |
|-------|------|
| `help` | Довідкова система по Pure Utils |

---

## Таблиці (Tables)

| Назва | Опис |
|-------|------|
| `errorLog` | Журнал помилок системи |
| `executionModulesFaust` | Дані виконання модулів Faust користувачами |
| `executionModulesSSIS` | Дані виконання SSIS пакетів |
| `executionModulesUsers` | Дані виконання модулів користувачами |
| `executionSqlText` | Кеш унікальних SQL текстів |
| `modulesInvalidReferences` | Невалідні посилання в модулях |
| `modulesSimilarity` | Схожість між модулями |
| `xeOffsets` | Позиції читання Extended Events файлів |
| *(+1 інша таблиця)* | |

---

## Представлення (Views)

| Назва | Опис |
|-------|------|
| `viewErrorLog` | Форматований перегляд журналу помилок |
| `viewExecutionModulesFaust` | Статистика виконання модулів Faust |
| `viewExecutionModulesSSIS` | Статистика виконання SSIS |
| `viewExecutionModulesUsers` | Статистика виконання модулів користувачами |

---

## Див. також

- [Огляд можливостей util](README.md)
- [Детальна документація по кожному об'єкту](detailed/)
- [Документація по схемі mcp](../mcp/README.md)
- [Інструкції по розгортанню](../deploy.md)

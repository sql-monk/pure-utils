## Основні компоненти проекту:

### 🔧 MCP інтеграція (Model Context Protocol)
Два .NET 8 сервери, які реалізують протокол для взаємодії з SQL Server через AI-асистентів:

- **PureSqlsMcp** - динамічний сервер для отримання метаданих БД:
  - Список баз даних, таблиць, представлень, процедур, функцій
  - Детальна інформація про структуру таблиць (колонки, індекси, партиції)
  - DDL історія змін об'єктів з фільтрацією за часом/користувачем/типом події
  - Генерація скриптів об'єктів з усіма залежностями

- **PlanSqlsMcp** - сервер для аналізу планів виконання:
  - Отримання estimated execution plans у форматі XML
  - Автоматичне очищення запитів від службових команд SHOWPLAN
  - Підтримка батчів та складних запитів

### 📊 Схема util - основна бібліотека (100+ об'єктів)

**Управління метаданими:**
- Функції для роботи з розширеними властивостями (MS_Description)
- Автоматичне витягування описів з коментарів у коді
- Універсальні функції для отримання ID/назв будь-яких об'єктів БД
- Процедури встановлення описів для всіх типів об'єктів

**Аналіз та оптимізація індексів:**
- [`indexesGetConventionNames`](util/Functions/indexesGetConventionNames.sql) - генерація стандартизованих назв (PK_, CI_, IX_ з суфіксами _INC, _FLT, _UQ)
- [`indexesGetMissing`](util/Functions/indexesGetMissing.sql) - пошук відсутніх індексів з розрахунком переваги створення
- [`indexesGetUnused`](util/Functions/indexesGetUnused.sql) - виявлення невикористовуваних індексів
- [`indexesGetSpaceUsed`](util/Functions/indexesGetSpaceUsed.sql) - детальна статистика використання дискового простору
- Автоматичне перейменування індексів за конвенціями

**Робота з SQL кодом:**
- Парсинг та аналіз модулів (процедур, функцій, тригерів)
- Рекурсивний пошук входжень у визначеннях об'єктів
- Виділення коментарів (однорядкових/багаторядкових)
- Розбиття коду на рядки з нумерацією
- Пошук схожих модулів через токенізацію та хешування

**Extended Events моніторинг:**
- Готові XE сесії для відстеження помилок, debug подій, активності користувачів
- Функції читання даних з XE файлів ([`xeGetErrors`](util/Functions/xeGetErrors.sql), [`xeGetDebug`](util/Functions/xeGetDebug.sql), [`xeGetModules`](util/Functions/xeGetModules.sql))
- Таблиці для довготривалого зберігання подій з оптимізованими індексами
- Відстеження позицій читання для інкрементального завантаження

**Генерація DDL скриптів:**
- [`tablesGetScript`](util/Functions/tablesGetScript.sql) - повний DDL таблиць з усіма обмеженнями
- [`objesctsScriptWithDependencies`](util/Procedures/objesctsScriptWithDependencies.sql) - рекурсивна генерація з урахуванням залежностей
- Підтримка cross-database залежностей та синонімів
- Правильний порядок створення об'єктів (topological sort)

### 🔌 Схема mcp - адаптери для AI-інтеграції

Процедури-обгортки, які формують JSON відповіді для MCP протоколу:
- [`GetDatabases`](mcp/Procedures/GetDatabases.sql), [`GetTables`](mcp/Procedures/GetTables.sql), [`GetViews`](mcp/Procedures/GetViews.sql), [`GetProcedures`](mcp/Procedures/GetProcedures.sql), [`GetFunctions`](mcp/Procedures/GetFunctions.sql) - списки об'єктів
- [`GetTableInfo`](mcp/Procedures/GetTableInfo.sql) - детальна структура таблиці з колонками та індексами
- [`GetDdlHistory`](mcp/Procedures/GetDdlHistory.sql) - історія DDL операцій з можливістю фільтрації
- [`ScriptObjectAndReferences`](mcp/Procedures/ScriptObjectAndReferences.sql) - генерація DDL з усіма залежностями
- [`FindLastModulePlan`](mcp/Procedures/FindLastModulePlan.sql) - пошук останнього execution plan для об'єкта

### 🛠️ Допоміжні компоненти

**PowerShell скрипти:**
- [`deployUtil.ps1`](deployUtil.ps1) - розгортання об'єктів з автоматичним вирішенням залежностей
- Build скрипти для компіляції MCP серверів у self-contained executables ([`PureSqlsMcp/build.ps1`](PureSqlsMcp/build.ps1), [`PlanSqlsMcp/build.ps1`](PlanSqlsMcp/build.ps1))

**Таблиці для аудиту та моніторингу:**
- [`eventsNotifications`](util/Tables/eventsNotifications.sql) - журнал DDL подій
- [`errorLog`](util/Tables/errorLog.sql) - централізоване логування помилок
- [`executionModulesUsers`](util/Tables/executionModulesUsers.sql), [`executionModulesSSIS`](util/Tables/executionModulesSSIS.sql) - історія виконання модулів по користувачах/SSIS
- [`executionSqlText`](util/Tables/executionSqlText.sql) - дедуплікований склад SQL текстів

**Утилітарні функції:**
- [`stringGetCreateTempScript`](util/Functions/stringGetCreateTempScript.sql) - генерація CREATE TABLE з аналізу SELECT запиту
- [`stringSplitMultiLineComment`](util/Functions/stringSplitMultiLineComment.sql) - розбір структурованих коментарів документації
- [`jobsGetNameByAppName`](util/Functions/jobsGetNameByAppName.sql) - визначення SQL Agent job за ApplicationName
- [`partitionFunctionsGetScript`](util/Functions/partitionFunctionsGetScript.sql) - генерація DDL для partition functions/schemes

Проект дотримується чітких конвенцій найменування, має детальну документацію в коментарях кожного об'єкта та орієнтований на автоматизацію рутинних задач адміністрування великих DWH з можливістю інтеграції з AI-асистентами для інтелектуального аналізу та оптимізації.

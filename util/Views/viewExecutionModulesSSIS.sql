/*
# Description
Представлення для відображення даних виконання SSIS модулів із таблиці executionModulesSSIS з приєднаними SQL текстами.
Автоматично конвертує час подій у локальний часовий пояс та надає зручний доступ до SQL коду.

# Columns
- xeId INT - унікальний ідентифікатор запису
- EventName NVARCHAR(50) - назва XE події
- EventTime DATETIME - час події (конвертований у локальний час)
- hb VARBINARY(32) - hash bucket
- statmentText NVARCHAR(MAX) - SQL текст інструкції
- sqlText NVARCHAR(MAX) - повний SQL текст
- StatementHash VARBINARY(32) - хеш інструкції
- SqlTextHash VARBINARY(32) - хеш SQL тексту
- ObjectName NVARCHAR(128) - назва SSIS об'єкта
- LineNumber INT - номер рядка в модулі
- DatabaseName NVARCHAR(128) - назва бази даних
- DatabaseId SMALLINT - ідентифікатор бази даних
- SessionId INT - ідентифікатор сесії
- ClientHostname NVARCHAR(128) - ім'я хоста клієнта
- ClientAppName NVARCHAR(256) - назва SSIS програми
- ServerPrincipalName NVARCHAR(128) - ім'я користувача сервера
- Duration BIGINT - тривалість виконання
- SourceDatabaseId INT - ідентифікатор вихідної бази даних
- ObjectId BIGINT - ідентифікатор об'єкта
- Offset INT - початковий зсув
- OffsetEnd INT - кінцевий зсув
- ObjectType NVARCHAR(10) - тип SSIS об'єкта
- ModuleRowCount BIGINT - кількість рядків модуля
- PlanHandle VARBINARY(64) - дескриптор плану виконання
- TaskTime BIGINT - час виконання задачі
*/
CREATE OR ALTER VIEW util.viewExecutionModulesSSIS
AS
SELECT
	f.xeId,
	f.EventName,
	DATEADD(MINUTE,DATEDIFF(MINUTE,GETUTCDATE(),GETDATE()),f.EventTime) EventTime,
	f.hb,
	st.sqlText statmentText,
	sqltext.sqlText,
	f.StatementHash,
	f.SqlTextHash,
	f.ObjectName,
	f.LineNumber,
	f.DatabaseName,
	f.DatabaseId,
	f.SessionId,
	f.ClientHostname,
	f.ClientAppName,
	f.ServerPrincipalName,
	f.Duration,
	f.SourceDatabaseId,
	f.ObjectId,
	f.Offset,
	f.OffsetEnd,
	f.ObjectType,
	f.ModuleRowCount,
	f.PlanHandle,
	f.TaskTime
FROM msdb.util.executionModulesSSIS f(NOLOCK)
	LEFT JOIN util.executionSqlText st(NOLOCK)ON f.StatementHash = st.sqlHash
	LEFT JOIN util.executionSqlText sqltext(NOLOCK)ON sqltext.sqlHash = f.SqlTextHash;
GO
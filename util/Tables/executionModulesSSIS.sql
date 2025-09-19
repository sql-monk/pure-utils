/*
# Description
Таблиця для зберігання подій виконання модулів SSIS із XE сесій.
Містить інформацію про виконання пакетів, задач та компонентів SQL Server Integration Services.

# Columns
- xeId INT IDENTITY - унікальний ідентифікатор запису
- EventName NVARCHAR(50) - назва XE події
- EventTime DATETIME2(7) - час події
- hb VARBINARY(32) - hash bucket
- ObjectName NVARCHAR(128) - назва об'єкта SSIS
- LineNumber INT - номер рядка в модулі (якщо застосовно)
- DatabaseName NVARCHAR(128) - назва бази даних
- DatabaseId SMALLINT - ідентифікатор бази даних
- SessionId INT - ідентифікатор сесії
- ClientHostname NVARCHAR(128) - ім'я хоста клієнта
- ClientAppName NVARCHAR(256) - назва SSIS програми
- ServerPrincipalName NVARCHAR(128) - ім'я користувача сервера
- StatementHash VARBINARY(32) - хеш інструкції
- Duration BIGINT - тривалість виконання
- SourceDatabaseId INT - ідентифікатор вихідної бази даних
- ObjectId BIGINT - ідентифікатор об'єкта
- Offset INT - початковий зсув
- OffsetEnd INT - кінцевий зсув
- ObjectType NVARCHAR(10) - тип об'єкта SSIS
- ModuleRowCount BIGINT - кількість рядків модуля
- SqlTextHash VARBINARY(32) - хеш SQL тексту
- PlanHandle VARBINARY(64) - дескриптор плану виконання
- TaskTime BIGINT - час виконання задачі
*/
CREATE TABLE util.xeModulesSSIS (
	xeId INT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
	EventName NVARCHAR(50) NOT NULL,
	EventTime DATETIME2(7) NOT NULL,
	hb VARBINARY(32) NOT NULL,
	ObjectName NVARCHAR(128) NOT NULL,
	LineNumber INT NULL,
	DatabaseName NVARCHAR(128) NULL,
	DatabaseId SMALLINT NULL,
	SessionId INT NULL,
	ClientHostname NVARCHAR(128) NULL,
	ClientAppName NVARCHAR(256) NULL,
	ServerPrincipalName NVARCHAR(128) NULL,
	StatementHash VARBINARY(32),
	Duration BIGINT NULL,
	SourceDatabaseId INT NULL,
	ObjectId BIGINT NULL,
	Offset INT NULL,
	OffsetEnd INT NULL,
	ObjectType NVARCHAR(10) NULL,
	ModuleRowCount BIGINT NULL,
	SqlTextHash VARBINARY(32),
	PlanHandle VARBINARY(64) NULL,
	TaskTime BIGINT NULL
) ON util
WITH (DATA_COMPRESSION = PAGE);


CREATE NONCLUSTERED INDEX ix_EventTime_EventName_hb
ON util.xeModulesSSIS(EventTime ASC, EventName ASC, hb ASC)
WITH(ONLINE = ON, SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE)
ON util;


CREATE NONCLUSTERED INDEX ix_ObjectName_DatabaseName
ON util.xeModulesSSIS(ObjectName ASC, DatabaseName ASC)
INCLUDE(EventTime, Duration, ModuleRowCount)
WITH(ONLINE = ON, SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE)
ON util;
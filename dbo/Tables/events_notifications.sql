/*
# Description
Таблиця для зберігання повідомлень про системні події (DDL) в базі даних.
Використовується для моніторингу та аудиту змін структури бази даних.

# Columns
- event_type NVARCHAR(36) - тип події (CREATE, ALTER, DROP та інші)
- post_time DATETIME - час виникнення події
- spid INT - ідентифікатор процесу
- server_name NVARCHAR(128) - назва сервера
- login_name NVARCHAR(128) - логін користувача
- user_name NVARCHAR(128) - ім'я користувача
- role_name NVARCHAR(128) - роль користувача
- database_name NVARCHAR(128) - назва бази даних
- schema_name NVARCHAR(128) - назва схеми
- object_name NVARCHAR(128) - назва об'єкта
- object_type NVARCHAR(128) - тип об'єкта
- login_type NVARCHAR(128) - тип входу
- target_object_name NVARCHAR(128) - назва цільового об'єкта
- target_object_type NVARCHAR(128) - тип цільового об'єкта
- tsql NVARCHAR(MAX) - текст SQL команди
- client_app_name NVARCHAR(128) - назва клієнтського додатка
- client_host_name NVARCHAR(128) - ім'я клієнтського хоста
*/
CREATE TABLE [dbo].[events_notifications] (
 [event_type] NVARCHAR (36) DEFAULT ('') NULL,
 [post_time] DATETIME NULL,
 [spid] INT DEFAULT ((0)) NULL,
 [server_name] NVARCHAR (128) NULL,
 [login_name] NVARCHAR (128) DEFAULT ('') NULL,
 [user_name] NVARCHAR (128) DEFAULT ('') NULL,
 [role_name] NVARCHAR (128) DEFAULT ('') NULL,
 [database_name] NVARCHAR (128) DEFAULT ('') NULL,
 [schema_name] NVARCHAR (128) DEFAULT ('') NULL,
 [object_name] NVARCHAR (128) DEFAULT ('') NULL,
 [object_type] NVARCHAR (128) DEFAULT ('') NULL,
 [login_type] NVARCHAR (128) DEFAULT ('') NULL,
 [target_object_name] NVARCHAR (128) DEFAULT ('') NULL,
 [target_object_type] NVARCHAR (128) DEFAULT ('') NULL,
 [property_name] NVARCHAR (128) DEFAULT ('') NULL,
 [property_value] NVARCHAR (128) DEFAULT ('') NULL,
 [parameters] XML NULL,
 [tsql_command] NVARCHAR (MAX) NULL
);
GO

CREATE NONCLUSTERED INDEX [ix_object_name_ok]
 ON [dbo].[events_notifications]([object_name] ASC) WITH (DATA_COMPRESSION = PAGE);
GO

CREATE CLUSTERED INDEX [ci_events_notifications]
 ON [dbo].[events_notifications]([event_type] ASC, [post_time] ASC) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE);
GO

CREATE NONCLUSTERED INDEX [ix_dt]
 ON [dbo].[events_notifications]([post_time] ASC) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE);
GO
 
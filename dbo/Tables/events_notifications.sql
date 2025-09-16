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
 
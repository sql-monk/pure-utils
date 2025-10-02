CREATE TABLE util.eventsNotifications (
	eventType NVARCHAR(36) NULL,
	postTime DATETIME NULL,
	spid INT NULL,
	serverName NVARCHAR(128) NULL,
	loginName NVARCHAR(128) NULL,
	userName NVARCHAR(128) NULL,
	roleName NVARCHAR(128) NULL,
	databaseName NVARCHAR(128) NULL,
	schemaName NVARCHAR(128) NULL,
	objectName NVARCHAR(128) NULL,
	objectType NVARCHAR(128) NULL,
	loginType NVARCHAR(128) NULL,
	targetObjectName NVARCHAR(128) NULL,
	targetObjectType NVARCHAR(128) NULL,
	propertyName NVARCHAR(128) NULL,
	propertyValue NVARCHAR(128) NULL,
	parameters XML NULL,
	tsqlCommand NVARCHAR(MAX) NULL
) ON util TEXTIMAGE_ON util
WITH (DATA_COMPRESSION = PAGE);
GO
 
CREATE CLUSTERED INDEX ci_events_notifications
ON util.eventsNotifications(postTime ASC, eventType ASC)
WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON,
	FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE
)
ON util;
GO
 
CREATE NONCLUSTERED INDEX ix_object_name
ON util.eventsNotifications(objectName ASC)
WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON,
	OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE
)
ON util;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT('')FOR eventType;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT((0))FOR spid;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT('')FOR loginName;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT('')FOR userName;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT('')FOR roleName;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT('')FOR databaseName;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT('')FOR schemaName;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT('')FOR objectName;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT('')FOR objectType;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT('')FOR loginType;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT('')FOR targetObjectName;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT('')FOR targetObjectType;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT('')FOR propertyName;
GO

ALTER TABLE util.eventsNotifications ADD DEFAULT('')FOR propertyValue;
GO



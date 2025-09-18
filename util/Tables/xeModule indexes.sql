CREATE NONCLUSTERED INDEX ix_EventTime_EventName_hb
ON util.xeModulesUsers(EventTime ASC, EventName ASC, hb ASC)
WITH(ONLINE = ON, SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE)
ON util;

CREATE NONCLUSTERED INDEX ix_EventTime_EventName_hb
ON util.xeModulesSSIS(EventTime ASC, EventName ASC, hb ASC)
WITH(ONLINE = ON, SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE)
ON util;

CREATE NONCLUSTERED INDEX ix_EventTime_EventName_hb
ON util.xeModulesFaust(EventTime ASC, EventName ASC, hb ASC)
WITH(ONLINE = ON, SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE)
ON util;


CREATE NONCLUSTERED INDEX ix_objectName_hostname
ON util.xeModulesFaust(ObjectName ASC, ClientHostname ASC)
INCLUDE(EventTime, Duration, ModuleRowCount)
WITH(ONLINE = ON, SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE)
ON util;


CREATE NONCLUSTERED INDEX ix_sessionid ON util.xeModulesUsers(SessionId)WITH(ONLINE = ON, SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE)ON util;


CREATE NONCLUSTERED INDEX ix_ServerPrincipalName_ObjectName
ON util.xeModulesUsers(
	ServerPrincipalName ASC,
	ObjectName ASC,
	DatabaseName ASC
)
INCLUDE(EventTime, Duration, ModuleRowCount)
WITH(ONLINE = ON, SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE)
ON util;



CREATE NONCLUSTERED INDEX ix_ObjectName_DatabaseName
ON util.xeModulesSSIS(ObjectName ASC, DatabaseName ASC)
INCLUDE(EventTime, Duration, ModuleRowCount)
WITH(ONLINE = ON, SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE)
ON util;
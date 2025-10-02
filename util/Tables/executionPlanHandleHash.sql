CREATE TABLE util.executionPlanHandleHash (
	planHandle VARBINARY(64),
	planHash BINARY(8),
	PRIMARY KEY(planHandle, planHash)
	WITH(DATA_COMPRESSION = PAGE)ON util
);
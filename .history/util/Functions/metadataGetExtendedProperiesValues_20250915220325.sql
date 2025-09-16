CREATE FUNCTION [util].[metadataGetExtendedProperiesValues](@majorId INT = NULL, @minorId SMALLINT = NULL, @property NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	SELECT
		ep.major_id Id,
		ep.class,
		util.metadataGetAnyName(ep.major_id, ep.minor_id, ep.class) name,
		ep.name propertyName,
		CONVERT(NVARCHAR(MAX), ep.value) propertyValue,
		CASE
			WHEN ep.class = 1 AND ep.minor_id = 0 THEN objs.objectType
			ELSE util.metadataGetClassName(ep.class)
		END typeDesc
	FROM sys.extended_properties ep (NOLOCK)
		OUTER APPLY metadataGetObjectsType(ep.major_id) objs
		OUTER APPLY(SELECT p.name FROM sys.parameters p (NOLOCK) WHERE ep.major_id = p.object_id AND ep.minor_id = p.parameter_id) params
		OUTER APPLY(SELECT c.name FROM sys.columns c (NOLOCK) WHERE ep.major_id = c.object_id AND ep.minor_id = c.column_id) cols
		OUTER APPLY(SELECT ix.name FROM sys.indexes ix (NOLOCK) WHERE ep.major_id = ix.object_id AND ep.minor_id = ix.index_id) idx
		OUTER APPLY(SELECT pf.name FROM sys.partition_functions pf (NOLOCK) WHERE ep.major_id = pf.function_id) partfunc
	WHERE ISNULL(@majorId, ep.major_id) = ep.major_id 
		AND ISNULL(@minorId, ep.minor_id) = ep.minor_id
		AND ISNULL(@property, ep.name) = ep.name
);
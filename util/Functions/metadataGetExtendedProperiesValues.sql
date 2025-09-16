CREATE FUNCTION util.metadataGetExtendedProperiesValues(@major NVARCHAR(128) = NULL, @minor NVARCHAR(128) = NULL, @property NVARCHAR(128) = NULL)
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
			WHEN ep.class = 1 AND ep.minor_id = 0 THEN util.metadataGetObjectType(ep.major_id)
			WHEN ep.class = 1 AND ep.minor_id > 0 THEN 'COLUMN'
			ELSE util.metadataGetClassName(ep.class)
		END typeDesc
	FROM sys.extended_properties ep(NOLOCK)
	WHERE
		(@property IS NULL OR ep.name = @property)
		AND (@major IS NULL OR ep.major_id = ISNULL(TRY_CONVERT(INT, @major), OBJECT_ID(@major)))
		AND (
			@minor IS NULL OR ep.minor_id = ISNULL(TRY_CONVERT(INT, @minor),
																				CASE ep.class
																					WHEN 1 THEN util.metadataGetColumnId(ep.major_id, @minor)
																					WHEN 2 THEN util.metadataGetIndexId(ep.major_id, @minor)
																					WHEN 7 THEN util.metadataGetParameterId(ep.major_id, @minor)
																				END
																			)
		)
);
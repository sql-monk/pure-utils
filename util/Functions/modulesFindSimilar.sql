/*
# Description
��������� ���� SQL ����� � ��� ����� �� ����� ������ �� ����.
����������� �������� ����������� ������, ���������� �� ��������� ��� ��������� �������� �� ��������.

# Parameters
@objectId INT = NULL - ������������� ��'���� ��� ���������

# Returns
TABLE - ������� ������� � ���������:
- objectId INT - ������������� ������������ ��'����
- similarObjectId INT - ������������� ������� ��'����  
- similarityPercent FLOAT - ������� ������� �� ��'������

# Usage
SELECT * FROM util.modulesFindSimilar(NULL);
-- ������ �� ���� ����� � ��� �����
*/
CREATE FUNCTION util.modulesFindSimilar(@objectId INT = NULL)
RETURNS TABLE
AS
RETURN(
	WITH cteNormalizedModules AS (
		SELECT
			m.object_id objectId,
			-- ���������� �����: �������� �� ����������� �� ������
			REPLACE(
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
								REPLACE(
									REPLACE(
										REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(m.definition, CHAR(13) + CHAR(10), CHAR(32)), CHAR(13), CHAR(32)), CHAR(10), CHAR(32)), CHAR(9), CHAR(32)),
											'<>',
											CHAR(32)
										),
										'+',
										CHAR(32)
									),
									'-',
									CHAR(32)
								),
								'*',
								CHAR(32)
							),
							'/',
							CHAR(32)
						),
						'=',
						CHAR(32)
					),
					',',
					CHAR(32)
				),
				'  ',
				' '
			) -- ��������� ������� ������ �� ���������
			normalizedText
		FROM sys.sql_modules m
		WHERE m.definition IS NOT NULL
	),
	cteTokenizedModules AS (
		SELECT
			cteNormalizedModules.objectId,
			-- ��������� ������������� ����� �� �����, ��������� ������
			TRIM(value) token,
			ROW_NUMBER() OVER (PARTITION BY cteNormalizedModules.objectId ORDER BY(SELECT NULL)) tokenPosition
		FROM cteNormalizedModules
			CROSS APPLY STRING_SPLIT(cteNormalizedModules.normalizedText, ' ')
		WHERE TRIM(value) <> '' AND LEN(TRIM(value)) > 0
	),
	cteTokenGroups AS (
		SELECT
			cteTokenizedModules.objectId,
			-- ������� �� 7 ������
			STRING_AGG(cteTokenizedModules.token, ' ') WITHIN GROUP(ORDER BY cteTokenizedModules.tokenPosition) tokenGroup
		FROM cteTokenizedModules
		GROUP BY cteTokenizedModules.objectId,
			(cteTokenizedModules.tokenPosition - 1) / 7
	--HAVING COUNT(*) = 7 -- ������ ����� ���� ����� � 7 ������
	),
	cteHash AS (
		SELECT �.objectId, HASHBYTES('SHA1', �.tokenGroup) hb, COUNT(*) OVER (PARTITION BY �.objectId) / 100.0 p FROM cteTokenGroups �
	)
	SELECT
		a.objectId objectId,
		b.objectId similarObjectId,
		COUNT_BIG(DISTINCT a.hb) / a.p similarityPercent
	FROM cteHash a
		JOIN cteHash b ON b.objectId <> a.objectId AND b.p <= a.p AND b.hb = a.hb
	WHERE (@objectId IS NULL OR a.objectId = @objectId)
	GROUP BY a.objectId,
		a.p,
		b.objectId
);
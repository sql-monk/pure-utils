/*
# Description
Знаходить схожі SQL модулі в базі даних на основі аналізу їх коду.
Використовує алгоритм нормалізації тексту, токенізації та хешування для порівняння подібності між модулями.

# Parameters
@objectId INT = NULL - ідентифікатор об'єкта для порівняння

# Returns
TABLE - Повертає таблицю з колонками:
- objectId INT - ідентифікатор оригінального об'єкта
- similarObjectId INT - ідентифікатор схожого об'єкта  
- similarityPercent FLOAT - відсоток схожості між об'єктами

# Usage
SELECT * FROM util.modulesFindSimilar(NULL);
-- Знайти всі схожі модулі в базі даних
*/
CREATE FUNCTION util.modulesFindSimilar(@objectId INT = NULL)
RETURNS TABLE
AS
RETURN(
	WITH cteNormalizedModules AS (
		SELECT
			m.object_id objectId,
			-- Нормалізуємо текст: замінюємо всі спецсимволи на пробіли
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
			) -- Приводимо множинні пробіли до одинарних
			normalizedText
		FROM sys.sql_modules m
		WHERE m.definition IS NOT NULL
	),
	cteTokenizedModules AS (
		SELECT
			cteNormalizedModules.objectId,
			-- Розбиваємо нормалізований текст на слова, виключаємо порожні
			TRIM(value) token,
			ROW_NUMBER() OVER (PARTITION BY cteNormalizedModules.objectId ORDER BY(SELECT NULL)) tokenPosition
		FROM cteNormalizedModules
			CROSS APPLY STRING_SPLIT(cteNormalizedModules.normalizedText, ' ')
		WHERE TRIM(value) <> '' AND LEN(TRIM(value)) > 0
	),
	cteTokenGroups AS (
		SELECT
			cteTokenizedModules.objectId,
			-- Групуємо по 7 токенів
			STRING_AGG(cteTokenizedModules.token, ' ') WITHIN GROUP(ORDER BY cteTokenizedModules.tokenPosition) tokenGroup
		FROM cteTokenizedModules
		GROUP BY cteTokenizedModules.objectId,
			(cteTokenizedModules.tokenPosition - 1) / 7
	--HAVING COUNT(*) = 7 -- Беремо тільки повні групи з 7 токенів
	),
	cteHash AS (
		SELECT с.objectId, HASHBYTES('SHA1', с.tokenGroup) hb, COUNT(*) OVER (PARTITION BY с.objectId) / 100.0 p FROM cteTokenGroups с
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
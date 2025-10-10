/*
# Description
Процедура довідки, яка виводить інформацію про доступні об'єкти в схемі util.
Показує список процедур, функцій та їх описи з розширених властивостей.

# Parameters
@keyword sysname = NULL - ключове слово для фільтрації результатів (NULL = всі об'єкти)
*/
CREATE OR ALTER PROCEDURE util.help
	@keyword SYSNAME = NULL
AS
BEGIN

	SET NOCOUNT ON;
	DECLARE @crlf VARCHAR(2) = CHAR(13) + CHAR(10);
	DECLARE @help NVARCHAR(MAX) = N'util.help
--OR
util.help keyword' + @crlf + @crlf;

	PRINT @help;


	SELECT @help = N'';
	DECLARE
		@typeDesc SYSNAME,
		@name NVARCHAR(128),
		@descr NVARCHAR(MAX);

	DECLARE mcur CURSOR STATIC LOCAL FORWARD_ONLY READ_ONLY FOR
	SELECT
		descr.typeDesc,
		descr.name,
		CONCAT(@crlf+params.paramsDescription + @crlf + @crlf, descr.description) descr
	FROM sys.objects o
		OUTER APPLY util.metadataGetDescriptions(o.object_id, DEFAULT) descr
		OUTER APPLY(
		SELECT
			o.object_id,
			STRING_AGG('	* ' + descr.description, @crlf) paramsDescription
		FROM util.metadataGetDescriptions(o.object_id, DEFAULT) descr
		WHERE
			o.schema_id = SCHEMA_ID('util') AND (descr.typeDesc IN ('parameter', 'column'))
	) params
	WHERE
		o.schema_id = SCHEMA_ID('util') AND (descr.typeDesc NOT IN ('parameter', 'column')) AND (@keyword IS NULL OR (descr.name LIKE '%' + @keyword + '%'))
	ORDER BY
		descr.typeDesc DESC,
		descr.name;

	DECLARE @lastCat SYSNAME = '';
	OPEN mcur;
	FETCH NEXT FROM mcur
	INTO
		@typeDesc,
		@name,
		@descr;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @help = CONCAT('## *', @typeDesc, '* ', REPLACE(REPLACE(@name, '[util].[', ''), ']', ''), ';', @crlf, @descr, @crlf);
		PRINT @help;

		FETCH NEXT FROM mcur
		INTO
			@typeDesc,
			@name,
			@descr;
	END;
	CLOSE mcur;
	DEALLOCATE mcur;
END;
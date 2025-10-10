
/*
# Description
Генерує повний DDL скрипт для створення таблиці, включаючи колонки, типи даних, обмеження та індекси.

# Parameters
@table NVARCHAR(128) = NULL - назва таблиці для генерації скрипта (NULL = усі таблиці)
@newName NVARCHAR(128) = NULL - нова назва таблиці в скрипті (NULL = використовувати оригінальну назву)

# Returns
TABLE - Повертає таблицю з колонками:
- SchemaName NVARCHAR(128) - назва схеми
- TableName NVARCHAR(128) - назва таблиці
- CreateScript NVARCHAR(MAX) - повний DDL скрипт для створення таблиці

# Usage
-- Згенерувати скрипт для конкретної таблиці
SELECT * FROM util.tablesGetScript('myTable', NULL);

-- Згенерувати скрипт з новою назвою таблиці
SELECT * FROM util.tablesGetScript('myTable', 'myNewTable');

-- Згенерувати скрипти для всіх таблиць
SELECT * FROM util.tablesGetScript(NULL, NULL);
*/
CREATE OR ALTER FUNCTION util.tablesGetScript(@table NVARCHAR(128) = NULL, @newName NVARCHAR(128) = NULL)
RETURNS TABLE
AS
RETURN(
	WITH TableInfo AS (
		SELECT
			OBJECT_SCHEMA_NAME(t.object_id) SchemaName,
			t.name TableName,
			t.object_id,
			t.type_desc,
			t.create_date,
			t.modify_date
		FROM sys.tables t(NOLOCK)
		WHERE
			(@table IS NULL OR t.object_id = ISNULL(TRY_CONVERT(INT, @table), OBJECT_ID(@table))) AND t.is_ms_shipped = 0 -- exclude system tables
	),
	ColumnInfo AS (
		SELECT
			c.object_id,
			c.column_id,
			c.name ColumnName,
			tp.name DataType,
			CASE
				WHEN tp.name IN ('varchar', 'char', 'varbinary', 'binary', 'text') THEN tp.name + '(' + CASE
																																																	WHEN c.max_length = -1 THEN 'MAX'
																																																	ELSE CAST(c.max_length AS VARCHAR(5))
																																																END + ')'
				WHEN tp.name IN ('nvarchar', 'nchar', 'ntext') THEN tp.name + '(' + CASE
																																							WHEN c.max_length = -1 THEN 'MAX'
																																							ELSE CAST(c.max_length / 2 AS VARCHAR(5))
																																						END + ')'
				WHEN tp.name IN ('datetime2', 'time2', 'datetimeoffset') THEN tp.name + '(' + CAST(c.scale AS VARCHAR(5)) + ')'
				WHEN tp.name IN ('decimal', 'numeric') THEN tp.name + '(' + CAST(c.precision AS VARCHAR(5)) + ', ' + CAST(c.scale AS VARCHAR(5)) + ')'
				WHEN tp.name IN ('float') THEN tp.name + '(' + CAST(c.precision AS VARCHAR(5)) + ')'
				ELSE tp.name
			END DataTypeWithSize,
			c.is_nullable,
			c.is_identity,
			ISNULL(ic.seed_value, 0) IdentitySeed,
			ISNULL(ic.increment_value, 0) IdentityIncrement,
			c.is_computed,
			cc.definition ComputedDefinition,
			cc.is_persisted,
			dc.definition DefaultDefinition,
			dc.name DefaultConstraintName
		FROM sys.columns c(NOLOCK)
			JOIN sys.types tp(NOLOCK)ON c.user_type_id = tp.user_type_id
			LEFT JOIN sys.identity_columns ic(NOLOCK)ON c.object_id = ic.object_id AND c.column_id = ic.column_id
			LEFT JOIN sys.computed_columns cc(NOLOCK)ON c.object_id = cc.object_id AND c.column_id = cc.column_id
			LEFT JOIN sys.default_constraints dc(NOLOCK)ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
		WHERE
			c.object_id IN(SELECT TableInfo.object_id FROM TableInfo)
	),
	PrimaryKeyInfo AS (
		SELECT
			kc.parent_object_id object_id,
			kc.name ConstraintName,
			STRING_AGG(QUOTENAME(c.name), ', ') WITHIN GROUP(ORDER BY ic.key_ordinal) KeyColumns
		FROM sys.key_constraints kc(NOLOCK)
			INNER JOIN sys.index_columns ic(NOLOCK)ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id
			INNER JOIN sys.columns c(NOLOCK)ON ic.object_id = c.object_id AND ic.column_id = c.column_id
		WHERE
			kc.type = 'PK' AND kc.parent_object_id IN(SELECT TableInfo.object_id FROM TableInfo)
		GROUP BY
			kc.parent_object_id,
			kc.name
	),
	ForeignKeyDetails AS (
		SELECT
			fk.parent_object_id object_id,
			fk.name ConstraintName,
			STRING_AGG(QUOTENAME(pc.name), ', ') WITHIN GROUP(ORDER BY fkc.constraint_column_id) ParentColumns,
			QUOTENAME(OBJECT_SCHEMA_NAME(fk.referenced_object_id)) + '.' + QUOTENAME(OBJECT_NAME(fk.referenced_object_id)) ReferencedTable,
			STRING_AGG(QUOTENAME(rc.name), ', ') WITHIN GROUP(ORDER BY fkc.constraint_column_id) ReferencedColumns
		FROM sys.foreign_keys fk(NOLOCK)
			INNER JOIN sys.foreign_key_columns fkc(NOLOCK)ON fk.object_id = fkc.constraint_object_id
			INNER JOIN sys.columns pc(NOLOCK)ON fkc.parent_object_id = pc.object_id AND fkc.parent_column_id = pc.column_id
			INNER JOIN sys.columns rc(NOLOCK)ON fkc.referenced_object_id = rc.object_id AND fkc.referenced_column_id = rc.column_id
		WHERE
			fk.parent_object_id IN(SELECT TableInfo.object_id FROM TableInfo)
		GROUP BY
			fk.parent_object_id,
			fk.object_id,
			fk.name,
			fk.referenced_object_id
	),
	ForeignKeyInfo AS (
		SELECT
			ForeignKeyDetails.object_id,
			STRING_AGG(
				'CONSTRAINT ' + QUOTENAME(ForeignKeyDetails.ConstraintName) + ' FOREIGN KEY (' + ForeignKeyDetails.ParentColumns + ') REFERENCES '
				+ ForeignKeyDetails.ReferencedTable + ' (' + ForeignKeyDetails.ReferencedColumns + ')',
				', '
			) ForeignKeyConstraints
		FROM ForeignKeyDetails
		GROUP BY ForeignKeyDetails.object_id
	),
	CheckConstraintInfo AS (
		SELECT
			cc.parent_object_id object_id,
			STRING_AGG('CONSTRAINT ' + QUOTENAME(cc.name) + ' CHECK ' + cc.definition, ', ') CheckConstraints
		FROM sys.check_constraints cc(NOLOCK)
		WHERE
			cc.parent_object_id IN(SELECT TableInfo.object_id FROM TableInfo)
		GROUP BY cc.parent_object_id
	)
	SELECT
		util.metadataGetObjectName(ti.object_id, DEFAULT) tableName,
		'CREATE TABLE ' + QUOTENAME(ti.SchemaName) + '.' + QUOTENAME(ISNULL(@newName, ti.TableName)) + ' (' + CHAR(13) + CHAR(10)
		+ STRING_AGG(
				'    ' + QUOTENAME(ci.ColumnName) + ' '
				+ CASE
						WHEN ci.is_computed = 1 THEN 'AS ' + ci.ComputedDefinition + CASE WHEN ci.is_persisted = 1 THEN ' PERSISTED' ELSE '' END
						ELSE
							ci.DataTypeWithSize
							+ CASE
									WHEN ci.is_identity = 1 THEN ' IDENTITY(' + CAST(ci.IdentitySeed AS VARCHAR(10)) + ', ' + CAST(ci.IdentityIncrement AS VARCHAR(10)) + ')'
									ELSE ''
								END + CASE WHEN ci.is_nullable = 0 THEN ' NOT NULL' ELSE ' NULL' END
							+ CASE
									WHEN ci.DefaultDefinition IS NOT NULL THEN ' DEFAULT ' + ci.DefaultDefinition
									ELSE ''
								END
					END,
				',' + CHAR(13) + CHAR(10)
			) WITHIN GROUP(ORDER BY ci.column_id)
		+ CASE
				WHEN pki.KeyColumns IS NOT NULL THEN
					',' + CHAR(13) + CHAR(10) + '    CONSTRAINT ' + QUOTENAME(CASE WHEN @newName IS NOT NULL THEN REPLACE(pki.ConstraintName, ti.TableName, @newName) ELSE pki.ConstraintName END) + ' PRIMARY KEY (' + pki.KeyColumns + ')'
				ELSE ''
			END + CASE
							WHEN fki.ForeignKeyConstraints IS NOT NULL THEN ',' + CHAR(13) + CHAR(10) + '    ' + CASE WHEN @newName IS NOT NULL THEN REPLACE(fki.ForeignKeyConstraints, ti.TableName, @newName) ELSE fki.ForeignKeyConstraints END
							ELSE ''
						END + CASE
										WHEN cci.CheckConstraints IS NOT NULL THEN ',' + CHAR(13) + CHAR(10) + '    ' + CASE WHEN @newName IS NOT NULL THEN REPLACE(cci.CheckConstraints, ti.TableName, @newName) ELSE cci.CheckConstraints END
										ELSE ''
									END + CHAR(13) + CHAR(10) + ');' createScript
	FROM TableInfo ti
		INNER JOIN ColumnInfo ci ON ti.object_id = ci.object_id
		LEFT JOIN PrimaryKeyInfo pki ON ti.object_id = pki.object_id
		LEFT JOIN ForeignKeyInfo fki ON ti.object_id = fki.object_id
		LEFT JOIN CheckConstraintInfo cci ON ti.object_id = cci.object_id
	GROUP BY
		ti.object_id,
		ti.SchemaName,
		ti.TableName,
		pki.ConstraintName,
		pki.KeyColumns,
		fki.ForeignKeyConstraints,
		cci.CheckConstraints
);
# Utils - SQL Server Database Utilities

Functions and procedures for SQL Server administration, monitoring, and development.

## Table of Contents

- [Error - Error Handling](#error---error-handling)
- [Description - Working with Descriptions](#description---working-with-descriptions)
- [Myself - System Self-Reflection](#myself---system-self-reflection)
- [History - Change History](#history---change-history)
- [Script - Script Generation](#script---script-generation)
- [Table - Working with Tables](#table---working-with-tables)
- [Index - Index Management](#index---index-management)
- [Metadata - Object Metadata](#metadata---object-metadata)
- [Column - Working with Columns](#column---working-with-columns)
- [ExtendedProperty - Extended Properties](#extendedproperty---extended-properties)
- [Object - Working with Objects](#object---working-with-objects)
- [Parameter - Function Parameters](#parameter---function-parameters)
- [Function - System Functions](#function---system-functions)
- [Permission - Permissions and Security](#permission---permissions-and-security)
- [Comment - Comment Analysis](#comment---comment-analysis)
- [Modules - Working with Modules](#modules---working-with-modules)
- [XE - Extended Events](#xe---extended-events)

## Error - Error Handling

### Functions and Procedures:
- `util.errorHandler` - centralized error handling with logging
- `util.errorLog` - table for storing error details

### Usage:
```sql
BEGIN TRY
    SELECT 1/0; -- Division by zero error
END TRY
BEGIN CATCH
    EXEC util.errorHandler @attachment = 'Context: testing division';
END CATCH

SELECT * FROM util.errorLog ORDER BY ErrorDateTime DESC;
```

## Description - Working with Descriptions

### Functions and Procedures:
- `util.modulesGetDescriptionFromComments` - extract descriptions from comments
- `util.modulesSetDescriptionFromComments` - automatic description setting
- `util.modulesGetDescriptionFromCommentsLegacy` - legacy format support

### Usage:
```sql
SELECT * FROM util.modulesGetDescriptionFromComments('util.xeGetErrors');
EXEC util.modulesSetDescriptionFromComments;
EXEC util.modulesSetDescriptionFromComments 'util.errorHandler';
```

## Myself - System Self-Reflection

### Functions:
- `util.myselfActiveIndexCreation` - monitor active index creation operations
- `util.myselfGetHistory` - execution history

### Usage:
```sql
SELECT * FROM util.myselfActiveIndexCreation();
SELECT * FROM util.myselfGetHistory();
```

## History - Change History

### Functions:
- `util.objectGetHistory` - object change history

### Usage:
```sql
SELECT * FROM util.objectGetHistory('myTable');
SELECT * FROM util.objectGetHistory(NULL) 
WHERE ChangeDate >= DATEADD(week, -1, GETDATE());
```

## Script - Script Generation

### Functions:
- `util.tablesGetScript` - generate table DDL scripts
- `util.indexesGetScript` - index creation scripts
- `util.indexesGetScriptConventionRename` - convention-based rename scripts
- `util.indexesGetConventionNames` - standard index names

### Usage:
```sql
SELECT * FROM util.tablesGetScript('myTable');
SELECT * FROM util.indexesGetScript('myTable');
SELECT * FROM util.indexesGetScriptConventionRename('myTable');
```

## Table - Working with Tables

### Functions:
- `util.tablesGetScript` - generate table DDL scripts
- `util.tablesGetIndexedColumns` - analyze indexed columns

### Usage:
```sql
SELECT * FROM util.tablesGetIndexedColumns('myTable');
SELECT * FROM util.tablesGetIndexedColumns(NULL);
```

## Index - Index Management

### Functions and Procedures:
- `util.indexesGetUnused` - detect unused indexes
- `util.indexesGetSpaceUsed` - analyze index space usage  
- `util.indexesGetSpaceUsedDetailed` - detailed partition-level analysis
- `util.indexesGetMissing` - missing index recommendations
- `util.indexesGetScript` - generate index DDL scripts
- `util.indexesGetConventionNames` - standard index names
- `util.indexesGetScriptConventionRename` - rename scripts
- `util.indexesSetConventionNames` - index renaming procedure

### Usage:
```sql
SELECT * FROM util.indexesGetUnused();
SELECT * FROM util.indexesGetSpaceUsed('myTable');
SELECT * FROM util.indexesGetSpaceUsedDetailed('myTable') ORDER BY TotalSpaceMB DESC;
SELECT * FROM util.indexesGetMissing('myTable') WHERE IndexAdvantage > 1000 ORDER BY IndexAdvantage DESC;
EXEC util.indexesSetConventionNames @table = 'myTable', @output = 1;
```

## Metadata - Object Metadata

### Functions:
- `util.metadataGetAnyId`, `util.metadataGetAnyName` - universal search functions
- `util.metadataGetColumns`, `util.metadataGetColumnId`, `util.metadataGetColumnName` - column operations
- `util.metadataGetIndexes`, `util.metadataGetIndexId`, `util.metadataGetIndexName` - index management
- `util.metadataGetParameters`, `util.metadataGetParameterId`, `util.metadataGetParameterName` - function parameters
- `util.metadataGetDataspaceId`, `util.metadataGetDataspaceName` - data spaces
- `util.metadataGetObjectType`, `util.metadataGetObjectsType` - object types
- `util.metadataGetCertificateName` - certificates
- `util.metadataGetClassByName`, `util.metadataGetClassName` - object classes
- `util.metadataGetPartitionFunctionId`, `util.metadataGetPartitionFunctionName` - partition functions
- `util.metadataGetDescriptions`, `util.metadataGetExtendedProperiesValues` - descriptions and properties
- `util.metadataGetRequiredPermission` - required permissions analysis

### Usage:
```sql
SELECT util.metadataGetAnyId('myTable', 1, NULL, NULL);
SELECT util.metadataGetAnyName(OBJECT_ID('myTable'), 1, NULL);
SELECT * FROM util.metadataGetColumns('myTable');
SELECT * FROM util.metadataGetIndexes('myTable');
SELECT util.metadataGetColumnId('myTable', 'myColumn');
```

## Column - Working with Columns

### Procedures:
- `util.metadataSetColumnDescription` - set column descriptions

```sql
EXEC util.metadataSetColumnDescription 
    @object = 'myTable', 
    @column = 'myColumn', 
    @description = 'Important column description';

SELECT util.metadataGetColumnName('myTable', 1);
```

## ExtendedProperty - Extended Properties

### Functions and Procedures:
- `util.metadataSetExtendedProperty` - set extended properties
- `util.metadataGetExtendedProperiesValues` - get property values
- `util.metadataSetColumnDescription`, `util.metadataSetTableDescription`, `util.metadataSetIndexDescription` and others - specialized procedures

```sql
EXEC util.metadataSetExtendedProperty 
    @name = 'MS_Description',
    @value = 'Important system table',
    @level0type = 'SCHEMA',
    @level0name = 'dbo',
    @level1type = 'TABLE',
    @level1name = 'myTable';

SELECT * FROM util.metadataGetExtendedProperiesValues();
```

## Object - Working with Objects

### Functions:
- `util.metadataGetObjectType` - get object types
- `util.objectGetHistory` - object change history

```sql
SELECT util.metadataGetObjectType(OBJECT_ID('myTable'));
SELECT * FROM util.objectGetHistory('myTable');
```

## Parameter - Function Parameters

### Functions and Procedures:
- `util.metadataGetParameters` - get parameter list
- `util.metadataGetParameterId`, `util.metadataGetParameterName` - parameter search
- `util.metadataSetParameterDescription` - set parameter descriptions

```sql
SELECT * FROM util.metadataGetParameters('util.errorHandler');
SELECT util.metadataGetParameterName('util.errorHandler', 1);

EXEC util.metadataSetParameterDescription 
    @object = 'util.errorHandler',
    @parameter = '@attachment',
    @description = 'Additional information for logging';
```

## Function - System Functions

### Procedures:
- `util.metadataSetFunctionDescription` - function description management

```sql
EXEC util.metadataSetFunctionDescription 
    @function = 'util.xeGetErrors',
    @description = 'Function for retrieving errors from Extended Events';
```

## Permission - Permissions and Security

### Functions:
- `util.metadataGetRequiredPermission` - analyze required permissions and cross-database dependencies

```sql
SELECT * FROM util.metadataGetRequiredPermission('myView');
SELECT * FROM util.metadataGetRequiredPermission(NULL) WHERE CrossDatabase = 1;
```

## Comment - Comment Analysis

### Functions:
- `util.modulesFindCommentsPositions` - find all comments
- `util.modulesFindMultilineCommentsPositions` - multi-line comments
- `util.modulesFindInlineCommentsPositions` - single-line comments

```sql
SELECT * FROM util.modulesFindCommentsPositions(OBJECT_ID('myProc'));
SELECT * FROM util.modulesFindMultilineCommentsPositions(NULL);
SELECT * FROM util.modulesFindInlineCommentsPositions(OBJECT_ID('util.errorHandler'));
```

## Modules - Working with Modules

### Functions:
- `util.modulesSplitToLines` - split into lines
- `util.modulesRecureSearchForOccurrences` - recursive search
- `util.modulesRecureSearchStartEndPositions` - block position search
- `util.modulesRecureSearchStartEndPositionsExtended` - extended search
- `util.modulesFindLinesPositions` - line position search
- `util.modulesGetCreateLineNumber` - CREATE line number
- `util.modulesGetDescriptionFromComments` - extract descriptions from comments
- `util.stringSplitMultiLineComment` - split multi-line comments

```sql
SELECT * FROM util.modulesSplitToLines('util.errorHandler', DEFAULT);
SELECT * FROM util.modulesRecureSearchForOccurrences('ERROR_NUMBER', 0);
SELECT * FROM util.modulesRecureSearchStartEndPositions('BEGIN', 'END');
SELECT * FROM util.modulesFindLinesPositions(OBJECT_ID('util.errorHandler'));
```

## XE - Extended Events

### Functions:
- `util.xeGetErrors` - server-level error tracking

```sql
-- All errors
SELECT * FROM util.xeGetErrors(NULL) ORDER BY EventTime DESC;

-- Errors from last hour
SELECT * FROM util.xeGetErrors(DATEADD(hour, -1, GETDATE())) WHERE Severity >= 16;

-- Error statistics
SELECT ErrorNumber, COUNT(*) as ErrorCount, MAX(EventTime) as LastOccurrence
FROM util.xeGetErrors(DATEADD(day, -7, GETDATE()))
GROUP BY ErrorNumber ORDER BY ErrorCount DESC;
```

## Installation

```sql
-- Create schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'util')
    EXEC('CREATE SCHEMA util');
```

Execute scripts in order: Tables/ → Functions/ → Procedures/
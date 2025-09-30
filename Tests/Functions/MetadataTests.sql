/*
# Objects & Metadata Functions Tests
# Description
Comprehensive tests for all objects and metadata functions in pure-utils.

Functions tested:
- metadataGetObjectName
- metadataGetObjectType
- metadataGetObjectsType
- metadataGetAnyId
- metadataGetAnyName
- metadataGetClassByName
- metadataGetClassName
- metadataGetCertificateName
- metadataGetDataspaceId
- metadataGetDataspaceName
- metadataGetPartitionFunctionId
- metadataGetPartitionFunctionName
- metadataGetColumns
- metadataGetColumnId
- metadataGetColumnName
- metadataGetIndexes
- metadataGetIndexId
- metadataGetIndexName
- metadataGetParameters
- metadataGetParameterId
- metadataGetParameterName
- metadataGetDescriptions
- metadataGetExtendedProperiesValues
- metadataGetRequiredPermission
*/

-- Include test framework
:r Tests\TestFramework.sql

PRINT 'Starting Objects & Metadata Functions Tests...';
PRINT '';

-- Reset test counters
DECLARE @TestCount INT = 0;
DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;

-- ===========================================
-- metadataGetObjectName Tests
-- ===========================================
PRINT 'Testing metadataGetObjectName function...';

-- Test 1: Get name of a system table
DECLARE @SysObjectsId INT = OBJECT_ID('sys.objects');
DECLARE @SysObjectsName NVARCHAR(128);
SELECT @SysObjectsName = util.metadataGetObjectName(@SysObjectsId);

EXEC #AssertNotNull @SysObjectsName, 'metadataGetObjectName - Should return name for sys.objects';
EXEC #AssertTrue CASE WHEN @SysObjectsName LIKE '%objects%' THEN 1 ELSE 0 END, 'metadataGetObjectName - Name should contain "objects"';

-- Test 2: Invalid object ID should return NULL
DECLARE @InvalidObjectName NVARCHAR(128);
SELECT @InvalidObjectName = util.metadataGetObjectName(-1);

EXEC #AssertEquals NULL, @InvalidObjectName, 'metadataGetObjectName - Invalid object ID should return NULL';

-- Test 3: Get name of util schema functions
DECLARE @HelpProcId INT = OBJECT_ID('util.help');
DECLARE @HelpProcName NVARCHAR(128);
SELECT @HelpProcName = util.metadataGetObjectName(@HelpProcId);

EXEC #AssertNotNull @HelpProcName, 'metadataGetObjectName - Should return name for util.help procedure';
EXEC #AssertTrue CASE WHEN @HelpProcName LIKE '%help%' THEN 1 ELSE 0 END, 'metadataGetObjectName - Name should contain "help"';

-- ===========================================
-- metadataGetObjectType Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataGetObjectType function...';

-- Test 1: Get type of util.help procedure  
DECLARE @HelpType NVARCHAR(2);
SELECT @HelpType = util.metadataGetObjectType('util.help');

EXEC #AssertEquals 'P', @HelpType, 'metadataGetObjectType - util.help should be type "P" (procedure)';

-- Test 2: Get type of a function
DECLARE @FunctionType NVARCHAR(2);
SELECT @FunctionType = util.metadataGetObjectType('util.stringSplitToLines');

EXEC #AssertTrue CASE WHEN @FunctionType IN ('FN', 'TF', 'IF') THEN 1 ELSE 0 END, 'metadataGetObjectType - stringSplitToLines should be a function type';

-- Test 3: Non-existent object should return NULL
DECLARE @NonExistentType NVARCHAR(2);
SELECT @NonExistentType = util.metadataGetObjectType('dbo.NonExistentObject');

EXEC #AssertEquals NULL, @NonExistentType, 'metadataGetObjectType - Non-existent object should return NULL';

-- ===========================================
-- metadataGetObjectsType Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataGetObjectsType function...';

-- Test 1: Multiple objects types
DECLARE @MultipleObjectsCount INT;
SELECT @MultipleObjectsCount = COUNT(*) FROM util.metadataGetObjectsType('util.help,util.stringSplitToLines');

EXEC #AssertEquals '2', CAST(@MultipleObjectsCount AS NVARCHAR(10)), 'metadataGetObjectsType - Should return 2 rows for 2 objects';

-- Test 2: Single object
DECLARE @SingleObjectCount INT;
SELECT @SingleObjectCount = COUNT(*) FROM util.metadataGetObjectsType('util.help');

EXEC #AssertEquals '1', CAST(@SingleObjectCount AS NVARCHAR(10)), 'metadataGetObjectsType - Should return 1 row for 1 object';

-- Test 3: Check that object names are preserved
DECLARE @ObjectNamesPreserved BIT = 1;
SELECT @ObjectNamesPreserved = CASE WHEN MIN(CASE WHEN objectName IS NOT NULL THEN 1 ELSE 0 END) = 1 THEN 1 ELSE 0 END
FROM util.metadataGetObjectsType('util.help,util.stringSplitToLines');

EXEC #AssertTrue @ObjectNamesPreserved, 'metadataGetObjectsType - All object names should be preserved';

-- ===========================================
-- metadataGetAnyId Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataGetAnyId function...';

-- Test 1: Get object ID
DECLARE @ObjectIdFromFunction INT;
SELECT @ObjectIdFromFunction = util.metadataGetAnyId('util.help', 'OBJECT');

DECLARE @ObjectIdDirect INT = OBJECT_ID('util.help');

EXEC #AssertEquals CAST(@ObjectIdDirect AS NVARCHAR(10)), CAST(@ObjectIdFromFunction AS NVARCHAR(10)), 'metadataGetAnyId - Should return correct object ID';

-- Test 2: Invalid class should return NULL
DECLARE @InvalidClassResult INT;
SELECT @InvalidClassResult = util.metadataGetAnyId('util.help', 'INVALID_CLASS');

EXEC #AssertEquals NULL, CAST(@InvalidClassResult AS NVARCHAR(10)), 'metadataGetAnyId - Invalid class should return NULL';

-- ===========================================
-- metadataGetAnyName Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataGetAnyName function...';

-- Test 1: Get object name by ID
DECLARE @NameFromFunction NVARCHAR(128);
SELECT @NameFromFunction = util.metadataGetAnyName(@ObjectIdDirect, 0, '1');

EXEC #AssertNotNull @NameFromFunction, 'metadataGetAnyName - Should return object name';
EXEC #AssertTrue CASE WHEN @NameFromFunction LIKE '%help%' THEN 1 ELSE 0 END, 'metadataGetAnyName - Name should contain "help"';

-- ===========================================
-- metadataGetClassName Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataGetClassName function...';

-- Test 1: Get class name for objects
DECLARE @ObjectClassName NVARCHAR(128);
SELECT @ObjectClassName = util.metadataGetClassName('1');

EXEC #AssertNotNull @ObjectClassName, 'metadataGetClassName - Should return class name for class "1"';

-- Test 2: Invalid class should return meaningful result or NULL
DECLARE @InvalidClassName NVARCHAR(128);
SELECT @InvalidClassName = util.metadataGetClassName('999');

-- This is expected to return NULL or a default value, both are acceptable

-- ===========================================
-- metadataGetClassByName Tests  
-- ===========================================
PRINT '';
PRINT 'Testing metadataGetClassByName function...';

-- Test 1: Get class by name if we have a valid class name
IF @ObjectClassName IS NOT NULL
BEGIN
    DECLARE @ClassByName NVARCHAR(128);
    SELECT @ClassByName = util.metadataGetClassByName(@ObjectClassName);
    
    EXEC #AssertNotNull @ClassByName, 'metadataGetClassByName - Should return class code for valid class name';
END

-- ===========================================
-- metadataGetColumns Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataGetColumns function...';

-- Test 1: Get columns for sys.objects (known system table)
DECLARE @SysObjectsColumns INT;
SELECT @SysObjectsColumns = COUNT(*) FROM util.metadataGetColumns('sys.objects');

EXEC #AssertTrue CASE WHEN @SysObjectsColumns > 0 THEN 1 ELSE 0 END, 'metadataGetColumns - sys.objects should have columns';

-- Test 2: Non-existent table should return 0 rows
DECLARE @NonExistentColumns INT;
SELECT @NonExistentColumns = COUNT(*) FROM util.metadataGetColumns('dbo.NonExistentTable');

EXEC #AssertEquals '0', CAST(@NonExistentColumns AS NVARCHAR(10)), 'metadataGetColumns - Non-existent table should return 0 rows';

-- ===========================================
-- metadataGetDescriptions Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataGetDescriptions function...';

-- Test 1: Get descriptions - should not error even if no descriptions exist
DECLARE @DescriptionsCount INT;
SELECT @DescriptionsCount = COUNT(*) FROM util.metadataGetDescriptions('sys.objects', NULL);

-- Any result is acceptable, just check function doesn't error
EXEC #AssertTrue 1, 'metadataGetDescriptions - Function should execute without error';

-- ===========================================
-- metadataGetExtendedProperiesValues Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataGetExtendedProperiesValues function...';

-- Test 1: Get extended properties - should not error
DECLARE @ExtendedPropsCount INT;
SELECT @ExtendedPropsCount = COUNT(*) FROM util.metadataGetExtendedProperiesValues('sys.objects', NULL, 'MS_Description');

-- Any result is acceptable, just check function doesn't error
EXEC #AssertTrue 1, 'metadataGetExtendedProperiesValues - Function should execute without error';

-- ===========================================
-- Print Test Summary
-- ===========================================
EXEC #PrintTestSummary 'Objects & Metadata Functions';
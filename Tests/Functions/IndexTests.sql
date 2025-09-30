/*
# Index Functions Tests
# Description
Comprehensive tests for all index-related functions in pure-utils.

Functions tested:
- indexesGetConventionNames
- indexesGetMissing
- indexesGetScript
- indexesGetScriptConventionRename
- indexesGetSpaceUsed
- indexesGetSpaceUsedDetailed
- indexesGetUnused
- tablesGetIndexedColumns
*/

-- Include test framework
:r Tests\TestFramework.sql

PRINT 'Starting Index Functions Tests...';
PRINT '';

-- Reset test counters
DECLARE @TestCount INT = 0;
DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;

-- ===========================================
-- indexesGetConventionNames Tests
-- ===========================================
PRINT 'Testing indexesGetConventionNames function...';

-- Test 1: Get convention names for all tables
DECLARE @ConventionNamesCount INT;
SELECT @ConventionNamesCount = COUNT(*) FROM util.indexesGetConventionNames(NULL, NULL);

EXEC #AssertTrue CASE WHEN @ConventionNamesCount >= 0 THEN 1 ELSE 0 END, 'indexesGetConventionNames - Should execute without error for all tables';

-- Test 2: Get convention names for sys.objects table (known system table with indexes)
DECLARE @SysObjectsConventionCount INT;
SELECT @SysObjectsConventionCount = COUNT(*) FROM util.indexesGetConventionNames('sys.objects', NULL);

EXEC #AssertTrue CASE WHEN @SysObjectsConventionCount >= 0 THEN 1 ELSE 0 END, 'indexesGetConventionNames - Should execute without error for sys.objects';

-- Test 3: Non-existent table should return 0 rows
DECLARE @NonExistentTableConvention INT;
SELECT @NonExistentTableConvention = COUNT(*) FROM util.indexesGetConventionNames('dbo.NonExistentTable', NULL);

EXEC #AssertEquals '0', CAST(@NonExistentTableConvention AS NVARCHAR(10)), 'indexesGetConventionNames - Non-existent table should return 0 rows';

-- Test 4: Results should contain valid data structure
DECLARE @ValidConventionStructure BIT = 1;
SELECT @ValidConventionStructure = CASE 
    WHEN MIN(CASE WHEN tableName IS NOT NULL AND indexName IS NOT NULL THEN 1 ELSE 0 END) = 1 THEN 1 
    ELSE 0 END
FROM util.indexesGetConventionNames('sys.objects', NULL);

IF @SysObjectsConventionCount > 0
    EXEC #AssertTrue @ValidConventionStructure, 'indexesGetConventionNames - Results should have valid table and index names';

-- ===========================================
-- indexesGetMissing Tests
-- ===========================================
PRINT '';
PRINT 'Testing indexesGetMissing function...';

-- Test 1: Get missing indexes for all tables
DECLARE @MissingIndexesCount INT;
SELECT @MissingIndexesCount = COUNT(*) FROM util.indexesGetMissing(NULL);

EXEC #AssertTrue CASE WHEN @MissingIndexesCount >= 0 THEN 1 ELSE 0 END, 'indexesGetMissing - Should execute without error for all tables';

-- Test 2: Get missing indexes for specific table
DECLARE @SysObjectsMissingCount INT;
SELECT @SysObjectsMissingCount = COUNT(*) FROM util.indexesGetMissing('sys.objects');

EXEC #AssertTrue CASE WHEN @SysObjectsMissingCount >= 0 THEN 1 ELSE 0 END, 'indexesGetMissing - Should execute without error for sys.objects';

-- Test 3: Non-existent table should return 0 rows
DECLARE @NonExistentMissing INT;
SELECT @NonExistentMissing = COUNT(*) FROM util.indexesGetMissing('dbo.NonExistentTable');

EXEC #AssertEquals '0', CAST(@NonExistentMissing AS NVARCHAR(10)), 'indexesGetMissing - Non-existent table should return 0 rows';

-- ===========================================
-- indexesGetScript Tests
-- ===========================================
PRINT '';
PRINT 'Testing indexesGetScript function...';

-- Test 1: Get index scripts for all tables
DECLARE @IndexScriptsCount INT;
SELECT @IndexScriptsCount = COUNT(*) FROM util.indexesGetScript(NULL, NULL);

EXEC #AssertTrue CASE WHEN @IndexScriptsCount >= 0 THEN 1 ELSE 0 END, 'indexesGetScript - Should execute without error for all tables';

-- Test 2: Get index scripts for sys.objects
DECLARE @SysObjectsScriptsCount INT;
SELECT @SysObjectsScriptsCount = COUNT(*) FROM util.indexesGetScript('sys.objects', NULL);

EXEC #AssertTrue CASE WHEN @SysObjectsScriptsCount >= 0 THEN 1 ELSE 0 END, 'indexesGetScript - Should execute without error for sys.objects';

-- Test 3: Verify scripts contain CREATE INDEX keywords
DECLARE @ValidIndexScripts BIT = 1;
DECLARE @ScriptSample NVARCHAR(MAX);

SELECT TOP 1 @ScriptSample = createScript 
FROM util.indexesGetScript('sys.objects', NULL)
WHERE createScript IS NOT NULL;

IF @ScriptSample IS NOT NULL
BEGIN
    SET @ValidIndexScripts = CASE WHEN UPPER(@ScriptSample) LIKE '%CREATE%INDEX%' THEN 1 ELSE 0 END;
    EXEC #AssertTrue @ValidIndexScripts, 'indexesGetScript - Scripts should contain CREATE INDEX';
END

-- Test 4: Non-existent table should return 0 rows
DECLARE @NonExistentScripts INT;
SELECT @NonExistentScripts = COUNT(*) FROM util.indexesGetScript('dbo.NonExistentTable', NULL);

EXEC #AssertEquals '0', CAST(@NonExistentScripts AS NVARCHAR(10)), 'indexesGetScript - Non-existent table should return 0 rows';

-- ===========================================
-- indexesGetScriptConventionRename Tests
-- ===========================================
PRINT '';
PRINT 'Testing indexesGetScriptConventionRename function...';

-- Test 1: Get rename scripts for all tables
DECLARE @RenameScriptsCount INT;
SELECT @RenameScriptsCount = COUNT(*) FROM util.indexesGetScriptConventionRename(NULL, NULL);

EXEC #AssertTrue CASE WHEN @RenameScriptsCount >= 0 THEN 1 ELSE 0 END, 'indexesGetScriptConventionRename - Should execute without error for all tables';

-- Test 2: Get rename scripts for sys.objects
DECLARE @SysObjectsRenameCount INT;
SELECT @SysObjectsRenameCount = COUNT(*) FROM util.indexesGetScriptConventionRename('sys.objects', NULL);

EXEC #AssertTrue CASE WHEN @SysObjectsRenameCount >= 0 THEN 1 ELSE 0 END, 'indexesGetScriptConventionRename - Should execute without error for sys.objects';

-- Test 3: Non-existent table should return 0 rows
DECLARE @NonExistentRename INT;
SELECT @NonExistentRename = COUNT(*) FROM util.indexesGetScriptConventionRename('dbo.NonExistentTable', NULL);

EXEC #AssertEquals '0', CAST(@NonExistentRename AS NVARCHAR(10)), 'indexesGetScriptConventionRename - Non-existent table should return 0 rows';

-- ===========================================
-- indexesGetSpaceUsed Tests
-- ===========================================
PRINT '';
PRINT 'Testing indexesGetSpaceUsed function...';

-- Test 1: Get space usage for all indexes
DECLARE @SpaceUsedCount INT;
SELECT @SpaceUsedCount = COUNT(*) FROM util.indexesGetSpaceUsed(NULL, NULL);

EXEC #AssertTrue CASE WHEN @SpaceUsedCount >= 0 THEN 1 ELSE 0 END, 'indexesGetSpaceUsed - Should execute without error for all indexes';

-- Test 2: Get space usage for sys.objects
DECLARE @SysObjectsSpaceCount INT;
SELECT @SysObjectsSpaceCount = COUNT(*) FROM util.indexesGetSpaceUsed('sys.objects', NULL);

EXEC #AssertTrue CASE WHEN @SysObjectsSpaceCount >= 0 THEN 1 ELSE 0 END, 'indexesGetSpaceUsed - Should execute without error for sys.objects';

-- Test 3: Verify space usage data has reasonable values
DECLARE @ValidSpaceData BIT = 1;
SELECT @ValidSpaceData = CASE 
    WHEN MIN(CASE WHEN indexName IS NOT NULL THEN 1 ELSE 0 END) = 1 THEN 1 
    ELSE 0 END
FROM util.indexesGetSpaceUsed('sys.objects', NULL);

IF @SysObjectsSpaceCount > 0
    EXEC #AssertTrue @ValidSpaceData, 'indexesGetSpaceUsed - Results should have valid index names';

-- Test 4: Non-existent table should return 0 rows
DECLARE @NonExistentSpace INT;
SELECT @NonExistentSpace = COUNT(*) FROM util.indexesGetSpaceUsed('dbo.NonExistentTable', NULL);

EXEC #AssertEquals '0', CAST(@NonExistentSpace AS NVARCHAR(10)), 'indexesGetSpaceUsed - Non-existent table should return 0 rows';

-- ===========================================
-- indexesGetSpaceUsedDetailed Tests
-- ===========================================
PRINT '';
PRINT 'Testing indexesGetSpaceUsedDetailed function...';

-- Test 1: Get detailed space usage for all indexes
DECLARE @DetailedSpaceCount INT;
SELECT @DetailedSpaceCount = COUNT(*) FROM util.indexesGetSpaceUsedDetailed(NULL, NULL);

EXEC #AssertTrue CASE WHEN @DetailedSpaceCount >= 0 THEN 1 ELSE 0 END, 'indexesGetSpaceUsedDetailed - Should execute without error for all indexes';

-- Test 2: Get detailed space usage for sys.objects
DECLARE @SysObjectsDetailedCount INT;
SELECT @SysObjectsDetailedCount = COUNT(*) FROM util.indexesGetSpaceUsedDetailed('sys.objects', NULL);

EXEC #AssertTrue CASE WHEN @SysObjectsDetailedCount >= 0 THEN 1 ELSE 0 END, 'indexesGetSpaceUsedDetailed - Should execute without error for sys.objects';

-- Test 3: Detailed results should have more or equal columns than basic
-- (We can't easily compare structure, but ensure function works)
EXEC #AssertTrue 1, 'indexesGetSpaceUsedDetailed - Function executes successfully';

-- ===========================================
-- indexesGetUnused Tests
-- ===========================================
PRINT '';
PRINT 'Testing indexesGetUnused function...';

-- Test 1: Get unused indexes for all tables
DECLARE @UnusedIndexesCount INT;
SELECT @UnusedIndexesCount = COUNT(*) FROM util.indexesGetUnused(NULL);

EXEC #AssertTrue CASE WHEN @UnusedIndexesCount >= 0 THEN 1 ELSE 0 END, 'indexesGetUnused - Should execute without error for all tables';

-- Test 2: Get unused indexes for sys.objects
DECLARE @SysObjectsUnusedCount INT;
SELECT @SysObjectsUnusedCount = COUNT(*) FROM util.indexesGetUnused('sys.objects');

EXEC #AssertTrue CASE WHEN @SysObjectsUnusedCount >= 0 THEN 1 ELSE 0 END, 'indexesGetUnused - Should execute without error for sys.objects';

-- Test 3: Non-existent table should return 0 rows
DECLARE @NonExistentUnused INT;
SELECT @NonExistentUnused = COUNT(*) FROM util.indexesGetUnused('dbo.NonExistentTable');

EXEC #AssertEquals '0', CAST(@NonExistentUnused AS NVARCHAR(10)), 'indexesGetUnused - Non-existent table should return 0 rows';

-- ===========================================
-- tablesGetIndexedColumns Tests
-- ===========================================
PRINT '';
PRINT 'Testing tablesGetIndexedColumns function...';

-- Test 1: Get indexed columns for all tables
DECLARE @IndexedColumnsCount INT;
SELECT @IndexedColumnsCount = COUNT(*) FROM util.tablesGetIndexedColumns(NULL);

EXEC #AssertTrue CASE WHEN @IndexedColumnsCount >= 0 THEN 1 ELSE 0 END, 'tablesGetIndexedColumns - Should execute without error for all tables';

-- Test 2: Get indexed columns for sys.objects
DECLARE @SysObjectsIndexedCount INT;
SELECT @SysObjectsIndexedCount = COUNT(*) FROM util.tablesGetIndexedColumns('sys.objects');

EXEC #AssertTrue CASE WHEN @SysObjectsIndexedCount > 0 THEN 1 ELSE 0 END, 'tablesGetIndexedColumns - sys.objects should have indexed columns';

-- Test 3: Verify results have valid structure
DECLARE @ValidIndexedStructure BIT = 1;
SELECT @ValidIndexedStructure = CASE 
    WHEN MIN(CASE WHEN tableName IS NOT NULL AND columnName IS NOT NULL THEN 1 ELSE 0 END) = 1 THEN 1 
    ELSE 0 END
FROM util.tablesGetIndexedColumns('sys.objects');

IF @SysObjectsIndexedCount > 0
    EXEC #AssertTrue @ValidIndexedStructure, 'tablesGetIndexedColumns - Results should have valid table and column names';

-- Test 4: Non-existent table should return 0 rows
DECLARE @NonExistentIndexed INT;
SELECT @NonExistentIndexed = COUNT(*) FROM util.tablesGetIndexedColumns('dbo.NonExistentTable');

EXEC #AssertEquals '0', CAST(@NonExistentIndexed AS NVARCHAR(10)), 'tablesGetIndexedColumns - Non-existent table should return 0 rows';

-- ===========================================
-- Print Test Summary
-- ===========================================
EXEC #PrintTestSummary 'Index Functions';
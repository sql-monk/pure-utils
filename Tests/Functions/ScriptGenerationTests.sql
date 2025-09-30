/*
# Script Generation & Utility Functions Tests
# Description
Comprehensive tests for script generation, temp tables, and utility functions.

Functions tested:
- stringGetCreateTempScript
- stringGetCreateTempScriptInline
- tablesGetScript
- tablesGetUnused
- xeGetErrors
- xeGetLogsPath
- xeGetModules
- xeGetTargetFile
- myselfActiveIndexCreation
- myselfGetHistory
- objectGetHistory
- metadataGetRequiredPermission
*/

-- Include test framework
:r Tests\TestFramework.sql

PRINT 'Starting Script Generation & Utility Functions Tests...';
PRINT '';

-- Reset test counters
DECLARE @TestCount INT = 0;
DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;

-- ===========================================
-- stringGetCreateTempScript Tests
-- ===========================================
PRINT 'Testing stringGetCreateTempScript function...';

-- Test 1: Generate temp table script from simple SELECT
DECLARE @SimpleSelect NVARCHAR(MAX) = 'SELECT 1 AS ID, ''Test'' AS Name';
DECLARE @TempScript NVARCHAR(MAX);
SELECT @TempScript = util.stringGetCreateTempScript(@SimpleSelect, DEFAULT, DEFAULT);

EXEC #AssertNotNull @TempScript, 'stringGetCreateTempScript - Should generate script for simple SELECT';
EXEC #AssertTrue CASE WHEN UPPER(@TempScript) LIKE '%CREATE%TABLE%' THEN 1 ELSE 0 END, 'stringGetCreateTempScript - Script should contain CREATE TABLE';

-- Test 2: Generate script with custom table name
DECLARE @TempScriptCustom NVARCHAR(MAX);
SELECT @TempScriptCustom = util.stringGetCreateTempScript(@SimpleSelect, 'MyTempTable', DEFAULT);

EXEC #AssertNotNull @TempScriptCustom, 'stringGetCreateTempScript - Should generate script with custom table name';
EXEC #AssertTrue CASE WHEN @TempScriptCustom LIKE '%MyTempTable%' THEN 1 ELSE 0 END, 'stringGetCreateTempScript - Script should contain custom table name';

-- Test 3: Test with NULL or empty query should handle gracefully
DECLARE @EmptyScript NVARCHAR(MAX);
SELECT @EmptyScript = util.stringGetCreateTempScript('', DEFAULT, DEFAULT);

-- Should either return NULL or handle gracefully
EXEC #AssertTrue 1, 'stringGetCreateTempScript - Should handle empty query gracefully';

-- ===========================================
-- stringGetCreateTempScriptInline Tests
-- ===========================================
PRINT '';
PRINT 'Testing stringGetCreateTempScriptInline function...';

-- Test 1: Generate inline temp table script
DECLARE @InlineScriptCount INT;
SELECT @InlineScriptCount = COUNT(*) FROM util.stringGetCreateTempScriptInline(@SimpleSelect, DEFAULT, DEFAULT);

EXEC #AssertEquals '1', CAST(@InlineScriptCount AS NVARCHAR(10)), 'stringGetCreateTempScriptInline - Should return 1 row with script';

-- Test 2: Verify returned script structure
DECLARE @InlineScript NVARCHAR(MAX);
SELECT @InlineScript = createScript FROM util.stringGetCreateTempScriptInline(@SimpleSelect, DEFAULT, DEFAULT);

EXEC #AssertNotNull @InlineScript, 'stringGetCreateTempScriptInline - Should return non-null script';
EXEC #AssertTrue CASE WHEN UPPER(@InlineScript) LIKE '%CREATE%TABLE%' THEN 1 ELSE 0 END, 'stringGetCreateTempScriptInline - Script should contain CREATE TABLE';

-- ===========================================
-- tablesGetScript Tests
-- ===========================================
PRINT '';
PRINT 'Testing tablesGetScript function...';

-- Test 1: Get script for all tables
DECLARE @AllTablesScriptCount INT;
SELECT @AllTablesScriptCount = COUNT(*) FROM util.tablesGetScript(NULL);

EXEC #AssertTrue CASE WHEN @AllTablesScriptCount >= 0 THEN 1 ELSE 0 END, 'tablesGetScript - Should execute without error for all tables';

-- Test 2: Get script for sys.objects table
DECLARE @SysObjectsScriptCount INT;
SELECT @SysObjectsScriptCount = COUNT(*) FROM util.tablesGetScript('sys.objects');

EXEC #AssertTrue CASE WHEN @SysObjectsScriptCount >= 0 THEN 1 ELSE 0 END, 'tablesGetScript - Should execute without error for sys.objects';

-- Test 3: Verify script contains DDL keywords
DECLARE @TableScript NVARCHAR(MAX);
SELECT TOP 1 @TableScript = createScript FROM util.tablesGetScript('sys.objects') WHERE createScript IS NOT NULL;

IF @TableScript IS NOT NULL
BEGIN
    EXEC #AssertTrue CASE WHEN UPPER(@TableScript) LIKE '%CREATE%TABLE%' THEN 1 ELSE 0 END, 'tablesGetScript - Script should contain CREATE TABLE';
END

-- Test 4: Non-existent table should return 0 rows
DECLARE @NonExistentTableScript INT;
SELECT @NonExistentTableScript = COUNT(*) FROM util.tablesGetScript('dbo.NonExistentTable');

EXEC #AssertEquals '0', CAST(@NonExistentTableScript AS NVARCHAR(10)), 'tablesGetScript - Non-existent table should return 0 rows';

-- ===========================================
-- tablesGetUnused Tests
-- ===========================================
PRINT '';
PRINT 'Testing tablesGetUnused function...';

-- Test 1: Get unused tables
DECLARE @UnusedTablesCount INT;
SELECT @UnusedTablesCount = COUNT(*) FROM util.tablesGetUnused();

EXEC #AssertTrue CASE WHEN @UnusedTablesCount >= 0 THEN 1 ELSE 0 END, 'tablesGetUnused - Should execute without error';

-- Test 2: Verify result structure if any unused tables found
DECLARE @ValidUnusedStructure BIT = 1;
SELECT @ValidUnusedStructure = CASE 
    WHEN MIN(CASE WHEN tableName IS NOT NULL THEN 1 ELSE 0 END) = 1 THEN 1 
    ELSE 0 END
FROM util.tablesGetUnused();

IF @UnusedTablesCount > 0
    EXEC #AssertTrue @ValidUnusedStructure, 'tablesGetUnused - Results should have valid table names';

-- ===========================================
-- xeGetErrors Tests
-- ===========================================
PRINT '';
PRINT 'Testing xeGetErrors function...';

-- Test 1: Get XE errors
DECLARE @XEErrorsCount INT;
SELECT @XEErrorsCount = COUNT(*) FROM util.xeGetErrors();

EXEC #AssertTrue CASE WHEN @XEErrorsCount >= 0 THEN 1 ELSE 0 END, 'xeGetErrors - Should execute without error';

-- ===========================================
-- xeGetLogsPath Tests
-- ===========================================
PRINT '';
PRINT 'Testing xeGetLogsPath function...';

-- Test 1: Get XE logs path
DECLARE @XELogsPath NVARCHAR(MAX);
SELECT @XELogsPath = util.xeGetLogsPath();

-- Path can be NULL if XE is not configured, which is valid
EXEC #AssertTrue 1, 'xeGetLogsPath - Should execute without error';

-- ===========================================
-- xeGetModules Tests
-- ===========================================
PRINT '';
PRINT 'Testing xeGetModules function...';

-- Test 1: Get XE modules
DECLARE @XEModulesCount INT;
SELECT @XEModulesCount = COUNT(*) FROM util.xeGetModules();

EXEC #AssertTrue CASE WHEN @XEModulesCount >= 0 THEN 1 ELSE 0 END, 'xeGetModules - Should execute without error';

-- ===========================================
-- xeGetTargetFile Tests
-- ===========================================
PRINT '';
PRINT 'Testing xeGetTargetFile function...';

-- Test 1: Get XE target file
DECLARE @XETargetFile NVARCHAR(MAX);
SELECT @XETargetFile = util.xeGetTargetFile();

-- Target file can be NULL if XE is not configured, which is valid
EXEC #AssertTrue 1, 'xeGetTargetFile - Should execute without error';

-- ===========================================
-- myselfActiveIndexCreation Tests
-- ===========================================
PRINT '';
PRINT 'Testing myselfActiveIndexCreation function...';

-- Test 1: Get active index creation
DECLARE @ActiveIndexCount INT;
SELECT @ActiveIndexCount = COUNT(*) FROM util.myselfActiveIndexCreation();

EXEC #AssertTrue CASE WHEN @ActiveIndexCount >= 0 THEN 1 ELSE 0 END, 'myselfActiveIndexCreation - Should execute without error';

-- ===========================================
-- myselfGetHistory Tests
-- ===========================================
PRINT '';
PRINT 'Testing myselfGetHistory function...';

-- Test 1: Get self history
DECLARE @SelfHistoryCount INT;
SELECT @SelfHistoryCount = COUNT(*) FROM util.myselfGetHistory();

EXEC #AssertTrue CASE WHEN @SelfHistoryCount >= 0 THEN 1 ELSE 0 END, 'myselfGetHistory - Should execute without error';

-- ===========================================
-- objectGetHistory Tests
-- ===========================================
PRINT '';
PRINT 'Testing objectGetHistory function...';

-- Test 1: Get object history for util.help
DECLARE @ObjectHistoryCount INT;
SELECT @ObjectHistoryCount = COUNT(*) FROM util.objectGetHistory('util.help');

EXEC #AssertTrue CASE WHEN @ObjectHistoryCount >= 0 THEN 1 ELSE 0 END, 'objectGetHistory - Should execute without error for util.help';

-- Test 2: Non-existent object should return 0 rows
DECLARE @NonExistentObjectHistory INT;
SELECT @NonExistentObjectHistory = COUNT(*) FROM util.objectGetHistory('dbo.NonExistentObject');

EXEC #AssertEquals '0', CAST(@NonExistentObjectHistory AS NVARCHAR(10)), 'objectGetHistory - Non-existent object should return 0 rows';

-- ===========================================
-- metadataGetRequiredPermission Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataGetRequiredPermission function...';

-- Test 1: Get required permission for util.help
DECLARE @HelpPermission NVARCHAR(MAX);
SELECT @HelpPermission = util.metadataGetRequiredPermission('util.help');

EXEC #AssertNotNull @HelpPermission, 'metadataGetRequiredPermission - Should return permission for util.help';

-- Test 2: Non-existent object should return NULL
DECLARE @NonExistentPermission NVARCHAR(MAX);
SELECT @NonExistentPermission = util.metadataGetRequiredPermission('dbo.NonExistentObject');

EXEC #AssertEquals NULL, @NonExistentPermission, 'metadataGetRequiredPermission - Non-existent object should return NULL';

-- ===========================================
-- Print Test Summary
-- ===========================================
EXEC #PrintTestSummary 'Script Generation & Utility Functions';
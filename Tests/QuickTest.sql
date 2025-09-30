/*
# Quick Test Runner
# Description
Executes a subset of critical tests for quick validation during development.

This is a lightweight test runner that covers core functionality without
running the full comprehensive test suite.

# Usage
Execute this script for quick validation of key functions.
*/

PRINT '╔════════════════════════════════════════════════════════════════╗';
PRINT '║                    PURE UTILS - QUICK TESTS                   ║';
PRINT '╚════════════════════════════════════════════════════════════════╝';
PRINT '';
PRINT 'Running quick validation tests...';
PRINT '';

-- Include test framework
:r Tests\TestFramework.sql

-- Reset test counters
DECLARE @TestCount INT = 0;
DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;

-- ===========================================
-- Core String Functions Quick Tests
-- ===========================================
PRINT 'Quick Test: Core String Functions';

-- Test stringSplitToLines
DECLARE @QuickStringTest INT;
SELECT @QuickStringTest = COUNT(*) FROM util.stringSplitToLines('Line1' + CHAR(10) + 'Line2', 1);
EXEC #AssertEquals '2', CAST(@QuickStringTest AS NVARCHAR(10)), 'Quick - stringSplitToLines basic functionality';

-- Test stringFindCommentsPositions
DECLARE @QuickCommentsTest INT;
SELECT @QuickCommentsTest = COUNT(*) FROM util.stringFindCommentsPositions('SELECT 1; -- comment', 1);
EXEC #AssertEquals '1', CAST(@QuickCommentsTest AS NVARCHAR(10)), 'Quick - stringFindCommentsPositions basic functionality';

-- ===========================================
-- Core Metadata Functions Quick Tests
-- ===========================================
PRINT 'Quick Test: Core Metadata Functions';

-- Test metadataGetObjectType
DECLARE @QuickObjectType NVARCHAR(2);
SELECT @QuickObjectType = util.metadataGetObjectType('util.help');
EXEC #AssertEquals 'P', @QuickObjectType, 'Quick - metadataGetObjectType for procedure';

-- Test metadataGetColumns
DECLARE @QuickColumnsTest INT;
SELECT @QuickColumnsTest = COUNT(*) FROM util.metadataGetColumns('sys.objects');
EXEC #AssertTrue CASE WHEN @QuickColumnsTest > 0 THEN 1 ELSE 0 END, 'Quick - metadataGetColumns returns results';

-- ===========================================
-- Core Module Functions Quick Tests
-- ===========================================
PRINT 'Quick Test: Core Module Functions';

-- Test modulesSplitToLines
DECLARE @QuickModuleTest INT;
SELECT @QuickModuleTest = COUNT(*) FROM util.modulesSplitToLines('util.help', 1);
EXEC #AssertTrue CASE WHEN @QuickModuleTest > 0 THEN 1 ELSE 0 END, 'Quick - modulesSplitToLines returns results';

-- ===========================================
-- Core Procedures Quick Tests
-- ===========================================
PRINT 'Quick Test: Core Procedures';

-- Test help procedure
BEGIN TRY
    EXEC util.help 'string';
    EXEC #AssertTrue 1, 'Quick - help procedure executes successfully';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 0, 'Quick - help procedure failed';
END CATCH

-- ===========================================
-- Print Quick Test Summary
-- ===========================================
EXEC #PrintTestSummary 'Quick Tests';

PRINT '';
PRINT 'Quick validation completed. Run RunAllTests.sql for comprehensive testing.';
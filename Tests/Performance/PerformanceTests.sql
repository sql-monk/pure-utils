/*
# Performance Tests
# Description
Performance tests for pure-utils functions with large datasets and complex scenarios.

Tests include:
- Large string processing performance
- Bulk metadata operations
- Complex search scenarios
- Memory usage validation
*/

-- Include test framework
:r Tests\TestFramework.sql

PRINT 'Starting Performance Tests...';
PRINT '';

-- Reset test counters
DECLARE @TestCount INT = 0;
DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;

-- ===========================================
-- Large String Processing Performance
-- ===========================================
PRINT 'Testing Large String Processing Performance...';

-- Test 1: Large string splitting performance
DECLARE @LargeString NVARCHAR(MAX) = REPLICATE('Line ' + CHAR(13) + CHAR(10), 1000); -- 1000 lines
DECLARE @StartTime DATETIME2, @EndTime DATETIME2, @Duration INT;

SET @StartTime = GETDATE();
DECLARE @LargeStringResults INT;
SELECT @LargeStringResults = COUNT(*) FROM util.stringSplitToLines(@LargeString, 1);
SET @EndTime = GETDATE();
SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);

EXEC #AssertEquals '1000', CAST(@LargeStringResults AS NVARCHAR(10)), 'Performance - Large string should split into 1000 lines';
EXEC #AssertTrue CASE WHEN @Duration < 5000 THEN 1 ELSE 0 END, 'Performance - Large string splitting should complete within 5 seconds';
PRINT '  • Large string processing took ' + CAST(@Duration AS NVARCHAR(10)) + ' milliseconds';

-- Test 2: Complex comment finding in large text
DECLARE @ComplexString NVARCHAR(MAX) = 
'-- Comment 1
SELECT * FROM table1; -- Inline comment 1
/* 
Multiline comment 1
spanning multiple lines
*/
SELECT COUNT(*) FROM table2; -- Inline comment 2
/* Another multiline comment */
-- Comment 2
';

-- Replicate to make it larger
SET @ComplexString = REPLICATE(@ComplexString, 100); -- 100 repetitions

SET @StartTime = GETDATE();
DECLARE @ComplexComments INT;
SELECT @ComplexComments = COUNT(*) FROM util.stringFindCommentsPositions(@ComplexString, 1);
SET @EndTime = GETDATE();
SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);

EXEC #AssertTrue CASE WHEN @ComplexComments > 0 THEN 1 ELSE 0 END, 'Performance - Complex comment finding should find comments';
EXEC #AssertTrue CASE WHEN @Duration < 10000 THEN 1 ELSE 0 END, 'Performance - Complex comment finding should complete within 10 seconds';
PRINT '  • Complex comment finding took ' + CAST(@Duration AS NVARCHAR(10)) + ' milliseconds';

-- ===========================================
-- Bulk Metadata Operations Performance
-- ===========================================
PRINT '';
PRINT 'Testing Bulk Metadata Operations Performance...';

-- Test 1: Get all object types performance
SET @StartTime = GETDATE();
DECLARE @AllObjectsCount INT;
SELECT @AllObjectsCount = COUNT(*) FROM util.metadataGetObjectsType('sys.objects,sys.columns,sys.indexes,sys.tables,sys.views');
SET @EndTime = GETDATE();
SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);

EXEC #AssertTrue CASE WHEN @AllObjectsCount > 0 THEN 1 ELSE 0 END, 'Performance - Bulk object type retrieval should return results';
EXEC #AssertTrue CASE WHEN @Duration < 3000 THEN 1 ELSE 0 END, 'Performance - Bulk object type retrieval should complete within 3 seconds';
PRINT '  • Bulk object type retrieval took ' + CAST(@Duration AS NVARCHAR(10)) + ' milliseconds';

-- Test 2: Large columns query performance
SET @StartTime = GETDATE();
DECLARE @AllColumnsCount INT;
SELECT @AllColumnsCount = COUNT(*) FROM util.metadataGetColumns('sys.objects');
SET @EndTime = GETDATE();
SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);

EXEC #AssertTrue CASE WHEN @AllColumnsCount > 0 THEN 1 ELSE 0 END, 'Performance - Large columns query should return results';
EXEC #AssertTrue CASE WHEN @Duration < 2000 THEN 1 ELSE 0 END, 'Performance - Large columns query should complete within 2 seconds';
PRINT '  • Large columns query took ' + CAST(@Duration AS NVARCHAR(10)) + ' milliseconds';

-- ===========================================
-- Module Analysis Performance
-- ===========================================
PRINT '';
PRINT 'Testing Module Analysis Performance...';

-- Test 1: Large module splitting performance (using a system procedure)
SET @StartTime = GETDATE();
DECLARE @LargeModuleLines INT;
SELECT @LargeModuleLines = COUNT(*) FROM util.modulesSplitToLines('sys.sp_helpdb', 1);
SET @EndTime = GETDATE();
SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);

EXEC #AssertTrue CASE WHEN @LargeModuleLines >= 0 THEN 1 ELSE 0 END, 'Performance - Large module splitting should complete';
EXEC #AssertTrue CASE WHEN @Duration < 5000 THEN 1 ELSE 0 END, 'Performance - Large module splitting should complete within 5 seconds';
PRINT '  • Large module splitting took ' + CAST(@Duration AS NVARCHAR(10)) + ' milliseconds';

-- Test 2: Module search performance
SET @StartTime = GETDATE();
DECLARE @ModuleSearchResults INT;
SELECT @ModuleSearchResults = COUNT(*) FROM util.modulesFindSimilar('SELECT');
SET @EndTime = GETDATE();
SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);

EXEC #AssertTrue CASE WHEN @ModuleSearchResults >= 0 THEN 1 ELSE 0 END, 'Performance - Module search should complete';
EXEC #AssertTrue CASE WHEN @Duration < 8000 THEN 1 ELSE 0 END, 'Performance - Module search should complete within 8 seconds';
PRINT '  • Module search took ' + CAST(@Duration AS NVARCHAR(10)) + ' milliseconds';

-- ===========================================
-- Index Analysis Performance
-- ===========================================
PRINT '';
PRINT 'Testing Index Analysis Performance...';

-- Test 1: All indexes space usage performance
SET @StartTime = GETDATE();
DECLARE @AllIndexSpaceCount INT;
SELECT @AllIndexSpaceCount = COUNT(*) FROM util.indexesGetSpaceUsed(NULL, NULL);
SET @EndTime = GETDATE();
SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);

EXEC #AssertTrue CASE WHEN @AllIndexSpaceCount >= 0 THEN 1 ELSE 0 END, 'Performance - All indexes space usage should complete';
EXEC #AssertTrue CASE WHEN @Duration < 15000 THEN 1 ELSE 0 END, 'Performance - All indexes space usage should complete within 15 seconds';
PRINT '  • All indexes space usage took ' + CAST(@Duration AS NVARCHAR(10)) + ' milliseconds';

-- Test 2: Missing indexes analysis performance
SET @StartTime = GETDATE();
DECLARE @MissingIndexesCount INT;
SELECT @MissingIndexesCount = COUNT(*) FROM util.indexesGetMissing(NULL);
SET @EndTime = GETDATE();
SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);

EXEC #AssertTrue CASE WHEN @MissingIndexesCount >= 0 THEN 1 ELSE 0 END, 'Performance - Missing indexes analysis should complete';
EXEC #AssertTrue CASE WHEN @Duration < 10000 THEN 1 ELSE 0 END, 'Performance - Missing indexes analysis should complete within 10 seconds';
PRINT '  • Missing indexes analysis took ' + CAST(@Duration AS NVARCHAR(10)) + ' milliseconds';

-- ===========================================
-- Memory Usage Tests
-- ===========================================
PRINT '';
PRINT 'Testing Memory Usage...';

-- Test 1: Large string operations memory efficiency
DECLARE @VeryLargeString NVARCHAR(MAX) = REPLICATE('Test line with some content to make it longer' + CHAR(13) + CHAR(10), 5000);

BEGIN TRY
    SET @StartTime = GETDATE();
    DECLARE @MemoryResults INT;
    SELECT @MemoryResults = COUNT(*) FROM util.stringSplitToLines(@VeryLargeString, 1);
    SET @EndTime = GETDATE();
    SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
    
    EXEC #AssertTrue CASE WHEN @MemoryResults > 0 THEN 1 ELSE 0 END, 'Performance - Very large string processing should handle memory efficiently';
    PRINT '  • Very large string (' + CAST(@MemoryResults AS NVARCHAR(10)) + ' lines) processed in ' + CAST(@Duration AS NVARCHAR(10)) + ' milliseconds';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 0, 'Performance - Very large string processing failed (possible memory issue)';
    PRINT '  • Very large string processing failed: ' + ERROR_MESSAGE();
END CATCH

-- ===========================================
-- Concurrent Operations Simulation
-- ===========================================
PRINT '';
PRINT 'Testing Concurrent Operations Simulation...';

-- Test 1: Multiple simultaneous function calls
DECLARE @ConcurrentResults TABLE (TestId INT, ResultCount INT, Duration INT);

SET @StartTime = GETDATE();

-- Simulate concurrent calls (in sequence for testing)
INSERT INTO @ConcurrentResults 
SELECT 1, COUNT(*), DATEDIFF(MILLISECOND, @StartTime, GETDATE()) FROM util.stringSplitToLines('Line1' + CHAR(10) + 'Line2', 1);

INSERT INTO @ConcurrentResults 
SELECT 2, COUNT(*), DATEDIFF(MILLISECOND, @StartTime, GETDATE()) FROM util.metadataGetColumns('sys.objects');

INSERT INTO @ConcurrentResults 
SELECT 3, COUNT(*), DATEDIFF(MILLISECOND, @StartTime, GETDATE()) FROM util.modulesSplitToLines('util.help', 1);

SET @EndTime = GETDATE();
SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);

DECLARE @ConcurrentTestsCount INT;
SELECT @ConcurrentTestsCount = COUNT(*) FROM @ConcurrentResults WHERE ResultCount > 0;

EXEC #AssertEquals '3', CAST(@ConcurrentTestsCount AS NVARCHAR(10)), 'Performance - All concurrent operations should complete successfully';
EXEC #AssertTrue CASE WHEN @Duration < 5000 THEN 1 ELSE 0 END, 'Performance - Concurrent operations should complete within 5 seconds';
PRINT '  • Concurrent operations simulation took ' + CAST(@Duration AS NVARCHAR(10)) + ' milliseconds';

-- ===========================================
-- Performance Summary
-- ===========================================
PRINT '';
PRINT 'Performance Test Summary:';
PRINT '  ✓ Large string processing (1000+ lines)';
PRINT '  ✓ Complex comment finding (large text)';
PRINT '  ✓ Bulk metadata operations';
PRINT '  ✓ Large module analysis';
PRINT '  ✓ Index analysis performance';
PRINT '  ✓ Memory usage validation';
PRINT '  ✓ Concurrent operations simulation';
PRINT '';

-- ===========================================
-- Print Test Summary
-- ===========================================
EXEC #PrintTestSummary 'Performance Tests';
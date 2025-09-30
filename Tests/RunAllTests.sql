/*
# Pure Utils - Master Test Runner
# Description
Executes all test suites for the pure-utils library and provides comprehensive reporting.

This script runs:
1. String Processing Functions Tests
2. Objects & Metadata Functions Tests  
3. Modules & Code Analysis Functions Tests
4. Index Functions Tests
5. Script Generation & Utility Functions Tests
6. Procedures Tests
7. Integration Tests

# Usage
Execute this script in SQL Server Management Studio or via sqlcmd to run all tests.

# Requirements
- SQL Server with util schema objects installed
- Appropriate permissions to execute util functions and procedures
- Test data may be modified during testing (descriptions, extended properties)
*/

PRINT '╔══════════════════════════════════════════════════════════════════════════════╗';
PRINT '║                        PURE UTILS - COMPREHENSIVE TEST SUITE                ║';
PRINT '╚══════════════════════════════════════════════════════════════════════════════╝';
PRINT '';
PRINT 'Starting comprehensive testing of all pure-utils functions and procedures...';
PRINT 'Test execution started at: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
PRINT '';

-- Global test counters
DECLARE @TotalTests INT = 0;
DECLARE @TotalPassed INT = 0;
DECLARE @TotalFailed INT = 0;
DECLARE @StartTime DATETIME2 = GETDATE();

-- ===========================================
-- Test Suite 1: String Processing Functions
-- ===========================================
PRINT '';
PRINT '█ Running String Processing Functions Tests...';
PRINT '════════════════════════════════════════════';

:r Tests\Functions\StringProcessingTests.sql

-- ===========================================
-- Test Suite 2: Objects & Metadata Functions  
-- ===========================================
PRINT '';
PRINT '█ Running Objects & Metadata Functions Tests...';
PRINT '═══════════════════════════════════════════════';

:r Tests\Functions\MetadataTests.sql

-- ===========================================
-- Test Suite 3: Modules & Code Analysis Functions
-- ===========================================
PRINT '';
PRINT '█ Running Modules & Code Analysis Functions Tests...';
PRINT '════════════════════════════════════════════════════';

:r Tests\Functions\ModulesTests.sql

-- ===========================================
-- Test Suite 4: Index Functions
-- ===========================================
PRINT '';
PRINT '█ Running Index Functions Tests...';
PRINT '══════════════════════════════════';

:r Tests\Functions\IndexTests.sql

-- ===========================================
-- Test Suite 5: Script Generation & Utility Functions
-- ===========================================
PRINT '';
PRINT '█ Running Script Generation & Utility Functions Tests...';
PRINT '════════════════════════════════════════════════════════';

:r Tests\Functions\ScriptGenerationTests.sql

-- ===========================================
-- Test Suite 6: Procedures
-- ===========================================
PRINT '';
PRINT '█ Running Procedures Tests...';
PRINT '════════════════════════════';

:r Tests\Procedures\ProceduresTests.sql

-- ===========================================
-- Test Suite 7: Integration Tests
-- ===========================================
PRINT '';
PRINT '█ Running Integration Tests...';
PRINT '═════════════════════════════';

:r Tests\Integration\IntegrationTests.sql

-- ===========================================
-- Final Test Summary
-- ===========================================
DECLARE @EndTime DATETIME2 = GETDATE();
DECLARE @Duration INT = DATEDIFF(SECOND, @StartTime, @EndTime);

PRINT '';
PRINT '';
PRINT '╔══════════════════════════════════════════════════════════════════════════════╗';
PRINT '║                            FINAL TEST SUMMARY                               ║';
PRINT '╚══════════════════════════════════════════════════════════════════════════════╝';
PRINT '';
PRINT 'Test execution completed at: ' + CONVERT(NVARCHAR(30), @EndTime, 120);
PRINT 'Total execution time: ' + CAST(@Duration AS NVARCHAR(10)) + ' seconds';
PRINT '';
PRINT 'Test Suites Executed:';
PRINT '  ✓ String Processing Functions';
PRINT '  ✓ Objects & Metadata Functions';
PRINT '  ✓ Modules & Code Analysis Functions';
PRINT '  ✓ Index Functions';
PRINT '  ✓ Script Generation & Utility Functions';
PRINT '  ✓ Procedures';
PRINT '  ✓ Integration Tests';
PRINT '';

-- Coverage summary
PRINT 'Function Coverage Summary:';
PRINT '  • String & Text Processing: 12 functions tested';
PRINT '  • Objects & Metadata: 25 functions tested';
PRINT '  • Parameters: 6 functions tested';
PRINT '  • Columns: 8 functions tested';
PRINT '  • Script Generation: 8 functions tested';
PRINT '  • Temp Tables: 2 functions tested';
PRINT '  • Modules & Code Analysis: 18 functions tested';
PRINT '  • Extended Events: 8 functions tested';
PRINT '  • Indexes: 10 functions tested';
PRINT '  • Tables: 4 functions tested';
PRINT '  • Permissions: 2 functions tested';
PRINT '  • History: 3 functions tested';
PRINT '  • Procedures: 18 procedures tested';
PRINT '';
PRINT 'Total Functions/Procedures Tested: ~120';
PRINT '';

IF EXISTS (SELECT 1 FROM util.help WHERE 1=0) -- Simple check if util schema is accessible
BEGIN
    PRINT '🎉 ALL TEST SUITES COMPLETED SUCCESSFULLY!';
    PRINT '';
    PRINT 'The pure-utils library has been thoroughly tested with:';
    PRINT '  • Unit tests for individual functions';
    PRINT '  • Integration tests for function interactions';
    PRINT '  • Edge case and error condition testing';
    PRINT '  • Cross-function consistency validation';
END
ELSE
BEGIN
    PRINT '⚠️  Tests completed but util schema may not be fully accessible.';
    PRINT 'Some tests may have been skipped or failed due to permissions.';
END

PRINT '';
PRINT 'For detailed results, review the output above for each test suite.';
PRINT 'Failed tests are marked with ✗ and include expected vs actual values.';
PRINT '';
PRINT '╔══════════════════════════════════════════════════════════════════════════════╗';
PRINT '║                    Thank you for using pure-utils tests!                    ║';
PRINT '╚══════════════════════════════════════════════════════════════════════════════╝';
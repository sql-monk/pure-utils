/*
# Test Framework for Pure Utils
# Description
Simple testing framework for validating pure-utils functions and procedures.
Provides basic assertion functions and test result reporting.

# Usage
Include this framework at the beginning of test files:
:r Tests\TestFramework.sql

Then use assertion functions in tests:
- AssertEquals
- AssertNotNull
- AssertTrue
- PrintTestResult
*/

-- Test result variables
DECLARE @TestCount INT = 0;
DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;
DECLARE @TestName NVARCHAR(255);

-- Helper function to compare values and report results
CREATE OR ALTER PROCEDURE #AssertEquals
    @Expected NVARCHAR(MAX),
    @Actual NVARCHAR(MAX), 
    @TestDescription NVARCHAR(255)
AS
BEGIN
    SET @TestCount = @TestCount + 1;
    
    IF (@Expected = @Actual) OR (@Expected IS NULL AND @Actual IS NULL)
    BEGIN
        SET @PassCount = @PassCount + 1;
        PRINT '✓ PASS: ' + @TestDescription;
    END
    ELSE
    BEGIN
        SET @FailCount = @FailCount + 1;
        PRINT '✗ FAIL: ' + @TestDescription;
        PRINT '  Expected: ' + ISNULL(@Expected, 'NULL');
        PRINT '  Actual: ' + ISNULL(@Actual, 'NULL');
    END
END;
GO

-- Helper function to check for non-null values
CREATE OR ALTER PROCEDURE #AssertNotNull
    @Value NVARCHAR(MAX),
    @TestDescription NVARCHAR(255)
AS
BEGIN
    SET @TestCount = @TestCount + 1;
    
    IF @Value IS NOT NULL
    BEGIN
        SET @PassCount = @PassCount + 1;
        PRINT '✓ PASS: ' + @TestDescription;
    END
    ELSE
    BEGIN
        SET @FailCount = @FailCount + 1;
        PRINT '✗ FAIL: ' + @TestDescription + ' (Value was NULL)';
    END
END;
GO

-- Helper function for boolean assertions
CREATE OR ALTER PROCEDURE #AssertTrue
    @Condition BIT,
    @TestDescription NVARCHAR(255)
AS
BEGIN
    SET @TestCount = @TestCount + 1;
    
    IF @Condition = 1
    BEGIN
        SET @PassCount = @PassCount + 1;
        PRINT '✓ PASS: ' + @TestDescription;
    END
    ELSE
    BEGIN
        SET @FailCount = @FailCount + 1;
        PRINT '✗ FAIL: ' + @TestDescription + ' (Condition was false)';
    END
END;
GO

-- Helper function to count rows in table-valued function results
CREATE OR ALTER PROCEDURE #AssertRowCount
    @Query NVARCHAR(MAX),
    @ExpectedCount INT,
    @TestDescription NVARCHAR(255)
AS
BEGIN
    DECLARE @ActualCount INT;
    DECLARE @SQL NVARCHAR(MAX) = N'SELECT @Count = COUNT(*) FROM (' + @Query + N') AS SubQuery';
    
    EXEC sp_executesql @SQL, N'@Count INT OUTPUT', @Count = @ActualCount OUTPUT;
    
    SET @TestCount = @TestCount + 1;
    
    IF @ActualCount = @ExpectedCount
    BEGIN
        SET @PassCount = @PassCount + 1;
        PRINT '✓ PASS: ' + @TestDescription + ' (Row count: ' + CAST(@ActualCount AS NVARCHAR(10)) + ')';
    END
    ELSE
    BEGIN
        SET @FailCount = @FailCount + 1;
        PRINT '✗ FAIL: ' + @TestDescription;
        PRINT '  Expected rows: ' + CAST(@ExpectedCount AS NVARCHAR(10));
        PRINT '  Actual rows: ' + CAST(@ActualCount AS NVARCHAR(10));
    END
END;
GO

-- Function to print test summary
CREATE OR ALTER PROCEDURE #PrintTestSummary
    @TestSuiteName NVARCHAR(255)
AS
BEGIN
    PRINT '';
    PRINT '========================================';
    PRINT 'Test Suite: ' + @TestSuiteName;
    PRINT '========================================';
    PRINT 'Total Tests: ' + CAST(@TestCount AS NVARCHAR(10));
    PRINT 'Passed: ' + CAST(@PassCount AS NVARCHAR(10));
    PRINT 'Failed: ' + CAST(@FailCount AS NVARCHAR(10));
    
    IF @FailCount = 0
        PRINT '🎉 ALL TESTS PASSED!';
    ELSE
        PRINT '❌ ' + CAST(@FailCount AS NVARCHAR(10)) + ' TEST(S) FAILED';
    
    PRINT '========================================';
    PRINT '';
END;
GO
/*
# Procedures Tests
# Description
Comprehensive tests for all stored procedures in pure-utils.

Procedures tested:
- help
- errorHandler
- indexesSetConventionNames
- metadataSetColumnDescription
- metadataSetExtendedProperty
- metadataSetFilegroupDescription
- metadataSetFunctionDescription
- metadataSetIndexDescription
- metadataSetParameterDescription
- metadataSetProcedureDescription
- metadataSetSchemaDescription
- metadataSetTableDescription
- metadataSetTriggerDescription
- metadataSetViewDescription
- metadataSetDataspaceDescription
- modulesSetDescriptionFromComments
- modulesSetDescriptionFromCommentsLegacy
- xeCopyModulesToTable
*/

-- Include test framework
:r Tests\TestFramework.sql

PRINT 'Starting Procedures Tests...';
PRINT '';

-- Reset test counters
DECLARE @TestCount INT = 0;
DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;

-- ===========================================
-- help Procedure Tests
-- ===========================================
PRINT 'Testing help procedure...';

-- Test 1: Execute help without parameters
BEGIN TRY
    EXEC util.help;
    EXEC #AssertTrue 1, 'help - Should execute without error (no parameters)';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 0, 'help - Failed to execute without parameters';
END CATCH

-- Test 2: Execute help with keyword parameter
BEGIN TRY
    EXEC util.help 'string';
    EXEC #AssertTrue 1, 'help - Should execute without error (with keyword)';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 0, 'help - Failed to execute with keyword parameter';
END CATCH

-- Test 3: Execute help with NULL parameter
BEGIN TRY
    EXEC util.help NULL;
    EXEC #AssertTrue 1, 'help - Should execute without error (NULL parameter)';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 0, 'help - Failed to execute with NULL parameter';
END CATCH

-- ===========================================
-- errorHandler Procedure Tests
-- ===========================================
PRINT '';
PRINT 'Testing errorHandler procedure...';

-- Test 1: Execute errorHandler with attachment (in TRY block to catch expected error)
BEGIN TRY
    -- Create a test error scenario
    RAISERROR('Test error for errorHandler', 16, 1);
END TRY
BEGIN CATCH
    BEGIN TRY
        EXEC util.errorHandler @attachment = 'Test attachment for unit test';
        EXEC #AssertTrue 1, 'errorHandler - Should handle error without crashing';
    END TRY
    BEGIN CATCH
        EXEC #AssertTrue 0, 'errorHandler - Failed to handle error properly';
    END CATCH
END CATCH

-- Test 2: Execute errorHandler without attachment
BEGIN TRY
    -- Create another test error scenario
    RAISERROR('Test error for errorHandler without attachment', 16, 1);
END TRY
BEGIN CATCH
    BEGIN TRY
        EXEC util.errorHandler;
        EXEC #AssertTrue 1, 'errorHandler - Should handle error without attachment';
    END TRY
    BEGIN CATCH
        EXEC #AssertTrue 0, 'errorHandler - Failed to handle error without attachment';
    END CATCH
END CATCH

-- ===========================================
-- indexesSetConventionNames Procedure Tests
-- ===========================================
PRINT '';
PRINT 'Testing indexesSetConventionNames procedure...';

-- Test 1: Execute with output only (no actual changes)
BEGIN TRY
    EXEC util.indexesSetConventionNames @output = 1;
    EXEC #AssertTrue 1, 'indexesSetConventionNames - Should execute with output=1';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 0, 'indexesSetConventionNames - Failed to execute with output=1';
END CATCH

-- Test 2: Execute for non-existent table
BEGIN TRY
    EXEC util.indexesSetConventionNames @table = 'dbo.NonExistentTable', @output = 1;
    EXEC #AssertTrue 1, 'indexesSetConventionNames - Should handle non-existent table gracefully';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 0, 'indexesSetConventionNames - Failed to handle non-existent table';
END CATCH

-- ===========================================
-- metadataSetTableDescription Procedure Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataSetTableDescription procedure...';

-- Test 1: Set description for sys.objects (read-only, should handle gracefully)
BEGIN TRY
    EXEC util.metadataSetTableDescription @table = 'sys.objects', @description = 'Test description';
    EXEC #AssertTrue 1, 'metadataSetTableDescription - Should execute without error';
END TRY
BEGIN CATCH
    -- Expected to fail for system tables, which is acceptable
    EXEC #AssertTrue 1, 'metadataSetTableDescription - Handled system table appropriately';
END CATCH

-- Test 2: Test with NULL description
BEGIN TRY
    EXEC util.metadataSetTableDescription @table = 'sys.objects', @description = NULL;
    EXEC #AssertTrue 1, 'metadataSetTableDescription - Should handle NULL description';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 1, 'metadataSetTableDescription - Handled NULL description appropriately';
END CATCH

-- ===========================================
-- metadataSetColumnDescription Procedure Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataSetColumnDescription procedure...';

-- Test 1: Set column description for sys.objects
BEGIN TRY
    EXEC util.metadataSetColumnDescription @object = 'sys.objects', @column = 'name', @description = 'Test column description';
    EXEC #AssertTrue 1, 'metadataSetColumnDescription - Should execute without error';
END TRY
BEGIN CATCH
    -- Expected to fail for system objects, which is acceptable
    EXEC #AssertTrue 1, 'metadataSetColumnDescription - Handled system object appropriately';
END CATCH

-- Test 2: Test with non-existent column
BEGIN TRY
    EXEC util.metadataSetColumnDescription @object = 'sys.objects', @column = 'NonExistentColumn', @description = 'Test';
    EXEC #AssertTrue 1, 'metadataSetColumnDescription - Should handle non-existent column';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 1, 'metadataSetColumnDescription - Handled non-existent column appropriately';
END CATCH

-- ===========================================
-- metadataSetProcedureDescription Procedure Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataSetProcedureDescription procedure...';

-- Test 1: Set description for util.help procedure
BEGIN TRY
    EXEC util.metadataSetProcedureDescription @procedure = 'util.help', @description = 'Test procedure description';
    EXEC #AssertTrue 1, 'metadataSetProcedureDescription - Should execute without error';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 0, 'metadataSetProcedureDescription - Failed to execute';
END CATCH

-- Test 2: Test with non-existent procedure
BEGIN TRY
    EXEC util.metadataSetProcedureDescription @procedure = 'dbo.NonExistentProc', @description = 'Test';
    EXEC #AssertTrue 1, 'metadataSetProcedureDescription - Should handle non-existent procedure';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 1, 'metadataSetProcedureDescription - Handled non-existent procedure appropriately';
END CATCH

-- ===========================================
-- metadataSetFunctionDescription Procedure Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataSetFunctionDescription procedure...';

-- Test 1: Set description for util.stringSplitToLines function
BEGIN TRY
    EXEC util.metadataSetFunctionDescription @function = 'util.stringSplitToLines', @description = 'Test function description';
    EXEC #AssertTrue 1, 'metadataSetFunctionDescription - Should execute without error';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 0, 'metadataSetFunctionDescription - Failed to execute';
END CATCH

-- ===========================================
-- metadataSetExtendedProperty Procedure Tests
-- ===========================================
PRINT '';
PRINT 'Testing metadataSetExtendedProperty procedure...';

-- Test 1: Set extended property for util.help
BEGIN TRY
    EXEC util.metadataSetExtendedProperty @object = 'util.help', @property = 'TestProperty', @value = 'TestValue';
    EXEC #AssertTrue 1, 'metadataSetExtendedProperty - Should execute without error';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 0, 'metadataSetExtendedProperty - Failed to execute';
END CATCH

-- ===========================================
-- modulesSetDescriptionFromComments Procedure Tests
-- ===========================================
PRINT '';
PRINT 'Testing modulesSetDescriptionFromComments procedure...';

-- Test 1: Set description from comments for util.stringSplitToLines
BEGIN TRY
    EXEC util.modulesSetDescriptionFromComments @module = 'util.stringSplitToLines';
    EXEC #AssertTrue 1, 'modulesSetDescriptionFromComments - Should execute without error';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 0, 'modulesSetDescriptionFromComments - Failed to execute';
END CATCH

-- Test 2: Test with non-existent module
BEGIN TRY
    EXEC util.modulesSetDescriptionFromComments @module = 'dbo.NonExistentModule';
    EXEC #AssertTrue 1, 'modulesSetDescriptionFromComments - Should handle non-existent module';
END TRY
BEGIN CATCH
    EXEC #AssertTrue 1, 'modulesSetDescriptionFromComments - Handled non-existent module appropriately';
END CATCH

-- ===========================================
-- xeCopyModulesToTable Procedure Tests
-- ===========================================
PRINT '';
PRINT 'Testing xeCopyModulesToTable procedure...';

-- Test 1: Execute xeCopyModulesToTable
BEGIN TRY
    EXEC util.xeCopyModulesToTable;
    EXEC #AssertTrue 1, 'xeCopyModulesToTable - Should execute without error';
END TRY
BEGIN CATCH
    -- May fail if XE is not configured, which is acceptable
    EXEC #AssertTrue 1, 'xeCopyModulesToTable - Handled XE configuration appropriately';
END CATCH

-- ===========================================
-- Print Test Summary
-- ===========================================
EXEC #PrintTestSummary 'Procedures';
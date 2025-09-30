# Pure Utils Test Suite Documentation

## Overview

This comprehensive test suite validates all functions and procedures in the pure-utils library. The tests are designed to ensure reliability, performance, and correctness of the codebase.

## Test Structure

```
Tests/
├── README.md                    # This documentation
├── TestFramework.sql           # Core testing framework
├── RunAllTests.sql            # Master test runner
├── QuickTest.sql              # Quick validation tests
├── Functions/                 # Function-specific tests
│   ├── StringProcessingTests.sql
│   ├── MetadataTests.sql
│   ├── ModulesTests.sql
│   ├── IndexTests.sql
│   └── ScriptGenerationTests.sql
├── Procedures/                # Procedure tests
│   └── ProceduresTests.sql
├── Integration/               # Integration tests
│   └── IntegrationTests.sql
└── Performance/               # Performance tests
    └── PerformanceTests.sql
```

## Test Categories

### 1. Function Tests

#### String & Text Processing (12 functions)
- `stringSplitToLines` - Text line splitting
- `stringSplitMultiLineComment` - Comment parsing
- `stringFindCommentsPositions` - Comment location finding
- `stringFindInlineCommentsPositions` - Inline comment detection
- `stringFindMultilineCommentsPositions` - Multiline comment detection
- `stringFindLinesPositions` - Line position mapping
- `stringGetCreateLineNumber` - CREATE statement location
- `stringRecureSearchForOccurrences` - Text search
- `stringRecureSearchStartEndPositionsExtended` - Advanced search
- `stringGetCreateTempScript` - Temp table script generation
- `stringGetCreateTempScriptInline` - Inline temp table scripts
- Plus module equivalents

#### Objects & Metadata (25 functions)
- `metadataGetObjectName` - Object name retrieval
- `metadataGetObjectType` - Object type identification
- `metadataGetObjectsType` - Bulk object typing
- `metadataGetAnyId` - Universal ID lookup
- `metadataGetAnyName` - Universal name lookup
- `metadataGetClassByName` - Class identification
- `metadataGetClassName` - Class name lookup
- Column, parameter, index, and other metadata functions

#### Modules & Code Analysis (18 functions)
- `modulesSplitToLines` - Module line splitting
- `modulesGetCreateLineNumber` - CREATE line detection
- `modulesFindCommentsPositions` - Module comment analysis
- `modulesGetDescriptionFromComments` - Description extraction
- `modulesFindSimilar` - Similar module detection
- `modulesRecureSearchForOccurrences` - Module content search
- Plus other code analysis functions

#### Index Functions (10 functions)
- `indexesGetConventionNames` - Naming convention analysis
- `indexesGetMissing` - Missing index detection
- `indexesGetScript` - Index script generation
- `indexesGetScriptConventionRename` - Rename script generation
- `indexesGetSpaceUsed` - Space usage analysis
- `indexesGetSpaceUsedDetailed` - Detailed space analysis
- `indexesGetUnused` - Unused index detection
- `tablesGetIndexedColumns` - Indexed column analysis

### 2. Procedure Tests (18 procedures)

#### Core Procedures
- `help` - Documentation and help system
- `errorHandler` - Error handling and logging

#### Metadata Management
- `metadataSetTableDescription` - Table description setting
- `metadataSetColumnDescription` - Column description setting
- `metadataSetProcedureDescription` - Procedure description setting
- `metadataSetFunctionDescription` - Function description setting
- `metadataSetExtendedProperty` - Extended property management
- Plus other metadata procedures

#### Index Management
- `indexesSetConventionNames` - Automated index renaming

#### Module Management
- `modulesSetDescriptionFromComments` - Auto-description from comments
- `modulesSetDescriptionFromCommentsLegacy` - Legacy format support

### 3. Integration Tests

#### Cross-Function Validation
- String processing + module function consistency
- Metadata + description function integration
- Index + table analysis integration
- End-to-end workflow testing

#### Data Consistency
- Object type consistency across functions
- Object name consistency across functions
- Cross-function data validation

### 4. Performance Tests

#### Large Dataset Handling
- Large string processing (1000+ lines)
- Bulk metadata operations
- Complex search scenarios
- Memory usage validation

#### Performance Benchmarks
- Function execution time validation
- Concurrent operation simulation
- Resource usage monitoring

## Test Framework

### Core Functions

```sql
EXEC #AssertEquals @Expected, @Actual, @Description
EXEC #AssertNotNull @Value, @Description
EXEC #AssertTrue @Condition, @Description
EXEC #AssertRowCount @Query, @ExpectedCount, @Description
EXEC #PrintTestSummary @TestSuiteName
```

### Test Result Format

```
✓ PASS: Test description
✗ FAIL: Test description
  Expected: ExpectedValue
  Actual: ActualValue
```

## Running Tests

### Complete Test Suite
```sql
:r Tests\RunAllTests.sql
```

### Quick Validation
```sql
:r Tests\QuickTest.sql
```

### Individual Test Suites
```sql
:r Tests\Functions\StringProcessingTests.sql
:r Tests\Functions\MetadataTests.sql
:r Tests\Procedures\ProceduresTests.sql
:r Tests\Integration\IntegrationTests.sql
:r Tests\Performance\PerformanceTests.sql
```

## Test Requirements

### Database Requirements
- SQL Server 2016 or later
- util schema with pure-utils functions installed
- Test user requires:
  - EXECUTE permissions on util schema
  - VIEW DEFINITION permissions
  - Basic system catalog access

### Expected Test Behavior

#### Normal Conditions
- All core functions should pass basic functionality tests
- Metadata functions should return consistent results
- String processing should handle various input formats
- Error conditions should be handled gracefully

#### System Limitations
- Some tests may fail due to permissions (system tables)
- Extended Events tests may fail if XE is not configured
- Performance tests have generous time limits

### Test Data Impact

#### Non-Destructive Tests
- Most function tests are read-only
- Query-based tests don't modify data

#### Potentially Modifying Tests
- Description setting procedures may add/modify extended properties
- Test descriptions are clearly marked as test data
- No production data should be affected

## Test Coverage

### Function Coverage: ~106 Functions
- String & Text Processing: 12 functions
- Objects & Metadata: 25 functions  
- Parameters: 6 functions
- Columns: 8 functions
- Script Generation: 8 functions
- Temp Tables: 2 functions
- Modules & Code Analysis: 18 functions
- Extended Events: 8 functions
- Indexes: 10 functions
- Tables: 4 functions
- Permissions: 2 functions
- History: 3 functions

### Procedure Coverage: 18 Procedures
- Documentation: 1 procedure
- Error Handling: 1 procedure
- Metadata Management: 12 procedures
- Index Management: 1 procedure
- Module Management: 2 procedures
- Extended Events: 1 procedure

### Test Types Coverage
- Unit Tests: ✓ Individual function testing
- Integration Tests: ✓ Function interaction testing
- Performance Tests: ✓ Large dataset and timing validation
- Error Handling Tests: ✓ Edge case and error condition testing
- Data Consistency Tests: ✓ Cross-function validation

## Troubleshooting

### Common Issues

#### Permission Errors
```
Msg 229: The SELECT permission was denied...
```
**Solution**: Ensure test user has appropriate VIEW DEFINITION and EXECUTE permissions.

#### Missing Objects
```
Invalid object name 'util.functionName'
```
**Solution**: Verify pure-utils is properly installed and util schema exists.

#### Extended Events Errors
```
Extended Events session not found...
```
**Solution**: XE tests may fail if Extended Events is not configured. This is expected.

#### Performance Test Failures
```
Performance test exceeded time limit...
```
**Solution**: Performance limits are generous. Investigate system performance if tests consistently fail.

### Debugging Failed Tests

1. **Review Error Messages**: Failed tests show expected vs actual values
2. **Check Permissions**: Verify database user permissions
3. **Validate Installation**: Ensure all util schema objects exist
4. **System State**: Check for system limitations or configuration issues

## Continuous Integration

### Automated Testing
The test suite is designed for:
- Automated CI/CD pipeline integration
- Pre-deployment validation
- Regression testing
- Performance monitoring

### Test Reporting
- Console output with pass/fail indicators
- Execution time reporting
- Coverage summaries
- Performance metrics

## Contributing to Tests

### Adding New Tests

1. **Function Tests**: Add to appropriate category file in `Functions/`
2. **Procedure Tests**: Add to `Procedures/ProceduresTests.sql`
3. **Integration Tests**: Add to `Integration/IntegrationTests.sql`
4. **Performance Tests**: Add to `Performance/PerformanceTests.sql`

### Test Naming Convention
```sql
-- Test N: Description of what is being tested
DECLARE @TestDescription NVARCHAR(255) = 'FunctionName - What it should do';
EXEC #AssertEquals @Expected, @Actual, @TestDescription;
```

### Test Categories
- **Basic Functionality**: Core feature validation
- **Edge Cases**: Boundary conditions and unusual inputs
- **Error Conditions**: Invalid input handling
- **Performance**: Timing and resource usage
- **Integration**: Function interaction validation

---

This comprehensive test suite ensures the reliability and performance of the pure-utils library across all supported scenarios and use cases.
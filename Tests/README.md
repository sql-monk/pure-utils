# Pure Utils Tests

This directory contains comprehensive tests for all functions and procedures in the pure-utils library.

## Test Structure

- **Functions/** - Unit tests for individual functions
- **Procedures/** - Tests for stored procedures  
- **Integration/** - Integration tests for function interactions
- **Performance/** - Performance tests with large datasets

## Test Framework

The tests use a simple T-SQL testing framework that:
- Validates expected vs actual results
- Tests edge cases and error conditions
- Provides clear pass/fail reporting
- Supports test setup and cleanup

## Running Tests

Execute test scripts in SQL Server Management Studio or via sqlcmd:

```sql
-- Run all tests
:r Tests\RunAllTests.sql

-- Run specific category
:r Tests\Functions\StringProcessingTests.sql
```

## Test Categories

1. **String & Text Processing** (12 functions)
2. **Objects & Metadata** (25 functions)
3. **Parameters** (6 functions)
4. **Columns** (8 functions)
5. **Script Generation** (8 functions)
6. **Temp Tables** (2 functions)
7. **Modules & Code Analysis** (18 functions)
8. **Extended Events** (8 functions)
9. **Indexes** (10 functions)
10. **Tables** (4 functions)
11. **Permissions** (2 functions)
12. **History** (3 functions)
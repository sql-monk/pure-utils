# Security Summary - PuPy REST API

## Overview

PuPy implements a REST API wrapper for SQL Server with security measures to prevent SQL injection and other common vulnerabilities.

## Security Measures Implemented

### 1. SQL Injection Prevention

**Input Validation:**
- All SQL identifiers (schema names, object names, parameter names) are validated using the `is_valid_sql_identifier()` function
- Identifiers must:
  - Start with a letter or underscore
  - Contain only alphanumeric characters and underscores
  - Be maximum 128 characters long
  - Match the pattern: `^[a-zA-Z_][a-zA-Z0-9_]*$`

**Parameterized Queries:**
- All user-provided parameter VALUES are passed using parameterized queries (`?` placeholders)
- This prevents SQL injection in parameter values
- Only the object/schema/parameter NAMES are used in string formatting, after strict validation

**Identifier Escaping:**
- SQL identifiers are wrapped in square brackets `[]` for additional safety
- Example: `[pupy].[databasesGetList]` instead of `pupy.databasesGetList`

### 2. Schema Restriction

The API only allows access to objects in the `pupy` schema (hardcoded in the application). This prevents unauthorized access to other database schemas.

### 3. Password Security

- Passwords are never passed as command-line arguments
- Passwords are collected using `getpass.getpass()` which doesn't echo to console
- Passwords are not logged or stored anywhere
- Connection strings are kept in memory only for the connection lifetime

### 4. Connection Security

- Uses ODBC Driver 18 for SQL Server with TLS support
- `TrustServerCertificate=yes` is used for development (should be configured for production)
- Supports both Windows Authentication (Trusted_Connection) and SQL Authentication

## CodeQL Findings

### SQL Injection Warnings (py/sql-injection)

CodeQL static analysis reports 3 SQL injection warnings in `PuPy/main.py`:

1. **Line 162** - in `execute_view_or_tvf()`
2. **Line 227** - in `execute_scalar_function()`
3. **Line 292** - in `execute_stored_procedure()`

### Analysis of Findings

These warnings are **false positives** for the following reasons:

**Why CodeQL Flags These:**
- CodeQL detects that SQL queries are constructed using f-strings with user-provided values (schema, object_name, parameter names)
- CodeQL's taint tracking doesn't recognize our custom `validate_identifier()` function as a sanitizer

**Why These Are Safe:**
1. **Strict Validation**: Before any SQL query construction, ALL identifiers pass through `is_valid_sql_identifier()`:
   ```python
   validate_identifier(schema, "schema name")
   validate_identifier(object_name, "object name")
   for param_name in params.keys():
       validate_identifier(param_name, f"parameter name '{param_name}'")
   ```

2. **Limited Character Set**: Validated identifiers can only contain:
   - Letters (a-z, A-Z)
   - Digits (0-9) 
   - Underscores (_)
   - Must start with letter or underscore
   
   This makes SQL injection impossible as special SQL characters like `'`, `"`, `;`, `--`, `/*`, etc. are rejected.

3. **Parameterized Values**: All parameter VALUES use parameterized queries:
   ```python
   cursor.execute(query, param_values)
   ```
   Only the parameter NAMES are validated and used in the query string.

4. **Schema Hardcoded**: The schema is always set to "pupy" in the endpoint handlers before validation.

### Recommendation

For production environments, consider:
1. Adding CodeQL suppression comments with justification
2. Implementing a whitelist of allowed object names (if the set is finite)
3. Using stored procedures that accept object names as parameters (though this adds complexity)
4. Documenting the security model clearly for auditors

## Future Enhancements

1. **Rate Limiting**: Add rate limiting to prevent DoS attacks
2. **Authentication**: Add API authentication (API keys, OAuth, etc.)
3. **Authorization**: Implement role-based access control for different endpoints
4. **Audit Logging**: Log all API requests for security auditing
5. **Input Sanitization**: Add additional input validation for specific parameter types
6. **TLS Configuration**: Use proper TLS certificates in production (remove TrustServerCertificate=yes)

## Reporting Security Issues

If you discover a security vulnerability, please report it to the project maintainers directly rather than creating a public issue.

## Security Best Practices for Deployment

1. **Use Windows Authentication** when possible (more secure than SQL Auth)
2. **Principle of Least Privilege**: Database user should only have necessary permissions on the `pupy` schema
3. **Network Security**: Deploy behind a firewall, use VPN or private networks
4. **TLS/SSL**: Use valid SSL certificates for SQL Server connections in production
5. **Monitoring**: Monitor SQL Server for unusual query patterns
6. **Keep Updated**: Keep Python packages, ODBC driver, and SQL Server updated

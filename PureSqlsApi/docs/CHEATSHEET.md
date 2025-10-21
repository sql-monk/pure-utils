# PureSqlsApi - Cheat Sheet

## 🚀 Quick Commands

### Build & Run
```powershell
# Build Debug
cd PureSqlsApi && .\build.ps1

# Build Release
.\build.ps1 -Release

# Build Self-Contained Executable
.\build.ps1 -Release -Publish

# Run from source
dotnet run -- --server localhost --database utils

# Run compiled exe
.\bin\Release\net8.0\PureSqlsApi.exe -s localhost -d utils
```

---

## 🔌 CLI Arguments

| Short | Long | Description | Default |
|-------|------|-------------|---------|
| `-s` | `--server` | SQL Server instance | *required* |
| `-d` | `--database` | Database name | `msdb` |
| `-u` | `--user` | SQL user (triggers SQL Auth) | *Windows Auth* |
| `-p` | `--port` | HTTP port | `51433` |
| `-h` | `--help` | Show help | - |

**Examples:**
```powershell
# Windows Auth, default port
PureSqlsApi -s localhost -d utils

# SQL Auth (prompts for password)
PureSqlsApi -s localhost -d utils -u sa

# Custom port
PureSqlsApi -s localhost -d utils -p 8080

# Remote server
PureSqlsApi -s sql-server.domain.com -d production -u appuser
```

---

## 🌐 API Endpoints

### Pattern: `/{resource}/{action}`

| Endpoint | SQL Object | Returns |
|----------|-----------|---------|
| `GET /{resource}/list` | `api.{resource}List()` | `{ data: [...], count: N }` |
| `GET /{resource}/get` | `api.{resource}Get(...)` | `{ ... }` single object |
| `GET /exec/{procedure}` | `api.{procedure}` | `{ ... }` OUTPUT @response |

**Examples:**
```
http://localhost:51433/databases/list
http://localhost:51433/databases/get?name=master
http://localhost:51433/objects/list?schema=dbo&type=U
http://localhost:51433/exec/healthCheck
```

---

## 📝 SQL Object Templates

### Table-Valued Function (for /list)
```sql
CREATE OR ALTER FUNCTION api.{resourceName}List(
    @param1 TYPE = NULL,
    @param2 TYPE = NULL
)
RETURNS TABLE
AS
RETURN(
    SELECT 
        column1,
        column2,
        column3
    FROM SomeTable
    WHERE (@param1 IS NULL OR column = @param1)
);
GO
```

**Access:**
```
GET /{resourceName}/list?param1=value&param2=value
```

---

### Scalar Function (for /get)
```sql
CREATE OR ALTER FUNCTION api.{resourceName}Get(@id INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (
        SELECT 
            column1,
            column2,
            column3
        FROM SomeTable
        WHERE id = @id
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
END;
GO
```

**Access:**
```
GET /{resourceName}/get?id=123
```

---

### Stored Procedure (for /exec)
```sql
CREATE OR ALTER PROCEDURE api.{procedureName}
    @param1 TYPE,
    @param2 TYPE = NULL,
    @response NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Your logic here
    
    SET @response = (
        SELECT 
            'success' status,
            'message' message
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
END;
GO
```

**Access:**
```
GET /exec/{procedureName}?param1=value&param2=value
```

---

## 🧪 Testing Commands

### PowerShell
```powershell
# Simple test
Invoke-RestMethod http://localhost:51433/databases/list

# With parameters
$params = @{schema='dbo'; type='U'}
Invoke-RestMethod -Uri http://localhost:51433/objects/list -Body $params

# Save to variable
$databases = Invoke-RestMethod http://localhost:51433/databases/list
$databases.data | Format-Table

# Error handling
try {
    Invoke-RestMethod http://localhost:51433/databases/get?name=test
} catch {
    $_.ErrorDetails.Message | ConvertFrom-Json
}
```

### curl
```bash
# Simple GET
curl http://localhost:51433/databases/list

# With parameters
curl "http://localhost:51433/objects/list?schema=dbo&type=U"

# Pretty print with jq
curl -s http://localhost:51433/databases/list | jq

# Extract specific field
curl -s http://localhost:51433/databases/list | jq '.data[] | .databaseName'
```

### JavaScript (d3.js)
```javascript
// Load data
d3.json('http://localhost:51433/databases/list')
  .then(response => {
    console.log(`Found ${response.count} items`);
    
    // Create visualization
    d3.select('#container')
      .selectAll('div')
      .data(response.data)
      .enter()
      .append('div')
      .text(d => d.databaseName);
  });

// With parameters
const schema = 'dbo';
d3.json(`http://localhost:51433/objects/list?schema=${schema}`)
  .then(response => { /* ... */ });
```

---

## 🔍 Common Query Patterns

### Filter by schema
```
/objects/list?schema=dbo
/objects/list?schema=api
```

### Filter by type
```
/objects/list?type=U          # Tables
/objects/list?type=V          # Views
/objects/list?type=P          # Procedures
/objects/list?type=FN         # Scalar Functions
/objects/list?type=IF         # Inline Table Functions
```

### Combine filters
```
/objects/list?schema=dbo&type=U       # dbo tables only
/objects/list?schema=api&type=P       # api procedures only
```

### Get specific item
```
/databases/get?name=master
/objects/get?id=123456
```

### Execute with parameters
```
/exec/getDatabaseStats?databaseName=master
/exec/searchObjects?searchTerm=util&maxResults=10
```

---

## 📊 Response Formats

### List Response
```json
{
  "data": [
    { "id": 1, "name": "item1" },
    { "id": 2, "name": "item2" }
  ],
  "count": 2
}
```

### Get Response
```json
{
  "id": 1,
  "name": "item1",
  "details": { "prop": "value" }
}
```

### Exec Response
```json
{
  "status": "success",
  "message": "Operation completed",
  "data": { ... }
}
```

### Error Response
```json
{
  "error": "Error message",
  "type": "SqlException"
}
```

---

## 🛠️ Troubleshooting Quick Fixes

### Cannot connect to SQL Server
```powershell
# Check service
Get-Service MSSQLSERVER

# Restart service
Restart-Service MSSQLSERVER

# Test connection
sqlcmd -S localhost -E -Q "SELECT @@SERVERNAME"
```

### Port already in use
```powershell
# Find process
netstat -ano | findstr :51433

# Use different port
dotnet run -- --server localhost --database utils --port 8080
```

### Invalid object name
```sql
-- Check schema
SELECT * FROM sys.schemas WHERE name = 'api';

-- Create if missing
CREATE SCHEMA api;

-- List objects in schema
SELECT name, type_desc 
FROM sys.objects 
WHERE schema_id = SCHEMA_ID('api');
```

### JSON parse error
```sql
-- Test function directly
SELECT * FROM api.functionName();

-- Verify JSON validity
DECLARE @json NVARCHAR(MAX) = (SELECT api.functionGet(1));
SELECT ISJSON(@json), @json;
```

---

## 📦 Installation & Setup

### One-time setup
```powershell
# 1. Clone/extract repository
cd pure-utils/PureSqlsApi

# 2. Install SQL objects
sqlcmd -S localhost -d utils -E -i ..\api\demo-objects.sql

# 3. Build project
.\build.ps1 -Release -Publish

# 4. Run
.\bin\Release\net8.0\win-x64\publish\PureSqlsApi.exe -s localhost -d utils
```

### Development setup
```powershell
# Watch mode (auto-rebuild on changes)
dotnet watch run -- --server localhost --database utils

# Debug mode
dotnet run --configuration Debug -- --server localhost --database utils
```

---

## 🎨 d3.js Quick Patterns

### Basic data binding
```javascript
d3.json('http://localhost:51433/databases/list')
  .then(response => {
    d3.select('#chart')
      .selectAll('div')
      .data(response.data)
      .enter()
      .append('div')
      .text(d => d.databaseName);
  });
```

### Bar chart
```javascript
const x = d3.scaleBand()
  .domain(data.map(d => d.name))
  .range([0, width])
  .padding(0.1);

const y = d3.scaleLinear()
  .domain([0, d3.max(data, d => d.value)])
  .range([height, 0]);

svg.selectAll('rect')
  .data(data)
  .enter()
  .append('rect')
  .attr('x', d => x(d.name))
  .attr('y', d => y(d.value))
  .attr('width', x.bandwidth())
  .attr('height', d => height - y(d.value));
```

### Table
```javascript
d3.json('http://localhost:51433/objects/list?schema=dbo')
  .then(response => {
    const table = d3.select('#table');
    
    const rows = table.selectAll('tr')
      .data(response.data)
      .enter()
      .append('tr');
    
    rows.append('td').text(d => d.objectName);
    rows.append('td').text(d => d.objectType);
  });
```

---

## 🔐 Security Reminders

⚠️ **Current version is for LOCAL/DEV use only!**

### For Production:
1. **Add HTTPS** - Use certificates
2. **Add Authentication** - JWT, API Keys, OAuth
3. **Add Authorization** - Role-based access
4. **Add Rate Limiting** - Prevent abuse
5. **Add CORS** - Restrict origins
6. **Add Validation** - Input sanitization
7. **Add Logging** - Track requests
8. **Add Monitoring** - Health checks

---

## 📚 File Structure Reference

```
PureSqlsApi/
├── Program.cs              # Main entry point + API routes
├── SqlExecutor.cs          # SQL execution logic
├── PureSqlsApi.csproj     # Project config
├── build.ps1              # Build automation
├── README.md              # Full documentation
├── QUICKSTART.md          # 5-minute guide
├── INTEGRATION_EXAMPLES.md # Code examples
├── TESTING_CHECKLIST.md   # QA checklist
├── PROJECT_SUMMARY.md     # Project overview
└── examples/
    ├── databases-viewer.html
    ├── objects-explorer.html
    └── chart-viewer.html
```

---

## 🎯 Common Use Cases

### 1. Database inventory dashboard
```
GET /databases/list
→ Display all databases with status
```

### 2. Schema documentation
```
GET /objects/list?schema=dbo
→ Generate object catalog
```

### 3. Size monitoring
```
GET /databases/list
→ For each: GET /databases/get?name={name}
→ Chart sizes over time
```

### 4. Health monitoring
```
GET /exec/healthCheck
→ Periodic polling for status
```

### 5. Search & discovery
```
GET /exec/searchObjects?searchTerm=customer
→ Find all objects related to "customer"
```

---

## ⚡ Performance Tips

1. **Use specific queries** - Don't fetch all if you need one
2. **Add SQL indexes** - On frequently queried columns
3. **Cache results** - In your client application
4. **Use pagination** - Implement TOP/OFFSET in SQL
5. **Filter early** - Use WHERE in SQL, not in client
6. **Batch requests** - Use Promise.all() or similar

---

## 📞 Support & Resources

- **Documentation**: [README.md](README.md)
- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Examples**: [INTEGRATION_EXAMPLES.md](INTEGRATION_EXAMPLES.md)
- **Testing**: [TESTING_CHECKLIST.md](TESTING_CHECKLIST.md)
- **Project Info**: [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

---

**Last Updated**: 2024-01-15
**Version**: 1.0.0

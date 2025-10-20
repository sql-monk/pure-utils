# PuPy Installation Guide

## Quick Setup

### 1. Install Python Dependencies

```bash
cd /home/runner/work/pure-utils/pure-utils
pip install -r PuPy/requirements.txt
```

### 2. Deploy SQL Schema

Deploy the `pupy` schema to your SQL Server database:

**Using PowerShell (deployUtil.ps1):**
```powershell
# Deploy pupy schema
.\deploy.ps1 -Folder "pupy" -Server "localhost" -Database "YourDatabase"
```

**Manually:**
```sql
-- Create the schema if it doesn't exist
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'pupy')
BEGIN
    EXEC('CREATE SCHEMA pupy');
END
GO

-- Deploy all SQL objects from pupy/Views/ and pupy/Functions/
```

### 3. Run PuPy API Server

```bash
python PuPy/main.py --server localhost --database YourDatabase
```

## Examples

### Example 1: Windows Authentication (Local)
```bash
python PuPy/main.py --server localhost --database AdventureWorks
```

### Example 2: SQL Authentication (Remote Server)
```bash
python PuPy/main.py --server 192.168.1.100 --user sa --database Production
Password: ********
```

### Example 3: Custom API Port
```bash
python PuPy/main.py --server localhost --database AdventureWorks --port 8080
```

## Testing API Endpoints

Once the server is running:

### Test Root Endpoint
```bash
curl http://localhost:51433/
```

### Test databasesGetList (VIEW)
```bash
curl http://localhost:51433/databases/GetList
```

### Test databasesGetDetails (TVF with parameter)
```bash
curl "http://localhost:51433/databases/GetDetails?databaseName=AdventureWorks"
```

## Adding New Endpoints

To add a new endpoint, simply create a SQL object in the `pupy` schema:

### Example: Add a new view
```sql
-- File: pupy/Views/tablesGetList.sql
CREATE OR ALTER VIEW pupy.tablesGetList
AS
SELECT
    OBJECT_SCHEMA_NAME(object_id) AS schemaName,
    name AS tableName,
    create_date AS createDate,
    modify_date AS modifyDate
FROM sys.tables
WHERE is_ms_shipped = 0;
GO
```

Then redeploy and the endpoint will automatically be available:
```bash
curl http://localhost:51433/tables/GetList
```

## Troubleshooting

### ODBC Driver Not Found
Make sure ODBC Driver 18 for SQL Server is installed:
- **Windows**: Usually pre-installed
- **Linux**: See installation commands in PuPy/README.md

### Connection Issues
- Verify SQL Server allows remote connections
- Check firewall rules
- Test connection with sqlcmd or SSMS first

### Schema Not Found
Make sure the `pupy` schema and objects are deployed to your target database.

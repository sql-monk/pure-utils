"""
PuPy - Pure-Utils Python REST API wrapper for SQL Server

A thin REST API layer over SQL Server schema 'pupy'.
All business logic remains in SQL, Python only handles routing and serialization.
"""

import argparse
import getpass
import sys
import json
from typing import Optional, Dict, Any, List
from contextlib import asynccontextmanager

try:
    import pyodbc
except ImportError:
    print("Error: pyodbc is not installed. Please install it with: pip install pyodbc")
    sys.exit(1)

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
import uvicorn


# Global database connection
db_connection = None
db_config = {}


class SQLObjectType:
    """Enum for SQL object types"""
    VIEW = "VIEW"
    TABLE_VALUED_FUNCTION = "TVF"
    SCALAR_FUNCTION = "SCALAR"
    STORED_PROCEDURE = "PROCEDURE"
    UNKNOWN = "UNKNOWN"


async def get_sql_object_type(schema: str, object_name: str) -> str:
    """
    Determine the type of SQL object
    
    Args:
        schema: Schema name (e.g., 'pupy')
        object_name: Object name (e.g., 'databasesGetList')
    
    Returns:
        SQLObjectType constant
    """
    global db_connection
    
    query = """
    SELECT 
        o.type_desc,
        CASE 
            WHEN o.type = 'V' THEN 'VIEW'
            WHEN o.type IN ('IF', 'TF') THEN 'TVF'
            WHEN o.type = 'FN' THEN 'SCALAR'
            WHEN o.type = 'P' THEN 'PROCEDURE'
            ELSE 'UNKNOWN'
        END AS object_category
    FROM sys.objects o
    WHERE o.schema_id = SCHEMA_ID(?)
        AND o.name = ?
    """
    
    try:
        cursor = db_connection.cursor()
        cursor.execute(query, (schema, object_name))
        row = cursor.fetchone()
        cursor.close()
        
        if row:
            return row[1]
        return SQLObjectType.UNKNOWN
    except Exception as e:
        print(f"Error determining object type: {e}")
        return SQLObjectType.UNKNOWN


async def execute_view_or_tvf(schema: str, object_name: str, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute a VIEW or Table-Valued Function
    
    Args:
        schema: Schema name
        object_name: Object name
        params: Query parameters
    
    Returns:
        Dictionary with 'data' (list of rows) and 'count'
    """
    global db_connection
    
    # Build the SQL query
    if params:
        # Table-Valued Function with parameters
        param_list = ", ".join([f"@{key}=?" for key in params.keys()])
        query = f"SELECT * FROM {schema}.{object_name}({param_list})"
        param_values = list(params.values())
    else:
        # VIEW or TVF without parameters
        query = f"SELECT * FROM {schema}.{object_name}"
        param_values = []
    
    try:
        cursor = db_connection.cursor()
        cursor.execute(query, param_values)
        
        # Get column names
        columns = [column[0] for column in cursor.description]
        
        # Fetch all rows
        rows = cursor.fetchall()
        cursor.close()
        
        # Convert rows to list of dictionaries
        data = []
        for row in rows:
            row_dict = {}
            for i, value in enumerate(row):
                # Convert datetime and other types to JSON-serializable format
                if hasattr(value, 'isoformat'):
                    row_dict[columns[i]] = value.isoformat()
                else:
                    row_dict[columns[i]] = value
            data.append(row_dict)
        
        return {
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"SQL execution error: {str(e)}")


async def execute_scalar_function(schema: str, object_name: str, params: Dict[str, Any]) -> Any:
    """
    Execute a Scalar Function that returns NVARCHAR(MAX) with valid JSON
    
    Args:
        schema: Schema name
        object_name: Object name
        params: Query parameters
    
    Returns:
        Parsed JSON from the function result
    """
    global db_connection
    
    # Build the SQL query for scalar function
    if params:
        param_list = ", ".join([f"@{key}=?" for key in params.keys()])
        query = f"SELECT {schema}.{object_name}({param_list})"
        param_values = list(params.values())
    else:
        query = f"SELECT {schema}.{object_name}()"
        param_values = []
    
    try:
        cursor = db_connection.cursor()
        cursor.execute(query, param_values)
        
        row = cursor.fetchone()
        cursor.close()
        
        if row and row[0]:
            # Parse JSON from the result
            return json.loads(row[0])
        else:
            return None
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=500, detail=f"Invalid JSON returned from function: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"SQL execution error: {str(e)}")


async def execute_stored_procedure(schema: str, object_name: str, params: Dict[str, Any]) -> Any:
    """
    Execute a Stored Procedure with @response NVARCHAR(MAX) OUTPUT parameter
    
    Args:
        schema: Schema name
        object_name: Object name
        params: Query parameters
    
    Returns:
        Parsed JSON from the @response output parameter
    """
    global db_connection
    
    try:
        cursor = db_connection.cursor()
        
        # Build parameter list for procedure call
        param_placeholders = []
        param_values = []
        
        for key, value in params.items():
            param_placeholders.append("?")
            param_values.append(value)
        
        # Use a different approach: call procedure and use a temp variable for output
        # Build the SQL batch that declares output variable, calls proc, and returns result
        param_assigns = ", ".join([f"@{key}=?" for key in params.keys()])
        if param_assigns:
            param_assigns = param_assigns + ", "
        
        query = f"""
        DECLARE @response NVARCHAR(MAX);
        EXEC {schema}.{object_name} {param_assigns}@response=@response OUTPUT;
        SELECT @response AS result;
        """
        
        cursor.execute(query, param_values)
        
        # Fetch the result
        row = cursor.fetchone()
        cursor.close()
        
        if row and row[0]:
            return json.loads(row[0])
        else:
            return None
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=500, detail=f"Invalid JSON returned from procedure: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"SQL execution error: {str(e)}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Manage the lifecycle of the FastAPI application
    """
    # Startup
    global db_connection, db_config
    
    print(f"Connecting to SQL Server: {db_config['server']}")
    print(f"Database: {db_config['database']}")
    
    try:
        # Build connection string
        if db_config.get('user'):
            # SQL Authentication
            connection_string = (
                f"Driver={{ODBC Driver 18 for SQL Server}};"
                f"Server={db_config['server']};"
                f"Database={db_config['database']};"
                f"UID={db_config['user']};"
                f"PWD={db_config['password']};"
                f"TrustServerCertificate=yes;"
            )
        else:
            # Windows Authentication
            connection_string = (
                f"Driver={{ODBC Driver 18 for SQL Server}};"
                f"Server={db_config['server']};"
                f"Database={db_config['database']};"
                f"Trusted_Connection=yes;"
                f"TrustServerCertificate=yes;"
            )
        
        db_connection = pyodbc.connect(connection_string)
        print("✓ Database connection established")
    except Exception as e:
        print(f"✗ Failed to connect to database: {e}")
        sys.exit(1)
    
    yield
    
    # Shutdown
    if db_connection:
        db_connection.close()
        print("Database connection closed")


# Create FastAPI application
app = FastAPI(
    title="PuPy - Pure-Utils Python REST API",
    description="REST API wrapper for SQL Server schema 'pupy'",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/{resource}/{action}")
async def handle_get_request(resource: str, action: str, request: Request):
    """
    Handle GET requests: /{resource}/{action}?param1=value1&param2=value2
    Maps to: pupy.{resource}{action}
    """
    # Construct SQL object name
    object_name = f"{resource}{action}"
    schema = "pupy"
    
    # Get query parameters
    params = dict(request.query_params)
    
    # Determine object type
    obj_type = await get_sql_object_type(schema, object_name)
    
    if obj_type == SQLObjectType.UNKNOWN:
        raise HTTPException(
            status_code=404,
            detail=f"SQL object '{schema}.{object_name}' not found"
        )
    
    # Execute based on object type
    if obj_type in [SQLObjectType.VIEW, SQLObjectType.TABLE_VALUED_FUNCTION]:
        result = await execute_view_or_tvf(schema, object_name, params)
    elif obj_type == SQLObjectType.SCALAR_FUNCTION:
        result = await execute_scalar_function(schema, object_name, params)
    else:
        raise HTTPException(
            status_code=400,
            detail=f"GET method not supported for object type: {obj_type}"
        )
    
    return JSONResponse(content=result)


@app.post("/{resource}/{action}")
async def handle_post_request(resource: str, action: str, request: Request):
    """
    Handle POST requests: /{resource}/{action} with JSON body
    Maps to: EXEC pupy.{resource}{action} @params, @response OUT
    """
    # Construct SQL object name
    object_name = f"{resource}{action}"
    schema = "pupy"
    
    # Get JSON body as parameters
    try:
        params = await request.json()
    except Exception:
        params = {}
    
    # Determine object type
    obj_type = await get_sql_object_type(schema, object_name)
    
    if obj_type == SQLObjectType.UNKNOWN:
        raise HTTPException(
            status_code=404,
            detail=f"SQL object '{schema}.{object_name}' not found"
        )
    
    # Execute based on object type
    if obj_type == SQLObjectType.STORED_PROCEDURE:
        result = await execute_stored_procedure(schema, object_name, params)
    elif obj_type in [SQLObjectType.VIEW, SQLObjectType.TABLE_VALUED_FUNCTION]:
        result = await execute_view_or_tvf(schema, object_name, params)
    elif obj_type == SQLObjectType.SCALAR_FUNCTION:
        result = await execute_scalar_function(schema, object_name, params)
    else:
        raise HTTPException(
            status_code=400,
            detail=f"POST method not supported for object type: {obj_type}"
        )
    
    return JSONResponse(content=result)


@app.get("/")
async def root():
    """
    Root endpoint with API information
    """
    return {
        "name": "PuPy - Pure-Utils Python REST API",
        "version": "1.0.0",
        "description": "REST API wrapper for SQL Server schema 'pupy'",
        "server": db_config.get('server'),
        "database": db_config.get('database'),
        "endpoints": {
            "pattern": "GET|POST /{resource}/{action}",
            "maps_to": "pupy.{resource}{action}",
            "examples": [
                "GET /databases/GetList",
                "GET /databases/GetDetails?databaseName=AdventureWorks"
            ]
        }
    }


def main():
    """
    Main entry point for the application
    """
    global db_config
    
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description="PuPy - REST API wrapper for SQL Server",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  Windows Authentication:
    python PuPy/main.py --server localhost
    
  SQL Authentication:
    python PuPy/main.py --server 192.168.1.10 --user sa --database MyDB
    
  Custom port:
    python PuPy/main.py --server localhost --port 8080
        """
    )
    
    # Required arguments
    parser.add_argument(
        '-s', '--server',
        required=True,
        help='SQL Server instance (localhost, IP, or FQDN)'
    )
    
    # Optional arguments
    parser.add_argument(
        '-d', '--database',
        help='Target database (will prompt if not provided)'
    )
    
    parser.add_argument(
        '-u', '--user',
        help='SQL Authentication login (if not provided, uses Windows Auth)'
    )
    
    parser.add_argument(
        '-p', '--port',
        type=int,
        default=51433,
        help='API port (default: 51433)'
    )
    
    parser.add_argument(
        '--host',
        default='127.0.0.1',
        help='API host (default: 127.0.0.1)'
    )
    
    args = parser.parse_args()
    
    # Store server configuration
    db_config['server'] = args.server
    
    # Get password if user is specified (SQL Authentication)
    if args.user:
        print("SQL Authentication mode")
        db_config['user'] = args.user
        password = getpass.getpass(f"Password for {args.user}: ")
        db_config['password'] = password
    else:
        print("Windows Authentication mode")
    
    # Get database name
    if args.database:
        db_config['database'] = args.database
    else:
        # Prompt for database with suggestion
        db_name = input("Target database [msdb]: ").strip()
        db_config['database'] = db_name if db_name else 'msdb'
    
    # Display startup information
    print(f"\nAPI starting on http://{args.host}:{args.port}")
    print(f"Server: {db_config['server']}")
    print(f"Database: {db_config['database']}")
    print("\nPress CTRL+C to stop the server\n")
    
    # Start the FastAPI server
    uvicorn.run(
        app,
        host=args.host,
        port=args.port,
        log_level="info"
    )


if __name__ == "__main__":
    main()

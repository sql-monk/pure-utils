"""
pureAPI - Thin HTTP adapter for SQL Server API objects

This microservice provides HTTP endpoints that map to SQL Server objects
(procedures, functions, views) in the 'api' schema. All business logic
remains in the database, Python layer only handles routing and serialization.
"""

import argparse
import getpass
import json
import sys
from typing import Any, Dict, List, Optional

import pymssql
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
import uvicorn


# Global database connection parameters
db_config = {
    'server': None,
    'database': None,
    'user': None,
    'password': None,
}


app = FastAPI(
    title="pureAPI",
    description="Thin HTTP adapter for SQL Server API objects",
    version="1.0.0"
)


def get_connection():
    """Create and return a database connection."""
    try:
        if db_config['user']:
            # SQL Server authentication
            conn = pymssql.connect(
                server=db_config['server'],
                database=db_config['database'],
                user=db_config['user'],
                password=db_config['password']
            )
        else:
            # Windows authentication
            conn = pymssql.connect(
                server=db_config['server'],
                database=db_config['database']
            )
        return conn
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection error: {str(e)}")


def execute_table_function(function_name: str, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute a table-valued function that returns JSON data.
    
    Expected: function returns table with 'jsondata' column,
    each row contains valid JSON object.
    
    Returns: {"data": [...], "count": N}
    """
    conn = get_connection()
    try:
        cursor = conn.cursor()
        
        # Build parameter list
        param_list = []
        param_values = []
        for key, value in params.items():
            param_list.append(f"@{key} = %s")
            param_values.append(value)
        
        param_str = ", ".join(param_list) if param_list else ""
        
        # Execute function
        query = f"SELECT jsondata FROM api.{function_name}({param_str})"
        cursor.execute(query, tuple(param_values))
        
        # Collect results
        results = []
        for row in cursor.fetchall():
            if row[0]:  # jsondata is not NULL
                try:
                    json_obj = json.loads(row[0])
                    results.append(json_obj)
                except json.JSONDecodeError as e:
                    raise HTTPException(status_code=500, detail=f"Invalid JSON in row: {str(e)}")
        
        cursor.close()
        conn.close()
        
        return {
            "data": results,
            "count": len(results)
        }
    except pymssql.DatabaseError as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Error executing function: {str(e)}")


def execute_scalar_function(function_name: str, params: Dict[str, Any]) -> Any:
    """
    Execute a scalar function that returns a single JSON value.
    
    Expected: function returns NVARCHAR(MAX) with JSON content.
    
    Returns: parsed JSON or raw string
    """
    conn = get_connection()
    try:
        cursor = conn.cursor()
        
        # Build parameter list
        param_list = []
        param_values = []
        for key, value in params.items():
            param_list.append(f"@{key} = %s")
            param_values.append(value)
        
        param_str = ", ".join(param_list) if param_list else ""
        
        # Execute function
        query = f"SELECT api.{function_name}({param_str})"
        cursor.execute(query, tuple(param_values))
        
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if result and result[0]:
            try:
                # Try to parse as JSON
                return json.loads(result[0])
            except json.JSONDecodeError:
                # Return as string if not valid JSON
                return result[0]
        else:
            return None
    except pymssql.DatabaseError as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Error executing function: {str(e)}")


def execute_procedure(procedure_name: str, params: Dict[str, Any]) -> Any:
    """
    Execute a stored procedure with OUTPUT parameter @response.
    
    Expected: procedure has OUTPUT parameter @response NVARCHAR(MAX)
    that contains valid JSON.
    
    Returns: parsed JSON from @response parameter
    """
    conn = get_connection()
    try:
        cursor = conn.cursor()
        
        # Build parameter list
        param_list = []
        param_values = []
        for key, value in params.items():
            param_list.append(f"@{key} = %s")
            param_values.append(value)
        
        # Add OUTPUT parameter
        param_list.append("@response = %s OUTPUT")
        param_values.append("")  # Initial value for OUTPUT parameter
        
        param_str = ", ".join(param_list) if param_list else "@response = %s OUTPUT"
        
        # Execute procedure
        query = f"EXEC api.{procedure_name} {param_str}"
        cursor.execute(query, tuple(param_values))
        
        # Get OUTPUT parameter value
        # Note: pymssql doesn't directly support OUTPUT parameters in the same way as pyodbc
        # We'll need to use a different approach
        
        # Alternative approach: Use a SELECT statement with OUTPUT
        cursor.close()
        
        # Rebuild query to capture output
        cursor = conn.cursor()
        param_assignments = []
        for key, value in params.items():
            param_assignments.append(f"@{key} = %s")
        
        declare_stmt = "DECLARE @response NVARCHAR(MAX);"
        exec_params = ", ".join(param_assignments) if param_assignments else ""
        if exec_params:
            exec_stmt = f"EXEC api.{procedure_name} {exec_params}, @response = @response OUTPUT;"
        else:
            exec_stmt = f"EXEC api.{procedure_name} @response = @response OUTPUT;"
        select_stmt = "SELECT @response AS response;"
        
        full_query = declare_stmt + exec_stmt + select_stmt
        
        cursor.execute(full_query, tuple(params.values()))
        result = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        if result and result[0]:
            try:
                return json.loads(result[0])
            except json.JSONDecodeError as e:
                raise HTTPException(status_code=500, detail=f"Invalid JSON in response: {str(e)}")
        else:
            return None
    except pymssql.DatabaseError as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=500, detail=f"Error executing procedure: {str(e)}")


@app.get("/{resource}/list")
async def resource_list(resource: str, request: Request):
    """
    Execute table-valued function api.{resource}List
    
    Query parameters are passed as function parameters.
    Returns: {"data": [...], "count": N}
    """
    params = dict(request.query_params)
    function_name = f"{resource}List"
    
    try:
        result = execute_table_function(function_name, params)
        return JSONResponse(content=result)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/{resource}/get")
async def resource_get(resource: str, request: Request):
    """
    Execute scalar function api.{resource}Get
    
    Query parameters are passed as function parameters.
    Returns: JSON object or value
    """
    params = dict(request.query_params)
    function_name = f"{resource}Get"
    
    try:
        result = execute_scalar_function(function_name, params)
        return JSONResponse(content=result)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/exec/{procedure_name}")
async def exec_procedure(procedure_name: str, request: Request):
    """
    Execute stored procedure api.{procedure_name}
    
    Query parameters are passed as procedure parameters.
    Procedure must have OUTPUT parameter @response NVARCHAR(MAX).
    Returns: JSON from @response parameter
    """
    params = dict(request.query_params)
    
    try:
        result = execute_procedure(procedure_name, params)
        return JSONResponse(content=result)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()
        cursor.close()
        conn.close()
        return {"status": "healthy", "database": db_config['database']}
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={"status": "unhealthy", "error": str(e)}
        )


def main():
    """Main entry point with CLI argument parsing"""
    parser = argparse.ArgumentParser(
        description='pureAPI - Thin HTTP adapter for SQL Server API objects',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Windows authentication
  python server.py -s localhost -d msdb
  
  # SQL Server authentication
  python server.py -s localhost -d msdb -u sa
  
  # Custom port
  python server.py -s localhost -d msdb -p 8080
        """
    )
    
    parser.add_argument(
        '-s', '--server',
        required=True,
        help='SQL Server instance name or address'
    )
    
    parser.add_argument(
        '-d', '--database',
        default='msdb',
        help='Database name (default: msdb)'
    )
    
    parser.add_argument(
        '-u', '--user',
        help='SQL Server user (omit for Windows authentication)'
    )
    
    parser.add_argument(
        '-p', '--port',
        type=int,
        default=51433,
        help='HTTP server port (default: 51433)'
    )
    
    parser.add_argument(
        '--host',
        default='127.0.0.1',
        help='HTTP server host (default: 127.0.0.1)'
    )
    
    args = parser.parse_args()
    
    # Set database configuration
    db_config['server'] = args.server
    db_config['database'] = args.database
    db_config['user'] = args.user
    
    # Get password if user is specified
    if args.user:
        db_config['password'] = getpass.getpass(f"Password for {args.user}: ")
    
    # Test database connection
    print(f"Testing connection to {args.server}/{args.database}...")
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT @@VERSION")
        version = cursor.fetchone()[0]
        print(f"Connected successfully!")
        print(f"SQL Server version: {version[:80]}...")
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"ERROR: Failed to connect to database: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Start server
    print(f"\nStarting pureAPI server on {args.host}:{args.port}")
    print(f"Database: {args.server}/{args.database}")
    print(f"Authentication: {'SQL Server' if args.user else 'Windows'}")
    print("\nAvailable endpoints:")
    print(f"  GET http://{args.host}:{args.port}/{{resource}}/list")
    print(f"  GET http://{args.host}:{args.port}/{{resource}}/get")
    print(f"  GET http://{args.host}:{args.port}/exec/{{procedureName}}")
    print(f"  GET http://{args.host}:{args.port}/health")
    print("\nPress Ctrl+C to stop the server")
    
    uvicorn.run(app, host=args.host, port=args.port, log_level="info")


if __name__ == "__main__":
    main()

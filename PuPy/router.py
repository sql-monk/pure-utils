"""
Модуль динамічної маршрутизації URL → SQL об'єкти
"""
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from typing import Dict, Any
import json
from database import DatabaseConnection


def create_app(db: DatabaseConnection) -> FastAPI:
    """
    Створення FastAPI додатку з динамічною маршрутизацією
    
    Args:
        db: Екземпляр DatabaseConnection
        
    Returns:
        FastAPI application
    """
    app = FastAPI(
        title="PuPy REST API",
        description="REST API з FastAPI поверх SQL Server (схема pupy)",
        version="1.0.0"
    )
    
    @app.get("/")
    async def root():
        """Кореневий маршрут"""
        return {
            "message": "PuPy REST API",
            "description": "HTTP → FastAPI (PuPy) → SQL Server (schema pupy) → JSON",
            "documentation": "/docs"
        }
    
    @app.get("/{resource}/{action}")
    async def handle_get_request(resource: str, action: str, request: Request):
        """
        Обробка GET запитів
        
        URL: /{resource}/{action} → SQL: pupy.{resource}{Action}
        Наприклад: /databases/list → pupy.databasesList
        """
        return await handle_request(resource, action, request, db)
    
    @app.post("/{resource}/{action}")
    async def handle_post_request(resource: str, action: str, request: Request):
        """
        Обробка POST запитів
        
        URL: /{resource}/{action} → SQL: pupy.{resource}{Action}
        """
        return await handle_request(resource, action, request, db)
    
    return app


def convert_url_to_sql_name(resource: str, action: str) -> str:
    """
    Конвертація URL в SQL назву об'єкта
    
    URL lowercase → SQL camelCase
    /databases/list → databasesList
    /tables/details → tablesDetails
    
    Args:
        resource: Ресурс (databases, tables, etc.)
        action: Дія (list, details, etc.)
        
    Returns:
        SQL назва об'єкта в camelCase
    """
    # Capitalize перша літера action
    action_camel = action[0].upper() + action[1:] if action else ''
    return f"{resource}{action_camel}"


async def handle_request(resource: str, action: str, request: Request, db: DatabaseConnection):
    """
    Обробка запиту та виклик відповідного SQL об'єкта
    
    Args:
        resource: Ресурс з URL
        action: Дія з URL
        request: FastAPI Request об'єкт
        db: DatabaseConnection
        
    Returns:
        JSONResponse з результатом
    """
    try:
        # Конвертація URL в SQL назву
        sql_name = convert_url_to_sql_name(resource, action)
        schema = 'pupy'
        
        # Отримання параметрів з query string
        params = dict(request.query_params)
        
        # Для POST запитів також обробляємо body
        if request.method == 'POST':
            try:
                body = await request.json()
                params.update(body)
            except:
                pass
        
        # Визначення типу об'єкта
        obj_type = db.get_object_type(schema, sql_name)
        
        if obj_type is None:
            raise HTTPException(
                status_code=404,
                detail=f"SQL object {schema}.{sql_name} not found"
            )
        
        # Виконання відповідного типу об'єкта
        if obj_type == 'TABLE_FUNCTION':
            # Table-valued function
            results = db.execute_table_function(schema, sql_name, params)
            return JSONResponse(content=results)
            
        elif obj_type == 'SCALAR_FUNCTION':
            # Scalar function (повертає JSON string)
            json_result = db.execute_scalar_function(schema, sql_name, params)
            try:
                parsed_json = json.loads(json_result)
                return JSONResponse(content=parsed_json)
            except json.JSONDecodeError:
                return JSONResponse(content={"result": json_result})
                
        elif obj_type == 'PROCEDURE':
            # Stored procedure з @response OUTPUT
            json_result = db.execute_procedure(schema, sql_name, params)
            try:
                parsed_json = json.loads(json_result)
                return JSONResponse(content=parsed_json)
            except json.JSONDecodeError:
                return JSONResponse(content={"result": json_result})
        
        else:
            raise HTTPException(
                status_code=500,
                detail=f"Unsupported object type: {obj_type}"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error executing SQL object: {str(e)}"
        )

"""
Модуль для роботи з SQL Server підключенням
"""
import pymssql
from typing import Dict, Any, Optional, List, Tuple
import json


class DatabaseConnection:
    """Клас для управління підключенням до SQL Server"""
    
    def __init__(self, config: Dict[str, Any]):
        """
        Ініціалізація підключення
        
        Args:
            config: Конфігурація підключення (server, port, user, password, database, trust_server_certificate)
        """
        self.config = config
        self._connection = None
        self._test_connection()
    
    def _test_connection(self):
        """Тестове підключення для перевірки параметрів"""
        conn = self._create_connection()
        conn.close()
    
    def _create_connection(self):
        """Створення нового підключення до SQL Server"""
        return pymssql.connect(
            server=self.config['server'],
            port=self.config['port'],
            user=self.config['user'],
            password=self.config['password'],
            database=self.config['database'],
            tds_version='7.4',
            as_dict=True
        )
    
    def execute_table_function(self, schema: str, name: str, params: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Виконання table-valued function
        
        Args:
            schema: Схема функції
            name: Назва функції
            params: Параметри для функції
            
        Returns:
            Список словників з результатами
        """
        conn = self._create_connection()
        cursor = conn.cursor()
        
        try:
            # Формування SQL запиту
            param_list = []
            for key, value in params.items():
                if value is None:
                    param_list.append('NULL')
                elif isinstance(value, str):
                    param_list.append(f"'{value}'")
                elif isinstance(value, bool):
                    param_list.append('1' if value else '0')
                else:
                    param_list.append(str(value))
            
            param_str = ', '.join(param_list) if param_list else ''
            query = f"SELECT * FROM {schema}.{name}({param_str})"
            
            cursor.execute(query)
            results = cursor.fetchall()
            
            return results if results else []
            
        finally:
            cursor.close()
            conn.close()
    
    def execute_scalar_function(self, schema: str, name: str, params: Dict[str, Any]) -> str:
        """
        Виконання scalar function (повертає NVARCHAR(MAX) JSON)
        
        Args:
            schema: Схема функції
            name: Назва функції
            params: Параметри для функції
            
        Returns:
            JSON string
        """
        conn = self._create_connection()
        cursor = conn.cursor(as_dict=False)
        
        try:
            # Формування SQL запиту
            param_list = []
            for key, value in params.items():
                if value is None:
                    param_list.append('NULL')
                elif isinstance(value, str):
                    param_list.append(f"'{value}'")
                elif isinstance(value, bool):
                    param_list.append('1' if value else '0')
                else:
                    param_list.append(str(value))
            
            param_str = ', '.join(param_list) if param_list else ''
            query = f"SELECT {schema}.{name}({param_str})"
            
            cursor.execute(query)
            result = cursor.fetchone()
            
            return result[0] if result and result[0] else '{}'
            
        finally:
            cursor.close()
            conn.close()
    
    def execute_procedure(self, schema: str, name: str, params: Dict[str, Any]) -> str:
        """
        Виконання stored procedure з @response OUTPUT
        
        Args:
            schema: Схема процедури
            name: Назва процедури
            params: Параметри для процедури
            
        Returns:
            JSON string з @response OUTPUT параметра
        """
        conn = self._create_connection()
        cursor = conn.cursor(as_dict=False)
        
        try:
            # Формування списку параметрів
            param_declarations = []
            param_assignments = []
            
            for key, value in params.items():
                param_declarations.append(f"DECLARE @{key} NVARCHAR(MAX) = '{value}'")
            
            # Завжди додаємо @response OUTPUT
            param_declarations.append("DECLARE @response NVARCHAR(MAX)")
            
            # Формування виклику процедури
            param_names = [f"@{key}" for key in params.keys()]
            param_names.append("@response OUTPUT")
            param_str = ', '.join(param_names)
            
            # Повний SQL скрипт
            sql_script = '\n'.join(param_declarations)
            sql_script += f"\nEXEC {schema}.{name} {param_str}"
            sql_script += "\nSELECT @response"
            
            cursor.execute(sql_script)
            result = cursor.fetchone()
            
            return result[0] if result and result[0] else '{}'
            
        finally:
            cursor.close()
            conn.close()
    
    def get_object_type(self, schema: str, name: str) -> Optional[str]:
        """
        Визначення типу об'єкта SQL
        
        Args:
            schema: Схема об'єкта
            name: Назва об'єкта
            
        Returns:
            'TF' (table function), 'FN' (scalar function), 'P' (procedure), або None
        """
        conn = self._create_connection()
        cursor = conn.cursor(as_dict=False)
        
        try:
            query = """
                SELECT o.type
                FROM sys.objects o
                INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
                WHERE s.name = %s AND o.name = %s
            """
            cursor.execute(query, (schema, name))
            result = cursor.fetchone()
            
            if result:
                obj_type = result[0].strip()
                # TF = table-valued function (inline)
                # FN = scalar function
                # P = stored procedure
                # IF = inline table-valued function
                if obj_type in ('TF', 'IF'):
                    return 'TABLE_FUNCTION'
                elif obj_type == 'FN':
                    return 'SCALAR_FUNCTION'
                elif obj_type == 'P':
                    return 'PROCEDURE'
            
            return None
            
        finally:
            cursor.close()
            conn.close()
    
    def get_object_parameters(self, schema: str, name: str) -> List[Tuple[str, str]]:
        """
        Отримання списку параметрів об'єкта
        
        Args:
            schema: Схема об'єкта
            name: Назва об'єкта
            
        Returns:
            Список кортежів (parameter_name, type_name)
        """
        conn = self._create_connection()
        cursor = conn.cursor(as_dict=False)
        
        try:
            query = """
                SELECT 
                    p.name,
                    TYPE_NAME(p.user_type_id) AS type_name
                FROM sys.parameters p
                INNER JOIN sys.objects o ON p.object_id = o.object_id
                INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
                WHERE s.name = %s AND o.name = %s
                    AND p.name != '@response'
                ORDER BY p.parameter_id
            """
            cursor.execute(query, (schema, name))
            results = cursor.fetchall()
            
            return [(row[0].lstrip('@'), row[1]) for row in results] if results else []
            
        finally:
            cursor.close()
            conn.close()

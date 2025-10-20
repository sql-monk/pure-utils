"""
PuPy REST API - Python Client Example

Приклад використання PuPy REST API з Python
"""
import requests
import json
from typing import List, Dict, Any, Optional


class PuPyClient:
    """Клієнт для роботи з PuPy REST API"""
    
    def __init__(self, base_url: str = "http://localhost:8000"):
        """
        Ініціалізація клієнта
        
        Args:
            base_url: Базова URL API
        """
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
    
    def _get(self, endpoint: str, params: Optional[Dict[str, Any]] = None) -> Any:
        """Виконання GET запиту"""
        url = f"{self.base_url}{endpoint}"
        response = self.session.get(url, params=params)
        response.raise_for_status()
        return response.json()
    
    def _post(self, endpoint: str, params: Optional[Dict[str, Any]] = None) -> Any:
        """Виконання POST запиту"""
        url = f"{self.base_url}{endpoint}"
        response = self.session.post(url, params=params)
        response.raise_for_status()
        return response.json()
    
    # Databases
    
    def list_databases(self) -> List[Dict[str, Any]]:
        """Отримання списку баз даних"""
        return self._get("/databases/list")
    
    def get_database(self, database_name: str) -> Dict[str, Any]:
        """Отримання інформації про базу даних"""
        return self._get("/databases/get", {"databaseName": database_name})
    
    # Tables
    
    def list_tables(self) -> List[Dict[str, Any]]:
        """Отримання списку таблиць"""
        return self._get("/tables/list")
    
    def get_table(self, name: str) -> Dict[str, Any]:
        """Отримання інформації про таблицю"""
        return self._get("/tables/get", {"name": name})
    
    def script_table(self, name: str) -> Dict[str, Any]:
        """Генерація DDL скрипту таблиці"""
        return self._post("/pupy/scriptTable", {"name": name})
    
    # Procedures
    
    def list_procedures(self) -> List[Dict[str, Any]]:
        """Отримання списку процедур"""
        return self._get("/procedures/list")
    
    # References
    
    def get_object_references(self, object_name: str) -> List[Dict[str, Any]]:
        """Отримання залежностей об'єкта"""
        return self._post("/pupy/objectReferences", {"object": object_name})


def main():
    """Демонстрація використання клієнта"""
    
    # Створення клієнта
    client = PuPyClient("http://localhost:8000")
    
    print("=" * 80)
    print("PuPy REST API - Python Client Example")
    print("=" * 80)
    
    # 1. Список баз даних
    print("\n1. Getting databases list...")
    databases = client.list_databases()
    print(f"   Found {len(databases)} databases")
    for db in databases[:3]:
        print(f"   - {db['name']} (ID: {db['databaseId']})")
    
    # 2. Деталі бази даних
    print("\n2. Getting database details...")
    try:
        db_info = client.get_database("msdb")
        print(f"   Database: {db_info.get('name')}")
        print(f"   Compatibility: {db_info.get('compatibilityLevel')}")
        print(f"   Recovery Model: {db_info.get('recoveryModelDesc')}")
    except Exception as e:
        print(f"   Error: {e}")
    
    # 3. Список таблиць
    print("\n3. Getting tables list...")
    try:
        tables = client.list_tables()
        print(f"   Found {len(tables)} tables")
        for table in tables[:3]:
            print(f"   - {table['schemaName']}.{table['tableName']} ({table.get('rowCount', 0)} rows)")
    except Exception as e:
        print(f"   Error: {e}")
    
    # 4. Список процедур
    print("\n4. Getting procedures list...")
    try:
        procedures = client.list_procedures()
        print(f"   Found {len(procedures)} procedures")
        for proc in procedures[:3]:
            print(f"   - {proc['schemaName']}.{proc['procedureName']}")
    except Exception as e:
        print(f"   Error: {e}")
    
    # 5. Деталі таблиці
    print("\n5. Getting table details...")
    try:
        # Використати першу знайдену таблицю
        if tables:
            table_name = f"{tables[0]['schemaName']}.{tables[0]['tableName']}"
            table_info = client.get_table(table_name)
            print(f"   Table: {table_info.get('schemaName')}.{table_info.get('tableName')}")
            
            columns = table_info.get('columns', [])
            if columns:
                columns_data = json.loads(columns) if isinstance(columns, str) else columns
                print(f"   Columns: {len(columns_data)}")
                for col in columns_data[:3]:
                    print(f"   - {col['columnName']} ({col['dataType']})")
    except Exception as e:
        print(f"   Error: {e}")
    
    print("\n" + "=" * 80)
    print("Example completed!")
    print("=" * 80)


if __name__ == "__main__":
    main()

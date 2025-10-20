"""
Тестовий скрипт для перевірки PuPy REST API

Використання:
    python PuPy/test_api.py [api_url]

Де api_url - базова URL API (за замовчуванням: http://localhost:8000)
"""
import sys
import requests
import json


def test_endpoint(base_url: str, endpoint: str, method: str = 'GET', params: dict = None):
    """
    Тестування окремого endpoint
    
    Args:
        base_url: Базова URL API
        endpoint: Endpoint для тестування
        method: HTTP метод (GET або POST)
        params: Параметри запиту
    """
    url = f"{base_url}{endpoint}"
    print(f"\n{'='*80}")
    print(f"🔍 Testing: {method} {url}")
    if params:
        print(f"📝 Parameters: {params}")
    print(f"{'='*80}")
    
    try:
        if method == 'GET':
            response = requests.get(url, params=params, timeout=10)
        else:
            response = requests.post(url, params=params, timeout=10)
        
        print(f"✅ Status: {response.status_code}")
        
        if response.status_code == 200:
            try:
                data = response.json()
                print(f"📦 Response (first 500 chars):")
                json_str = json.dumps(data, indent=2, ensure_ascii=False)
                if len(json_str) > 500:
                    print(json_str[:500] + "\n... (truncated)")
                else:
                    print(json_str)
            except:
                print(f"📦 Response: {response.text[:500]}")
        else:
            print(f"❌ Error: {response.text}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")


def main():
    """Головна функція тестування"""
    base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"
    
    print(f"🚀 Testing PuPy REST API at {base_url}")
    print(f"{'='*80}")
    
    # Тест 1: Кореневий endpoint
    test_endpoint(base_url, "/", "GET")
    
    # Тест 2: Table-valued function - databases list
    test_endpoint(base_url, "/databases/list", "GET")
    
    # Тест 3: Scalar function - get database details
    test_endpoint(base_url, "/databases/get", "GET", {"databaseName": "msdb"})
    
    # Тест 4: Table-valued function - tables list
    test_endpoint(base_url, "/tables/list", "GET")
    
    # Тест 5: Scalar function - get table details
    # test_endpoint(base_url, "/tables/get", "GET", {"name": "dbo.sysjobs"})
    
    # Тест 6: Table-valued function - procedures list
    test_endpoint(base_url, "/procedures/list", "GET")
    
    # Тест 7: Stored procedure - object references
    # test_endpoint(base_url, "/pupy/objectReferences", "POST", {"object": "msdb.dbo.sysjobs"})
    
    # Тест 8: Stored procedure - script table
    # test_endpoint(base_url, "/pupy/scriptTable", "POST", {"name": "dbo.sysjobs"})
    
    print(f"\n{'='*80}")
    print(f"✅ Testing completed!")
    print(f"📖 Full API documentation: {base_url}/docs")
    print(f"{'='*80}\n")


if __name__ == "__main__":
    main()

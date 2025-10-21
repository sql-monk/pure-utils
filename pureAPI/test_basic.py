#!/usr/bin/env python3
"""
Basic smoke tests for pureAPI server
Tests the API structure without requiring a running SQL Server
"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi.testclient import TestClient


def test_imports():
    """Test that all required modules can be imported"""
    try:
        import pymssql
        import fastapi
        import uvicorn
        print("✓ All required modules imported successfully")
        return True
    except ImportError as e:
        print(f"✗ Import error: {e}")
        return False


def test_server_structure():
    """Test that server module has correct structure"""
    try:
        from server import app, main
        print("✓ Server module loaded successfully")
        
        # Check that FastAPI app is configured
        assert app.title == "pureAPI"
        print("✓ FastAPI app configured correctly")
        
        # Check routes
        routes = [route.path for route in app.routes]
        expected_routes = [
            "/{resource}/list",
            "/{resource}/get",
            "/exec/{procedure_name}",
            "/health"
        ]
        
        for expected_route in expected_routes:
            if expected_route in routes:
                print(f"✓ Route {expected_route} registered")
            else:
                print(f"✗ Route {expected_route} not found")
                return False
        
        return True
    except Exception as e:
        print(f"✗ Error testing server structure: {e}")
        return False


def test_api_documentation():
    """Test that API documentation is accessible"""
    try:
        from server import app
        client = TestClient(app)
        
        # Test OpenAPI schema
        response = client.get("/openapi.json")
        assert response.status_code == 200
        print("✓ OpenAPI schema accessible")
        
        # Test docs
        response = client.get("/docs")
        assert response.status_code == 200
        print("✓ API documentation accessible")
        
        return True
    except Exception as e:
        print(f"✗ Error testing API documentation: {e}")
        return False


def main():
    """Run all tests"""
    print("=" * 60)
    print("pureAPI Basic Tests")
    print("=" * 60)
    print()
    
    tests = [
        ("Module Imports", test_imports),
        ("Server Structure", test_server_structure),
        ("API Documentation", test_api_documentation),
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n{test_name}:")
        print("-" * 40)
        results.append(test_func())
    
    print()
    print("=" * 60)
    passed = sum(results)
    total = len(results)
    print(f"Results: {passed}/{total} test groups passed")
    print("=" * 60)
    
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())

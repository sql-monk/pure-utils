#!/usr/bin/env python3
"""
Example demonstrating pureAPI usage

This script shows how to interact with pureAPI endpoints using Python requests library.
"""

import requests
import json


# Configuration
BASE_URL = "http://localhost:51433"


def print_response(title, response):
    """Pretty print API response"""
    print(f"\n{'='*60}")
    print(f"{title}")
    print(f"{'='*60}")
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        try:
            data = response.json()
            print(json.dumps(data, indent=2, ensure_ascii=False))
        except:
            print(response.text)
    else:
        print(f"Error: {response.text}")


def main():
    """Run example API calls"""
    
    print("pureAPI Usage Examples")
    print("Make sure the server is running: python server.py -s localhost -d msdb")
    
    # Health check
    print_response(
        "1. Health Check",
        requests.get(f"{BASE_URL}/health")
    )
    
    # List all databases
    print_response(
        "2. List all databases",
        requests.get(f"{BASE_URL}/databases/list")
    )
    
    # List only ONLINE databases
    print_response(
        "3. List ONLINE databases (with filter)",
        requests.get(f"{BASE_URL}/databases/list", params={"stateDesc": "ONLINE"})
    )
    
    # Get specific database
    print_response(
        "4. Get specific database (ID=1)",
        requests.get(f"{BASE_URL}/database/get", params={"databaseId": 1})
    )
    
    # Execute test operation
    print_response(
        "5. Execute test operation",
        requests.get(f"{BASE_URL}/exec/testOperation", params={"testValue": "Hello pureAPI"})
    )
    
    print("\n" + "="*60)
    print("Examples completed!")
    print("="*60)


if __name__ == "__main__":
    try:
        main()
    except requests.exceptions.ConnectionError:
        print("\nError: Could not connect to pureAPI server.")
        print("Make sure the server is running:")
        print("  python server.py -s localhost -d msdb")
    except Exception as e:
        print(f"\nError: {e}")

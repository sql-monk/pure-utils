#!/bin/bash
#
# PuPy REST API - Приклади використання з curl
#
# Використання: ./curl_examples.sh [api_url]
# 

API_URL="${1:-http://localhost:8000}"

echo "=================================================="
echo "PuPy REST API - curl Examples"
echo "API URL: $API_URL"
echo "=================================================="

echo ""
echo "1. Root endpoint"
echo "=================================================="
curl -s "$API_URL/" | jq '.'

echo ""
echo ""
echo "2. GET /databases/list (Table-valued function)"
echo "=================================================="
curl -s "$API_URL/databases/list" | jq '.'

echo ""
echo ""
echo "3. GET /databases/get?databaseName=msdb (Scalar function)"
echo "=================================================="
curl -s "$API_URL/databases/get?databaseName=msdb" | jq '.'

echo ""
echo ""
echo "4. GET /tables/list (Table-valued function)"
echo "=================================================="
curl -s "$API_URL/tables/list" | jq '. | length' 
echo "Tables found (showing first 3):"
curl -s "$API_URL/tables/list" | jq '.[0:3]'

echo ""
echo ""
echo "5. GET /procedures/list (Table-valued function)"
echo "=================================================="
curl -s "$API_URL/procedures/list" | jq '. | length'
echo "Procedures found (showing first 3):"
curl -s "$API_URL/procedures/list" | jq '.[0:3]'

echo ""
echo ""
echo "6. POST /pupy/objectReferences?object=... (Stored procedure)"
echo "=================================================="
echo "Example: curl -X POST '$API_URL/pupy/objectReferences?object=dbo.MyTable'"

echo ""
echo ""
echo "7. POST /pupy/scriptTable?name=... (Stored procedure)"
echo "=================================================="
echo "Example: curl -X POST '$API_URL/pupy/scriptTable?name=dbo.MyTable'"

echo ""
echo "=================================================="
echo "Documentation: $API_URL/docs"
echo "=================================================="

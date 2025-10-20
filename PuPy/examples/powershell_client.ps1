#Requires -Version 5.1
<#
.SYNOPSIS
    PuPy REST API - PowerShell Client Example

.DESCRIPTION
    Приклад використання PuPy REST API з PowerShell

.PARAMETER ApiUrl
    Базова URL API (за замовчуванням: http://localhost:8000)

.EXAMPLE
    .\powershell_client.ps1 -ApiUrl "http://localhost:8000"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ApiUrl = "http://localhost:8000"
)

# Функція для виконання GET запиту
function Invoke-PuPyGet {
    param(
        [string]$Endpoint,
        [hashtable]$Parameters = @{}
    )
    
    $uri = "$ApiUrl$Endpoint"
    if ($Parameters.Count -gt 0) {
        $queryString = ($Parameters.GetEnumerator() | ForEach-Object { 
            "$($_.Key)=$([System.Uri]::EscapeDataString($_.Value))" 
        }) -join '&'
        $uri = "$uri?$queryString"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json"
        return $response
    }
    catch {
        Write-Error "Error calling $uri : $_"
        return $null
    }
}

# Функція для виконання POST запиту
function Invoke-PuPyPost {
    param(
        [string]$Endpoint,
        [hashtable]$Parameters = @{}
    )
    
    $uri = "$ApiUrl$Endpoint"
    if ($Parameters.Count -gt 0) {
        $queryString = ($Parameters.GetEnumerator() | ForEach-Object { 
            "$($_.Key)=$([System.Uri]::EscapeDataString($_.Value))" 
        }) -join '&'
        $uri = "$uri?$queryString"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json"
        return $response
    }
    catch {
        Write-Error "Error calling $uri : $_"
        return $null
    }
}

# Головна функція
function Main {
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "PuPy REST API - PowerShell Client Example" -ForegroundColor Cyan
    Write-Host "API URL: $ApiUrl" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    
    # 1. Список баз даних
    Write-Host "`n1. Getting databases list..." -ForegroundColor Yellow
    $databases = Invoke-PuPyGet -Endpoint "/databases/list"
    if ($databases) {
        Write-Host "   Found $($databases.Count) databases" -ForegroundColor Green
        $databases | Select-Object -First 3 | ForEach-Object {
            Write-Host "   - $($_.name) (ID: $($_.databaseId))" -ForegroundColor Gray
        }
    }
    
    # 2. Деталі бази даних
    Write-Host "`n2. Getting database details..." -ForegroundColor Yellow
    $dbInfo = Invoke-PuPyGet -Endpoint "/databases/get" -Parameters @{ databaseName = "msdb" }
    if ($dbInfo) {
        Write-Host "   Database: $($dbInfo.name)" -ForegroundColor Green
        Write-Host "   Compatibility: $($dbInfo.compatibilityLevel)" -ForegroundColor Gray
        Write-Host "   Recovery Model: $($dbInfo.recoveryModelDesc)" -ForegroundColor Gray
    }
    
    # 3. Список таблиць
    Write-Host "`n3. Getting tables list..." -ForegroundColor Yellow
    $tables = Invoke-PuPyGet -Endpoint "/tables/list"
    if ($tables) {
        Write-Host "   Found $($tables.Count) tables" -ForegroundColor Green
        $tables | Select-Object -First 3 | ForEach-Object {
            Write-Host "   - $($_.schemaName).$($_.tableName) ($($_.rowCount) rows)" -ForegroundColor Gray
        }
    }
    
    # 4. Список процедур
    Write-Host "`n4. Getting procedures list..." -ForegroundColor Yellow
    $procedures = Invoke-PuPyGet -Endpoint "/procedures/list"
    if ($procedures) {
        Write-Host "   Found $($procedures.Count) procedures" -ForegroundColor Green
        $procedures | Select-Object -First 3 | ForEach-Object {
            Write-Host "   - $($_.schemaName).$($_.procedureName)" -ForegroundColor Gray
        }
    }
    
    # 5. Деталі таблиці
    Write-Host "`n5. Getting table details..." -ForegroundColor Yellow
    if ($tables -and $tables.Count -gt 0) {
        $firstTable = $tables[0]
        $tableName = "$($firstTable.schemaName).$($firstTable.tableName)"
        $tableInfo = Invoke-PuPyGet -Endpoint "/tables/get" -Parameters @{ name = $tableName }
        
        if ($tableInfo) {
            Write-Host "   Table: $($tableInfo.schemaName).$($tableInfo.tableName)" -ForegroundColor Green
            
            if ($tableInfo.columns) {
                $columns = $tableInfo.columns | ConvertFrom-Json
                Write-Host "   Columns: $($columns.Count)" -ForegroundColor Gray
                $columns | Select-Object -First 3 | ForEach-Object {
                    Write-Host "   - $($_.columnName) ($($_.dataType))" -ForegroundColor Gray
                }
            }
        }
    }
    
    # 6. Залежності об'єкта
    Write-Host "`n6. Getting object references..." -ForegroundColor Yellow
    if ($tables -and $tables.Count -gt 0) {
        $firstTable = $tables[0]
        $tableName = "$($firstTable.schemaName).$($firstTable.tableName)"
        $references = Invoke-PuPyPost -Endpoint "/pupy/objectReferences" -Parameters @{ object = $tableName }
        
        if ($references) {
            if ($references.Count -gt 0) {
                Write-Host "   Found $($references.Count) references" -ForegroundColor Green
                $references | Select-Object -First 3 | ForEach-Object {
                    Write-Host "   - $($_.referencedSchema).$($_.referencedObject)" -ForegroundColor Gray
                }
            } else {
                Write-Host "   No references found" -ForegroundColor Gray
            }
        }
    }
    
    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "Example completed!" -ForegroundColor Green
    Write-Host "Documentation: $ApiUrl/docs" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
}

# Запуск
Main

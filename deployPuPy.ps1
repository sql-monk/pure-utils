<#
.SYNOPSIS
    Розгортає об'єкти зі схеми pupy.

.DESCRIPTION
    Скрипт створює схему pupy (якщо не існує) та розгортає всі SQL об'єкти з папки pupy.

.PARAMETER Server
    Ім'я SQL Server

.PARAMETER Database
    Ім'я бази даних

.EXAMPLE
    .\deployPuPy.ps1 -Server "localhost" -Database "AdventureWorks"
    
.EXAMPLE
    .\deployPuPy.ps1 -Server "192.168.1.10" -Database "Production"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Server,
    
    [Parameter(Mandatory = $true)]
    [string]$Database
)

$ErrorActionPreference = "Stop"

Write-Host "PuPy Schema Deployment" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host "Server: $Server"
Write-Host "Database: $Database"
Write-Host ""

# Connection string
$ConnectionString = "Server=$Server;Database=$Database;Integrated Security=True;TrustServerCertificate=True;"

# Create schema if not exists
$CreateSchemaSQL = @"
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'pupy')
BEGIN
    EXEC('CREATE SCHEMA pupy');
    PRINT 'Schema pupy created';
END
ELSE
BEGIN
    PRINT 'Schema pupy already exists';
END
"@

Write-Host "Creating schema pupy..." -ForegroundColor Yellow
try {
    Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $CreateSchemaSQL -ErrorAction Stop
    Write-Host "✓ Schema created/verified" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to create schema: $_" -ForegroundColor Red
    exit 1
}

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PuPyDir = Join-Path $ScriptDir "pupy"

# Deploy order: Views, then Functions, then Procedures
$DeployOrder = @("Views", "Functions", "Procedures")

$TotalDeployed = 0
$TotalErrors = 0

foreach ($folder in $DeployOrder) {
    $FolderPath = Join-Path $PuPyDir $folder
    
    if (-not (Test-Path $FolderPath)) {
        Write-Host "Folder not found: $FolderPath, skipping..." -ForegroundColor Yellow
        continue
    }
    
    $SqlFiles = Get-ChildItem -Path $FolderPath -Filter "*.sql" -File | Sort-Object Name
    
    if ($SqlFiles.Count -eq 0) {
        Write-Host "No SQL files found in $folder" -ForegroundColor Gray
        continue
    }
    
    Write-Host ""
    Write-Host "Deploying $folder..." -ForegroundColor Yellow
    Write-Host "-------------------" -ForegroundColor Yellow
    
    foreach ($file in $SqlFiles) {
        $ObjectName = $file.BaseName
        Write-Host "  Deploying: $ObjectName" -NoNewline
        
        try {
            $SqlContent = Get-Content $file.FullName -Raw -Encoding UTF8
            Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $SqlContent -ErrorAction Stop
            Write-Host " ✓" -ForegroundColor Green
            $TotalDeployed++
        } catch {
            Write-Host " ✗" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor Red
            $TotalErrors++
        }
    }
}

Write-Host ""
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host "Successfully deployed: $TotalDeployed" -ForegroundColor Green
Write-Host "Errors: $TotalErrors" -ForegroundColor $(if ($TotalErrors -gt 0) { "Red" } else { "Green" })

if ($TotalErrors -eq 0) {
    Write-Host ""
    Write-Host "✓ Deployment completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "✗ Deployment completed with errors" -ForegroundColor Red
    exit 1
}

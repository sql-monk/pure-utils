#Requires -Version 5.1
<#
.SYNOPSIS
    Скрипт розгортання PuPy SQL об'єктів

.DESCRIPTION
    Розгортає схему pupy та всі пов'язані SQL об'єкти (functions, procedures)
    на вказаний SQL Server та базу даних

.PARAMETER Server
    SQL Server instance name або IP адреса (за замовчуванням: localhost)

.PARAMETER Database
    Назва бази даних для розгортання (за замовчуванням: msdb)

.PARAMETER Username
    SQL Server username (опціонально, використовується Windows Auth якщо не вказано)

.PARAMETER Password
    SQL Server password (опціонально, потрібен якщо вказано Username)

.EXAMPLE
    .\deployPupy.ps1 -Server "localhost" -Database "MyDB"

.EXAMPLE
    .\deployPupy.ps1 -Server "192.168.1.10" -Database "MyDB" -Username "sa" -Password "MyPass123"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Server = "localhost",
    
    [Parameter(Mandatory=$false)]
    [string]$Database = "msdb",
    
    [Parameter(Mandatory=$false)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [string]$Password
)

# Кольори для виводу
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }

# Заголовок
Write-Host "`n" -NoNewline
Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        PuPy SQL Objects Deployment Script           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Перевірка sqlcmd
Write-Info "Checking sqlcmd availability..."
$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
if (-not $sqlcmd) {
    Write-Error "sqlcmd not found. Please install SQL Server Command Line Tools."
    exit 1
}
Write-Success "sqlcmd found: $($sqlcmd.Source)"

# Формування параметрів підключення
$authParams = if ($Username) {
    "-U $Username -P $Password"
} else {
    "-E"
}

# Тестування підключення
Write-Info "Testing connection to SQL Server..."
$testQuery = "SELECT @@VERSION"
$result = sqlcmd -S $Server -d $Database $authParams -Q $testQuery -h -1 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to connect to SQL Server: $result"
    exit 1
}
Write-Success "Connected to SQL Server: $Server"
Write-Success "Target database: $Database"

# Функція для виконання SQL файлу
function Deploy-SqlFile {
    param(
        [string]$FilePath,
        [string]$Description
    )
    
    Write-Info "Deploying: $Description"
    Write-Host "   File: $FilePath" -ForegroundColor Gray
    
    $result = sqlcmd -S $Server -d $Database $authParams -i $FilePath -b 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Deployed: $Description"
        return $true
    } else {
        Write-Error "Failed to deploy: $Description"
        Write-Host "   Error: $result" -ForegroundColor Red
        return $false
    }
}

# Лічильники
$successCount = 0
$failCount = 0

# 1. Розгортання схеми
Write-Host "`n══════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "Step 1: Creating schema 'pupy'" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════════`n" -ForegroundColor Yellow

if (Test-Path "Security/pupy.sql") {
    if (Deploy-SqlFile -FilePath "Security/pupy.sql" -Description "Schema pupy") {
        $successCount++
    } else {
        $failCount++
    }
} else {
    Write-Warning "Schema file not found: Security/pupy.sql"
}

# 2. Розгортання Functions
Write-Host "`n══════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "Step 2: Deploying Functions" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════════`n" -ForegroundColor Yellow

$functionsPath = "pupy/Functions"
if (Test-Path $functionsPath) {
    $functionFiles = Get-ChildItem -Path $functionsPath -Filter "*.sql" | Sort-Object Name
    foreach ($file in $functionFiles) {
        if (Deploy-SqlFile -FilePath $file.FullName -Description "Function: $($file.BaseName)") {
            $successCount++
        } else {
            $failCount++
        }
    }
} else {
    Write-Warning "Functions directory not found: $functionsPath"
}

# 3. Розгортання Procedures
Write-Host "`n══════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "Step 3: Deploying Procedures" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════════`n" -ForegroundColor Yellow

$proceduresPath = "pupy/Procedures"
if (Test-Path $proceduresPath) {
    $procedureFiles = Get-ChildItem -Path $proceduresPath -Filter "*.sql" | Sort-Object Name
    foreach ($file in $procedureFiles) {
        if (Deploy-SqlFile -FilePath $file.FullName -Description "Procedure: $($file.BaseName)") {
            $successCount++
        } else {
            $failCount++
        }
    }
} else {
    Write-Warning "Procedures directory not found: $proceduresPath"
}

# Підсумок
Write-Host "`n" -NoNewline
Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                 Deployment Summary                   ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Success "Successfully deployed: $successCount objects"
if ($failCount -gt 0) {
    Write-Error "Failed to deploy: $failCount objects"
}
Write-Host ""

# Виведення додаткової інформації
if ($successCount -gt 0 -and $failCount -eq 0) {
    Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║            ✅ Deployment completed successfully!      ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "   1. Install Python dependencies: pip install -r requirements.txt" -ForegroundColor Gray
    Write-Host "   2. Start PuPy API server: python PuPy/main.py --server $Server --database $Database" -ForegroundColor Gray
    Write-Host "   3. Test API: python PuPy/test_api.py" -ForegroundColor Gray
    Write-Host ""
    exit 0
} else {
    Write-Error "Deployment completed with errors. Please check the output above."
    exit 1
}

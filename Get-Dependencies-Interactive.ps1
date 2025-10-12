<#
.SYNOPSIS
    Інтерактивний генератор дерев залежностей для SQL об'єктів

.DESCRIPTION
    Запитує назву об'єкта та генерує два MD файли:
    1. Forward dependencies (від чого залежить)
    2. Backward dependencies (що залежить від об'єкта)
#>

Clear-Host

Write-Host ""
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SQL Dependencies Tree Generator" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Запитуємо об'єкт для аналізу
$objectToAnalyze = Read-Host "Enter object name (e.g., util.metadataGetDescriptions)"

if ([string]::IsNullOrWhiteSpace($objectToAnalyze)) {
    Write-Host "Error: Object name is required!" -ForegroundColor Red
    exit 1
}

$scriptRoot = $PSScriptRoot
$outputFolder = Join-Path $scriptRoot "dependencies"

if (-not (Test-Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory | Out-Null
}

Write-Host ""
Write-Host "Analyzing: $objectToAnalyze" -ForegroundColor Yellow
Write-Host ""

# Функції
function Get-ObjectPath {
    param([string]$ObjectName)
    
    $cleanName = $ObjectName.Replace("[", "").Replace("]", "").Trim()
    if (-not $cleanName.EndsWith('.sql')) { $cleanName = "$cleanName.sql" }
    
    $files = Get-ChildItem -Path $scriptRoot -Filter $cleanName -Recurse -File | 
        Where-Object { $_.FullName -notmatch '[\\/]\.[^\\/]+[\\/]' }
    
    return if ($files) { $files[0].FullName } else { $null }
}

function Get-ReferencedObjects {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) { return @() }
    
    $sql = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $sql) { return @() }
    
    $pattern = '\[?(util|mcp)\]?\.\[?(\w+)\]?'
    $regexMatches = [regex]::Matches($sql, $pattern)
    
    $references = @()
    foreach ($match in $regexMatches) {
        $fullName = "$($match.Groups[1].Value).$($match.Groups[2].Value)"
        $currentFileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        if ($match.Groups[2].Value -ne $currentFileName) {
            $references += $fullName
        }
    }
    
    return $references | Select-Object -Unique
}

function Build-ForwardTree {
    param([string]$ObjectName, [int]$Level = 0, [hashtable]$Visited = @{})
    
    if ($Visited.ContainsKey($ObjectName)) { return @() }
    $Visited[$ObjectName] = $true
    
    $indent = "  " * $Level
    $result = @()
    $filePath = Get-ObjectPath -ObjectName $ObjectName
    
    if ($filePath) {
        $references = Get-ReferencedObjects -FilePath $filePath
        if ($references.Count -gt 0) {
            foreach ($ref in $references) {
                $result += "$indent- **$ref**"
                if ($Level -lt 10) {
                    $result += Build-ForwardTree -ObjectName $ref -Level ($Level + 1) -Visited $Visited
                }
            }
        }
        elseif ($Level -gt 0) { $result += "$indent  _(no dependencies)_" }
    }
    elseif ($Level -gt 0) { $result += "$indent  _(file not found)_" }
    
    return $result
}

function Build-BackwardTree {
    param([string]$TargetObject, [int]$Level = 0, [hashtable]$Visited = @{})
    
    if ($Visited.ContainsKey($TargetObject)) { return @() }
    $Visited[$TargetObject] = $true
    
    $indent = "  " * $Level
    $result = @()
    
    $allSqlFiles = Get-ChildItem -Path $scriptRoot -Filter "*.sql" -Recurse -File | 
        Where-Object { $_.FullName -notmatch '[\\/]\.[^\\/]+[\\/]' -and $_.FullName -match '[\\/](util|mcp)[\\/]' }
    
    $referencingObjects = @()
    
    foreach ($file in $allSqlFiles) {
        $references = Get-ReferencedObjects -FilePath $file.FullName
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $schema = if ($file.FullName -match '[\\/](util|mcp)[\\/]') { $matches[1] } else { 'dbo' }
        $fullName = "$schema.$fileName"
        
        $cleanTargetName = $TargetObject -replace '^\w+\.'
        if (($references -contains $TargetObject -or $references -contains $cleanTargetName) -and $fullName -ne $TargetObject) {
            $referencingObjects += $fullName
        }
    }
    
    if ($referencingObjects.Count -gt 0) {
        foreach ($refObj in $referencingObjects) {
            $result += "$indent- **$refObj**"
            if ($Level -lt 10) {
                $result += Build-BackwardTree -TargetObject $refObj -Level ($Level + 1) -Visited $Visited
            }
        }
    }
    elseif ($Level -gt 0) { $result += "$indent  _(no references)_" }
    
    return $result
}

# Генеруємо Forward Dependencies
Write-Host "[1/2] Building forward dependencies tree..." -ForegroundColor Cyan
$forwardDeps = Build-ForwardTree -ObjectName $objectToAnalyze

$forwardMd = @"
# Forward Dependencies: $objectToAnalyze

> Об'єкти, від яких залежить **$objectToAnalyze**

## Дерево залежностей

``````
$objectToAnalyze
$(if ($forwardDeps.Count -gt 0) { $forwardDeps -join "`n" } else { "  (no dependencies)" })
``````

---
*Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

$forwardFile = Join-Path $outputFolder "$($objectToAnalyze.Replace('.', '_'))_forward.md"
$forwardMd | Out-File -FilePath $forwardFile -Encoding UTF8 -NoNewline

Write-Host "      ✓ Saved: $([System.IO.Path]::GetFileName($forwardFile))" -ForegroundColor Green

# Генеруємо Backward Dependencies
Write-Host "[2/2] Building backward dependencies tree..." -ForegroundColor Cyan
$backwardDeps = Build-BackwardTree -TargetObject $objectToAnalyze

$backwardMd = @"
# Backward Dependencies: $objectToAnalyze

> Об'єкти, які залежать від **$objectToAnalyze**

## Дерево залежностей

``````
$objectToAnalyze
$(if ($backwardDeps.Count -gt 0) { $backwardDeps -join "`n" } else { "  (no references)" })
``````

---
*Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

$backwardFile = Join-Path $outputFolder "$($objectToAnalyze.Replace('.', '_'))_backward.md"
$backwardMd | Out-File -FilePath $backwardFile -Encoding UTF8 -NoNewline

Write-Host "      ✓ Saved: $([System.IO.Path]::GetFileName($backwardFile))" -ForegroundColor Green

Write-Host ""
Write-Host "════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Done! Files saved to:" -ForegroundColor Green
Write-Host "  $outputFolder" -ForegroundColor White
Write-Host "════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# Питаємо чи відкрити папку
$openFolder = Read-Host "Open folder? (Y/n)"
if ($openFolder -ne 'n' -and $openFolder -ne 'N') {
    Start-Process $outputFolder
}

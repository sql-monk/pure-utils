#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build script for PureSqlsMcp project
.DESCRIPTION
    Builds the project and creates a self-contained executable
.PARAMETER Configuration
    Build configuration (Debug or Release). Default is Release.
.PARAMETER Runtime
    Target runtime identifier. Default is win-x64.
.PARAMETER Clean
    Clean before build
.EXAMPLE
    .\build.ps1
    .\build.ps1 -Configuration Debug
    .\build.ps1 -Clean
#>

param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    
    [string]$Runtime = 'win-x64',
    
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$SourcePath = $PSScriptRoot
$ProjectFile = Join-Path $SourcePath "PureSqlsMcp.csproj"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  PureSqlsMcp Build Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if project exists
if (-not (Test-Path $ProjectFile)) {
    Write-Host "ERROR: Project file not found: $ProjectFile" -ForegroundColor Red
    exit 1
}

Set-Location $SourcePath

try {
    # Clean if requested
    if ($Clean) {
        Write-Host "Cleaning previous build..." -ForegroundColor Yellow
        dotnet clean -c $Configuration
        
        # Kill any running processes
        Get-Process -Name "PureSqlsMcp" -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 1
        
        # Remove publish directories
        $publishDirs = @(
            ".\bin\$Configuration\net8.0\$Runtime\publish",
            ".\bin\$Configuration\publish-standalone",
            ".\publish"
        )
        
        foreach ($dir in $publishDirs) {
            if (Test-Path $dir) {
                Write-Host "  Removing: $dir" -ForegroundColor Gray
                Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        Write-Host "Clean completed" -ForegroundColor Green
        Write-Host ""
    }
    
    # Build
    Write-Host "Building project ($Configuration)..." -ForegroundColor Yellow
    dotnet build -c $Configuration
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    
    Write-Host "Build completed" -ForegroundColor Green
    Write-Host ""
    
    # Publish
    Write-Host "Publishing self-contained executable..." -ForegroundColor Yellow
    Write-Host "  Configuration: $Configuration" -ForegroundColor Gray
    Write-Host "  Runtime: $Runtime" -ForegroundColor Gray
    Write-Host "  Single file: Yes" -ForegroundColor Gray
    Write-Host "  Trimmed: No (required for SQL Client compatibility)" -ForegroundColor Gray
    Write-Host ""
    
    dotnet publish -c $Configuration -r $Runtime --self-contained -p:PublishSingleFile=true -p:PublishTrimmed=false
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Publish failed" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    
    Write-Host "Publish completed" -ForegroundColor Green
    Write-Host ""
    
    # Show results
    $publishPath = ".\bin\$Configuration\net8.0\$Runtime\publish\PureSqlsMcp.exe"
    
    if (Test-Path $publishPath) {
        Write-Host "=====================================" -ForegroundColor Cyan
        Write-Host "  Build Summary" -ForegroundColor Cyan
        Write-Host "=====================================" -ForegroundColor Cyan
        
        $exeInfo = Get-Item $publishPath
        $fullPath = $exeInfo.FullName
        $sizeMB = [math]::Round($exeInfo.Length / 1MB, 2)
        
        Write-Host ""
        Write-Host "Executable: " -NoNewline -ForegroundColor White
        Write-Host "PureSqlsMcp.exe" -ForegroundColor Green
        Write-Host "Location: " -NoNewline -ForegroundColor White
        Write-Host $fullPath -ForegroundColor Green
        Write-Host "Size: " -NoNewline -ForegroundColor White
        Write-Host "$sizeMB MB" -ForegroundColor Green
        Write-Host "Created: " -NoNewline -ForegroundColor White
        Write-Host $exeInfo.LastWriteTime -ForegroundColor Green
        Write-Host ""
        Write-Host "=====================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Build successful! Ready to use." -ForegroundColor Green
        Write-Host ""
        Write-Host "Usage examples:" -ForegroundColor Yellow
        Write-Host "  .\bin\$Configuration\net8.0\$Runtime\publish\PureSqlsMcp.exe --server localhost --database master" -ForegroundColor Gray
        Write-Host "  .\bin\$Configuration\net8.0\$Runtime\publish\PureSqlsMcp.exe -s myserver -d mydb -u user -p password" -ForegroundColor Gray
        Write-Host ""
    }
    else {
        Write-Host "Warning: Executable not found at expected location" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
finally {
    Set-Location $PSScriptRoot
}

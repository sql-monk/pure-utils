# Build script for PureSqlsApi

param(
    [switch]$Release,
    [switch]$Publish,
    [string]$Runtime = "win-x64"
)

$ErrorActionPreference = "Stop"

$configuration = if ($Release) { "Release" } else { "Debug" }

Write-Host "Building PureSqlsApi ($configuration)..." -ForegroundColor Cyan

if ($Publish) {
    Write-Host "Publishing self-contained executable for $Runtime..." -ForegroundColor Yellow
    
    dotnet publish `
        --configuration $configuration `
        --runtime $Runtime `
        --self-contained true `
        -p:PublishSingleFile=true `
        -p:EnableCompressionInSingleFile=true `
        -p:DebugType=embedded
        
    if ($LASTEXITCODE -eq 0) {
        $outputPath = "bin\$configuration\net8.0\$Runtime\publish\PureSqlsApi.exe"
        Write-Host "`nBuild successful!" -ForegroundColor Green
        Write-Host "Executable: $outputPath" -ForegroundColor Green
        Write-Host "`nRun with: .\$outputPath --server localhost --database utils" -ForegroundColor Cyan
    }
} else {
    dotnet build --configuration $configuration
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nBuild successful!" -ForegroundColor Green
        Write-Host "`nRun with: dotnet run --project PureSqlsApi.csproj -- --server localhost --database utils" -ForegroundColor Cyan
    }
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nBuild failed!" -ForegroundColor Red
    exit 1
}

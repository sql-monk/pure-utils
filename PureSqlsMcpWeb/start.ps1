# Quick start script for PureSqlsMcpWeb
# Швидкий запуск Web API

Write-Host "🚀 Starting PureSqlsMcpWeb API..." -ForegroundColor Green

# Check if built
$dllPath = "bin\Release\net8.0\PureSqlsMcpWeb.dll"
if (-not (Test-Path $dllPath)) {
    Write-Host "📦 Building project first..." -ForegroundColor Yellow
    & .\build.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed. Cannot start." -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n🌐 API will be available at:" -ForegroundColor Cyan
Write-Host "   http://localhost:5000" -ForegroundColor White
Write-Host "   http://localhost:5000/swagger" -ForegroundColor White
Write-Host "`n Press Ctrl+C to stop`n" -ForegroundColor Yellow

dotnet run --project PureSqlsMcpWeb.csproj

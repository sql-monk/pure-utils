# Build script for PureSqlsMcpWeb
# Скрипт для збірки та публікації Web API

param(
    [string]$Configuration = "Release",
    [string]$OutputPath = "bin\Release\net8.0\publish"
)

Write-Host "🔨 Building PureSqlsMcpWeb..." -ForegroundColor Green

# Restore dependencies
Write-Host "`n📦 Restoring NuGet packages..." -ForegroundColor Cyan
dotnet restore

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to restore packages" -ForegroundColor Red
    exit 1
}

# Build
Write-Host "`n🔧 Building project..." -ForegroundColor Cyan
dotnet build -c $Configuration --no-restore

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

# Publish
Write-Host "`n📤 Publishing..." -ForegroundColor Cyan
dotnet publish -c $Configuration -o $OutputPath --no-build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Publish failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Build completed successfully!" -ForegroundColor Green
Write-Host "📁 Output: $OutputPath" -ForegroundColor Yellow
Write-Host "`n🚀 To run the application:" -ForegroundColor Cyan
Write-Host "   cd $OutputPath" -ForegroundColor White
Write-Host "   dotnet PureSqlsMcpWeb.dll" -ForegroundColor White

# Простий скрипт для генерації залежностей SQL об'єктів
$scriptRoot = $PSScriptRoot

# Отримуємо всі SQL файли з util та mcp
$allFiles = Get-ChildItem -Path $scriptRoot -Filter "*.sql" -Recurse | 
    Where-Object { $_.FullName -match '[\\/](util|mcp)[\\/]' -and $_.FullName -notmatch '[\\/]\.[^\\/]+[\\/]' }

# Словник для збереження залежностей кожного об'єкта
$objectsMap = @{}

Write-Host "Scanning $($allFiles.Count) SQL files..." -ForegroundColor Cyan

# Проходимось по всіх файлах
foreach ($file in $allFiles) {
    $sql = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $sql) { continue }
    
    # Визначаємо схему та ім'я об'єкта
    $schema = if ($file.FullName -match '[\\/](util|mcp)[\\/]') { $matches[1] } else { 'dbo' }
    $objectName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $fullName = "$schema.$objectName"
    
    # Ініціалізуємо об'єкт якщо ще не існує
    if (-not $objectsMap.ContainsKey($fullName)) {
        $objectsMap[$fullName] = @{
            References = @()  # На що посилається цей об'єкт
            Referenced = @()  # Хто посилається на цей об'єкт
        }
    }
    
    # Шукаємо всі посилання на util.* та mcp.*
    $pattern = '(?:^|[\s\(,=])(?:\[?(util|mcp)\]?\.(?:\[?([a-zA-Z_][a-zA-Z0-9_]*)\]?))'
    $regexMatches = [regex]::Matches($sql, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    
    foreach ($match in $regexMatches) {
        $refSchema = $match.Groups[1].Value
        $refObject = $match.Groups[2].Value
        $refFullName = "$refSchema.$refObject"
        
        # Не додаємо самопосилання
        if ($refObject -ne $objectName) {
            # Додаємо до списку references поточного об'єкта
            if ($objectsMap[$fullName].References -notcontains $refFullName) {
                $objectsMap[$fullName].References += $refFullName
            }
            
            # Ініціалізуємо referenced об'єкт якщо не існує
            if (-not $objectsMap.ContainsKey($refFullName)) {
                $objectsMap[$refFullName] = @{
                    References = @()
                    Referenced = @()
                }
            }
            
            # Додаємо до списку referenced того об'єкта
            if ($objectsMap[$refFullName].Referenced -notcontains $fullName) {
                $objectsMap[$refFullName].Referenced += $fullName
            }
        }
    }
}

# Перетворюємо в масив PSCustomObject
$result = $objectsMap.Keys | Sort-Object | ForEach-Object {
    [PSCustomObject]@{
        Object = $_
        References = $objectsMap[$_].References | Sort-Object
        Referenced = $objectsMap[$_].Referenced | Sort-Object
    }
}

# Виводимо результат
$result | ConvertTo-Json -Depth 10

<#
.SYNOPSIS
    Розгортає об'єкти зі схеми util з автоматичним вирішенням залежностей.

.DESCRIPTION
    Скрипт шукає SQL файли об'єктів схеми util, аналізує їх залежності від інших об'єктів util,
    і розгортає їх у правильному порядку (спочатку залежності, потім сам об'єкт).

.PARAMETER Server
    Ім'я SQL Server

.PARAMETER Database
    Ім'я бази даних

.PARAMETER Utils
    Ім'я об'єкту в схемі util для розгортання, маска для пошуку, або масив імен.
    Приклади: 
    - "mcpBuildParameterJson" - конкретний об'єкт
    - "mcp*" - всі об'єкти що починаються з "mcp"
    - @("mcpBuildParameterJson", "mcpMapSqlTypeToJsonType") - масив об'єктів

.EXAMPLE
    .\deployUtil.ps1 -Server "localhost" -Database "master" -Utils "mcpBuildParameterJson"
    
.EXAMPLE
    .\deployUtil.ps1 -Server "localhost" -Database "master" -Utils "mcp*"
    
.EXAMPLE
    .\deployUtil.ps1 -Server "localhost" -Database "master" -Utils @("mcpBuildParameterJson", "mcpMapSqlTypeToJsonType")
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Server,
    
    [Parameter(Mandatory = $true)]
    [string]$Database,
    
    [Parameter(Mandatory = $true)]
    [object]$Utils
)

# Перевірка наявності модуля dbatools
if (-not (Get-Module -ListAvailable -Name dbatools)) {
    Write-Error "Модуль dbatools не встановлено. Встановіть його за допомогою: Install-Module -Name dbatools"
    exit 1
}

Import-Module dbatools

# Отримуємо шлях до кореневої директорії проекту (де знаходиться скрипт)
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilPath = Join-Path $scriptRoot "util"

# Перевірка існування директорії util
if (-not (Test-Path $utilPath)) {
    Write-Error "Директорія util не знайдена: $utilPath"
    exit 1
}

# Хеш-таблиця для кешування вже оброблених файлів (запобігання циклічним залежностям)
$processedObjects = @{}

<#
.SYNOPSIS
    Знаходить файл об'єкту за його ім'ям
#>
function Find-ObjectFile {
    param(
        [string]$ObjectName
    )
    
    # Шукаємо файл у всіх підпапках util (Functions, Procedures, Tables, Views)
    $possiblePaths = @(
        Join-Path $utilPath "Functions\$ObjectName.sql"
        Join-Path $utilPath "Procedures\$ObjectName.sql"
        Join-Path $utilPath "Tables\$ObjectName.sql"
        Join-Path $utilPath "Views\$ObjectName.sql"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    return $null
}

<#
.SYNOPSIS
    Витягує залежності від об'єктів util з SQL коду
#>
function Get-UtilDependencies {
    param(
        [string]$SqlContent
    )
    
    $dependencies = @()
    
    # Регулярний вираз для пошуку посилань на util.ObjectName
    # Підтримує варіанти: util.Object, [util].Object, util.[Object], [util].[Object]
    $pattern = '\[?util\]?\.(\[?[A-Za-z_][A-Za-z0-9_]*\]?)'
    
    $depMatches = [regex]::Matches($SqlContent, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    foreach ($match in $depMatches) {
        $objectName = $match.Groups[1].Value
        # Видаляємо квадратні дужки якщо вони є
        $objectName = $objectName -replace '[\[\]]', ''
        
        if ($objectName -and $objectName -notin $dependencies) {
            $dependencies += $objectName
        }
    }
    
    return $dependencies
}

<#
.SYNOPSIS
    Рекурсивно обробляє об'єкт і його залежності, збираючи SQL в правильному порядку
#>
function Get-ObjectWithDependencies {
    param(
        [string]$ObjectName,
        [int]$Depth = 0
    )
    
    # Перевірка на циклічні залежності та вже оброблені об'єкти
    if ($processedObjects.ContainsKey($ObjectName)) {
        Write-Verbose ("$('  ' * $Depth)Об'єкт '$ObjectName' вже оброблено, пропускаємо")
        return ""
    }
    
    Write-Verbose ("$('  ' * $Depth)Обробка об'єкту: $ObjectName")
    
    # Знаходимо файл об'єкту
    $objectFile = Find-ObjectFile -ObjectName $ObjectName
    
    if (-not $objectFile) {
        Write-Warning ("$('  ' * $Depth)Файл для об'єкту '$ObjectName' не знайдено")
        return ""
    }
    
    # Читаємо вміст файлу
    $content = Get-Content -Path $objectFile -Raw -Encoding UTF8
    
    # Витягуємо залежності
    $dependencies = Get-UtilDependencies -SqlContent $content
    
    if ($dependencies.Count -gt 0) {
        Write-Verbose ("$('  ' * $Depth)Знайдено залежності: " + ($dependencies -join ", "))
    }
    
    # Рекурсивно обробляємо залежності
    $dependenciesSql = ""
    foreach ($dep in $dependencies) {
        # Пропускаємо саму себе (якщо об'єкт посилається на себе)
        if ($dep -ne $ObjectName) {
            $depSql = Get-ObjectWithDependencies -ObjectName $dep -Depth ($Depth + 1)
            if ($depSql) {
                $dependenciesSql += $depSql + "`r`n`r`n"
            }
        }
    }
    
    # Позначаємо об'єкт як оброблений
    $processedObjects[$ObjectName] = $true
    
    # Повертаємо SQL: спочатку всі залежності, потім сам об'єкт
    $result = $dependenciesSql + $content
    
    Write-Verbose ("$('  ' * $Depth)Об'єкт '$ObjectName' успішно оброблено")
    
    return $result
}

<#
.SYNOPSIS
    Знаходить файли об'єктів за маскою або масивом імен
#>
function Get-ObjectFiles {
    param(
        [object]$Utils
    )
    
    $objectNames = @()
    
    if ($Utils -is [array]) {
        # Якщо передано масив імен
        $objectNames = $Utils
    }
    elseif ($Utils -like "*`**" -or $Utils -like "*?*") {
        # Якщо передано маску (містить * або ?)
        Write-Verbose "Пошук файлів за маскою: $Utils"
        
        $allFiles = Get-ChildItem -Path $utilPath -Recurse -Filter "*.sql" | Where-Object { 
            $_.Directory.Name -in @('Functions', 'Procedures', 'Tables', 'Views') 
        }
        
        foreach ($file in $allFiles) {
            $name = $file.BaseName
            if ($name -like $Utils) {
                $objectNames += $name
            }
        }
        
        if ($objectNames.Count -eq 0) {
            Write-Warning "Не знайдено файлів за маскою: $Utils"
        }
    }
    else {
        # Якщо передано одне ім'я
        $objectNames = @($Utils)
    }
    
    return $objectNames
}

# Основна логіка
try {
    Write-Host "=== Розгортання об'єктів util ===" -ForegroundColor Cyan
    Write-Host "Сервер: $Server" -ForegroundColor Gray
    Write-Host "База даних: $Database" -ForegroundColor Gray
    Write-Host "Об'єкти: $Utils" -ForegroundColor Gray
    Write-Host ""
    
    # Отримуємо список об'єктів для розгортання
    $objectsToProcess = Get-ObjectFiles -Utils $Utils
    
    if ($objectsToProcess.Count -eq 0) {
        Write-Error "Не знайдено об'єктів для розгортання"
        exit 1
    }
    
    Write-Host "Знайдено об'єктів: $($objectsToProcess.Count)" -ForegroundColor Green
    Write-Host ($objectsToProcess -join ", ") -ForegroundColor Gray
    Write-Host ""
    
    # Збираємо SQL для всіх об'єктів
    $finalSql = ""
    
    foreach ($objName in $objectsToProcess) {
        Write-Host "Збір залежностей для: $objName" -ForegroundColor Yellow
        
        $sql = Get-ObjectWithDependencies -ObjectName $objName
        
        if ($sql) {
            $finalSql += "-- ===== Розгортання $objName =====" + "`r`n"
            $finalSql += $sql + "`r`n`r`n"
        }
    }
    
    if (-not $finalSql) {
        Write-Error "Не вдалося згенерувати SQL для розгортання"
        exit 1
    }
    
    Write-Host ""
    Write-Host "=== Розгортання на сервер ===" -ForegroundColor Cyan
    Write-Host "Кількість символів SQL: $($finalSql.Length)" -ForegroundColor Gray
    Write-Host ""
    
    # Виконуємо SQL
    try {
        $result = Invoke-DbaQuery -SqlInstance $Server -Database $Database -Query $finalSql -EnableException
        Write-Host "✓ Розгортання успішно завершено!" -ForegroundColor Green
        
        # Виводимо інформацію про розгорнуті об'єкти
        Write-Host ""
        Write-Host "Розгорнуто об'єктів: $($processedObjects.Count)" -ForegroundColor Green
        foreach ($obj in $processedObjects.Keys | Sort-Object) {
            Write-Host "  ✓ $obj" -ForegroundColor Gray
        }
    }
    catch {
        Write-Error "Помилка при виконанні SQL: $_"
        
        # Зберігаємо SQL в файл для діагностики
        $errorSqlFile = Join-Path $scriptRoot "deployUtil_error.sql"
        $finalSql | Out-File -FilePath $errorSqlFile -Encoding UTF8
        Write-Host ""
        Write-Host "SQL збережено в файл для діагностики: $errorSqlFile" -ForegroundColor Yellow
        
        exit 1
    }
}
catch {
    Write-Error "Критична помилка: $_"
    Write-Error $_.ScriptStackTrace
    exit 1
}

<#
.SYNOPSIS
    Розгортає об'єкти зі схем util або mcp з автоматичним вирішенням залежностей.

.DESCRIPTION
    Скрипт шукає SQL файли об'єктів схем util/mcp, аналізує їх залежності від інших об'єктів,
    і розгортає їх у правильному порядку (спочатку залежності, потім сам об'єкт).

.PARAMETER Server
    Ім'я SQL Server

.PARAMETER Database
    Ім'я бази даних

.PARAMETER Schema
    Схема для розгортання ('util' або 'mcp'). За замовчуванням 'util'.

.PARAMETER Objects
    Ім'я об'єкту для розгортання, маска для пошуку, або масив імен.
    Приклади: 
    - "mcpBuildParameterJson" - конкретний об'єкт
    - "mcp*" - всі об'єкти що починаються з "mcp"
    - @("mcpBuildParameterJson", "mcpMapSqlTypeToJsonType") - масив об'єктів

.EXAMPLE
    .\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "util" -Objects "mcpBuildParameterJson"
    
.EXAMPLE
    .\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "mcp" -Objects "GetTables"
    
.EXAMPLE
    .\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "util" -Objects "mcp*"
    
.EXAMPLE
    .\deployUtil.ps1 -Server "localhost" -Database "master" -Schema "mcp" -Objects @("GetTables", "GetDatabases")
#>




[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Server,
    
    [Parameter(Mandatory = $true)]
    [string]$Database,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('util', 'mcp')]
    [string]$Schema = 'util',
    
    [Parameter(Mandatory = $true)]
    [object]$Objects
)

# Імпорт банерів
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptRoot "banners.ps1")

# Вивід банера
Write-PureUtilsBanner

# Перевірка наявності модуля dbatools
if (-not (Get-Module -ListAvailable -Name dbatools)) {
    Write-Error "Модуль dbatools не встановлено. Встановіть його за допомогою: Install-Module -Name dbatools"
    exit 1
}

Import-Module dbatools

# Визначаємо шлях до схеми
$schemaPath = Join-Path $scriptRoot $Schema

# Перевірка існування директорії схемиФ
if (-not (Test-Path $schemaPath)) {
    Write-Error "Директорія схеми '$Schema' не знайдена: $schemaPath"
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
    
    # Шукаємо файл у всіх підпапках обраної схеми (Functions, Procedures, Tables, Views)
    $possiblePaths = @(
        Join-Path $schemaPath "Functions\$ObjectName.sql"
        Join-Path $schemaPath "Procedures\$ObjectName.sql"
        Join-Path $schemaPath "Views\$ObjectName.sql"
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
    Витягує залежності від об'єктів util або mcp з SQL коду
#>
function Get-SchemaDependencies {
    param(
        [string]$SqlContent
    )
    
    $dependencies = @()
    
    # Регулярний вираз для пошуку посилань на schema.ObjectName
    # Підтримує варіанти: 
    # - util.Object, [util].Object, util.[Object], [util].[Object]
    # - mcp.Object, [mcp].Object, mcp.[Object], [mcp].[Object]
    # - db.util.Object, [db].util.Object та інші комбінації
    $schemaPattern = "\\[?$Schema\\]?"
    $pattern = "(?:\\[?[A-Za-z_][A-Za-z0-9_]*\\]?\\.)?$schemaPattern\\.(\\[?[A-Za-z_][A-Za-z0-9_]*\\]?)"
    
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
    
    Write-Host ("$('  ' * $Depth)Обробка об'єкту: $ObjectName")
    
    # Знаходимо файл об'єкту
    $objectFile = Find-ObjectFile -ObjectName $ObjectName
    
    if (-not $objectFile) {
        Write-Warning ("$('  ' * $Depth)Файл для об'єкту '$ObjectName' не знайдено")
        return ""
    }
    
    # Читаємо вміст файлу
    $content = Get-Content -Path $objectFile -Raw -Encoding UTF8
    
    # Витягуємо залежності
    $dependencies = Get-SchemaDependencies -SqlContent $content
    
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
                $dependenciesSql += $depSql + "`r`nGO`r`n`r`n"
            }
        }
    }
    
    # Позначаємо об'єкт як оброблений
    $processedObjects[$ObjectName] = $true
    
    # Повертаємо SQL: спочатку всі залежності, потім сам об'єкт
    # Додаємо GO після кожного об'єкта для правильного виконання батчів
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
    
    if ($Objects -is [array]) {
        # Якщо передано масив імен
        $objectNames = $Objects
    }
    elseif ($Objects -like "*`**" -or $Objects -like "*?*") {
        # Якщо передано маску (містить * або ?)
        Write-Verbose "Пошук файлів за маскою: $Objects"
        
        $allFiles = Get-ChildItem -Path $schemaPath -Recurse -Filter "*.sql" | Where-Object { 
            $_.Directory.Name -in @('Functions', 'Procedures', 'Tables', 'Views') 
        }
        
        foreach ($file in $allFiles) {
            $name = $file.BaseName
            if ($name -like $Objects) {
                $objectNames += $name
            }
        }
        
        if ($objectNames.Count -eq 0) {
            Write-Warning "Не знайдено файлів за маскою: $Objects"
        }
    }
    else {
        # Якщо передано одне ім'я
        $objectNames = @($Objects)
    }
    
    return $objectNames
}

# Основна логіка
try {
    Write-Host "Розгортання об'єктів схеми $Schema" -ForegroundColor DarkGreen
    Write-Host "Сервер: $Server" -ForegroundColor Gray
    Write-Host "База даних: $Database" -ForegroundColor Gray
    Write-Host "Схема: $Schema" -ForegroundColor Gray
    Write-Host "Об'єкти: $Objects" -ForegroundColor Gray
    Write-Host ""
    
    # Отримуємо список об'єктів для розгортання
    $objectsToProcess = Get-ObjectFiles -Utils $Objects
    
    if ($objectsToProcess.Count -eq 0) {
        Write-Error "Не знайдено об'єктів для розгортання"
        exit 1
    }
     
    
    # Збираємо SQL для всіх об'єктів
    $finalSql = ""
    
    foreach ($objName in $objectsToProcess) {
        
        $sql = Get-ObjectWithDependencies -ObjectName $objName
        
        if ($sql) {
            $finalSql += $sql + "`r`nGO`r`n`r`n"
        }
    }
    
    if (-not $finalSql) {
        Write-Error "Не вдалося згенерувати SQL для розгортання"
        exit 1
    }
    
    
    # Виконуємо SQL
    try {
        # Розділяємо SQL на батчі по GO
        $batches = $finalSql -split '\r?\nGO\r?\n'
        
        $batchNumber = 0
        foreach ($batch in $batches) {
            $batch = $batch.Trim()
            if ($batch) {
                $batchNumber++
                # Write-Verbose "Виконання батча $batchNumber..."
                Write-Verbose $batch 
                $result = Invoke-DbaQuery -SqlInstance $Server -Database $Database -Query $batch -EnableException
            }
        }
     
        # Виводимо інформацію про розгорнуті об'єкти
        Write-Host "Розгорнуто об'єктів: $($processedObjects.Count)" -ForegroundColor Cyan
        foreach ($obj in $processedObjects.Keys | Sort-Object) {
            Write-Host " - $obj" -ForegroundColor Gray
        }

        # Встановлюємо описи з коментарів для кожного розгорнутого об'єкту
        Write-Host ""
        Write-Host "Встановлення описів з коментарів..." -ForegroundColor DarkGreen
        
        foreach ($obj in $processedObjects.Keys | Sort-Object) {
            try {
                $fullObjectName = "$Schema.$obj"
                Write-Verbose "Встановлення опису для: $fullObjectName"
                
                $descriptionQuery = "EXEC util.modulesSetDescriptionFromComments @object = '$fullObjectName';"
                Invoke-DbaQuery -SqlInstance $Server -Database $Database -Query $descriptionQuery -EnableException
                
                Write-Host " ✓ $fullObjectName" -ForegroundColor Gray
            }
            catch {
                Write-Warning "Не вдалося встановити опис для '$fullObjectName': $_"
            }
        }
    }
    catch {
        Write-Error "Помилка при виконанні SQL (батч $batchNumber): $_"
        
        # Зберігаємо SQL в файл для діагностики
        $errorSqlFile = Join-Path $scriptRoot "deployUtil_error.sql"
        $finalSql | Out-File -FilePath $errorSqlFile -Encoding UTF8
        Write-Host ""
        Write-Host "SQL збережено в файл для діагностики: $errorSqlFile" -ForegroundColor Yellow
        
        exit 1
    }
    Write-Host ""
    Write-Host "#########################################################" -ForegroundColor DarkGray
    Write-Host ""

}
catch {
    Write-Error "Критична помилка: $_"
    Write-Error $_.ScriptStackTrace
    exit 1
}



<#
.SYNOPSIS
    Скрипт для розгортання Pure Utils об'єктів бази даних з автоматичним управлінням залежностями

.DESCRIPTION
    Розгортає SQL об'єкти (функції, процедури, views, таблиці) в зазначену базу даних.
    Автоматично визначає та розгортає залежності в правильному порядку.
    Підтримує фільтрацію об'єктів та пропуск певних файлів.
    
    ВАЖЛИВО:
    - Розгортаються тільки об'єкти рівня бази даних (модулі та таблиці)
    - Об'єкти рівня серверу (Extended Events тощо) ігноруються
    - При розгортанні таблиць існуюча таблиця перейменовується з префіксом __obs_ та timestamp
      Приклад: util.ErrorLog -> util.__obs_ErrorLog_20251012021430

.PARAMETER SqlInstance
    Ім'я SQL Server інстансу (обов'язковий параметр)

.PARAMETER Database
    Назва бази даних для розгортання (обов'язковий параметр)

.PARAMETER DeployFilters
    Масив фільтрів для вибору файлів на розгортання (опційно)
    Приклад: @("metadata*", "help", "*GetScript")
    Якщо не вказано - розгортаються всі файли

.PARAMETER SkipFilters
    Масив фільтрів для пропуску файлів (опційно)
    Файли що відповідають цим фільтрам будуть пропущені навіть якщо є в залежностях

.PARAMETER SetDescription
    Чи виконувати util.modulesSetDescriptionFromComments після розгортання (за замовчуванням: $true)

.PARAMETER CreateSchema
    Чи створювати схеми util та mcp за потреби (за замовчуванням: $true)

.PARAMETER SkipAllTables
    Чи пропускати всі таблиці при розгортанні (за замовчуванням: $true)

.PARAMETER SkipReferences
    Чи пропускати перевірку та додавання залежностей (за замовчуванням: $false)

.PARAMETER Schema
    Схема для розгортання: util або mcp (за замовчуванням: util)

.PARAMETER ErrorActionPreference
    Дія при помилці: Continue, Stop, SilentlyContinue (за замовчуванням: Continue)

.PARAMETER Help
    Показати довідку

.EXAMPLE
    .\deploy.ps1 -SqlInstance "localhost" -Database "utils"

.EXAMPLE
    .\deploy.ps1 -SqlInstance "localhost" -Database "utils" -DeployFilters @("metadata*", "*GetScript")

.EXAMPLE
    .\deploy.ps1 -SqlInstance "localhost" -Database "utils" -Schema "mcp"

.EXAMPLE
    .\deploy.ps1 -SqlInstance "localhost" -Database "utils" -Schema "util" -DeployFilters @("help", "errorHandler")

.EXAMPLE
    .\deploy.ps1 -SqlInstance "localhost" -Database "utils" -SkipFilters @("*Test*") -SkipAllTables $false

.EXAMPLE
    .\deploy.ps1 -SqlInstance "localhost" -Database "utils" -Verbose
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SqlInstance,

    [Parameter(Mandatory = $true)]
    [string]$Database,

    [Parameter(Mandatory = $false)]
    [string[]]$DeployFilters = @("*"),

    [Parameter(Mandatory = $false)]
    [string[]]$SkipFilters = @(),

    [Parameter(Mandatory = $false)]
    [bool]$SetDescription = $true,

    [Parameter(Mandatory = $false)]
    [bool]$SkipAllTables = $true,

    [Parameter(Mandatory = $false)]
    [bool]$SkipReferences = $false,

    [Parameter(Mandatory = $false)]
    [ValidateSet('util', 'mcp', 'api')]
    [string]$Schema = 'util',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Continue', 'Stop', 'SilentlyContinue')]
    [string]$ErrorActionPreference = 'Continue',

    [Parameter(Mandatory = $false)]
    [switch]$Help
)

# Показати довідку якщо запитано
if ($Help) {
    $help = @"
    --------------------------------
    Довідка по скрипту розгортання
    --------------------------------
    Параметри:
    - SqlInstance: Ім'я SQL Server інстансу (обов`язковий параметр)
    - Database: Назва бази даних для розгортання (обов'язковий параметр)
    - DeployFilters: Масив фільтрів для вибору файлів на розгортання (опційно)
    - SkipFilters: Масив фільтрів для пропуску файлів (опційно)
    - SetDescription: Чи виконувати util.modulesSetDescriptionFromComments після розгортання (за замовчуванням: `$true)
    - CreateSchema: Чи створювати схеми util та mcp за потреби (за замовчуванням: `$true)
    - SkipAllTables: Чи пропускати всі таблиці при розгортанні (за замовчуванням: `$true)
    - SkipReferences: Чи пропускати перевірку та додавання залежностей (за замовчуванням: `$false)
    - Schema: Схема для розгортання: util або mcp (за замовчуванням: util)
    - ErrorActionPreference: Дія при помилці: Continue, Stop, SilentlyContinue (за замовчуванням: Continue)
    - Help: Показати довідку 
"@

    Write-Host $help -ForegroundColor DarkYellow
}

# Імпорт банерів
. "$PSScriptRoot\banners.ps1"

# Показати банер тільки один раз за сесію
# if (-not $Global:PureUtilsBannerShown) {
Write-PureUtilsBanner
# $Global:PureUtilsBannerShown = $true
# }

# Глобальні змінні
$script:deploymentList = [System.Collections.ArrayList]::new()
$script:processedFiles = [System.Collections.Generic.HashSet[string]]::new()
$script:scriptRoot = $PSScriptRoot
$script:ErrorActionPreference = $ErrorActionPreference

#region Helper Functions

function Write-DeploymentInfo {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-DeploymentError {
    param(
        [string]$Message,
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    Write-Host "ERROR: $Message" -ForegroundColor Red
    if ($ErrorRecord) {
        Write-Host $ErrorRecord.Exception.Message -ForegroundColor Red
    }
}

function Get-ObjectPath {
    <#
    .SYNOPSIS
        Знаходить шлях до SQL файлу по назві об'єкта
    #>
    param(
        [string]$ObjectName
    )
    
    $cleanName = $ObjectName.Replace("[", "").Replace("]", "").Trim()
    
    # Додаємо .sql якщо відсутнє
    if (-not $cleanName.EndsWith('.sql')) {
        $cleanName = "$cleanName.sql"
    }
    
    # Шукаємо файл рекурсивно, ігноруючи папки що починаються з крапки
    $files = Get-ChildItem -Path $script:scriptRoot -Filter $cleanName -Recurse -File | 
    Where-Object { $_.FullName -notmatch '[\\/]\.[^\\/]+[\\/]' }
    
    if ($files) {
        return $files[0].FullName
    }
    
    return $null
}

function Get-ReferencedObjects {
    <#
    .SYNOPSIS
        Витягує всі посилання на об'єкти util.* та mcp.* з SQL файлу
    #>
    param(
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        return @()
    }
    
    $sql = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    
    if (-not $sql) {
        return @()
    }
    
    # Шукаємо посилання на об'єкти схем util та mcp
    $pattern = '\[?(util|mcp)\]?\.\[?(\w+)\]?'
    $regexMatches = [regex]::Matches($sql, $pattern)
    
    $references = @()
    foreach ($match in $regexMatches) {
        $schema = $match.Groups[1].Value
        $objectName = $match.Groups[2].Value
        $fullName = "$schema.$objectName"
        
        # Не додаємо self-reference
        $currentFileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        if ($objectName -ne $currentFileName) {
            $references += $fullName
        }
    }
    
    return $references | Select-Object -Unique
}

function Test-ShouldSkipFile {
    <#
    .SYNOPSIS
        Перевіряє чи файл повинен бути пропущений згідно фільтрів
    #>
    param(
        [string]$FilePath
    )
    
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    
    # Пропускаємо Extended Event Sessions (серверні об'єкти)
    if ($FilePath -match '[\\/]XESessions[\\/]') {
        Write-Verbose "Skipping XE Session (server-level object): $fileName"
        return $true
    }
    
    # Перевіряємо SkipFilters
    foreach ($filter in $SkipFilters) {
        if ($fileName -like $filter) {
            return $true
        }
    }
    
    # Перевіряємо SkipAllTables
    if ($SkipAllTables -and $FilePath -match '[\\/]Tables[\\/]') {
        return $true
    }
    
    return $false
}

function Add-FileToDeploymentList {
    <#
    .SYNOPSIS
        Додає файл до списку розгортання з рекурсивною обробкою залежностей
    .DESCRIPTION
        Алгоритм:
        1. Перевіряємо чи файл вже оброблено (уникаємо дублювання та циклів)
        2. Якщо не пропускаємо залежності - спочатку додаємо ВСІ залежності рекурсивно
        3. Потім додаємо поточний файл
        
        Результат: залежності завжди в списку вище, ніж залежний від них об'єкт
    #>
    param(
        [string]$FilePath,
        [int]$Depth = 0
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Verbose "File not found: $FilePath"
        return
    }
    
    # Нормалізуємо шлях
    $FilePath = [System.IO.Path]::GetFullPath($FilePath)
    
    # Перевіряємо чи файл не в skip-списку
    if (Test-ShouldSkipFile -FilePath $FilePath) {
        Write-Verbose "Skipping file (matched skip filter): $FilePath"
        return
    }

    # Перевіряємо чи файл вже оброблено (захист від дублювання та циклів)
    if ($script:processedFiles.Contains($FilePath)) {
        Write-Verbose "Already processed: $FilePath"
        return
    }
    
    # Позначаємо файл як оброблений
    [void]$script:processedFiles.Add($FilePath)
    
    # Якщо не пропускаємо залежності - спочатку додаємо їх рекурсивно
    if (-not $SkipReferences -and $Depth -lt 50) {
        $references = Get-ReferencedObjects -FilePath $FilePath
        
        foreach ($ref in $references) {
            $refObjectName = $ref -replace '^[^.]+\.', ''
            $refPath = Get-ObjectPath -ObjectName $refObjectName
            
            if ($refPath) {
                Write-Verbose "$('  ' * $Depth)Processing dependency: $ref -> $refPath"
                Add-FileToDeploymentList -FilePath $refPath -Depth ($Depth + 1)
            }
            else {
                Write-Verbose "$('  ' * $Depth)Dependency not found in project: $ref"
            }
        }
    }
    
    # Додаємо поточний файл в кінець списку (після всіх залежностей)
    Write-Verbose "$('  ' * $Depth)Adding to deployment list: $FilePath"
    [void]$script:deploymentList.Add($FilePath)
}



function Rename-ExistingTable {
    <#
    .SYNOPSIS
        Перейменовує існуючу таблицю додавши префікс __obs_ та timestamp
    #>
    param(
        [string]$Schema,
        [string]$TableName
    )
    
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $newName = "__obs_${TableName}_${timestamp}"
    
    $checkTableSql = @"
IF OBJECT_ID('[$Schema].[$TableName]', 'U') IS NOT NULL
BEGIN
    EXEC sp_rename '[$Schema].[$TableName]', '$newName';
    PRINT 'Renamed table [$Schema].[$TableName] to [$Schema].[$newName]';
END
"@
    
    try {
        Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $checkTableSql -EnableException
        return $true
    }
    catch {
        Write-DeploymentError "Failed to rename table [$Schema].[$TableName]" -ErrorRecord $_
        return $false
    }
}

function Deploy-SqlFile {
    <#
    .SYNOPSIS
        Розгортає один SQL файл
    #>
    param(
        [string]$FilePath
    )
    
    Write-Host $FilePath -ForegroundColor DarkCyan
    # Console.WriteLine("Deploying SQL File: $FilePath");

    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    # $relativePath = $FilePath.Replace($script:scriptRoot, "").TrimStart('\', '/')
    
    # Визначаємо схему з шляху
    $schema = if ($FilePath -match '[\\/](api|util|mcp)[\\/]') { $matches[1] } else { 'dbo' }
    $fullObjectName = "[$schema].[$fileName]"
    
    Write-Host $fullObjectName -ForegroundColor DarkMagenta
    
    try {
        # Якщо це таблиця - перейменовуємо існуючу
        if ($FilePath -match '[\\/]Tables[\\/]') {
            Rename-ExistingTable -Schema $schema -TableName $fileName
        }
        
        $sql = Get-Content -Path $FilePath -Raw -Encoding UTF8
        
        Write-Host "Executing SQL..." -ForegroundColor DarkYellow
        Write-Host $SqlInstance -ForegroundColor DarkGreen
        Write-Host $Database -ForegroundColor DarkGreen

        Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $sql -QueryTimeout 300 -EnableException | Out-Null
        
        # Успішно розгорнуто - нічого не виводимо
        return $true
    }
    catch {
        Write-DeploymentError "Failed to deploy $fullObjectName" -ErrorRecord $_
        
        if ($script:ErrorActionPreference -eq 'Stop') {
            throw
        }
        
        return $false
    }
}

function Set-ModuleDescriptions {
    <#
    .SYNOPSIS
        Встановлює описи для модулів з коментарів
    #>
    
    Write-DeploymentInfo "`nSetting module descriptions from comments..." -Color Cyan
    
    # Перевіряємо чи існує процедура
    $cmdSetDescription = @"
IF(OBJECT_ID('util.modulesSetDescriptionFromComments') IS NOT NULL)
BEGIN
	DECLARE @cmd NVARCHAR(MAX);
	DECLARE mcur CURSOR STATIC LOCAL READ_ONLY FORWARD_ONLY FOR
	SELECT CONCAT('EXEC util.modulesSetDescriptionFromComments ', QUOTENAME(OBJECT_SCHEMA_NAME(object_id)), '.', QUOTENAME(OBJECT_NAME(object_id)))
	FROM sys.sql_modules
	WHERE OBJECT_SCHEMA_NAME(object_id) IN ('mcp', 'util');
	OPEN mcur;
    FETCH NEXT FROM mcur INTO @cmd;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC sp_executesql @cmd;
        END TRY
        BEGIN CATCH
            PRINT CONCAT('Failed to set description using command: ', @cmd, '. Error: ', ERROR_MESSAGE());
        END CATCH
        FETCH NEXT FROM mcur INTO @cmd;
    END
    CLOSE mcur;
    DEALLOCATE mcur;
END
"@
    
    try {
        Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $cmdSetDescription
    }
    catch {
        Write-DeploymentError "Failed to set module descriptions" -ErrorRecord $_
    }
}

#endregion

#region Main Execution

try {
    # Перевіряємо наявність dbatools модуля
    if (-not (Get-Module -ListAvailable -Name dbatools)) {
        Write-DeploymentError "dbatools PowerShell module is not installed. Please install it using: Install-Module -Name dbatools"
        return
    }
    
    Import-Module dbatools -ErrorAction Stop
    
    # Перевіряємо підключення до SQL Server
    Write-DeploymentInfo "Testing connection to SQL Server..." -Color Cyan
    try {
        $testQuery = "SELECT @@VERSION AS Version, DB_NAME() AS CurrentDatabase"
        $connectionTest = Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $testQuery -EnableException
        Write-DeploymentInfo "Connected successfully to [$SqlInstance].[$Database]" -Color Green
        Write-Verbose "SQL Server Version: $($connectionTest.Version)"
    }
    catch {
        Write-DeploymentError "Failed to connect to SQL Server [$SqlInstance].[$Database]" -ErrorRecord $_
        return
    }
    
    Write-DeploymentInfo "`nDeployment Configuration:" -Color Cyan
    Write-DeploymentInfo "  SQL Instance: $SqlInstance" -Color DarkGray
    Write-DeploymentInfo "  Database: $Database" -Color DarkGray
    Write-DeploymentInfo "  Schema: $Schema" -Color DarkGray
    Write-DeploymentInfo "  Deploy Filters: $(if($DeployFilters.Count -eq 0){'Not Specified'}else{$DeployFilters -join ', '})" -Color DarkGray
    Write-DeploymentInfo "  Skip Filters: $(if($SkipFilters.Count -eq 0){'[None]'}else{$SkipFilters -join ', '})" -Color DarkGray
    Write-DeploymentInfo "  Skip Tables: $SkipAllTables" -Color DarkGray
    Write-DeploymentInfo "  Skip References: $SkipReferences" -Color DarkGray
    Write-DeploymentInfo "  Set Descriptions: $SetDescription" -Color DarkGray
    Write-DeploymentInfo ""
    
    # Створюємо схеми за потреби
    $schemaSql = Get-Content -Path "$script:scriptRoot\Security\$Schema.sql" -Raw
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $schemaSql -EnableException 
    
    # Формуємо список файлів для розгортання
    Write-DeploymentInfo "Building deployment list..." -Color Cyan
    
    # Визначаємо шлях до папки схеми
    $schemaPath = Join-Path -Path $script:scriptRoot -ChildPath $Schema
   
    # Якщо вказані фільтри - шукаємо файли що відповідають фільтрам
    $allSqlFiles = @()
    foreach ($filter in $DeployFilters) {
        # Додаємо .sql до фільтра якщо відсутнє
        $sqlFilter = if ($filter.EndsWith('.sql')) { $filter } else { "$filter.sql" }
            
        $matchedFiles = Get-ChildItem -Path $schemaPath -Filter $sqlFilter -Recurse -File | 
        Where-Object { 
            $_.FullName -notmatch '[\\/]\.[^\\/]+[\\/]' -and
            $_.FullName -notmatch '[\\/]XESessions[\\/]'
        }
            
        $allSqlFiles += $matchedFiles
    }
        
    # Видаляємо дублікати
    # $allSqlFiles = $allSqlFiles | Select-Object -Unique
 
    foreach ($file in $allSqlFiles) {
        Add-FileToDeploymentList -FilePath $file.FullName
    }
    
    Write-DeploymentInfo "Files to deploy: $($script:deploymentList.Count)" -Color Cyan
    
    if ($script:deploymentList.Count -eq 0) {
        Write-DeploymentInfo "No files to deploy" -Color Yellow
        return
    }
    
    # Розгортаємо файли в зворотному порядку (залежності першими)
    Write-DeploymentInfo "`nDeploying objects..." -Color Cyan
    
    $deployedCount = 0
    $errorCount = 0

    # Розгортаємо файли в порядку додавання (залежності вже на правильних місцях)
    for ($i = 0; $i -lt $script:deploymentList.Count; $i++) {
        $filePath = $script:deploymentList[$i]
        
        if (Deploy-SqlFile -FilePath $filePath) {
            $deployedCount++
        }
        else {
            $errorCount++
        }
    }
    
    Write-DeploymentInfo "`nDeployment Summary:" -Color Cyan
    Write-DeploymentInfo "  Successfully deployed: $deployedCount" -Color Green
    if ($errorCount -gt 0) {
        Write-DeploymentInfo "  Failed: $errorCount" -Color Red
    }
    
    # Встановлюємо описи з коментарів
    if ($SetDescription) {
        Set-ModuleDescriptions
    }
    
    Write-DeploymentInfo "`nDeployment completed!" -Color Green
}
catch {
    Write-DeploymentError "Deployment failed" -ErrorRecord $_
    
    if ($script:ErrorActionPreference -eq 'Stop') {
        throw
    }
    
    exit 1
}

#endregion
# PowerShell Скрипти

## Огляд

pure-utils включає PowerShell скрипти для автоматизації розгортання та компіляції компонентів. Всі скрипти використовують модуль `dbatools` для роботи з SQL Server.

## deployUtil.ps1

### Призначення

Розгортання об'єктів зі схем `util` або `mcp` з автоматичним вирішенням залежностей.

### Основні можливості

- **Автоматичний аналіз залежностей** між об'єктами
- **Правильний порядок розгортання** (спочатку залежності)
- **Підтримка масок** для розгортання групи об'єктів
- **Запобігання циклічним залежностям**
- **Інтеграція з dbatools**

### Параметри

#### Обов'язкові параметри

**-Server** (string)
- Ім'я SQL Server
- Приклади: `"localhost"`, `".\SQLEXPRESS"`, `"sql-server.domain.com"`

**-Database** (string)
- Ім'я бази даних для розгортання
- Приклад: `"master"`, `"YourDatabase"`

**-Objects** (string або array)
- Ім'я об'єкту, маска або масив імен
- Примклади:
  - `"mcpBuildParameterJson"` - конкретний об'єкт
  - `"mcp*"` - всі об'єкти що починаються з "mcp"
  - `@("GetTables", "GetDatabases")` - масив об'єктів
  - `@("*")` - всі об'єкти

#### Опціональні параметри

**-Schema** (string)
- Схема для розгортання: `'util'` або `'mcp'`
- За замовчуванням: `'util'`
- Validation: `[ValidateSet('util', 'mcp')]`

### Приклади використання

#### Розгортання одного об'єкта

```powershell
.\deployUtil.ps1 `
    -Server "localhost" `
    -Database "master" `
    -Schema "util" `
    -Objects "indexesGetConventionNames"
```

#### Розгортання всіх об'єктів схеми util

```powershell
.\deployUtil.ps1 `
    -Server "localhost" `
    -Database "master" `
    -Schema "util" `
    -Objects @("*")
```

#### Розгортання об'єктів за маскою

```powershell
# Всі функції metadata
.\deployUtil.ps1 `
    -Server "localhost" `
    -Database "master" `
    -Schema "util" `
    -Objects "metadata*"

# Всі функції indexes
.\deployUtil.ps1 `
    -Server "localhost" `
    -Database "master" `
    -Schema "util" `
    -Objects "indexes*"

# Всі функції xe
.\deployUtil.ps1 `
    -Server "localhost" `
    -Database "master" `
    -Schema "util" `
    -Objects "xe*"
```

#### Розгортання масиву об'єктів

```powershell
.\deployUtil.ps1 `
    -Server "localhost" `
    -Database "master" `
    -Schema "util" `
    -Objects @(
        "metadataGetAnyId",
        "metadataGetAnyName",
        "indexesGetMissing",
        "indexesGetConventionNames"
    )
```

#### Розгортання схеми mcp

```powershell
.\deployUtil.ps1 `
    -Server "localhost" `
    -Database "master" `
    -Schema "mcp" `
    -Objects @("GetDatabases", "GetTables", "GetTableInfo")
```

#### Віддалений SQL Server

```powershell
.\deployUtil.ps1 `
    -Server "sql-server.company.com" `
    -Database "Production" `
    -Schema "util" `
    -Objects @("*")
```

### Як працює аналіз залежностей

#### 1. Пошук файлів

Скрипт шукає SQL файли у підпапках схеми:
- `util/Functions/`
- `util/Procedures/`
- `util/Tables/`
- `util/Views/`

Або:
- `mcp/Procedures/`
- `mcp/Functions/`

#### 2. Витягування залежностей

Для кожного файлу аналізує SQL код та знаходить посилання на інші об'єкти:

```powershell
function Get-SchemaDependencies {
    param([string]$SqlContent)
    
    $dependencies = @()
    
    # Regex для пошуку util.ObjectName або mcp.ObjectName
    $pattern = "\b(util|mcp)\.(\w+)\b"
    $matches = [regex]::Matches($SqlContent, $pattern)
    
    foreach ($match in $matches) {
        $schemaName = $match.Groups[1].Value
        $objectName = $match.Groups[2].Value
        
        if ($schemaName -eq $Schema) {
            $dependencies += $objectName
        }
    }
    
    return $dependencies | Select-Object -Unique
}
```

#### 3. Topological sort

Впорядковує об'єкти так, щоб залежності розгортались перед об'єктами, що їх використовують:

```
Приклад:
  indexesGetConventionNames залежить від metadataGetAnyId
  
Порядок розгортання:
  1. metadataGetAnyId
  2. indexesGetConventionNames
```

#### 4. Запобігання циклам

Кешує вже оброблені об'єкти:

```powershell
$processedObjects = @{}

function Deploy-ObjectWithDependencies {
    param([string]$ObjectName)
    
    # Перевірка циклічних залежностей
    if ($processedObjects.ContainsKey($ObjectName)) {
        return
    }
    
    # Спочатку розгорнути залежності
    $dependencies = Get-Dependencies $ObjectName
    foreach ($dep in $dependencies) {
        Deploy-ObjectWithDependencies $dep
    }
    
    # Потім розгорнути сам об'єкт
    Invoke-DbaQuery -SqlInstance $Server -Database $Database -File $filePath
    
    $processedObjects[$ObjectName] = $true
}
```

### Вивід та логування

Скрипт виводить інформацію про процес:

```
Розгортання об'єкта: metadataGetAnyId
  Файл: C:\...\util\Functions\metadataGetAnyId.sql
  Залежності: немає
  
Розгортання об'єкта: indexesGetConventionNames
  Файл: C:\...\util\Functions\indexesGetConventionNames.sql
  Залежності: metadataGetAnyId (вже розгорнуто)
  
Успішно розгорнуто 2 об'єкти
```

### Помилки та усунення

#### Помилка: "Модуль dbatools не встановлено"

**Рішення**:
```powershell
Install-Module -Name dbatools -Scope CurrentUser -Force
```

#### Помилка: "Не вдається підключитися до SQL Server"

**Рішення**:
- Перевірте ім'я сервера
- Перевірте SQL Server Authentication / Windows Authentication
- Перевірте firewall правила
- Перевірте SQL Server Browser service

#### Помилка: "Файл об'єкту не знайдено"

**Рішення**:
- Перевірте правильність назви об'єкту
- Перевірте наявність файлу у відповідній папці
- Перевірте схему (util/mcp)

#### Помилка SQL при розгортанні

**Рішення**:
- Перевірте синтаксис SQL у файлі
- Перевірте права користувача
- Перевірте залежності вручну

### Розширення скрипту

#### Додавання підтримки SQL Authentication

```powershell
param(
    [Parameter(Mandatory = $false)]
    [PSCredential]$SqlCredential
)

# У виклику Invoke-DbaQuery
if ($SqlCredential) {
    Invoke-DbaQuery -SqlInstance $Server -Database $Database `
        -SqlCredential $SqlCredential -File $filePath
}
```

#### Додавання backup перед розгортанням

```powershell
function Backup-DatabaseObjects {
    $backupPath = ".\backup_" + (Get-Date -Format "yyyyMMdd_HHmmss")
    New-Item -ItemType Directory -Path $backupPath
    
    foreach ($obj in $ObjectsToBackup) {
        Export-DbaScript -SqlInstance $Server -Database $Database `
            -Object $obj -FilePath "$backupPath\$obj.sql"
    }
}
```

---

## PureSqlsMcp/build.ps1

### Призначення

Компіляція PureSqlsMcp .NET сервера у self-contained executable.

### Основні можливості

- **Перевірка .NET SDK 8.0**
- **Self-contained build** (не потребує .NET Runtime)
- **Single file executable**
- **Платформа win-x64**

### Параметри

Скрипт не має параметрів, все налаштовано всередині.

### Приклад використання

```powershell
cd PureSqlsMcp
.\build.ps1
```

### Вивід

```
Перевірка наявності .NET SDK 8.0...
.NET SDK 8.0 знайдено

Компіляція PureSqlsMcp...
Publish succeeded

Виконуваний файл створено:
C:\...\PureSqlsMcp\bin\Release\net8.0\win-x64\publish\PureSqlsMcp.exe
```

### Конфігурація build

```powershell
dotnet publish -c Release -r win-x64 --self-contained true `
    -p:PublishSingleFile=true `
    -p:PublishTrimmed=false `
    -p:IncludeNativeLibrariesForSelfExtract=true
```

**Параметри**:
- `-c Release` - Release конфігурація
- `-r win-x64` - Windows x64 runtime
- `--self-contained true` - включити .NET runtime
- `-p:PublishSingleFile=true` - один exe файл
- `-p:PublishTrimmed=false` - без trimming (для сумісності)
- `-p:IncludeNativeLibrariesForSelfExtract=true` - включити native dll

### Кастомізація

#### Інші платформи

```powershell
# Linux x64
dotnet publish -c Release -r linux-x64 --self-contained true

# macOS x64
dotnet publish -c Release -r osx-x64 --self-contained true

# ARM64
dotnet publish -c Release -r win-arm64 --self-contained true
```

#### Framework-dependent build (менший розмір)

```powershell
dotnet publish -c Release -r win-x64 --self-contained false
```

---

## PlanSqlsMcp/build.ps1

### Призначення

Компіляція PlanSqlsMcp .NET сервера у self-contained executable.

### Використання

Аналогічно до PureSqlsMcp/build.ps1:

```powershell
cd PlanSqlsMcp
.\build.ps1
```

---

## Best Practices

1. **Використовуйте Git** для version control скриптів
2. **Тестуйте на dev середовищі** перед production
3. **Створюйте backup** перед розгортанням на production
4. **Документуйте зміни** у коментарях скриптів
5. **Використовуйте параметри** замість hardcoded значень
6. **Логуйте результати** розгортання
7. **Автоматизуйте** через CI/CD де можливо

## Автоматизація через CI/CD

### Приклад Azure DevOps Pipeline

```yaml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - util/**
      - mcp/**

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  inputs:
    filePath: 'deployUtil.ps1'
    arguments: '-Server $(SqlServer) -Database $(Database) -Schema util -Objects @("*")'
  displayName: 'Deploy util schema'

- task: PowerShell@2
  inputs:
    filePath: 'deployUtil.ps1'
    arguments: '-Server $(SqlServer) -Database $(Database) -Schema mcp -Objects @("*")'
  displayName: 'Deploy mcp schema'
```

### Приклад GitHub Actions

```yaml
name: Deploy pure-utils

on:
  push:
    branches: [ main ]
    paths:
      - 'util/**'
      - 'mcp/**'

jobs:
  deploy:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Install dbatools
      shell: powershell
      run: Install-Module -Name dbatools -Force -Scope CurrentUser
    
    - name: Deploy util schema
      shell: powershell
      run: |
        .\deployUtil.ps1 `
          -Server ${{ secrets.SQL_SERVER }} `
          -Database ${{ secrets.SQL_DATABASE }} `
          -Schema util `
          -Objects @("*")
```

## Наступні кроки

- [Конфігурація MCP](config.md)
- [Модулі](modules/util.md)
- [Приклади](examples.md)

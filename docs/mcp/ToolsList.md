# mcp.ToolsList

## Опис

Функція для отримання списку всіх доступних MCP tools у форматі JSON. Автоматично сканує схему `mcp` та генерує опис кожної процедури у форматі, сумісному з MCP protocol.

## Синтаксис

```sql
SELECT mcp.ToolsList();
```

## Параметри

Функція не має параметрів.

## Повертає

**Тип:** NVARCHAR(MAX)  
**Формат:** JSON масив з описом MCP tools

### Структура відповіді

```json
{
  "tools": [
    {
      "name": "GetDatabases",
      "description": "Процедура для отримання списку баз даних",
      "inputSchema": {
        "type": "object",
        "properties": {},
        "required": []
      }
    },
    {
      "name": "GetTables",
      "description": "Процедура для отримання списку таблиць",
      "inputSchema": {
        "type": "object",
        "properties": {
          "database": {
            "type": "string",
            "description": "Назва бази даних"
          },
          "filter": {
            "type": "string",
            "description": "Фільтр за назвою таблиці"
          }
        },
        "required": ["database"]
      }
    }
  ]
}
```

## Приклади

### Базове використання

```sql
-- Отримати список всіх MCP tools
SELECT mcp.ToolsList();
```

### Форматований вивід

```sql
-- Для красивого виводу в SSMS
DECLARE @json NVARCHAR(MAX) = mcp.ToolsList();
SELECT @json AS ToolsList;
```

### Використання в PowerShell

```powershell
# Отримати та розібрати список tools
$result = Invoke-DbaQuery -SqlInstance "localhost" -Database "Utils" `
    -Query "SELECT mcp.ToolsList() AS ToolsList"

$tools = ($result.ToolsList | ConvertFrom-Json).tools

# Вивести назви всіх tools
$tools | Select-Object name, description | Format-Table
```

## Як працює

Функція автоматично:
1. Сканує всі об'єкти в схемі `mcp`
2. Витягує описи з коментарів (через `util.metadataGetDescriptions`)
3. Аналізує параметри кожної процедури (через `util.mcpGetObjectParameters`)
4. Визначає обов'язкові та опціональні параметри
5. Генерує JSON schema для кожного tool
6. Формує фінальний JSON масив

## Використання в MCP серверах

Ця функція автоматично викликається MCP серверами при запуску:
- **PureSqlsMcp** - консольний сервер
- **PureSqlsMcpWeb** - веб-сервер
- **PlanSqlsMcp** - сервер для планів

Сервери використовують результат для реєстрації доступних tools та їх параметрів.

## Формат Tool Definition

Кожен tool описується за стандартом MCP:

```json
{
  "name": "ToolName",
  "description": "Опис з коментарів",
  "inputSchema": {
    "type": "object",
    "properties": {
      "param1": {
        "type": "string|number|boolean",
        "description": "Опис параметра"
      }
    },
    "required": ["param1"]
  }
}
```

## Маппінг SQL типів на JSON типи

Функція використовує `util.mcpMapSqlTypeToJsonType` для конвертації:

| SQL Type | JSON Type |
|----------|-----------|
| INT, BIGINT, SMALLINT | number |
| BIT | boolean |
| VARCHAR, NVARCHAR, TEXT | string |
| DATETIME, DATE | string |
| DECIMAL, FLOAT, REAL | number |

## Примітки

1. **Автоматичне виявлення**: Нові процедури автоматично з'являються в списку
2. **Описи**: Витягуються з коментарів у коді (# Description секція)
3. **Параметри**: Автоматично аналізуються з сигнатури процедури
4. **Обов'язкові параметри**: Параметри без DEFAULT значення

## Внутрішня структура

Функція використовує наступні CTE:
- `UtilObjects` - всі об'єкти в схемі mcp
- `ObjectDescriptions` - описи об'єктів
- `AllParameters` - всі параметри
- `ParameterProperties` - JSON properties параметрів
- `RequiredParameters` - обов'язкові параметри
- `ToolsJson` - фінальний JSON для кожного tool

## Вихідний код

Розташування: `/mcp/Functions/ToolsList.sql`

## Пов'язані об'єкти

- `util.mcpBuildToolJson` - побудова JSON для tool
- `util.mcpBuildParameterJson` - побудова JSON для параметра
- `util.mcpGetObjectParameters` - отримання параметрів об'єкта
- `util.mcpMapSqlTypeToJsonType` - маппінг типів
- `util.metadataGetDescriptions` - отримання описів

## Розширення

Щоб додати нову MCP процедуру:
1. Створіть процедуру в схемі `mcp`
2. Додайте структурований коментар з описом
3. Процедура автоматично з'явиться в результаті `ToolsList()`

## Див. також

- [Огляд схеми mcp](../README.md)
- [Список всіх MCP об'єктів](../objects-list.md)
- [Інструкції по розгортанню](../../deploy.md)

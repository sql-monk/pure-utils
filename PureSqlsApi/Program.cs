using System.Data;
using Microsoft.Data.SqlClient;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

// Парсинг аргументів командного рядка
string server = "localhost";
string database = "msdb";
bool integratedSecurity = true;
string? userId = null;
string? password = null;
int port = 51433;
string host = "localhost";

for (int i = 0; i < args.Length; i++)
{
    switch (args[i].ToLower())
    {
        case "--server" or "-s":
            if (i + 1 < args.Length) server = args[++i];
            break;
        case "--database" or "-d":
            if (i + 1 < args.Length) database = args[++i];
            break;
        case "--user" or "-u":
            if (i + 1 < args.Length)
            {
                userId = args[++i];
                integratedSecurity = false;
            }
            break;
        case "--port" or "-p":
            if (i + 1 < args.Length) port = int.Parse(args[++i]);
            break;
        case "--host" or "-h":
            if (i + 1 < args.Length) host = args[++i];
            break;
        case "--help":
            Console.WriteLine("PureSqlsApi - HTTP API адаптер для SQL Server об'єктів у схемі api");
            Console.WriteLine();
            Console.WriteLine("Використання:");
            Console.WriteLine("  --server/-s <server>    SQL Server instance (за замовчуванням: localhost)");
            Console.WriteLine("  --database/-d <db>      База даних (за замовчуванням: msdb)");
            Console.WriteLine("  --user/-u <user>        Користувач SQL (якщо не вказано - Windows auth)");
            Console.WriteLine("  --port/-p <port>        HTTP порт (за замовчуванням: 51433)");
            Console.WriteLine("  --host/-h <host>        HTTP host (за замовчуванням: localhost)");
            Console.WriteLine("  --help                  Ця довідка");
            Console.WriteLine();
            Console.WriteLine("Приклади:");
            Console.WriteLine("  PureSqlsApi --server localhost --database TestDB --port 5000");
            Console.WriteLine("  PureSqlsApi -s myserver -d MyDB -u myuser -p 8080");
            return 0;
    }
}

// Запит паролю якщо потрібна SQL автентифікація
if (!integratedSecurity && !string.IsNullOrEmpty(userId))
{
    Console.Write("Пароль: ");
    password = ReadPassword();
    Console.WriteLine();
}

// Створення connection string
var builder_cs = new SqlConnectionStringBuilder
{
    DataSource = server,
    InitialCatalog = database,
    IntegratedSecurity = integratedSecurity,
    TrustServerCertificate = true,
    Encrypt = true
};

if (!integratedSecurity && !string.IsNullOrEmpty(userId))
{
    builder_cs.UserID = userId;
    builder_cs.Password = password;
}

string connectionString = builder_cs.ConnectionString;

// Перевірка підключення до БД
try
{
    using var testConnection = new SqlConnection(connectionString);
    testConnection.Open();
    Console.WriteLine($"✓ Підключено до SQL Server: {server}, база даних: {database}");
}
catch (Exception ex)
{
    Console.Error.WriteLine($"✗ Помилка підключення до SQL Server: {ex.Message}");
    return 1;
}

// Конфігурація веб-сервера
builder.Services.AddSingleton(connectionString);
builder.WebHost.UseUrls($"http://{host}:{port}");

var app = builder.Build();

// Обробка помилок
app.Use(async (context, next) =>
{
    try
    {
        await next();
    }
    catch (Exception ex)
    {
        context.Response.StatusCode = 500;
        context.Response.ContentType = "application/json";
        
        var errorResponse = new
        {
            error = ex.Message,
            type = ex.GetType().Name
        };
        
        await context.Response.WriteAsJsonAsync(errorResponse);
    }
});

// Маршрут: GET /{resource}/list
app.MapGet("/{resource}/list", async (string resource, HttpContext context, string connectionString) =>
{
    var queryParams = context.Request.Query;
    var result = await ExecuteListFunction(connectionString, resource, queryParams);
    return Results.Json(result);
});

// Маршрут: GET /{resource}/get
app.MapGet("/{resource}/get", async (string resource, HttpContext context, string connectionString) =>
{
    var queryParams = context.Request.Query;
    var result = await ExecuteGetFunction(connectionString, resource, queryParams);
    return Results.Content(result, "application/json");
});

// Маршрут: GET /exec/{procedureName}
app.MapGet("/exec/{procedureName}", async (string procedureName, HttpContext context, string connectionString) =>
{
    var queryParams = context.Request.Query;
    var result = await ExecuteProcedure(connectionString, procedureName, queryParams);
    return Results.Content(result, "application/json");
});

Console.WriteLine($"✓ PureSqlsApi запущено на http://{host}:{port}");
Console.WriteLine();
Console.WriteLine("Доступні маршрути:");
Console.WriteLine($"  GET http://{host}:{port}/{{resource}}/list     - виклик api.{{resource}}List");
Console.WriteLine($"  GET http://{host}:{port}/{{resource}}/get      - виклик api.{{resource}}Get");
Console.WriteLine($"  GET http://{host}:{port}/exec/{{procedureName}} - виклик api.{{procedureName}}");
Console.WriteLine();
Console.WriteLine("Натисніть Ctrl+C для зупинки сервера");

app.Run();

return 0;

// Функція для виконання таблично-функції (list)
static async Task<object> ExecuteListFunction(string connectionString, string resource, IQueryCollection queryParams)
{
    using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync();

    string functionName = $"api.{resource}List";
    using var command = new SqlCommand($"SELECT * FROM {functionName}()", connection);
    command.CommandType = CommandType.Text;
    command.CommandTimeout = 180;

    // Додавання параметрів
    var parameters = BuildParametersFromQuery(queryParams);
    if (parameters.Count > 0)
    {
        var paramList = string.Join(", ", parameters.Select(p => $"@{p.Key}"));
        command.CommandText = $"SELECT * FROM {functionName}({paramList})";
        
        foreach (var param in parameters)
        {
            command.Parameters.AddWithValue($"@{param.Key}", param.Value);
        }
    }

    var jsonArray = new List<JsonElement>();
    using var reader = await command.ExecuteReaderAsync();
    
    while (await reader.ReadAsync())
    {
        // Припускаємо, що є колонка jsondata
        string jsonData = reader.GetString(0);
        var jsonElement = JsonSerializer.Deserialize<JsonElement>(jsonData);
        jsonArray.Add(jsonElement);
    }

    return new
    {
        count = jsonArray.Count,
        data = jsonArray
    };
}

// Функція для виконання скалярної функції (get)
static async Task<string> ExecuteGetFunction(string connectionString, string resource, IQueryCollection queryParams)
{
    using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync();

    string functionName = $"api.{resource}Get";
    using var command = new SqlCommand($"SELECT {functionName}()", connection);
    command.CommandType = CommandType.Text;
    command.CommandTimeout = 180;

    // Додавання параметрів
    var parameters = BuildParametersFromQuery(queryParams);
    if (parameters.Count > 0)
    {
        var paramList = string.Join(", ", parameters.Select(p => $"@{p.Key}"));
        command.CommandText = $"SELECT {functionName}({paramList})";
        
        foreach (var param in parameters)
        {
            command.Parameters.AddWithValue($"@{param.Key}", param.Value);
        }
    }

    var result = await command.ExecuteScalarAsync();
    return result?.ToString() ?? "{}";
}

// Функція для виконання процедури (exec)
static async Task<string> ExecuteProcedure(string connectionString, string procedureName, IQueryCollection queryParams)
{
    using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync();

    using var command = new SqlCommand($"api.{procedureName}", connection);
    command.CommandType = CommandType.StoredProcedure;
    command.CommandTimeout = 180;

    // Додавання OUTPUT параметра
    var responseParam = command.Parameters.Add("@response", SqlDbType.NVarChar, -1);
    responseParam.Direction = ParameterDirection.Output;

    // Додавання вхідних параметрів
    var parameters = BuildParametersFromQuery(queryParams);
    foreach (var param in parameters)
    {
        command.Parameters.AddWithValue($"@{param.Key}", param.Value);
    }

    await command.ExecuteNonQueryAsync();

    return responseParam.Value?.ToString() ?? "{}";
}

// Побудова словника параметрів з query string
static Dictionary<string, object> BuildParametersFromQuery(IQueryCollection queryParams)
{
    var parameters = new Dictionary<string, object>();
    
    foreach (var param in queryParams)
    {
        if (param.Value.Count > 0)
        {
            // Спроба розпарсити як число
            if (int.TryParse(param.Value[0], out int intValue))
            {
                parameters[param.Key] = intValue;
            }
            else if (decimal.TryParse(param.Value[0], out decimal decimalValue))
            {
                parameters[param.Key] = decimalValue;
            }
            else if (bool.TryParse(param.Value[0], out bool boolValue))
            {
                parameters[param.Key] = boolValue;
            }
            else
            {
                parameters[param.Key] = param.Value[0]!;
            }
        }
    }
    
    return parameters;
}

// Функція для безпечного читання паролю
static string ReadPassword()
{
    var password = string.Empty;
    ConsoleKeyInfo key;
    
    do
    {
        key = Console.ReadKey(true);
        
        if (key.Key != ConsoleKey.Backspace && key.Key != ConsoleKey.Enter)
        {
            password += key.KeyChar;
            Console.Write("*");
        }
        else if (key.Key == ConsoleKey.Backspace && password.Length > 0)
        {
            password = password.Substring(0, password.Length - 1);
            Console.Write("\b \b");
        }
    }
    while (key.Key != ConsoleKey.Enter);
    
    return password;
}

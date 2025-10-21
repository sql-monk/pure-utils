using System.Text;
using Microsoft.Data.SqlClient;
using PureSqlsApi;

var builder = WebApplication.CreateBuilder(args);

// Парсимо CLI аргументи
var config = ParseArguments(args);

// Якщо не вказано сервер - виводимо help
if (string.IsNullOrEmpty(config.Server))
{
    ShowHelp();
    return;
}

// Якщо потрібен SQL auth і не вказано пароль - запитуємо
if (!config.UseWindowsAuth && string.IsNullOrEmpty(config.Password))
{
    Console.Write($"Password for user '{config.User}': ");
    config.Password = ReadPassword();
    Console.WriteLine();
}

// Будуємо connection string
var connectionString = BuildConnectionString(config);

// Перевіряємо підключення
var executor = new SqlExecutor(connectionString);
Console.WriteLine($"Testing connection to {config.Server}\\{config.Database}...");

if (!await executor.TestConnectionAsync())
{
    Console.WriteLine("ERROR: Cannot connect to SQL Server");
    return;
}

Console.WriteLine("Connection successful!");

// Налаштовуємо веб-сервер
builder.WebHost.UseUrls($"http://localhost:{config.Port}");

var app = builder.Build();

// Middleware для логування помилок
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
        
        var errorResponse = System.Text.Json.JsonSerializer.Serialize(new
        {
            error = ex.Message,
            type = ex.GetType().Name
        });
        
        Console.WriteLine($"Error: {ex.Message}");
        Console.WriteLine($"Error Type: {ex.GetType().Name}");
        Console.WriteLine($"Stack Trace: {ex.StackTrace}");
        Console.WriteLine($"Request Path: {context.Request.Path}");
        Console.WriteLine($"Request Query: {context.Request.QueryString}");

        await context.Response.WriteAsync(errorResponse);
    }
});

// Головна сторінка з документацією
app.MapGet("/", () => Results.Content(
    """
    <html>
    <head><title>PureSqlsApi</title></head>
    <body>
        <h1>PureSqlsApi - SQL Server REST API Gateway</h1>
        <h2>Available Endpoints:</h2>
        <ul>
            <li><code>GET /{resource}/list?param=value</code> - викликає api.{resource}List()</li>
            <li><code>GET /{resource}/get?param=value</code> - викликає api.{resource}Get()</li>
            <li><code>GET /exec/{procedureName}?param=value</code> - викликає api.{procedureName} процедуру</li>
        </ul>
        <h2>Examples:</h2>
        <ul>
            <li><a href="/databases/list">/databases/list</a></li>
            <li><a href="/databases/get?name=master">/databases/get?name=master</a></li>
            <li><a href="/objects/list?schema=dbo">/objects/list?schema=dbo</a></li>
        </ul>
    </body>
    </html>
    """,
    "text/html"
));

// Маршрут для list (table-valued functions)
app.MapGet("/{resource}/list", async (string resource, HttpContext context) =>
{
    var parameters = context.Request.Query
        .ToDictionary(
            kvp => kvp.Key,
            kvp => kvp.Value.ToString()
        );

    var result = await executor.ExecuteListFunctionAsync(resource, parameters);
    return Results.Content(result, "application/json");
});

// Маршрут для get (scalar functions)
app.MapGet("/{resource}/get", async (string resource, HttpContext context) =>
{
    var parameters = context.Request.Query
        .ToDictionary(
            kvp => kvp.Key,
            kvp => kvp.Value.ToString()
        );

    var result = await executor.ExecuteGetFunctionAsync(resource, parameters);
    return Results.Content(result, "application/json");
});

// Маршрут для exec (stored procedures з OUTPUT)
app.MapGet("/exec/{procedureName}", async (string procedureName, HttpContext context) =>
{
    var parameters = context.Request.Query
        .ToDictionary(
            kvp => kvp.Key,
            kvp => kvp.Value.ToString()
        );

    var result = await executor.ExecuteProcedureAsync(procedureName, parameters);
    return Results.Content(result, "application/json");
});

Console.WriteLine($"\nPureSqlsApi started on http://localhost:{config.Port}");
Console.WriteLine($"Connected to: {config.Server}\\{config.Database}");
Console.WriteLine("\nPress Ctrl+C to stop\n");

app.Run();

// ============================================================================
// Helper Methods
// ============================================================================

static ConnectionConfig ParseArguments(string[] args)
{
    var config = new ConnectionConfig();

    for (int i = 0; i < args.Length; i++)
    {
        var arg = args[i];
        var nextArg = i + 1 < args.Length ? args[i + 1] : null;

        switch (arg)
        {
            case "-s":
            case "--server":
                config.Server = nextArg ?? "";
                i++;
                break;

            case "-d":
            case "--database":
                config.Database = nextArg ?? "msdb";
                i++;
                break;

            case "-u":
            case "--user":
                config.User = nextArg ?? "";
                config.UseWindowsAuth = false;
                i++;
                break;

            case "-p":
            case "--port":
                if (int.TryParse(nextArg, out var port))
                {
                    config.Port = port;
                }
                i++;
                break;

            case "-h":
            case "--help":
                ShowHelp();
                Environment.Exit(0);
                break;
        }
    }
    Console.WriteLine("Configuration:");
    Console.WriteLine($"  Server: {config.Server}");
    Console.WriteLine($"  Database: {config.Database}");
    Console.WriteLine($"  Authentication: {(config.UseWindowsAuth ? "Windows" : "SQL")}");
    Console.WriteLine($"  Port: {config.Port}");
    config.GetType().GetProperties().ToList().ForEach(prop =>
    {
        Console.WriteLine($"  {prop.Name}: {prop.GetValue(config)}");
    });
    return config;
}

static string BuildConnectionString(ConnectionConfig config)
{
    var builder = new SqlConnectionStringBuilder
    {
        DataSource = config.Server,
        InitialCatalog = config.Database,
        TrustServerCertificate = true,
        Encrypt = true
    };

    if (config.UseWindowsAuth)
    {
        builder.IntegratedSecurity = true;
    }
    else
    {
        builder.UserID = config.User;
        builder.Password = config.Password;
    }

    return builder.ConnectionString;
}

static string ReadPassword()
{
    var password = new StringBuilder();
    ConsoleKeyInfo key;

    do
    {
        key = Console.ReadKey(true);

        if (key.Key == ConsoleKey.Backspace && password.Length > 0)
        {
            password.Remove(password.Length - 1, 1);
            Console.Write("\b \b");
        }
        else if (!char.IsControl(key.KeyChar))
        {
            password.Append(key.KeyChar);
            Console.Write("*");
        }
    } while (key.Key != ConsoleKey.Enter);

    return password.ToString();
}

static void ShowHelp()
{
    Console.WriteLine("""
        PureSqlsApi - SQL Server REST API Gateway
        
        Usage:
            PureSqlsApi --server <server> [options]
        
        Required:
            -s, --server <server>       SQL Server instance name
        
        Optional:
            -d, --database <database>   Database name (default: msdb)
            -u, --user <username>       SQL Server user (if not specified, uses Windows Authentication)
            -p, --port <port>           HTTP port (default: 51433)
            -h, --help                  Show this help
        
        Examples:
            # Windows Authentication
            PureSqlsApi --server localhost --database utils
        
            # SQL Authentication
            PureSqlsApi --server localhost --database utils --user sa
        
            # Custom port
            PureSqlsApi --server localhost --database utils --port 8080
        
        API Endpoints:
            GET /{resource}/list?param=value    - Calls api.{resource}List()
            GET /{resource}/get?param=value     - Calls api.{resource}Get()
            GET /exec/{procedure}?param=value   - Calls api.{procedure} with OUTPUT @response
        
        """);
}

// ============================================================================
// Configuration Class
// ============================================================================

class ConnectionConfig
{
    public string Server { get; set; } = "";
    public string Database { get; set; } = "msdb";
    public string User { get; set; } = "";
    public string Password { get; set; } = "";
    public bool UseWindowsAuth { get; set; } = true;
    public int Port { get; set; } = 51433;
}

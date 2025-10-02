using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Data;
using Microsoft.Data.SqlClient;

namespace PureSqlsMcp;

[JsonSourceGenerationOptions(
    PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
    WriteIndented = false,
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull)]
[JsonSerializable(typeof(JsonRpcRequest))]
[JsonSerializable(typeof(JsonRpcResponse))]
[JsonSerializable(typeof(JsonRpcError))]
[JsonSerializable(typeof(JsonElement))]
[JsonSerializable(typeof(Dictionary<string, object>))]
[JsonSerializable(typeof(object))]
internal partial class JsonContext : JsonSerializerContext
{
}

public class PureMcpServer
{
    private readonly string _connectionString;
    private readonly string _serverName;
    private readonly string _databaseName;
    private readonly bool _integratedSecurity;
    private readonly string? _userId;
    private readonly string? _password;
    
    private readonly JsonSerializerOptions _jsonOptions;

    public PureMcpServer(string server, string database, bool integratedSecurity = true, 
        string? userId = null, string? password = null)
    {
        _serverName = server;
        _databaseName = database;
        _integratedSecurity = integratedSecurity;
        _userId = userId;
        _password = password;
        
        var builder = new SqlConnectionStringBuilder
        {
            DataSource = server,
            InitialCatalog = database,
            IntegratedSecurity = integratedSecurity,
            TrustServerCertificate = true,
            Encrypt = true
        };

        if (!integratedSecurity && !string.IsNullOrEmpty(userId))
        {
            builder.UserID = userId;
            builder.Password = password;
        }

        _connectionString = builder.ConnectionString;
        
        _jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = false,
            DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
            TypeInfoResolver = JsonContext.Default
        };
    }

    public async Task RunAsync()
    {
        Console.Error.WriteLine("PureSqlsMcp started");
        Console.Error.WriteLine();

        using var stdin = Console.OpenStandardInput();
        using var stdout = Console.OpenStandardOutput();
        var encoding = new UTF8Encoding(false);
        using var reader = new StreamReader(stdin, encoding);
        using var writer = new StreamWriter(stdout, encoding) { AutoFlush = true };

        while (!reader.EndOfStream)
        {
            var line = await reader.ReadLineAsync();
            if (string.IsNullOrEmpty(line)) continue;

            try
            {
                
                var request = JsonSerializer.Deserialize(line, JsonContext.Default.JsonRpcRequest);
                if (request == null) continue;

                if (!request.Id.HasValue || request.Id.Value.ValueKind == JsonValueKind.Null)
                {
                    Console.Error.WriteLine($"notification: {request.Method}");
                    continue;
                }

                var response = await ProcessRequestAsync(request);
                var responseJson = JsonSerializer.Serialize(response, JsonContext.Default.JsonRpcResponse);

                Console.Error.WriteLine($"response: {responseJson}");

                await writer.WriteLineAsync(responseJson);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"error: {ex.Message}");
                Console.Error.WriteLine($"Stack trace: {ex.StackTrace}");
            }
        }
    }

    private async Task<JsonRpcResponse> ProcessRequestAsync(JsonRpcRequest request)
    {
        try
        {
            switch (request.Method)
            {
                case "initialize":
                    var initResult = new Dictionary<string, object>
                    {
                        ["protocolVersion"] = "2024-11-05",
                        ["serverInfo"] = new Dictionary<string, object>
                        {
                            ["name"] = "mcp-sqlserver-dynamic",
                            ["version"] = "2.0.0"
                        },
                        ["capabilities"] = new Dictionary<string, object>
                        {
                            ["tools"] = new Dictionary<string, object>()
                        }
                    };
                    return new JsonRpcResponse 
                    { 
                        Id = request.Id,
                        Result = initResult
                    };

                case "tools/list":
                    return new JsonRpcResponse 
                    { 
                        Id = request.Id,
                        Result = await GetToolsListAsync()
                    };

                case "tools/call":
                    return new JsonRpcResponse 
                    { 
                        Id = request.Id,
                        Result = await CallToolAsync(request.Params)
                    };

                default:
                    return new JsonRpcResponse
                    {
                        Id = request.Id,
                        Error = new JsonRpcError
                        {
                            Code = -32601,
                            Message = $"unknown method: {request.Method}"
                        }
                    };
            }
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Error ProcessRequest: {ex.GetType().Name}: {ex.Message}");
            Console.Error.WriteLine($"Stack trace: {ex.StackTrace}");
            return new JsonRpcResponse
            {
                Id = request.Id,
                Error = new JsonRpcError
                {
                    Code = -32603,
                    Message = $"Internal error: {ex.GetType().Name}: {ex.Message}"
                }
            };
        }
    }

    private async Task<object> GetToolsListAsync()
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand("SELECT mcp.ToolsList()", connection);
        command.CommandType = CommandType.Text;

        var result = await command.ExecuteScalarAsync();
        var jsonString = result?.ToString() ?? "{}";
        
       
        return JsonSerializer.Deserialize(jsonString, JsonContext.Default.JsonElement);
    }

    private async Task<object> CallToolAsync(JsonElement? paramsElement)
    {
        if (!paramsElement.HasValue)
        {
            throw new ArgumentException("empty params for tools/call");
        }

        var toolName = paramsElement.Value.GetProperty("name").GetString();
        

        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand($"mcp.{toolName}", connection);
        command.CommandType = CommandType.StoredProcedure;

        if (paramsElement.Value.TryGetProperty("arguments", out var args) && args.ValueKind == JsonValueKind.Object)
        {
            foreach (var prop in args.EnumerateObject())
            {
                object paramValue = prop.Value.ValueKind switch
                {
                    JsonValueKind.String => prop.Value.GetString() ?? (object)DBNull.Value,
                    JsonValueKind.Number => prop.Value.GetDecimal(),
                    JsonValueKind.True => true,
                    JsonValueKind.False => false,
                    JsonValueKind.Null => DBNull.Value,
                    _ => prop.Value.GetRawText()
                };
                
                command.Parameters.AddWithValue($"@{prop.Name}", paramValue);
            }
        }

        using var reader = await command.ExecuteReaderAsync();
        
        string jsonString = "{}";
        if (await reader.ReadAsync())
        {
            jsonString = reader.GetString(0);
        }


        return JsonSerializer.Deserialize(jsonString, JsonContext.Default.JsonElement);
    }
}

// JSON-RPC ?????
public class JsonRpcRequest
{
    public string Jsonrpc { get; set; } = "2.0";
    public string Method { get; set; } = "";
    public JsonElement? Params { get; set; }
    public JsonElement? Id { get; set; }
}

public class JsonRpcResponse
{
    [JsonPropertyName("jsonrpc")]
    public string Jsonrpc { get; set; } = "2.0";
    
    [JsonPropertyName("id")]
    public JsonElement? Id { get; set; }
    
    [JsonPropertyName("result")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public object? Result { get; set; }
    
    [JsonPropertyName("error")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public JsonRpcError? Error { get; set; }
}

public class JsonRpcError
{
    [JsonPropertyName("code")]
    public int Code { get; set; }
    
    [JsonPropertyName("message")]
    public string Message { get; set; } = "";
    
    [JsonPropertyName("data")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public object? Data { get; set; }
}

using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;

namespace PlanSqlsMcp;

[JsonSourceGenerationOptions(
    PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
    WriteIndented = false,
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull)]
[JsonSerializable(typeof(JsonRpcRequest))]
[JsonSerializable(typeof(JsonRpcResponse))]
[JsonSerializable(typeof(JsonRpcError))]
[JsonSerializable(typeof(JsonElement))]
[JsonSerializable(typeof(Dictionary<string, object>))]
[JsonSerializable(typeof(List<object>))]
[JsonSerializable(typeof(List<string>))]
[JsonSerializable(typeof(string))]
[JsonSerializable(typeof(object))]
internal partial class JsonContext : JsonSerializerContext
{
}

public class PlanMcpServer
{
  private readonly string _connectionString;
  private readonly string _serverName;
  private readonly string _databaseName;
  private readonly JsonSerializerOptions _jsonOptions;

  // Regex для видалення SET SHOWPLAN_* команд
  private static readonly Regex ShowplanRegex = new Regex(
      @"SET\s+SHOWPLAN[_A-Z]*\s+(ON|OFF)\s*;?\s*",
      RegexOptions.IgnoreCase | RegexOptions.Compiled | RegexOptions.Multiline
  );

  // Regex для видалення GO батчів
  private static readonly Regex GoRegex = new Regex(
      @"^\s*GO\s*$",
      RegexOptions.IgnoreCase | RegexOptions.Compiled | RegexOptions.Multiline
  );

  public PlanMcpServer(string server, string database, bool integratedSecurity = true,
      string? userId = null, string? password = null)
  {
    _serverName = server;
    _databaseName = database;

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
    Console.Error.WriteLine("PlanSqlsMcp started");
    Console.Error.WriteLine($"Server: {_serverName}, Database: {_databaseName}");
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
              ["name"] = "mcp-sqlserver-execution-plan",
              ["version"] = "1.0.0"
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
            Result = GetToolsList()
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

  private object GetToolsList()
  {
    var tools = new List<object>
    {
      new Dictionary<string, object>
      {
        ["name"] = "ShowEstimatedExecutionPlan",
        ["description"] = "Отримує estimated execution plan для SQL запиту в форматі XML",
        ["inputSchema"] = new Dictionary<string, object>
        {
          ["type"] = "object",
          ["properties"] = new Dictionary<string, object>
          {
            ["query"] = new Dictionary<string, object>
            {
              ["type"] = "string",
              ["description"] = "SQL запит для якого потрібно отримати estimated execution plan"
            }
          },
          ["required"] = new List<string> { "query" }
        }
      }
    };

    return new Dictionary<string, object>
    {
      ["tools"] = tools
    };
  }

  private async Task<object> CallToolAsync(JsonElement? paramsElement)
  {
    if (!paramsElement.HasValue)
    {
      throw new ArgumentException("empty params for tools/call");
    }

    var toolName = paramsElement.Value.GetProperty("name").GetString();

    if (toolName != "ShowEstimatedExecutionPlan")
    {
      throw new ArgumentException($"Unknown tool: {toolName}");
    }

    // Отримуємо query з аргументів
    if (!paramsElement.Value.TryGetProperty("arguments", out var args) ||
        !args.TryGetProperty("query", out var queryElement))
    {
      throw new ArgumentException("Missing 'query' argument");
    }

    var query = queryElement.GetString();
    if (string.IsNullOrWhiteSpace(query))
    {
      throw new ArgumentException("Query cannot be empty");
    }

    // Очищаємо query від SET SHOWPLAN команд і GO
    var cleanQuery = CleanQuery(query);

    // Отримуємо execution plan
    var executionPlan = await GetExecutionPlanAsync(cleanQuery);

    // Повертаємо результат у форматі MCP
    return new Dictionary<string, object>
    {
      ["content"] = new List<object>
      {
        new Dictionary<string, object>
        {
          ["type"] = "text",
          ["text"] = executionPlan
        }
      }
    };
  }

  private string CleanQuery(string query)
  {
    // Видаляємо всі SET SHOWPLAN_* оператори
    var cleaned = ShowplanRegex.Replace(query, string.Empty);

    // Видаляємо GO батчі
    cleaned = GoRegex.Replace(cleaned, string.Empty);

    // Видаляємо зайві порожні рядки
    cleaned = Regex.Replace(cleaned, @"^\s*\r?\n", string.Empty, RegexOptions.Multiline);
    cleaned = Regex.Replace(cleaned, @"\r?\n\s*$", string.Empty, RegexOptions.Multiline);

    return cleaned.Trim();
  }

  private async Task<string> GetExecutionPlanAsync(string query)
  {
    using var connection = new SqlConnection(_connectionString);
    await connection.OpenAsync();

    try
    {
      // Вмикаємо SHOWPLAN_XML
      using (var cmdOn = new SqlCommand("SET SHOWPLAN_XML ON", connection))
      {
        await cmdOn.ExecuteNonQueryAsync();
      }

      // Виконуємо запит і отримуємо план
      using var cmdQuery = new SqlCommand(query, connection);
      cmdQuery.CommandTimeout = 180;

      using var reader = await cmdQuery.ExecuteReaderAsync();
      
      string? executionPlan = null;
      if (await reader.ReadAsync())
      {
        executionPlan = reader.GetString(0);
      }

      reader.Close();

      // Вимикаємо SHOWPLAN_XML
      using (var cmdOff = new SqlCommand("SET SHOWPLAN_XML OFF", connection))
      {
        await cmdOff.ExecuteNonQueryAsync();
      }

      return executionPlan ?? "No execution plan returned";
    }
    catch (Exception ex)
    {
      // У разі помилки гарантуємо що SHOWPLAN вимкнено
      try
      {
        using var cmdOff = new SqlCommand("SET SHOWPLAN_XML OFF", connection);
        await cmdOff.ExecuteNonQueryAsync();
      }
      catch
      {
        // Ігноруємо помилку при вимиканні
      }

      throw new Exception($"Error getting execution plan: {ex.Message}", ex);
    }
  }
}

// JSON-RPC класи
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

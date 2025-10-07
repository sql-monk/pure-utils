using System.Data;
using System.Diagnostics;
using System.Text.Json;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;
using PureSqlsMcpWeb.Models;

namespace PureSqlsMcpWeb.Services;

/// <summary>
/// Сервіс для роботи з SQL Server інструментами
/// </summary>
public class SqlToolsService
{
    private readonly string _connectionString;
    private readonly int _commandTimeout;
    private readonly ILogger<SqlToolsService> _logger;

    public SqlToolsService(IOptions<SqlConnectionOptions> options, ILogger<SqlToolsService> logger)
    {
        _logger = logger;
        var opts = options.Value;
        _commandTimeout = opts.CommandTimeout;

        var builder = new SqlConnectionStringBuilder
        {
            DataSource = opts.Server,
            InitialCatalog = opts.Database,
            IntegratedSecurity = opts.IntegratedSecurity,
            TrustServerCertificate = opts.TrustServerCertificate,
            Encrypt = opts.Encrypt
        };

        if (!opts.IntegratedSecurity && !string.IsNullOrEmpty(opts.UserId))
        {
            builder.UserID = opts.UserId;
            builder.Password = opts.Password;
        }

        _connectionString = builder.ConnectionString;

        _logger.LogInformation("SqlToolsService initialized for server: {Server}, database: {Database}", 
            opts.Server, opts.Database);
    }

    /// <summary>
    /// Отримати список доступних інструментів
    /// </summary>
    public async Task<JsonElement> GetToolsListAsync()
    {
        try
        {
            _logger.LogInformation("Getting tools list");

            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();

            using var command = new SqlCommand("SELECT mcp.ToolsList()", connection);
            command.CommandType = CommandType.Text;
            command.CommandTimeout = _commandTimeout;

            var result = await command.ExecuteScalarAsync();
            var jsonString = result?.ToString() ?? "{}";

            _logger.LogInformation("Tools list retrieved successfully");

            return JsonSerializer.Deserialize<JsonElement>(jsonString);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting tools list");
            throw;
        }
    }

    /// <summary>
    /// Викликати інструмент (процедуру)
    /// </summary>
    public async Task<ToolCallResponse> CallToolAsync(string toolName, Dictionary<string, object>? arguments)
    {
        var sw = Stopwatch.StartNew();
        
        try
        {
            _logger.LogInformation("Calling tool: {ToolName} with arguments: {Arguments}", 
                toolName, JsonSerializer.Serialize(arguments));

            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();

            using var command = new SqlCommand($"mcp.{toolName}", connection);
            command.CommandType = CommandType.StoredProcedure;
            command.CommandTimeout = _commandTimeout;

            // Додаємо параметри
            if (arguments != null)
            {
                foreach (var arg in arguments)
                {
                    object paramValue = arg.Value switch
                    {
                        JsonElement jsonElement => ConvertJsonElement(jsonElement),
                        null => DBNull.Value,
                        _ => arg.Value
                    };

                    command.Parameters.AddWithValue($"@{arg.Key}", paramValue);
                }
            }

            // Виконуємо процедуру
            using var reader = await command.ExecuteReaderAsync();

            string jsonString = "{}";
            if (await reader.ReadAsync())
            {
                jsonString = reader.GetString(0);
            }

            sw.Stop();

            _logger.LogInformation("Tool {ToolName} executed successfully in {ElapsedMs}ms", 
                toolName, sw.ElapsedMilliseconds);

            return new ToolCallResponse
            {
                Success = true,
                Result = JsonSerializer.Deserialize<JsonElement>(jsonString),
                ExecutionTimeMs = sw.ElapsedMilliseconds
            };
        }
        catch (Exception ex)
        {
            sw.Stop();
            _logger.LogError(ex, "Error calling tool {ToolName}", toolName);

            return new ToolCallResponse
            {
                Success = false,
                ErrorMessage = $"{ex.GetType().Name}: {ex.Message}",
                ExecutionTimeMs = sw.ElapsedMilliseconds
            };
        }
    }

    /// <summary>
    /// Перевірити підключення до БД
    /// </summary>
    public async Task<bool> TestConnectionAsync()
    {
        try
        {
            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Connection test failed");
            return false;
        }
    }

    private static object ConvertJsonElement(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.String => (object)(element.GetString() ?? string.Empty),
            JsonValueKind.Number => element.TryGetInt32(out var intVal) ? intVal : element.GetDecimal(),
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Null => DBNull.Value,
            _ => element.GetRawText()
        };
    }
}

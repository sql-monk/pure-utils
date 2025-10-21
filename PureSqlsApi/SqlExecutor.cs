using System.Data;
using System.Text.Json;
using Microsoft.Data.SqlClient;

namespace PureSqlsApi;

/// <summary>
/// Helper клас для виконання SQL-запитів
/// </summary>
public class SqlExecutor
{
    private readonly string _connectionString;

    public SqlExecutor(string connectionString)
    {
        _connectionString = connectionString;
    }

    /// <summary>
    /// Виконує table-valued function api.{resource}List і повертає JSON-масив
    /// </summary>
    public async Task<string> ExecuteListFunctionAsync(string resourceName, Dictionary<string, string> parameters)
    {
        Console.WriteLine($"{_connectionString}");
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        // Будуємо виклик функції з параметрами
        var paramNames = string.Join(", ", parameters.Select(p => $"@{p.Key}"));
        var sql = paramNames.Length > 0 
            ? $"SELECT * FROM api.{resourceName}List({paramNames})"
            : $"SELECT * FROM api.{resourceName}List()";

        using var command = new SqlCommand(sql, connection);
        command.CommandType = CommandType.Text;
        command.CommandTimeout = 180;

        // Додаємо параметри
        foreach (var param in parameters)
        {
            command.Parameters.AddWithValue($"@{param.Key}", 
                string.IsNullOrEmpty(param.Value) ? DBNull.Value : param.Value);
        }

        
        Console.WriteLine("Executing SQL Command:");
        Console.WriteLine(sql);


        var results = new List<JsonElement>();
        using var reader = await command.ExecuteReaderAsync();

        while (await reader.ReadAsync())
        {
            // Читаємо всі колонки як JSON об'єкт
            var row = new Dictionary<string, object?>();
            for (int i = 0; i < reader.FieldCount; i++)
            {
                var fieldName = reader.GetName(i);
                var value = reader.IsDBNull(i) ? null : reader.GetValue(i);
                row[fieldName] = value;
            }
            
            var jsonString = JsonSerializer.Serialize(row);
            results.Add(JsonSerializer.Deserialize<JsonElement>(jsonString));
        }

        // Повертаємо об'єкт з data та count
        var response = new
        {
            data = results,
            count = results.Count
        };

        return JsonSerializer.Serialize(response, new JsonSerializerOptions 
        { 
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = true 
        });
    }

    /// <summary>
    /// Виконує scalar function api.{resource}Get і повертає JSON
    /// </summary>
    public async Task<string> ExecuteGetFunctionAsync(string resourceName, Dictionary<string, string> parameters)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        // Будуємо виклик скалярної функції
        var paramNames = string.Join(", ", parameters.Select(p => $"@{p.Key}"));
        var sql = $"SELECT api.{resourceName}Get({paramNames})";

        using var command = new SqlCommand(sql, connection);
        command.CommandType = CommandType.Text;
        command.CommandTimeout = 180;

        // Додаємо параметри
        foreach (var param in parameters)
        {
            command.Parameters.AddWithValue($"@{param.Key}", 
                string.IsNullOrEmpty(param.Value) ? DBNull.Value : param.Value);
        }

        var result = await command.ExecuteScalarAsync();
        var jsonString = result?.ToString() ?? "null";

        return jsonString;
    }

    /// <summary>
    /// Виконує stored procedure api.{procedureName} з OUTPUT параметром @response
    /// </summary>
    public async Task<string> ExecuteProcedureAsync(string procedureName, Dictionary<string, string> parameters)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand($"api.{procedureName}", connection);
        command.CommandType = CommandType.StoredProcedure;
        command.CommandTimeout = 180;

        // Додаємо вхідні параметри
        foreach (var param in parameters)
        {
            command.Parameters.AddWithValue($"@{param.Key}", 
                string.IsNullOrEmpty(param.Value) ? DBNull.Value : param.Value);
        }

        // Додаємо OUTPUT параметр
        var outputParam = command.Parameters.Add("@response", SqlDbType.NVarChar, -1);
        outputParam.Direction = ParameterDirection.Output;

        await command.ExecuteNonQueryAsync();

        var jsonString = outputParam.Value?.ToString() ?? "null";
        return jsonString;
    }

    /// <summary>
    /// Перевіряє з'єднання з базою даних
    /// </summary>
    public async Task<bool> TestConnectionAsync()
    {
        try
        {
            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();
            return true;
        }
        catch
        {
            return false;
        }
    }
}

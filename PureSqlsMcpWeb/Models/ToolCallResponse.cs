using System.Text.Json;

namespace PureSqlsMcpWeb.Models;

/// <summary>
/// Відповідь на виклик інструменту
/// </summary>
public class ToolCallResponse
{
    /// <summary>
    /// Успішність виконання
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// Результат виконання (JSON)
    /// </summary>
    public JsonElement? Result { get; set; }

    /// <summary>
    /// Повідомлення про помилку (якщо є)
    /// </summary>
    public string? ErrorMessage { get; set; }

    /// <summary>
    /// Час виконання в мілісекундах
    /// </summary>
    public long ExecutionTimeMs { get; set; }
}

namespace PureSqlsMcpWeb.Models;

/// <summary>
/// Запит на виклик інструменту
/// </summary>
public class ToolCallRequest
{
    /// <summary>
    /// Назва інструменту (процедури)
    /// </summary>
    public string ToolName { get; set; } = string.Empty;

    /// <summary>
    /// Аргументи для виклику
    /// </summary>
    public Dictionary<string, object>? Arguments { get; set; }
}

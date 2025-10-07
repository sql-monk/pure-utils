using System.Text.Json;

namespace PureSqlsMcpWeb.Models;

/// <summary>
/// Інформація про інструмент
/// </summary>
public class ToolInfo
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public JsonElement? InputSchema { get; set; }
}

/// <summary>
/// Список доступних інструментів
/// </summary>
public class ToolsListResponse
{
    public List<ToolInfo> Tools { get; set; } = new();
}

using Microsoft.AspNetCore.Mvc;
using PureSqlsMcpWeb.Models;
using PureSqlsMcpWeb.Services;

namespace PureSqlsMcpWeb.Controllers;

/// <summary>
/// API для роботи з SQL Server інструментами
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class ToolsController : ControllerBase
{
    private readonly SqlToolsService _sqlToolsService;
    private readonly ILogger<ToolsController> _logger;

    public ToolsController(SqlToolsService sqlToolsService, ILogger<ToolsController> logger)
    {
        _sqlToolsService = sqlToolsService;
        _logger = logger;
    }

    /// <summary>
    /// Отримати список доступних інструментів
    /// </summary>
    /// <returns>Список інструментів з їх описом та параметрами</returns>
    [HttpGet("list")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetToolsList()
    {
        try
        {
            var result = await _sqlToolsService.GetToolsListAsync();
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting tools list");
            return StatusCode(500, new { error = ex.Message });
        }
    }

    /// <summary>
    /// Викликати конкретний інструмент
    /// </summary>
    /// <param name="request">Запит з назвою інструменту та аргументами</param>
    /// <returns>Результат виконання інструменту</returns>
    [HttpPost("call")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> CallTool([FromBody] ToolCallRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.ToolName))
        {
            return BadRequest(new { error = "ToolName is required" });
        }

        try
        {
            var result = await _sqlToolsService.CallToolAsync(request.ToolName, request.Arguments);
            
            if (result.Success)
            {
                return Ok(result);
            }
            else
            {
                return StatusCode(500, result);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calling tool {ToolName}", request.ToolName);
            return StatusCode(500, new { error = ex.Message });
        }
    }

    /// <summary>
    /// Викликати інструмент через GET запит (для простих запитів без параметрів)
    /// </summary>
    /// <param name="toolName">Назва інструменту</param>
    /// <returns>Результат виконання інструменту</returns>
    [HttpGet("call/{toolName}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> CallToolGet(string toolName)
    {
        if (string.IsNullOrWhiteSpace(toolName))
        {
            return BadRequest(new { error = "ToolName is required" });
        }

        try
        {
            // Отримуємо query parameters як аргументи
            var arguments = Request.Query
                .Where(q => q.Key != "toolName")
                .ToDictionary(q => q.Key, q => (object)q.Value.ToString());

            var result = await _sqlToolsService.CallToolAsync(toolName, arguments.Count > 0 ? arguments : null);
            
            if (result.Success)
            {
                return Ok(result);
            }
            else
            {
                return StatusCode(500, result);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calling tool {ToolName}", toolName);
            return StatusCode(500, new { error = ex.Message });
        }
    }

    /// <summary>
    /// Перевірити підключення до бази даних
    /// </summary>
    /// <returns>Статус підключення</returns>
    [HttpGet("connection-test")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<IActionResult> TestConnection()
    {
        var isConnected = await _sqlToolsService.TestConnectionAsync();
        
        if (isConnected)
        {
            return Ok(new { status = "connected", timestamp = DateTime.UtcNow });
        }
        else
        {
            return StatusCode(503, new { status = "disconnected", timestamp = DateTime.UtcNow });
        }
    }
}
